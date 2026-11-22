/// A daily reading unit: a portion of a book.
class Unit {
  const Unit({
    required this.id,
    required this.bookId,
    required this.orderIndex,
    required this.title,
    required this.pageStart,
    required this.pageEnd,
    required this.wordCount,
    required this.text,
    this.difficulty = 1,
    this.explanation,
    this.explainedAt,
  });

  final int id;
  final int bookId;
  final int orderIndex;
  final String title;
  final int pageStart;
  final int pageEnd;
  final int wordCount;
  final String text;

  /// 1 = normal, 2 = denser, 3 = hardest. Used by planning.
  final int difficulty;

  /// Reserved for the future explanation feature; always null in v0.
  final String? explanation;
  final DateTime? explainedAt;

  @override
  bool operator ==(Object other) =>
      other is Unit &&
      other.id == id &&
      other.bookId == bookId &&
      other.orderIndex == orderIndex &&
      other.title == title &&
      other.pageStart == pageStart &&
      other.pageEnd == pageEnd &&
      other.wordCount == wordCount &&
      other.text == text &&
      other.difficulty == difficulty &&
      other.explanation == explanation &&
      other.explainedAt == explainedAt;

  @override
  int get hashCode => Object.hash(
    id,
    bookId,
    orderIndex,
    title,
    pageStart,
    pageEnd,
    wordCount,
    text,
    difficulty,
    explanation,
    explainedAt,
  );
}

/// Values needed to create a [Unit]; the id is assigned by the database.
class NewUnit {
  const NewUnit({
    required this.bookId,
    required this.orderIndex,
    required this.title,
    required this.pageStart,
    required this.pageEnd,
    required this.wordCount,
    required this.text,
    this.difficulty = 1,
    this.explanation,
    this.explainedAt,
  });

  final int bookId;
  final int orderIndex;
  final String title;
  final int pageStart;
  final int pageEnd;
  final int wordCount;
  final String text;
  final int difficulty;
  final String? explanation;
  final DateTime? explainedAt;
}
