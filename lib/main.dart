import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:luma/core/l10n/gen/app_localizations.dart';
import 'package:luma/core/l10n/locale_cubit.dart';
import 'package:luma/core/l10n/locale_preference.dart';
import 'package:luma/core/l10n/locale_store.dart';
import 'package:luma/core/theme/app_theme.dart';
import 'package:luma/core/theme/reader_settings_cubit.dart';
import 'package:luma/data/db/app_database.dart';
import 'package:luma/data/files/reader_settings_store.dart';
import 'package:luma/data/files/reminder_preference_store.dart';
import 'package:luma/data/repositories/plan_repository.dart';
import 'package:luma/domain/notifications/reminder_window.dart';
import 'package:luma/features/settings/settings_page.dart';
import 'package:luma/features/today/today_page.dart';
import 'package:luma/services/notifications/local_notification_service.dart';
import 'package:luma/services/notifications/notification_coordinator.dart';
import 'package:luma/services/notifications/reminder_copy.dart';
import 'package:luma/services/notifications/reminder_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localeCubit = LocaleCubit(FileLocaleStore());
  final readerSettingsCubit = ReaderSettingsCubit(FileReaderSettingsStore());
  await Future.wait([localeCubit.load(), readerSettingsCubit.load()]);

  final database = AppDatabase();
  final planRepository = PlanRepository(database);
  final notificationService = LocalNotificationService();
  final reminders = NotificationCoordinator(
    service: notificationService,
    loadPendingDays: planRepository.findPendingDaysBetween,
    preferences: FileReminderPreferenceStore(),
  );

  // Initialise before the first frame so a cold-start notification tap can be
  // routed to Today. Scheduling itself can run after the UI is visible.
  try {
    await notificationService.initialize();
  } on Exception {
    // Reminders are optional; the rest of the app still works without them.
  }

  runApp(
    LumaApp(
      localeCubit: localeCubit,
      readerSettingsCubit: readerSettingsCubit,
      reminders: reminders,
    ),
  );

  unawaited(_refreshReminders(reminders, localeCubit.state));
}

Future<void> _refreshReminders(
  NotificationCoordinator reminders,
  LocalePreference preference,
) async {
  try {
    final l10n = await _loadLocalizations(preference);
    await reminders.rescheduleUpcoming(
      copy: ReminderCopy(
        title: l10n.reminderNotificationTitle,
        body: l10n.reminderNotificationBody,
      ),
    );
  } on Exception {
    // A failed refresh must never block the app; the next open retries.
  }
}

Future<AppLocalizations> _loadLocalizations(LocalePreference preference) {
  final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
  final locale =
      preference.locale ??
      (deviceLocale.languageCode == 'ar'
          ? const Locale('ar')
          : const Locale('en'));
  return AppLocalizations.delegate.load(locale);
}

/// Root widget of the app.
class LumaApp extends StatelessWidget {
  const LumaApp({
    super.key,
    required this.localeCubit,
    required this.readerSettingsCubit,
    this.reminders,
  });

  final LocaleCubit localeCubit;
  final ReaderSettingsCubit readerSettingsCubit;
  final ReminderManager? reminders;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: localeCubit),
        BlocProvider.value(value: readerSettingsCubit),
      ],
      child: _LocalizedApp(reminders: reminders),
    );
  }
}

class _LocalizedApp extends StatefulWidget {
  const _LocalizedApp({this.reminders});

  final ReminderManager? reminders;

  @override
  State<_LocalizedApp> createState() => _LocalizedAppState();
}

class _LocalizedAppState extends State<_LocalizedApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final preference = context.watch<LocaleCubit>().state;
    final readerSettings = context.watch<ReaderSettingsCubit>().state;
    final theme = AppTheme.build(
      readerSettings.theme,
      isArabic: _usesArabicUi(preference),
    );
    final reminders = widget.reminders;

    return MaterialApp(
      navigatorKey: _navigatorKey,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: preference.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.light,
      routes: {TodayPage.routeName: (_) => const TodayPage()},
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        if (reminders == null) return content;
        return _NotificationTapHandler(
          navigatorKey: _navigatorKey,
          reminders: reminders,
          child: content,
        );
      },
      home: SettingsPage(reminders: reminders),
    );
  }

  /// Reader theme wins over the device theme; this only resolves the UI font.
  bool _usesArabicUi(LocalePreference preference) {
    if (preference == LocalePreference.ar) return true;
    if (preference == LocalePreference.en) return false;
    return WidgetsBinding.instance.platformDispatcher.locale.languageCode ==
        'ar';
  }
}

class _NotificationTapHandler extends StatefulWidget {
  const _NotificationTapHandler({
    required this.navigatorKey,
    required this.reminders,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final ReminderManager reminders;
  final Widget child;

  @override
  State<_NotificationTapHandler> createState() =>
      _NotificationTapHandlerState();
}

class _NotificationTapHandlerState extends State<_NotificationTapHandler> {
  StreamSubscription<String>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.reminders.taps.listen(_openIfToday);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final payload = await widget.reminders.takeLaunchPayload();
      if (!mounted) return;
      _openIfToday(payload);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _openIfToday(String? payload) {
    if (payload != todayReminderPayload) return;
    widget.navigatorKey.currentState?.pushNamed(TodayPage.routeName);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
