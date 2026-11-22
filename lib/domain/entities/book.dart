/// Language of a book's content. Independent of the UI language.
enum BookLanguage {
  ar,
  en;

  String get code => name;
}

class Book {
  const Book({
    required this.id,
    required this.title,
    required this.language,
    required this.filePath,
    required this.totalPages,
    required this.createdAt,
  });

  final int id;
  final String title;
  final BookLanguage language;
  final String filePath;
  final int totalPages;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      other is Book &&
      other.id == id &&
      other.title == title &&
      other.language == language &&
      other.filePath == filePath &&
      other.totalPages == totalPages &&
      other.createdAt == createdAt;

  @override
  int get hashCode =>
      Object.hash(id, title, language, filePath, totalPages, createdAt);
}
