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
}
