import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/theme/app_fonts.dart';
import 'package:luma/core/theme/app_typography.dart';
import 'package:luma/core/theme/reader_palette.dart';
import 'package:luma/domain/entities/reader_settings.dart';

void main() {
  group('reading typography', () {
    test('English uses Literata and the tighter default line height', () {
      final style = AppTypography.readingStyle(isArabic: false);

      expect(style.fontFamily, AppFonts.readingEnglish);
      expect(style.fontSize, AppTypography.englishReadingSize);
      expect(style.height, AppTypography.englishReadingLineHeight);
      expect(style.letterSpacing, 0);
    });

    test('Arabic is larger, taller and has no letter spacing', () {
      final style = AppTypography.readingStyle(isArabic: true);

      expect(style.fontFamily, AppFonts.readingArabic);
      expect(style.fontSize, greaterThan(AppTypography.englishReadingSize));
      expect(style.height, inInclusiveRange(1.8, 2.0));
      expect(style.letterSpacing, isNull);
    });

    test('font scale and line height multiply the tokens', () {
      final style = AppTypography.readingStyle(
        isArabic: true,
        settings: const ReaderSettings(fontScale: 1.25, lineHeight: 1.1),
      );

      expect(
        style.fontSize,
        closeTo(AppTypography.arabicReadingSize * 1.25, 0.001),
      );
      expect(style.height, closeTo(1.9 * 1.1, 0.001));
    });

    test('UI text theme follows the language and palette', () {
      final english = AppTypography.uiTextTheme(
        isArabic: false,
        palette: ReaderPalette.light,
      );
      final arabic = AppTypography.uiTextTheme(
        isArabic: true,
        palette: ReaderPalette.sepia,
      );

      expect(english.bodyLarge?.fontFamily, AppFonts.uiEnglish);
      expect(arabic.bodyLarge?.fontFamily, AppFonts.uiArabic);
      expect(
        arabic.bodyLarge!.fontSize,
        greaterThan(english.bodyLarge!.fontSize!),
      );
      expect(arabic.titleLarge?.letterSpacing, isNull);
      expect(arabic.bodyLarge?.color, ReaderPalette.sepia.text);
      expect(english.bodySmall?.color, ReaderPalette.light.mutedText);
    });
  });

  test('reading style uses the provided color token', () {
    final style = AppTypography.readingStyle(
      isArabic: false,
      color: ReaderPalette.dark.text,
    );

    expect(style.color, ReaderPalette.dark.text);
  });
}
