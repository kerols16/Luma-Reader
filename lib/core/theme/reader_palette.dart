import 'package:flutter/material.dart';
import 'package:luma/domain/entities/reader_settings.dart';

/// Color tokens for the three reader themes.
@immutable
class ReaderPalette {
  const ReaderPalette({
    required this.theme,
    required this.background,
    required this.text,
    required this.mutedText,
    required this.surface,
    required this.divider,
    required this.accent,
    required this.onAccent,
  });

  final ReaderTheme theme;
  final Color background;
  final Color text;
  final Color mutedText;
  final Color surface;
  final Color divider;
  final Color accent;
  final Color onAccent;

  Brightness get brightness =>
      theme == ReaderTheme.dark ? Brightness.dark : Brightness.light;

  static const light = ReaderPalette(
    theme: ReaderTheme.light,
    background: Color(0xFFFBFAF7),
    text: Color(0xFF1F1F1F),
    mutedText: Color(0xFF6B6862),
    surface: Color(0xFFF2F0EA),
    divider: Color(0xFFE4E0D8),
    accent: Color(0xFF7A5C3E),
    onAccent: Color(0xFFFBFAF7),
  );

  static const sepia = ReaderPalette(
    theme: ReaderTheme.sepia,
    background: Color(0xFFF4ECD8),
    text: Color(0xFF3B2F1E),
    mutedText: Color(0xFF7A6A52),
    surface: Color(0xFFEDE3CC),
    divider: Color(0xFFDDD0B4),
    accent: Color(0xFF7A5C3E),
    onAccent: Color(0xFFF4ECD8),
  );

  static const dark = ReaderPalette(
    theme: ReaderTheme.dark,
    background: Color(0xFF16171A),
    text: Color(0xFFD9D6CF),
    mutedText: Color(0xFF9A968D),
    surface: Color(0xFF202227),
    divider: Color(0xFF2C2E33),
    accent: Color(0xFFC9A97A),
    onAccent: Color(0xFF16171A),
  );

  static ReaderPalette of(ReaderTheme theme) => switch (theme) {
    ReaderTheme.light => light,
    ReaderTheme.sepia => sepia,
    ReaderTheme.dark => dark,
  };
}
