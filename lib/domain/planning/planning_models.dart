/// Input models for the daily planner.
library;

/// A paragraph inside a chapter. Sub-headings force a preferred split point.
class PlanningParagraph {
  PlanningParagraph(this.text, {this.isSubHeading = false});

  final String text;
  final bool isSubHeading;

  late final int wordCount = _countWords(text);
}

/// A chapter (or section) of a book, ready to be split and packed.
///
/// Chapters with the same [sectionId] may be merged into one day. A different
/// [sectionId] marks a part/section boundary that must never be merged across.
class PlanningChapter {
  PlanningChapter({
    required this.id,
    required this.title,
    required this.paragraphs,
    this.difficulty = 1,
    this.sectionId = 'default',
  });

  final String id;
  final String title;
  final List<PlanningParagraph> paragraphs;

  /// 1 = normal, 2 = denser, 3 = hardest.
  final int difficulty;
  final String sectionId;

  late final int wordCount = paragraphs.fold(
    0,
    (total, paragraph) => total + paragraph.wordCount,
  );
}

int _countWords(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 0;
  return trimmed.split(RegExp(r'\s+')).length;
}
