import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
  ];

  /// Application name shown in the app switcher and task switcher
  ///
  /// In en, this message translates to:
  /// **'Luma'**
  String get appTitle;

  /// Progress through a reading plan, shown above today's unit
  ///
  /// In en, this message translates to:
  /// **'Day {current} of {total}'**
  String dayOfTotal(int current, int total);

  /// Remaining days in the reading plan
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No days left} one{1 day left} other{{count} days left}}'**
  String daysLeft(int count);

  /// Confirmation after finishing today's reading
  ///
  /// In en, this message translates to:
  /// **'Done for today'**
  String get doneForToday;

  /// Placeholder action for the future AI explanation feature; hidden in v0
  ///
  /// In en, this message translates to:
  /// **'Explain this part'**
  String get explainThisPart;

  /// Title of the settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Setting that controls the UI language
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguage;

  /// Use the device language
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// English language name
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Arabic language name
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageArabic;

  /// Section title for reading preferences
  ///
  /// In en, this message translates to:
  /// **'Reader settings'**
  String get readerSettings;

  /// Reading text size label
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get fontSize;

  /// Reading line height label
  ///
  /// In en, this message translates to:
  /// **'Line spacing'**
  String get lineHeight;

  /// Reader color theme label
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Light reading theme
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Sepia reading theme
  ///
  /// In en, this message translates to:
  /// **'Sepia'**
  String get themeSepia;

  /// Dark reading theme
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Toggle between Western and Arabic-Indic numerals
  ///
  /// In en, this message translates to:
  /// **'Arabic digits'**
  String get arabicDigits;

  /// Sample paragraph that previews the reading typography in settings
  ///
  /// In en, this message translates to:
  /// **'The quiet morning light spread slowly across the page, and the day began with a few calm lines.'**
  String get readerPreviewText;

  /// Section title for notification preferences
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsSection;

  /// Label for the daily reading reminder switch
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get notificationDailyReminder;

  /// Reminder switch subtitle when reminders are enabled
  ///
  /// In en, this message translates to:
  /// **'One gentle reminder a day, when a reading is waiting.'**
  String get notificationSubtitleOn;

  /// Reminder switch subtitle when reminders are disabled
  ///
  /// In en, this message translates to:
  /// **'Off. Turn on one gentle reminder a day.'**
  String get notificationSubtitleOff;

  /// Title of the friendly screen shown before the system permission prompt
  ///
  /// In en, this message translates to:
  /// **'A gentle daily nudge'**
  String get notificationPermissionTitle;

  /// Explanation shown before asking for notification permission
  ///
  /// In en, this message translates to:
  /// **'Luma can send one quiet reminder when a reading is waiting. No streaks, no pressure. You can turn it off in Settings anytime.'**
  String get notificationPermissionBody;

  /// Button that opens the system notification permission prompt
  ///
  /// In en, this message translates to:
  /// **'Turn on reminders'**
  String get notificationPermissionEnable;

  /// Button that dismisses the notification permission screen
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notificationPermissionNotNow;

  /// Shown when notification permission was not granted
  ///
  /// In en, this message translates to:
  /// **'Notifications are off. You can allow them in your device settings.'**
  String get notificationPermissionDenied;

  /// Confirmation after enabling reminders
  ///
  /// In en, this message translates to:
  /// **'Reminders are on.'**
  String get notificationPermissionGranted;

  /// Button that opens the device notification settings
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get notificationOpenSettings;

  /// Title of the daily local reading reminder
  ///
  /// In en, this message translates to:
  /// **'A quiet moment for reading'**
  String get reminderNotificationTitle;

  /// Body of the daily local reading reminder
  ///
  /// In en, this message translates to:
  /// **'Your next reading is ready whenever you are.'**
  String get reminderNotificationBody;

  /// Title of the Today screen
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayTitle;

  /// Placeholder on the Today screen until reading units are wired up
  ///
  /// In en, this message translates to:
  /// **'Your daily reading will appear here.'**
  String get todayPlaceholder;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
