import 'package:drift/drift.dart';

import '../../domain/entities/plan_day.dart';
import '../../domain/entities/reading_plan.dart';
import '../../domain/entities/unit.dart';
import '../db/app_database.dart';
import '../db/mappers.dart';

/// Plan and plan-day storage. Always returns domain entities.
class PlanRepository {
  PlanRepository(this._db);

  final AppDatabase _db;

  Future<ReadingPlan> createPlan({
    required int bookId,
    required DateTime startDate,
    required DateTime endDate,
    required int minutesPerDay,
    required ReadingGoal goal,
    required int readingSpeedWpm,
  }) async {
    final row = await _db
        .into(_db.plans)
        .insertReturning(
          PlansCompanion.insert(
            bookId: bookId,
            startDate: startDate,
            endDate: endDate,
            minutesPerDay: minutesPerDay,
            goal: goal,
            readingSpeedWpm: readingSpeedWpm,
          ),
        );
    return row.toDomain();
  }

  Future<PlanDay> addDay({
    required int planId,
    required DateTime date,
    required int minutesBudget,
    PlanDayStatus status = PlanDayStatus.pending,
  }) async {
    final row = await _db
        .into(_db.planDays)
        .insertReturning(
          PlanDaysCompanion.insert(
            planId: planId,
            date: date,
            status: status,
            minutesBudget: minutesBudget,
          ),
        );
    return row.toDomain();
  }

  /// Adds units to a day in the given order.
  Future<void> addUnitsToDay(int planDayId, List<int> unitIds) async {
    if (unitIds.isEmpty) return;
    await _db.batch((batch) {
      batch.insertAll(_db.planDayUnits, [
        for (var index = 0; index < unitIds.length; index++)
          PlanDayUnitsCompanion.insert(
            planDayId: planDayId,
            unitId: unitIds[index],
            orderIndex: index,
          ),
      ]);
    });
  }

  Future<ReadingPlan?> findPlanForBook(int bookId) async {
    final row =
        await (_db.select(_db.plans)
              ..where((table) => table.bookId.equals(bookId))
              ..orderBy([(table) => OrderingTerm.desc(table.startDate)])
              ..limit(1))
            .getSingleOrNull();
    return row?.toDomain();
  }

  Future<PlanDay?> findDayById(int id) async {
    final row = await (_db.select(
      _db.planDays,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  Future<List<PlanDay>> findDays(int planId) async {
    final query = _db.select(_db.planDays)
      ..where((table) => table.planId.equals(planId))
      ..orderBy([(table) => OrderingTerm.asc(table.date)]);
    final rows = await query.get();
    return List.unmodifiable(rows.map((row) => row.toDomain()));
  }

  /// Pending reading days between two inclusive dates, across all plans.
  ///
  /// Used to rebuild the rolling notification window on app open.
  Future<List<PlanDay>> findPendingDaysBetween(
    DateTime startInclusive,
    DateTime endInclusive,
  ) async {
    final query = _db.select(_db.planDays)
      ..where(
        (table) =>
            table.status.equalsValue(PlanDayStatus.pending) &
            table.date.isBiggerOrEqualValue(startInclusive) &
            table.date.isSmallerOrEqualValue(endInclusive),
      )
      ..orderBy([(table) => OrderingTerm.asc(table.date)]);
    final rows = await query.get();
    return List.unmodifiable(rows.map((row) => row.toDomain()));
  }

  Stream<List<PlanDay>> watchDays(int planId) {
    final query = _db.select(_db.planDays)
      ..where((table) => table.planId.equals(planId))
      ..orderBy([(table) => OrderingTerm.asc(table.date)]);
    return query.watch().map(
      (rows) => List.unmodifiable(rows.map((row) => row.toDomain())),
    );
  }

  Future<void> setDayStatus(int planDayId, PlanDayStatus status) async {
    await (_db.update(_db.planDays)
          ..where((table) => table.id.equals(planDayId)))
        .write(PlanDaysCompanion(status: Value(status)));
  }

  /// The units assigned to a day, in reading order.
  Future<List<Unit>> unitsForDay(int planDayId) async {
    final query = _db.select(_db.planDayUnits).join([
      innerJoin(_db.units, _db.units.id.equalsExp(_db.planDayUnits.unitId)),
    ])..where(_db.planDayUnits.planDayId.equals(planDayId));
    query.orderBy([OrderingTerm.asc(_db.planDayUnits.orderIndex)]);

    final rows = await query.get();
    return List.unmodifiable(
      rows.map((row) => row.readTable(_db.units).toDomain()),
    );
  }
}
