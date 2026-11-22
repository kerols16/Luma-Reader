import 'package:drift/drift.dart';

import '../../domain/entities/unit_progress.dart';
import '../db/app_database.dart';
import '../db/mappers.dart';

/// Per-unit progress. Always returns domain entities.
class ProgressRepository {
  ProgressRepository(this._db);

  final AppDatabase _db;

  /// Replaces the stored progress for [unitId].
  Future<UnitProgress> save({
    required int unitId,
    required double scrollOffset,
    DateTime? completedAt,
  }) async {
    final row = await _db
        .into(_db.progress)
        .insertReturning(
          ProgressCompanion.insert(
            unitId: Value(unitId),
            scrollOffset: Value(scrollOffset),
            completedAt: Value(completedAt),
          ),
          onConflict: DoUpdate(
            (_) => ProgressCompanion(
              scrollOffset: Value(scrollOffset),
              completedAt: Value(completedAt),
            ),
          ),
        );
    return row.toDomain();
  }

  /// Saves the scroll position without changing completion state.
  Future<UnitProgress> saveScrollOffset(int unitId, double scrollOffset) async {
    final existing = await findForUnit(unitId);
    return save(
      unitId: unitId,
      scrollOffset: scrollOffset,
      completedAt: existing?.completedAt,
    );
  }

  Future<UnitProgress> markCompleted(
    int unitId, {
    double? scrollOffset,
    DateTime? at,
  }) async {
    final existing = await findForUnit(unitId);
    return save(
      unitId: unitId,
      scrollOffset: scrollOffset ?? existing?.scrollOffset ?? 0,
      completedAt: at ?? DateTime.now(),
    );
  }

  Future<UnitProgress?> findForUnit(int unitId) async {
    final row = await (_db.select(
      _db.progress,
    )..where((table) => table.unitId.equals(unitId))).getSingleOrNull();
    return row?.toDomain();
  }

  Stream<UnitProgress?> watchForUnit(int unitId) {
    final query = _db.select(_db.progress)
      ..where((table) => table.unitId.equals(unitId));
    return query.watchSingleOrNull().map((row) => row?.toDomain());
  }

  Future<void> delete(int unitId) async {
    await (_db.delete(
      _db.progress,
    )..where((table) => table.unitId.equals(unitId))).go();
  }
}
