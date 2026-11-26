// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Luma';

  @override
  String dayOfTotal(int current, int total) {
    return 'Day $current of $total';
  }

  @override
  String daysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
      zero: 'No days left',
    );
    return '$_temp0';
  }

  @override
  String get doneForToday => 'Done for today';

  @override
  String get explainThisPart => 'Explain this part';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appLanguage => 'App language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get readerSettings => 'Reader settings';

  @override
  String get fontSize => 'Font size';

  @override
  String get lineHeight => 'Line spacing';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSepia => 'Sepia';

  @override
  String get themeDark => 'Dark';

  @override
  String get arabicDigits => 'Arabic digits';

  @override
  String get readerPreviewText =>
      'The quiet morning light spread slowly across the page, and the day began with a few calm lines.';

  @override
  String get notificationsSection => 'Notifications';

  @override
  String get notificationDailyReminder => 'Daily reminder';

  @override
  String get notificationSubtitleOn =>
      'One gentle reminder a day, when a reading is waiting.';

  @override
  String get notificationSubtitleOff =>
      'Off. Turn on one gentle reminder a day.';

  @override
  String get notificationPermissionTitle => 'A gentle daily nudge';

  @override
  String get notificationPermissionBody =>
      'Luma can send one quiet reminder when a reading is waiting. No streaks, no pressure. You can turn it off in Settings anytime.';

  @override
  String get notificationPermissionEnable => 'Turn on reminders';

  @override
  String get notificationPermissionNotNow => 'Not now';

  @override
  String get notificationPermissionDenied =>
      'Notifications are off. You can allow them in your device settings.';

  @override
  String get notificationPermissionGranted => 'Reminders are on.';

  @override
  String get notificationOpenSettings => 'Open settings';

  @override
  String get reminderNotificationTitle => 'A quiet moment for reading';

  @override
  String get reminderNotificationBody =>
      'Your next reading is ready whenever you are.';

  @override
  String get todayTitle => 'Today';

  @override
  String get todayPlaceholder => 'Your daily reading will appear here.';
}
