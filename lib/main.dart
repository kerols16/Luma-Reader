import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:luma/core/l10n/gen/app_localizations.dart';
import 'package:luma/core/l10n/locale_cubit.dart';
import 'package:luma/core/l10n/locale_preference.dart';
import 'package:luma/core/l10n/locale_store.dart';
import 'package:luma/core/theme/app_theme.dart';
import 'package:luma/core/theme/reader_settings_cubit.dart';
import 'package:luma/data/files/reader_settings_store.dart';
import 'package:luma/features/settings/settings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localeCubit = LocaleCubit(FileLocaleStore());
  final readerSettingsCubit = ReaderSettingsCubit(FileReaderSettingsStore());
  await Future.wait([localeCubit.load(), readerSettingsCubit.load()]);

  runApp(
    LumaApp(localeCubit: localeCubit, readerSettingsCubit: readerSettingsCubit),
  );
}

/// Root widget of the app.
///
/// Routing is wired up in a later step.
class LumaApp extends StatelessWidget {
  const LumaApp({
    super.key,
    required this.localeCubit,
    required this.readerSettingsCubit,
  });

  final LocaleCubit localeCubit;
  final ReaderSettingsCubit readerSettingsCubit;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: localeCubit),
        BlocProvider.value(value: readerSettingsCubit),
      ],
      child: const _LocalizedApp(),
    );
  }
}

class _LocalizedApp extends StatelessWidget {
  const _LocalizedApp();

  @override
  Widget build(BuildContext context) {
    final preference = context.watch<LocaleCubit>().state;
    final readerSettings = context.watch<ReaderSettingsCubit>().state;
    final theme = AppTheme.build(
      readerSettings.theme,
      isArabic: _usesArabicUi(preference),
    );

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: preference.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.light,
      home: const SettingsPage(),
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
