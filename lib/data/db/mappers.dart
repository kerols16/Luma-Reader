import '../../domain/entities/book.dart';
import '../../domain/entities/plan_day.dart';
import '../../domain/entities/plan_day_unit.dart';
import '../../domain/entities/reading_plan.dart';
import '../../domain/entities/unit.dart';
import '../../domain/entities/unit_progress.dart';
import 'app_database.dart';

extension BookRowMapper on BookRow {
  Book toDomain() => Book(
    id: id,
    title: title,
    language: language,
    filePath: filePath,
    totalPages: totalPages,
    createdAt: createdAt,
  );
}

extension UnitRowMapper on UnitRow {
  Unit toDomain() => Unit(
    id: id,
    bookId: bookId,
    orderIndex: orderIndex,
    title: title,
    pageStart: pageStart,
    pageEnd: pageEnd,
    wordCount: wordCount,
    text: content,
    difficulty: difficulty,
    explanation: explanation,
    explainedAt: explainedAt,
  );
}

extension PlanRowMapper on PlanRow {
  ReadingPlan toDomain() => ReadingPlan(
    id: id,
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
    minutesPerDay: minutesPerDay,
    goal: goal,
    readingSpeedWpm: readingSpeedWpm,
  );
}

extension PlanDayRowMapper on PlanDayRow {
  PlanDay toDomain() => PlanDay(
    id: id,
    planId: planId,
    date: date,
    status: status,
    minutesBudget: minutesBudget,
  );
}

extension PlanDayUnitRowMapper on PlanDayUnitRow {
  PlanDayUnit toDomain() =>
      PlanDayUnit(planDayId: planDayId, unitId: unitId, orderIndex: orderIndex);
}

extension ProgressRowMapper on ProgressRow {
  UnitProgress toDomain() => UnitProgress(
    unitId: unitId,
    scrollOffset: scrollOffset,
    completedAt: completedAt,
  );
}
