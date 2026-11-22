import 'package:flutter_test/flutter_test.dart';
import 'package:luma/domain/entities/book.dart';
import 'package:luma/domain/entities/reading_plan.dart';
import 'package:luma/domain/planning/planning.dart';

import 'planning_test_helpers.dart';

const _wpm = 100;

void main() {
  group('minutes and difficulty', () {
    test('minutes = words / wpm * difficulty factor', () {
      for (final (difficulty, expected) in [
        (1, 10.0),
        (2, 12.0),
        (3, 15.0),
        (9, 15.0),
      ]) {
        final schedule = planDays(
          chapters: [
            makeChapter('c', [1000], difficulty: difficulty),
          ],
          startDate: DateTime(2026, 1, 5),
          dayCount: 1,
          minutesPerDay: 60,
          readingSpeedWpm: _wpm,
        );

        expect(schedule.days.single.minutesAssigned, closeTo(expected, 1e-9));
      }
    });

    test('placeholder reading speeds are 150 Arabic and 220 English', () {
      expect(ReadingSpeedDefaults.forLanguage(BookLanguage.ar), 150);
      expect(ReadingSpeedDefaults.forLanguage(BookLanguage.en), 220);
    });
  });

  group('packing', () {
    test('packs chapters within the 0.7x-1.3x tolerance', () {
      final schedule = planDays(
        chapters: [
          for (var i = 0; i < 20; i++) makeChapter('c$i', [400]),
        ],
        startDate: DateTime(2026, 1, 5),
        dayCount: 10,
        minutesPerDay: 10,
        readingSpeedWpm: _wpm,
      );

      expect(schedule.days, hasLength(10));
      expect(schedule.totalDays, 10);
      expect(schedule.dailyTarget, closeTo(8, 1e-9));
      for (final day in schedule.days) {
        expect(day.minutesAssigned, closeTo(8, 1e-9));
      }
      expect(schedule.totalMinutesAssigned, closeTo(80, 1e-9));
    });

    test('many tiny chapters are balanced within the tolerance', () {
      final schedule = planDays(
        chapters: [
          for (var i = 0; i < 30; i++) makeChapter('c$i', [100]),
        ],
        startDate: DateTime(2026, 1, 5),
        dayCount: 10,
        minutesPerDay: 10,
        readingSpeedWpm: _wpm,
      );

      expect(schedule.days, hasLength(10));
      expect(schedule.totalMinutesAssigned, closeTo(30, 1e-9));
      for (final day in schedule.days) {
        expect(day.minutesAssigned, closeTo(3, 1e-9));
      }
    });

    test('small chapters merge with the next chapter in the same section', () {
      final schedule = planDays(
        chapters: [
          makeChapter('small', [300]),
          makeChapter('next', [500]),
        ],
        startDate: DateTime(2026, 1, 5),
        dayCount: 1,
        minutesPerDay: 10,
        readingSpeedWpm: _wpm,
      );

      expect(schedule.days, hasLength(1));
      expect(
        schedule.days.single.readings.map((reading) => reading.chapterId),
        ['small', 'next'],
      );
      expect(schedule.days.single.minutesAssigned, closeTo(8, 1e-9));
    });

    test('never merges across a section boundary', () {
      final schedule = planDays(
        chapters: [
          makeChapter('endOfPart', [300], sectionId: 'part-one'),
          makeChapter('newPart', [500], sectionId: 'part-two'),
        ],
        startDate: DateTime(2026, 1, 5),
        dayCount: 2,
        minutesPerDay: 10,
        readingSpeedWpm: _wpm,
      );

      expect(schedule.days, hasLength(2));
      expect(schedule.days.first.readings.map((reading) => reading.chapterId), [
        'endOfPart',
      ]);
      expect(schedule.days.last.readings.map((reading) => reading.chapterId), [
        'newPart',
      ]);
    });

    test('content that does not fit extends the deadline', () {
      final schedule = planDays(
        chapters: [
          for (var i = 0; i < 4; i++) makeChapter('c$i', [1000]),
        ],
        startDate: DateTime(2026, 1, 5),
        dayCount: 2,
        minutesPerDay: 10,
        readingSpeedWpm: _wpm,
        goal: ReadingGoal.understand,
      );

      expect(schedule.requestedDayCount, 2);
      expect(schedule.extendsDeadline, isTrue);
      expect(schedule.days, hasLength(4));
      expect(schedule.days.last.date, DateTime(2026, 1, 8));
    });

    test('a whole chapter at 1.3x the budget is allowed', () {
      final schedule = planDays(
        chapters: [
          makeChapter('c', [1300]),
        ],
        startDate: DateTime(2026, 1, 5),
        dayCount: 1,
        minutesPerDay: 10,
        readingSpeedWpm: _wpm,
        goal: ReadingGoal.understand,
      );

      expect(schedule.days.single.readings, hasLength(1));
      expect(schedule.days.single.minutesAssigned, closeTo(13, 1e-9));
    });
  });

  group('no deadline', () {
    test('packs up to the daily budget and projects the finish date', () {
      final schedule = planDays(
        chapters: [
          for (var i = 0; i < 6; i++) makeChapter('c$i', [500]),
        ],
        startDate: DateTime(2026, 1, 5),
        minutesPerDay: 10,
        readingSpeedWpm: _wpm,
      );

      expect(schedule.hasDeadline, isFalse);
      expect(schedule.requestedDayCount, isNull);
      expect(schedule.extendsDeadline, isFalse);
      expect(schedule.totalDays, 3);
      expect(schedule.days.map((day) => day.date), [
        DateTime(2026, 1, 5),
        DateTime(2026, 1, 6),
        DateTime(2026, 1, 7),
      ]);
      expect(schedule.projectedFinishDate, DateTime(2026, 1, 7));
      expect(schedule.dailyTarget, 10);
      for (final day in schedule.days) {
        expect(day.minutesAssigned, closeTo(10, 1e-9));
      }
    });

    test('skips blackout dates while projecting the finish', () {
      final schedule = planDays(
        chapters: [
          for (var i = 0; i < 3; i++) makeChapter('c$i', [1000]),
        ],
        startDate: DateTime(2026, 1, 5),
        minutesPerDay: 10,
        readingSpeedWpm: _wpm,
        blackouts: BlackoutCalendar(dates: {DateTime(2026, 1, 6)}),
      );

      expect(schedule.days.map((day) => day.date), [
        DateTime(2026, 1, 5),
        DateTime(2026, 1, 7),
        DateTime(2026, 1, 8),
      ]);
      expect(schedule.projectedFinishDate, DateTime(2026, 1, 8));
    });

    test('never overflows, even when content needs many days', () {
      final schedule = planDays(
        chapters: [
          for (var i = 0; i < 20; i++) makeChapter('c$i', [1000]),
        ],
        startDate: DateTime(2026, 1, 5),
        minutesPerDay: 10,
        readingSpeedWpm: _wpm,
      );

      expect(schedule.totalDays, 20);
      expect(schedule.extendsDeadline, isFalse);
      expect(schedule.suggestions, isEmpty);
      expect(schedule.projectedFinishDate, DateTime(2026, 1, 24));
    });
  });

  group('deadline pacing', () {
    test('even mode spreads content over the available days', () {
      final schedule = planDays(
        chapters: [
          for (var i = 0; i < 10; i++) makeChapter('c$i', [600]),
        ],
        startDate: DateTime(2026, 1, 5),
        dayCount: 10,
        minutesPerDay: 10,
        readingSpeedWpm: _wpm,
      );

      expect(schedule.dailyTarget, closeTo(6, 1e-9));
      expect(schedule.totalDays, 10);
      expect(schedule.extendsDeadline, isFalse);
      for (final day in schedule.days) {
        expect(day.minutesAssigned, closeTo(6, 1e-9));
        expect(day.minutesBudget, closeTo(6, 1e-9));
      }
    });

    test('even mode distributes instead of finishing early like fastest', () {
      final chapters = [
        for (var i = 0; i < 10; i++) makeChapter('c$i', [200]),
      ];
      final even = planDays(
        chapters: chapters,
        startDate: DateTime(2026, 1, 5),
        dayCount: 10,
        minutesPerDay: 10,
        readingSpeedWpm: _wpm,
      );
      final fastest = planDays(
        chapters: chapters,
        startDate: DateTime(2026, 1, 5),
        dayCount: 10,
        minutesPerDay: 10,
        readingSpeedWpm: _wpm,
        pacing: PacingMode.fastest,
      );

      expect(even.totalDays, 10);
      expect(fastest.totalDays, 2);
      expect(even.dailyTarget, closeTo(2, 1e-9));
      expect(fastest.dailyTarget, 10);
    });

    test('even mode caps the target at minutesPerDay when content fits', () {
      final schedule = planDays(
        chapters: [
          for (var i = 0; i < 5; i++) makeChapter('c$i', [1000]),
        ],
        startDate: DateTime(2026, 1, 5),
        dayCount: 5,
        minutesPerDay: 10,
        readingSpeedWpm: _wpm,
      );

      expect(schedule.dailyTarget, 10);
      expect(schedule.totalDays, 5);
      expect(schedule.extendsDeadline, isFalse);
    });

    test('even mode overflows with suggestions when content cannot fit', () {
      final schedule = planDays(
        chapters: [
          for (var i = 0; i < 4; i++) makeChapter('c$i', [1000]),
        ],
        startDate: DateTime(2026, 1, 5),
        dayCount: 2,
        minutesPerDay: 10,
        readingSpeedWpm: _wpm,
        goal: ReadingGoal.understand,
      );

      expect(schedule.dailyTarget, 10);
      expect(schedule.extendsDeadline, isTrue);
      expect(schedule.totalDays, greaterThan(2));
      expect(schedule.suggestions, hasLength(3));
      expect(schedule.suggestions[0], isA<ExtendDeadlineOption>());
      expect(schedule.suggestions[1], isA<RaiseDailyBudgetOption>());
      expect(schedule.suggestions[2], isA<TrimLowPriorityOption>());
      expect(
        (schedule.suggestions[0] as ExtendDeadlineOption).days,
        schedule.totalDays - 2,
      );
      expect(
        (schedule.suggestions[1] as RaiseDailyBudgetOption).minutes,
        greaterThan(0),
      );
    });

    test('fastest mode fills days and finishes early', () {
      final schedule = planDays(
        chapters: [
          for (var i = 0; i < 10; i++) makeChapter('c$i', [600]),
        ],
        startDate: DateTime(2026, 1, 5),
        dayCount: 10,
        minutesPerDay: 10,
        readingSpeedWpm: _wpm,
        pacing: PacingMode.fastest,
      );

      expect(schedule.totalDays, 5);
      for (final day in schedule.days) {
        expect(day.minutesAssigned, closeTo(12, 1e-9));
      }
    });
  });

  group('splitting', () {
    test('never splits a paragraph', () {
      final chapter = makeChapter('c', [90, 310, 120, 480, 220, 600]);
      final schedule = planDays(
        chapters: [chapter],
        startDate: DateTime(2026, 1, 5),
        dayCount: 5,
        minutesPerDay: 10,
        readingSpeedWpm: _wpm,
        goal: ReadingGoal.understand,
      );

      final readings = schedule.days
          .expand((day) => day.readings)
          .where((reading) => reading.chapterId == 'c')
          .toList();

      expect(readings.length, greaterThan(1));
      final covered = <int>[];
      for (final reading in readings) {
        var expectedWords = 0;
        for (
          var index = reading.paragraphStart;
          index <= reading.paragraphEnd;
          index++
        ) {
          covered.add(index);
          expectedWords += chapter.paragraphs[index].wordCount;
        }
        expect(reading.wordCount, expectedWords);
        expect(reading.minutes, closeTo(expectedWords / _wpm, 1e-9));
      }
      expect(covered, [0, 1, 2, 3, 4, 5]);
      expect(
        readings.map((reading) => reading.id).toSet(),
        hasLength(readings.length),
      );
    });

    test('splits an oversized chapter at sub-headings first', () {
      final schedule = planDays(
        chapters: [
          makeChapter('big', [200, 10, 1000, 1000, 300], headingIndexes: {1}),
        ],
        startDate: DateTime(2026, 1, 5),
        dayCount: 5,
        minutesPerDay: 10,
        readingSpeedWpm: _wpm,
        goal: ReadingGoal.understand,
      );

      final readings = schedule.days.expand((day) => day.readings).toList();

      expect(readings.length, greaterThan(1));
      // The pre-heading block ends at paragraph 0; the heading starts a piece.
      expect(
        readings.where(
          (reading) => reading.paragraphStart == 0 && reading.paragraphEnd == 0,
        ),
        isNotEmpty,
      );
      expect(
        readings.where((reading) => reading.paragraphStart == 1),
        isNotEmpty,
      );
      expect(
        readings.where(
          (reading) => reading.paragraphStart == 0 && reading.paragraphEnd >= 1,
        ),
        isEmpty,
      );
    });

    test('splits at paragraph boundaries near the target without headings', () {
      final schedule = planDays(
        chapters: [makeChapter('long', List.filled(10, 300))],
        startDate: DateTime(2026, 1, 5),
        dayCount: 5,
        minutesPerDay: 10,
        readingSpeedWpm: _wpm,
        goal: ReadingGoal.understand,
      );

      final readings = schedule.days.expand((day) => day.readings).toList();

      expect(readings.length, greaterThan(1));
      for (final reading in readings) {
        expect(reading.wordCount, lessThanOrEqualTo(1300));
      }
      expect(readings.fold(0.0, (total, r) => total + r.minutes), 30);
    });

    test('novels keep chapters whole up to 1.25x the budget', () {
      final paragraphs = List.filled(13, 100);

      final novel = planDays(
        chapters: [makeChapter('n', paragraphs)],
        startDate: DateTime(2026, 1, 5),
        minutesPerDay: 10,
        readingSpeedWpm: _wpm,
        goal: ReadingGoal.read,
      );
      final study = planDays(
        chapters: [makeChapter('n', paragraphs)],
        startDate: DateTime(2026, 1, 5),
        minutesPerDay: 10,
        readingSpeedWpm: _wpm,
        goal: ReadingGoal.understand,
      );

      expect(novel.days.expand((day) => day.readings).length, greaterThan(1));
      expect(study.days.expand((day) => day.readings), hasLength(1));
    });

    test('a novel chapter under 1.25x stays whole', () {
      final schedule = planDays(
        chapters: [makeChapter('n', List.filled(12, 100))],
        startDate: DateTime(2026, 1, 5),
        dayCount: 1,
        minutesPerDay: 10,
        readingSpeedWpm: _wpm,
        goal: ReadingGoal.read,
      );

      expect(schedule.days.single.readings, hasLength(1));
      expect(schedule.days.single.readings.single.isWholeChapter, isTrue);
    });
  });

  group('blackout calendar', () {
    test('skips blackout weekdays', () {
      final schedule = planDays(
        chapters: [
          for (var i = 0; i < 5; i++) makeChapter('c$i', [1000]),
        ],
        startDate: DateTime(2026, 1, 5), // Monday
        endDate: DateTime(2026, 1, 11), // Sunday
        minutesPerDay: 10,
        readingSpeedWpm: _wpm,
        goal: ReadingGoal.understand,
        blackouts: const BlackoutCalendar(
          weekdays: {DateTime.saturday, DateTime.sunday},
        ),
      );

      expect(schedule.requestedDayCount, 5);
      expect(schedule.days.map((day) => day.date), [
        DateTime(2026, 1, 5),
        DateTime(2026, 1, 6),
        DateTime(2026, 1, 7),
        DateTime(2026, 1, 8),
        DateTime(2026, 1, 9),
      ]);
    });

    test('skips specific blackout dates', () {
      final schedule = planDays(
        chapters: [
          for (var i = 0; i < 3; i++) makeChapter('c$i', [1000]),
        ],
        startDate: DateTime(2026, 1, 5),
        dayCount: 3,
        minutesPerDay: 10,
        readingSpeedWpm: _wpm,
        goal: ReadingGoal.understand,
        blackouts: BlackoutCalendar(dates: {DateTime(2026, 1, 6)}),
      );

      expect(schedule.days.map((day) => day.date), [
        DateTime(2026, 1, 5),
        DateTime(2026, 1, 7),
        DateTime(2026, 1, 8),
      ]);
    });

    test('throws when the window has zero reading days', () {
      expect(
        () => planDays(
          chapters: [
            makeChapter('c', [1000]),
          ],
          startDate: DateTime(2026, 1, 5),
          endDate: DateTime(2026, 1, 5),
          minutesPerDay: 10,
          readingSpeedWpm: _wpm,
          blackouts: const BlackoutCalendar(weekdays: {DateTime.monday}),
        ),
        throwsA(isA<PlanningException>()),
      );
    });

    test('throws when all weekdays are blacked out with dayCount', () {
      expect(
        () => planDays(
          chapters: [
            makeChapter('c', [1000]),
          ],
          startDate: DateTime(2026, 1, 5),
          dayCount: 3,
          minutesPerDay: 10,
          readingSpeedWpm: _wpm,
          blackouts: const BlackoutCalendar(
            weekdays: {
              DateTime.monday,
              DateTime.tuesday,
              DateTime.wednesday,
              DateTime.thursday,
              DateTime.friday,
              DateTime.saturday,
              DateTime.sunday,
            },
          ),
        ),
        throwsA(isA<PlanningException>()),
      );
    });
  });

  group('validation', () {
    test('rejects both deadline forms together', () {
      expect(
        () => planDays(
          chapters: [
            makeChapter('c', [1000]),
          ],
          startDate: DateTime(2026, 1, 5),
          endDate: DateTime(2026, 1, 6),
          dayCount: 2,
          minutesPerDay: 10,
          readingSpeedWpm: _wpm,
        ),
        throwsArgumentError,
      );
    });

    test('allows no deadline at all', () {
      final schedule = planDays(
        chapters: [
          makeChapter('c', [1000]),
        ],
        startDate: DateTime(2026, 1, 5),
        minutesPerDay: 10,
        readingSpeedWpm: _wpm,
      );

      expect(schedule.requestedDayCount, isNull);
      expect(schedule.hasDeadline, isFalse);
      expect(schedule.extendsDeadline, isFalse);
      expect(schedule.suggestions, isEmpty);
      expect(schedule.totalDays, 1);
      expect(schedule.projectedFinishDate, DateTime(2026, 1, 5));
    });

    test('rejects an end date before the start date', () {
      expect(
        () => planDays(
          chapters: [
            makeChapter('c', [1000]),
          ],
          startDate: DateTime(2026, 1, 5),
          endDate: DateTime(2026, 1, 4),
          minutesPerDay: 10,
          readingSpeedWpm: _wpm,
        ),
        throwsA(isA<PlanningException>()),
      );
    });

    test('rejects empty content', () {
      expect(
        () => planDays(
          chapters: [
            makeChapter('c', [0]),
          ],
          startDate: DateTime(2026, 1, 5),
          dayCount: 1,
          minutesPerDay: 10,
          readingSpeedWpm: _wpm,
        ),
        throwsA(isA<PlanningException>()),
      );
    });
  });

  group('today progress', () {
    test('exposes minutes done / minutes budget', () {
      final schedule = planDays(
        chapters: [
          makeChapter('a', [600]),
          makeChapter('b', [400]),
        ],
        startDate: DateTime(2026, 1, 5),
        dayCount: 1,
        minutesPerDay: 10,
        readingSpeedWpm: _wpm,
      );
      final day = schedule.days.single;

      final progress = day.progress(minutesDone: 4);
      expect(progress.minutesDone, 4);
      expect(progress.minutesBudget, 10);
      expect(progress.ratio, closeTo(0.4, 1e-9));
      expect(progress.isDone, isFalse);
      expect(progress.remainingMinutes, 6);

      final done = day.progress(minutesDone: 10);
      expect(done.isDone, isTrue);
      expect(done.ratio, 1);

      final over = day.progress(minutesDone: 14);
      expect(over.isOverBudget, isTrue);
      expect(over.ratio, 1);
    });

    test('can compute progress from completed reading ids', () {
      final schedule = planDays(
        chapters: [
          makeChapter('a', [600]),
          makeChapter('b', [400]),
        ],
        startDate: DateTime(2026, 1, 5),
        dayCount: 1,
        minutesPerDay: 10,
        readingSpeedWpm: _wpm,
      );
      final day = schedule.days.single;
      final first = day.readings.first;

      final progress = day.progressFor({first.id});

      expect(progress.minutesDone, closeTo(first.minutes, 1e-9));
      expect(progress.ratio, closeTo(0.6, 1e-9));
    });
  });
}
