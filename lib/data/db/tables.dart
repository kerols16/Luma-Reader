import 'package:drift/drift.dart';

import '../../domain/entities/book.dart';
import '../../domain/entities/plan_day.dart';
import '../../domain/entities/reading_plan.dart';

@DataClassName('BookRow')
@TableIndex(name: 'books_created_at', columns: {#createdAt})
class Books extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get language => textEnum<BookLanguage>()();
  TextColumn get filePath => text()();
  IntColumn get totalPages => integer()();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('UnitRow')
@TableIndex(
  name: 'units_book_order',
  columns: {#bookId, #orderIndex},
  unique: true,
)
class Units extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId =>
      integer().references(Books, #id, onDelete: KeyAction.cascade)();
  IntColumn get orderIndex => integer()();
  TextColumn get title => text()();
  IntColumn get pageStart => integer()();
  IntColumn get pageEnd => integer()();
  IntColumn get wordCount => integer()();

  /// Stored as `text`, which is a reserved Dart getter name in tables.
  TextColumn get content => text().named('text')();

  IntColumn get difficulty => integer().withDefault(const Constant(1))();
  TextColumn get explanation => text().nullable()();
  DateTimeColumn get explainedAt => dateTime().nullable()();
}

@DataClassName('PlanRow')
@TableIndex(name: 'plans_book', columns: {#bookId})
class Plans extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId =>
      integer().references(Books, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  IntColumn get minutesPerDay => integer()();
  TextColumn get goal => textEnum<ReadingGoal>()();
  IntColumn get readingSpeedWpm => integer()();
}

@DataClassName('PlanDayRow')
@TableIndex(
  name: 'plan_days_plan_date',
  columns: {#planId, #date},
  unique: true,
)
@TableIndex(name: 'plan_days_date', columns: {#date})
class PlanDays extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId =>
      integer().references(Plans, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();
  TextColumn get status => textEnum<PlanDayStatus>()();
  IntColumn get minutesBudget => integer()();
}

@DataClassName('PlanDayUnitRow')
@TableIndex(
  name: 'plan_day_units_day_order',
  columns: {#planDayId, #orderIndex},
)
@TableIndex(name: 'plan_day_units_unit', columns: {#unitId})
class PlanDayUnits extends Table {
  IntColumn get planDayId =>
      integer().references(PlanDays, #id, onDelete: KeyAction.cascade)();
  IntColumn get unitId =>
      integer().references(Units, #id, onDelete: KeyAction.cascade)();
  IntColumn get orderIndex => integer()();

  @override
  Set<Column> get primaryKey => {planDayId, unitId};
}

@DataClassName('ProgressRow')
class Progress extends Table {
  IntColumn get unitId =>
      integer().references(Units, #id, onDelete: KeyAction.cascade)();
  RealColumn get scrollOffset => real().withDefault(const Constant(0))();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {unitId};
}
