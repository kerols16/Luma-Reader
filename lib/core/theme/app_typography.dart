import 'package:flutter/material.dart';
import 'package:luma/core/theme/app_fonts.dart';
import 'package:luma/core/theme/reader_palette.dart';
import 'package:luma/domain/entities/reader_settings.dart';

/// Typography tokens for reading text and UI text.
///
/// Arabic is intentionally larger with a taller line height. Arabic never gets
/// italics or letter-spacing.
abstract final class AppTypography {
  static const englishReadingSize = 19.0;
  static const arabicReadingSize = 21.5;
  static const englishReadingLineHeight = 1.6;
  static const arabicReadingLineHeight = 1.9;
  static const arabicUiScale = 1.06;

  /// Style for book content.
  ///
  /// [ReaderSettings.lineHeight] is a multiplier over the language default, so
  /// Arabic stays around 1.8–2.0 and English stays tighter.
  static TextStyle readingStyle({
    required bool isArabic,
    ReaderSettings settings = const ReaderSettings(),
    Color? color,
  }) {
    final fontSize =
        (isArabic ? arabicReadingSize : englishReadingSize) *
        settings.fontScale;
    final height =
        (isArabic ? arabicReadingLineHeight : englishReadingLineHeight) *
        settings.lineHeight;

    return TextStyle(
      fontFamily: isArabic ? AppFonts.readingArabic : AppFonts.readingEnglish,
      fontFamilyFallback: isArabic
          ? AppFonts.readingFallbackArabic
          : AppFonts.readingFallbackEnglish,
      fontSize: fontSize,
      height: height,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.normal,
      letterSpacing: isArabic ? null : 0,
      color: color,
    );
  }

  /// Material text theme for chrome, based on the reader palette.
  static TextTheme uiTextTheme({
    required bool isArabic,
    required ReaderPalette palette,
  }) {
    TextStyle style(
      double size, {
      FontWeight weight = FontWeight.w400,
      Color? color,
    }) {
      final scale = isArabic ? arabicUiScale : 1.0;
      return TextStyle(
        fontFamily: isArabic ? AppFonts.uiArabic : AppFonts.uiEnglish,
        fontFamilyFallback: isArabic
            ? AppFonts.uiFallbackArabic
            : AppFonts.uiFallbackEnglish,
        fontSize: size * scale,
        fontWeight: weight,
        height: isArabic ? 1.5 : 1.35,
        letterSpacing: isArabic ? null : 0,
        fontStyle: FontStyle.normal,
        color: color ?? palette.text,
      );
    }

    return TextTheme(
      displayLarge: style(34, weight: FontWeight.w600),
      displayMedium: style(30, weight: FontWeight.w600),
      displaySmall: style(26, weight: FontWeight.w600),
      headlineLarge: style(24, weight: FontWeight.w600),
      headlineMedium: style(22, weight: FontWeight.w600),
      headlineSmall: style(20, weight: FontWeight.w600),
      titleLarge: style(19, weight: FontWeight.w600),
      titleMedium: style(16, weight: FontWeight.w500),
      titleSmall: style(14, weight: FontWeight.w500),
      bodyLarge: style(16),
      bodyMedium: style(14),
      bodySmall: style(12, color: palette.mutedText),
      labelLarge: style(14, weight: FontWeight.w500),
      labelMedium: style(12, weight: FontWeight.w500),
      labelSmall: style(11, weight: FontWeight.w500, color: palette.mutedText),
    );
  }
}
