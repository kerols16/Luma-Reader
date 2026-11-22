import 'package:flutter_test/flutter_test.dart';
import 'package:luma/domain/planning/planning.dart';

PlannedReading _reading(int day, int index, {double minutes = 1}) {
  return PlannedReading(
    id: 'd$day-r$index',
    chapterId: 'c$day-$index',
    chapterTitle: 'Chapter $day.$index',
    sectionId: 'section',
    paragraphStart: 0,
    paragraphEnd: 0,
    wordCount: (minutes * 100).round(),
    minutes: minutes,
    isWholeChapter: true,
  );
}

PlanSchedule _fourDaySchedule() {
  return PlanSchedule(
    days: [
      for (var day = 1; day <= 4; day++)
        ScheduledDay(
          date: DateTime(2026, 1, 4 + day),
          minutesBudget: 10,
          readings: [
            for (var index = 0; index < 10; index++) _reading(day, index),
          ],
        ),
    ],
    requestedDayCount: 4,
  );
}

PlanSchedule _fourDayOpenSchedule() {
  return PlanSchedule(days: _fourDaySchedule().days, dailyTarget: 10);
}

void main() {
  group('one missed day', () {
    test('moves the remainder into the next days automatically', () {
      final schedule = _fourDaySchedule();
      final missed = schedule.days.first;

      final result = rescheduleAfterMiss(
        schedule: schedule,
        missedDates: {missed.date},
        today: schedule.days[1].date,
      );

      expect(result, isA<RescheduleApplied>());
      final applied = result as RescheduleApplied;
      expect(applied.missedDays, 1);
      expect(applied.movedMinutes, closeTo(10, 1e-9));
      expect(applied.schedule.days, hasLength(4));
      expect(applied.schedule.days.first.readings, isEmpty);
      expect(applied.schedule.days[1].minutesAssigned, closeTo(15, 1e-9));
      expect(applied.schedule.days[2].minutesAssigned, closeTo(13, 1e-9));
      expect(applied.schedule.days[3].minutesAssigned, closeTo(12, 1e-9));
      expect(applied.schedule.days.expand((day) => day.readings).length, 40);
      expect(applied.schedule.totalMinutesAssigned, closeTo(40, 1e-9));
    });

    test('keeps the next day at or below 1.5x the budget', () {
      final schedule = _fourDaySchedule();

      final result =
          rescheduleAfterMiss(
                schedule: schedule,
                missedDates: {schedule.days.first.date},
                today: schedule.days[1].date,
              )
              as RescheduleApplied;

      expect(
        result.schedule.days[1].minutesAssigned,
        lessThanOrEqualTo(15 + 1e-9),
      );
    });

    test('throws when there is no day after the missed day', () {
      final schedule = _fourDaySchedule();

      expect(
        () => rescheduleAfterMiss(
          schedule: schedule,
          missedDates: {schedule.days.last.date},
          today: schedule.days.last.date,
        ),
        throwsA(isA<PlanningException>()),
      );
    });

    test('extra days skip blackout dates', () {
      final schedule = PlanSchedule(
        days: [
          ScheduledDay(
            date: DateTime(2026, 1, 5),
            minutesBudget: 10,
            readings: [
              for (var index = 0; index < 15; index++) _reading(1, index),
            ],
          ),
          ScheduledDay(
            date: DateTime(2026, 1, 6),
            minutesBudget: 10,
            readings: [
              for (var index = 0; index < 10; index++) _reading(2, index),
            ],
          ),
        ],
        requestedDayCount: 2,
      );

      final result =
          rescheduleAfterMiss(
                schedule: schedule,
                missedDates: {DateTime(2026, 1, 5)},
                today: DateTime(2026, 1, 6),
                // The next three calendar days are all blacked out.
                blackouts: BlackoutCalendar(
                  dates: {
                    DateTime(2026, 1, 7),
                    DateTime(2026, 1, 8),
                    DateTime(2026, 1, 9),
                  },
                ),
              )
              as RescheduleApplied;

      expect(result.schedule.days.map((day) => day.date), [
        DateTime(2026, 1, 5),
        DateTime(2026, 1, 6),
        DateTime(2026, 1, 10),
      ]);
      expect(result.schedule.days[1].minutesAssigned, closeTo(15, 1e-9));
      expect(result.schedule.days[2].minutesAssigned, closeTo(10, 1e-9));
      expect(result.movedMinutes, closeTo(15, 1e-9));
    });

    test('never adds moved readings to a blackout day in the plan', () {
      final schedule = PlanSchedule(
        days: [
          ScheduledDay(
            date: DateTime(2026, 1, 5),
            minutesBudget: 10,
            readings: [
              for (var index = 0; index < 3; index++)
                _reading(1, index, minutes: 2),
            ],
          ),
          ScheduledDay(
            date: DateTime(2026, 1, 7), // blacked out below
            minutesBudget: 10,
            readings: [
              for (var index = 0; index < 10; index++) _reading(2, index),
            ],
          ),
          ScheduledDay(
            date: DateTime(2026, 1, 8),
            minutesBudget: 10,
            readings: [
              for (var index = 0; index < 5; index++) _reading(3, index),
            ],
          ),
        ],
        requestedDayCount: 3,
      );

      final result =
          rescheduleAfterMiss(
                schedule: schedule,
                missedDates: {DateTime(2026, 1, 5)},
                today: DateTime(2026, 1, 7),
                blackouts: BlackoutCalendar(dates: {DateTime(2026, 1, 7)}),
              )
              as RescheduleApplied;

      expect(result.schedule.days[1].readings, hasLength(10));
      expect(result.schedule.days[1].minutesAssigned, closeTo(10, 1e-9));
      expect(result.schedule.days[2].minutesAssigned, closeTo(11, 1e-9));
    });
  });

  group('two or more missed days', () {
    test('returns a suggestion and does not change the plan', () {
      final schedule = _fourDaySchedule();
      final missed = {schedule.days[0].date, schedule.days[1].date};

      final result = rescheduleAfterMiss(
        schedule: schedule,
        missedDates: missed,
        today: schedule.days[2].date,
      );

      expect(result, isA<RescheduleSuggestion>());
      final suggestion = result as RescheduleSuggestion;
      expect(suggestion.missedDays, 2);
      expect(suggestion.missedMinutes, closeTo(20, 1e-9));
      expect(suggestion.options, hasLength(3));
      expect(suggestion.options[0], isA<ExtendDeadlineOption>());
      expect(suggestion.options[1], isA<RaiseDailyBudgetOption>());
      expect(suggestion.options[2], isA<TrimLowPriorityOption>());

      final extend = suggestion.options[0] as ExtendDeadlineOption;
      final raise = suggestion.options[1] as RaiseDailyBudgetOption;
      final trim = suggestion.options[2] as TrimLowPriorityOption;
      expect(extend.days, 2);
      expect(raise.minutes, 20);
      expect(trim.unitIds, isNotEmpty);

      // Original plan is untouched; the user decides.
      expect(schedule.days, hasLength(4));
      expect(schedule.days.first.readings, hasLength(10));
    });

    test('suggestion options scale with the missed amount', () {
      final schedule = _fourDaySchedule();
      final missed = {
        schedule.days[0].date,
        schedule.days[1].date,
        schedule.days[2].date,
      };

      final suggestion =
          rescheduleAfterMiss(
                schedule: schedule,
                missedDates: missed,
                today: schedule.days.last.date,
              )
              as RescheduleSuggestion;

      expect(suggestion.missedDays, 3);
      expect((suggestion.options[0] as ExtendDeadlineOption).days, 3);
      expect((suggestion.options[1] as RaiseDailyBudgetOption).minutes, 30);
    });
  });

  test('no missed days returns the plan unchanged', () {
    final schedule = _fourDaySchedule();

    final result =
        rescheduleAfterMiss(
              schedule: schedule,
              missedDates: const {},
              today: schedule.days.first.date,
            )
            as RescheduleApplied;

    expect(result.missedDays, 0);
    expect(result.movedMinutes, 0);
    expect(result.schedule, same(schedule));
  });

  group('no deadline', () {
    test('a missed day shifts the remaining content and finish date', () {
      final schedule = _fourDayOpenSchedule();
      final missed = schedule.days.first;

      final result =
          rescheduleAfterMiss(
                schedule: schedule,
                missedDates: {missed.date},
                today: schedule.days[1].date,
              )
              as RescheduleApplied;

      expect(result.missedDays, 1);
      expect(result.movedMinutes, closeTo(10, 1e-9));
      expect(result.schedule.hasDeadline, isFalse);
      expect(result.schedule.extendsDeadline, isFalse);
      expect(result.schedule.days, hasLength(4));
      expect(result.schedule.days.map((day) => day.date), [
        DateTime(2026, 1, 6),
        DateTime(2026, 1, 7),
        DateTime(2026, 1, 8),
        DateTime(2026, 1, 9),
      ]);
      expect(result.schedule.days.first.readings.first.id, 'd1-r0');
      expect(result.schedule.days.last.readings.first.id, 'd4-r0');
      expect(result.schedule.projectedFinishDate, DateTime(2026, 1, 9));
    });

    test('multiple misses still apply automatically without a suggestion', () {
      final schedule = _fourDayOpenSchedule();

      final result =
          rescheduleAfterMiss(
                schedule: schedule,
                missedDates: {schedule.days[0].date, schedule.days[1].date},
                today: schedule.days[2].date,
              )
              as RescheduleApplied;

      expect(result.missedDays, 2);
      expect(result.schedule.days.map((day) => day.date), [
        DateTime(2026, 1, 7),
        DateTime(2026, 1, 8),
        DateTime(2026, 1, 9),
        DateTime(2026, 1, 10),
      ]);
      expect(result.schedule.projectedFinishDate, DateTime(2026, 1, 10));
    });

    test('a missed final day adds one day instead of throwing', () {
      final schedule = _fourDayOpenSchedule();

      final result =
          rescheduleAfterMiss(
                schedule: schedule,
                missedDates: {schedule.days.last.date},
                today: schedule.days.last.date,
              )
              as RescheduleApplied;

      expect(result.schedule.days, hasLength(4));
      expect(result.schedule.projectedFinishDate, DateTime(2026, 1, 9));
      expect(result.schedule.days.last.readings.first.id, 'd4-r0');
    });
  });

  test('with a deadline, catch-up limits use dailyTarget', () {
    final schedule = PlanSchedule(
      days: [
        ScheduledDay(
          date: DateTime(2026, 1, 5),
          minutesBudget: 5,
          readings: [
            for (var index = 0; index < 10; index++) _reading(1, index),
          ],
        ),
        ScheduledDay(
          date: DateTime(2026, 1, 6),
          minutesBudget: 5,
          readings: [
            for (var index = 0; index < 3; index++) _reading(2, index),
          ],
        ),
        ScheduledDay(
          date: DateTime(2026, 1, 7),
          minutesBudget: 5,
          readings: const [],
        ),
      ],
      requestedDayCount: 3,
      dailyTarget: 5,
    );

    final result =
        rescheduleAfterMiss(
              schedule: schedule,
              missedDates: {DateTime(2026, 1, 5)},
              today: DateTime(2026, 1, 6),
            )
            as RescheduleApplied;

    expect(result.schedule.days[1].minutesAssigned, closeTo(7, 1e-9));
    expect(result.schedule.days[2].minutesAssigned, closeTo(6, 1e-9));
  });
}
