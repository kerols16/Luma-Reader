import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/data/db/app_database.dart';
import 'package:luma/data/repositories/book_repository.dart';
import 'package:luma/data/repositories/plan_repository.dart';
import 'package:luma/data/repositories/progress_repository.dart';
import 'package:luma/data/repositories/unit_repository.dart';
import 'package:luma/domain/entities/book.dart';
import 'package:luma/domain/entities/plan_day.dart';
import 'package:luma/domain/entities/reading_plan.dart';
import 'package:luma/domain/entities/unit.dart';

void main() {
  late AppDatabase db;
  late BookRepository books;
  late UnitRepository units;
  late PlanRepository plans;
  late ProgressRepository progress;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    books = BookRepository(db);
    units = UnitRepository(db);
    plans = PlanRepository(db);
    progress = ProgressRepository(db);
    // Force the schema to be created before the first assertion.
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() => db.close());

  Future<Book> addBook({String title = 'Sample Book'}) => books.create(
    title: title,
    language: BookLanguage.en,
    filePath: '/books/sample.pdf',
    totalPages: 320,
    createdAt: DateTime(2026, 1, 1),
  );

  Future<Unit> addUnit(
    Book book, {
    int orderIndex = 0,
    String text = 'Some text',
  }) => units.add(
    NewUnit(
      bookId: book.id,
      orderIndex: orderIndex,
      title: 'Chapter $orderIndex',
      pageStart: orderIndex * 10,
      pageEnd: orderIndex * 10 + 9,
      wordCount: 1200,
      text: text,
    ),
  );

  test('schema version is 1 and tables exist', () async {
    expect(db.schemaVersion, 1);

    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
        )
        .get();
    final names = tables.map((row) => row.read<String>('name')).toList();

    expect(
      names,
      containsAll([
        'books',
        'units',
        'plans',
        'plan_days',
        'plan_day_units',
        'progress',
      ]),
    );
  });

  test('expected indexes are created', () async {
    final rows = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
        .get();
    final names = rows.map((row) => row.read<String>('name')).toList();

    expect(
      names,
      containsAll([
        'books_created_at',
        'units_book_order',
        'plans_book',
        'plan_days_plan_date',
        'plan_days_date',
        'plan_day_units_day_order',
        'plan_day_units_unit',
      ]),
    );
  });

  group('BookRepository', () {
    test('creates and reads a book', () async {
      final created = await addBook();

      final found = await books.findById(created.id);

      expect(found, created);
      expect(found?.language, BookLanguage.en);
      expect(found?.totalPages, 320);
    });

    test('lists books newest first', () async {
      await books.create(
        title: 'Older',
        language: BookLanguage.ar,
        filePath: '/older.pdf',
        totalPages: 10,
        createdAt: DateTime(2025, 1, 1),
      );
      await books.create(
        title: 'Newer',
        language: BookLanguage.en,
        filePath: '/newer.pdf',
        totalPages: 20,
        createdAt: DateTime(2026, 1, 1),
      );

      final all = await books.findAll();

      expect(all.map((book) => book.title), ['Newer', 'Older']);
    });
  });

  group('UnitRepository', () {
    test('stores text, difficulty and returns units in order', () async {
      final book = await addBook();
      await addUnit(book, orderIndex: 1, text: 'Second');
      await addUnit(book, orderIndex: 0, text: 'First');

      final stored = await units.findAllForBook(book.id);

      expect(stored.map((unit) => unit.text), ['First', 'Second']);
      expect(stored.first.difficulty, 1);
      expect(stored.first.bookId, book.id);
    });

    test('rejects duplicate order indexes for one book', () async {
      final book = await addBook();
      await addUnit(book, orderIndex: 0);

      expect(addUnit(book, orderIndex: 0), throwsA(isA<Exception>()));
    });

    test('rejects units for a missing book (foreign keys are on)', () async {
      await addBook();

      await expectLater(
        units.add(
          const NewUnit(
            bookId: 999,
            orderIndex: 0,
            title: 'Orphan',
            pageStart: 1,
            pageEnd: 1,
            wordCount: 10,
            text: 'orphan',
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('PlanRepository', () {
    test('creates a plan with days and ordered units', () async {
      final book = await addBook();
      final unitA = await addUnit(book, orderIndex: 0);
      final unitB = await addUnit(book, orderIndex: 1);

      final plan = await plans.createPlan(
        bookId: book.id,
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 28),
        minutesPerDay: 60,
        goal: ReadingGoal.understand,
        readingSpeedWpm: 220,
      );
      final day = await plans.addDay(
        planId: plan.id,
        date: DateTime(2026, 2, 1),
        minutesBudget: 60,
      );
      await plans.addUnitsToDay(day.id, [unitB.id, unitA.id]);

      final foundPlan = await plans.findPlanForBook(book.id);
      final foundDays = await plans.findDays(plan.id);
      final dayUnits = await plans.unitsForDay(day.id);

      expect(foundPlan, plan);
      expect(foundDays, [day]);
      expect(dayUnits.map((unit) => unit.id), [unitB.id, unitA.id]);

      await plans.setDayStatus(day.id, PlanDayStatus.done);
      final updated = await plans.findDayById(day.id);
      expect(updated?.status, PlanDayStatus.done);
    });

    test('allows only one day per plan per date', () async {
      final book = await addBook();
      final plan = await plans.createPlan(
        bookId: book.id,
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 28),
        minutesPerDay: 60,
        goal: ReadingGoal.read,
        readingSpeedWpm: 220,
      );
      final date = DateTime(2026, 2, 1);
      await plans.addDay(planId: plan.id, date: date, minutesBudget: 60);

      expect(
        plans.addDay(planId: plan.id, date: date, minutesBudget: 30),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('ProgressRepository', () {
    test('saves scroll and completion, and preserves each other', () async {
      final book = await addBook();
      final unit = await addUnit(book);

      final saved = await progress.save(unitId: unit.id, scrollOffset: 120.5);
      expect(saved.scrollOffset, 120.5);
      expect(saved.isCompleted, isFalse);

      final completed = await progress.markCompleted(unit.id);
      expect(completed.isCompleted, isTrue);
      expect(completed.scrollOffset, 120.5);

      final scrolled = await progress.saveScrollOffset(unit.id, 480);
      expect(scrolled.scrollOffset, 480);
      expect(scrolled.isCompleted, isTrue);
    });

    test('deletes progress', () async {
      final book = await addBook();
      final unit = await addUnit(book);
      await progress.save(unitId: unit.id, scrollOffset: 10);

      await progress.delete(unit.id);

      expect(await progress.findForUnit(unit.id), isNull);
    });
  });

  test('deleting a book cascades to all dependent rows', () async {
    final book = await addBook();
    final unit = await addUnit(book);
    final plan = await plans.createPlan(
      bookId: book.id,
      startDate: DateTime(2026, 2, 1),
      endDate: DateTime(2026, 2, 28),
      minutesPerDay: 60,
      goal: ReadingGoal.review,
      readingSpeedWpm: 150,
    );
    final day = await plans.addDay(
      planId: plan.id,
      date: DateTime(2026, 2, 1),
      minutesBudget: 60,
    );
    await plans.addUnitsToDay(day.id, [unit.id]);
    await progress.markCompleted(unit.id);

    await books.delete(book.id);

    expect(await db.select(db.books).get(), isEmpty);
    expect(await db.select(db.units).get(), isEmpty);
    expect(await db.select(db.plans).get(), isEmpty);
    expect(await db.select(db.planDays).get(), isEmpty);
    expect(await db.select(db.planDayUnits).get(), isEmpty);
    expect(await db.select(db.progress).get(), isEmpty);
  });
}
