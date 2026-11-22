// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'لوما';

  @override
  String dayOfTotal(int current, int total) {
    return 'اليوم $current من $total';
  }

  @override
  String daysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم متبقٍ',
      many: '$count يومًا متبقيًا',
      few: '$count أيام متبقية',
      two: 'يومان متبقيان',
      one: 'يوم واحد متبقٍ',
      zero: 'لا أيام متبقية',
    );
    return '$_temp0';
  }

  @override
  String get doneForToday => 'انتهيت لهذا اليوم';

  @override
  String get explainThisPart => 'اشرح هذا الجزء';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get appLanguage => 'لغة التطبيق';

  @override
  String get languageSystem => 'النظام';

  @override
  String get languageEnglish => 'الإنجليزية';

  @override
  String get languageArabic => 'العربية';

  @override
  String get readerSettings => 'إعدادات القراءة';

  @override
  String get fontSize => 'حجم الخط';

  @override
  String get lineHeight => 'تباعد الأسطر';

  @override
  String get theme => 'المظهر';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeSepia => 'ورقي';

  @override
  String get themeDark => 'داكن';

  @override
  String get arabicDigits => 'الأرقام العربية';

  @override
  String get readerPreviewText =>
      'ضوء الصباح الهادئ ينتشر بهدوء على الصفحة، ويبدأ اليوم ببضعة أسطر مطمئنة.';
}
