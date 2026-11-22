import 'package:flutter_test/flutter_test.dart';
import 'package:luma/domain/entities/reader_settings.dart';

void main() {
  group('ReaderSettings', () {
    test('defaults are comfortable', () {
      const settings = ReaderSettings();

      expect(settings.fontScale, 1.0);
      expect(settings.lineHeight, 1.0);
      expect(settings.theme, ReaderTheme.light);
      expect(settings.arabicDigits, isFalse);
    });

    test('copyWith replaces only the given fields', () {
      const settings = ReaderSettings();
      final updated = settings.copyWith(
        fontScale: 1.2,
        theme: ReaderTheme.sepia,
      );

      expect(updated.fontScale, 1.2);
      expect(updated.theme, ReaderTheme.sepia);
      expect(updated.lineHeight, settings.lineHeight);
      expect(updated.arabicDigits, settings.arabicDigits);
    });

    test('JSON round trip preserves everything', () {
      const settings = ReaderSettings(
        fontScale: 1.35,
        lineHeight: 1.1,
        theme: ReaderTheme.dark,
        arabicDigits: true,
      );

      final restored = ReaderSettings.fromJson(settings.toJson());

      expect(restored, settings);
    });

    test('invalid JSON falls back to safe values', () {
      final restored = ReaderSettings.fromJson({
        'fontScale': 99,
        'lineHeight': 'wide',
        'theme': 'neon',
        'arabicDigits': 'yes',
      });

      expect(restored.fontScale, ReaderSettings.maxFontScale);
      expect(restored.lineHeight, 1.0);
      expect(restored.theme, ReaderTheme.light);
      expect(restored.arabicDigits, isFalse);
    });
  });
}
