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

  @override
  String get notificationsSection => 'الإشعارات';

  @override
  String get notificationDailyReminder => 'التذكير اليومي';

  @override
  String get notificationSubtitleOn =>
      'تذكير لطيف واحد يوميًا، عندما تكون هناك قراءة بانتظارك.';

  @override
  String get notificationSubtitleOff => 'متوقف. فعّله لتذكير لطيف واحد كل يوم.';

  @override
  String get notificationPermissionTitle => 'تنبيه يومي لطيف';

  @override
  String get notificationPermissionBody =>
      'يستطيع لوما إرسال تذكير هادئ واحد عندما تكون قراءتك بانتظارك. بلا سلاسل إنجاز ولا ضغط. يمكنك إيقافه من الإعدادات في أي وقت.';

  @override
  String get notificationPermissionEnable => 'تفعيل التذكيرات';

  @override
  String get notificationPermissionNotNow => 'ليس الآن';

  @override
  String get notificationPermissionDenied =>
      'الإشعارات متوقفة. يمكنك السماح بها من إعدادات جهازك.';

  @override
  String get notificationPermissionGranted => 'التذكيرات مفعّلة.';

  @override
  String get notificationOpenSettings => 'فتح الإعدادات';

  @override
  String get reminderNotificationTitle => 'لحظة هادئة للقراءة';

  @override
  String get reminderNotificationBody =>
      'قراءتك التالية جاهزة متى ما كنت مستعدًا.';

  @override
  String get todayTitle => 'اليوم';

  @override
  String get todayPlaceholder => 'ستظهر قراءة اليوم هنا.';
}
