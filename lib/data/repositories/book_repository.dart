import 'package:drift/drift.dart';

import '../../domain/entities/book.dart';
import '../db/app_database.dart';
import '../db/mappers.dart';

/// Book storage. Always returns domain entities, never drift rows.
class BookRepository {
  BookRepository(this._db);

  final AppDatabase _db;

  Stream<List<Book>> watchAll() {
    final query = _db.select(_db.books)
      ..orderBy([(table) => OrderingTerm.desc(table.createdAt)]);
    return query.watch().map(
      (rows) => List.unmodifiable(rows.map((row) => row.toDomain())),
    );
  }

  Future<List<Book>> findAll() async {
    final query = _db.select(_db.books)
      ..orderBy([(table) => OrderingTerm.desc(table.createdAt)]);
    final rows = await query.get();
    return List.unmodifiable(rows.map((row) => row.toDomain()));
  }

  Future<Book?> findById(int id) async {
    final row = await (_db.select(
      _db.books,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  Future<Book> create({
    required String title,
    required BookLanguage language,
    required String filePath,
    required int totalPages,
    DateTime? createdAt,
  }) async {
    final row = await _db
        .into(_db.books)
        .insertReturning(
          BooksCompanion.insert(
            title: title,
            language: language,
            filePath: filePath,
            totalPages: totalPages,
            createdAt: createdAt ?? DateTime.now(),
          ),
        );
    return row.toDomain();
  }

  /// Cascades to units, plans and progress.
  Future<void> delete(int id) async {
    await (_db.delete(_db.books)..where((table) => table.id.equals(id))).go();
  }
}
