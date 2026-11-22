import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/theme/reader_palette.dart';
import 'package:luma/domain/entities/reader_settings.dart';

void main() {
  group('ReaderPalette', () {
    test('starts from the agreed theme values', () {
      expect(ReaderPalette.light.background, const Color(0xFFFBFAF7));
      expect(ReaderPalette.light.text, const Color(0xFF1F1F1F));
      expect(ReaderPalette.sepia.background, const Color(0xFFF4ECD8));
      expect(ReaderPalette.sepia.text, const Color(0xFF3B2F1E));
      expect(ReaderPalette.dark.background, const Color(0xFF16171A));
      expect(ReaderPalette.dark.text, const Color(0xFFD9D6CF));
    });

    test('only the dark theme is dark', () {
      expect(ReaderPalette.light.brightness, Brightness.light);
      expect(ReaderPalette.sepia.brightness, Brightness.light);
      expect(ReaderPalette.dark.brightness, Brightness.dark);
    });

    test('maps every reader theme to a palette', () {
      for (final theme in ReaderTheme.values) {
        expect(ReaderPalette.of(theme).theme, theme);
      }
    });
  });
}
