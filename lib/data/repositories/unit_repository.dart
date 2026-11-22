import 'package:drift/drift.dart';

import '../../domain/entities/unit.dart';
import '../db/app_database.dart';
import '../db/mappers.dart';

/// Unit storage. Always returns domain entities, never drift rows.
class UnitRepository {
  UnitRepository(this._db);

  final AppDatabase _db;

  Future<Unit> add(NewUnit unit) async {
    final row = await _db
        .into(_db.units)
        .insertReturning(
          UnitsCompanion.insert(
            bookId: unit.bookId,
            orderIndex: unit.orderIndex,
            title: unit.title,
            pageStart: unit.pageStart,
            pageEnd: unit.pageEnd,
            wordCount: unit.wordCount,
            content: unit.text,
            difficulty: Value(unit.difficulty),
            explanation: Value(unit.explanation),
            explainedAt: Value(unit.explainedAt),
          ),
        );
    return row.toDomain();
  }

  Future<List<Unit>> addAll(List<NewUnit> units) => _db.transaction(() async {
    final result = <Unit>[];
    for (final unit in units) {
      result.add(await add(unit));
    }
    return List.unmodifiable(result);
  });

  Future<Unit?> findById(int id) async {
    final row = await (_db.select(
      _db.units,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  Future<List<Unit>> findAllForBook(int bookId) async {
    final query = _db.select(_db.units)
      ..where((table) => table.bookId.equals(bookId))
      ..orderBy([(table) => OrderingTerm.asc(table.orderIndex)]);
    final rows = await query.get();
    return List.unmodifiable(rows.map((row) => row.toDomain()));
  }

  Stream<List<Unit>> watchForBook(int bookId) {
    final query = _db.select(_db.units)
      ..where((table) => table.bookId.equals(bookId))
      ..orderBy([(table) => OrderingTerm.asc(table.orderIndex)]);
    return query.watch().map(
      (rows) => List.unmodifiable(rows.map((row) => row.toDomain())),
    );
  }

  Future<void> deleteForBook(int bookId) async {
    await (_db.delete(
      _db.units,
    )..where((table) => table.bookId.equals(bookId))).go();
  }
}
