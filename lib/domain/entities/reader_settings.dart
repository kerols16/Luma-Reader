/// Reader color schemes.
enum ReaderTheme { light, sepia, dark }

/// User preferences for the reading experience.
///
/// [lineHeight] is a multiplier over the language-specific default line height
/// (Arabic 1.9, English 1.6), so 1.0 keeps each language comfortable.
class ReaderSettings {
  const ReaderSettings({
    this.fontScale = 1.0,
    this.lineHeight = 1.0,
    this.theme = ReaderTheme.light,
    this.arabicDigits = false,
  });

  static const minFontScale = 0.8;
  static const maxFontScale = 1.6;
  static const minLineHeight = 0.85;
  static const maxLineHeight = 1.35;

  final double fontScale;
  final double lineHeight;
  final ReaderTheme theme;
  final bool arabicDigits;

  ReaderSettings copyWith({
    double? fontScale,
    double? lineHeight,
    ReaderTheme? theme,
    bool? arabicDigits,
  }) {
    return ReaderSettings(
      fontScale: fontScale ?? this.fontScale,
      lineHeight: lineHeight ?? this.lineHeight,
      theme: theme ?? this.theme,
      arabicDigits: arabicDigits ?? this.arabicDigits,
    );
  }

  Map<String, Object?> toJson() => {
    'fontScale': fontScale,
    'lineHeight': lineHeight,
    'theme': theme.name,
    'arabicDigits': arabicDigits,
  };

  factory ReaderSettings.fromJson(Map<String, Object?> json) {
    return ReaderSettings(
      fontScale: _boundedDouble(
        json['fontScale'],
        fallback: 1.0,
        min: minFontScale,
        max: maxFontScale,
      ),
      lineHeight: _boundedDouble(
        json['lineHeight'],
        fallback: 1.0,
        min: minLineHeight,
        max: maxLineHeight,
      ),
      theme: ReaderTheme.values.firstWhere(
        (theme) => theme.name == json['theme'],
        orElse: () => ReaderTheme.light,
      ),
      arabicDigits: json['arabicDigits'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReaderSettings &&
      other.fontScale == fontScale &&
      other.lineHeight == lineHeight &&
      other.theme == theme &&
      other.arabicDigits == arabicDigits;

  @override
  int get hashCode => Object.hash(fontScale, lineHeight, theme, arabicDigits);
}

double _boundedDouble(
  Object? value, {
  required double fallback,
  required double min,
  required double max,
}) {
  if (value is! num) return fallback;
  final number = value.toDouble();
  if (number.isNaN) return fallback;
  return number.clamp(min, max).toDouble();
}
