import 'package:flutter/material.dart';

import '../../domain/entities/reader_settings.dart';
import 'app_typography.dart';

/// Single reading column, centered, with a comfortable measure.
///
/// Maximum width is ~680 logical px; margins use directional insets so RTL
/// layouts mirror correctly.
class ReadingColumn extends StatelessWidget {
  const ReadingColumn({
    super.key,
    required this.child,
    this.maxWidth = 680,
    this.horizontalPadding = 24,
  });

  final Widget child;
  final double maxWidth;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: horizontalPadding,
            vertical: 8,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Book text whose direction comes from its content, not the UI locale.
///
/// Books mix Arabic and English, so the caller passes [isArabic].
class ReadingText extends StatelessWidget {
  const ReadingText(
    this.text, {
    super.key,
    required this.isArabic,
    this.settings = const ReaderSettings(),
    this.color,
  });

  final String text;
  final bool isArabic;
  final ReaderSettings settings;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Text(
        text,
        textAlign: TextAlign.start,
        style: AppTypography.readingStyle(
          isArabic: isArabic,
          settings: settings,
          color: color,
        ),
      ),
    );
  }
}
