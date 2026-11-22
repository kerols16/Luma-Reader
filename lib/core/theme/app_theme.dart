import 'package:flutter/material.dart';
import 'package:luma/core/theme/app_fonts.dart';
import 'package:luma/core/theme/app_typography.dart';
import 'package:luma/core/theme/reader_palette.dart';
import 'package:luma/domain/entities/reader_settings.dart';

/// Builds the app theme from the selected reader theme and UI language.
///
/// Colors and fonts must be referenced through this theme or the palette tokens,
/// never inline in widgets.
abstract final class AppTheme {
  static ThemeData build(ReaderTheme theme, {required bool isArabic}) {
    final palette = ReaderPalette.of(theme);

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: palette.accent,
          brightness: palette.brightness,
        ).copyWith(
          primary: palette.accent,
          onPrimary: palette.onAccent,
          surface: palette.background,
          onSurface: palette.text,
          onSurfaceVariant: palette.mutedText,
          surfaceContainerHighest: palette.surface,
          outline: palette.divider,
          outlineVariant: palette.divider,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      fontFamily: isArabic ? AppFonts.uiArabic : AppFonts.uiEnglish,
      textTheme: AppTypography.uiTextTheme(
        isArabic: isArabic,
        palette: palette,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.text,
        surfaceTintColor: palette.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      dividerTheme: DividerThemeData(color: palette.divider, thickness: 1),
      listTileTheme: ListTileThemeData(
        textColor: palette.text,
        iconColor: palette.mutedText,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: palette.accent,
        thumbColor: palette.accent,
        inactiveTrackColor: palette.divider,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.onAccent
              : palette.mutedText,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.accent
              : palette.divider,
        ),
      ),
    );
  }
}
