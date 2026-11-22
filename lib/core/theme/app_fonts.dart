/// Bundled font families. Fonts must work offline and be OFL-licensed.
abstract final class AppFonts {
  static const readingArabic = 'Amiri';
  static const readingEnglish = 'Literata';
  static const uiArabic = 'IBMPlexSansArabic';
  static const uiEnglish = 'Inter';

  /// Latin fallback for Arabic text that quotes English, and vice versa.
  static const readingFallbackArabic = [readingEnglish];
  static const readingFallbackEnglish = [readingArabic];
  static const uiFallbackArabic = [uiEnglish];
  static const uiFallbackEnglish = [uiArabic];
}
