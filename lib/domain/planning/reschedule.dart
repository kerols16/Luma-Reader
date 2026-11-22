import 'dart:math';

import 'package:luma/domain/planning/blackout_calendar.dart';
import 'package:luma/domain/planning/planning_policy.dart';
import 'package:luma/domain/planning/recovery_options.dart';
import 'package:luma/domain/planning/schedule_models.dart';

/// Result of evaluating missed days.
sealed class RescheduleResult {
  const RescheduleResult();
}

/// One missed day was absorbed automatically.
class RescheduleApplied extends RescheduleResult {
  const RescheduleApplied({
    required this.schedule,
    required this.missedDays,
    required this.movedMinutes,
  });

  final PlanSchedule schedule;
  final int missedDays;
  final double movedMinutes;
}

/// Two or more missed days: the user must choose a recovery option.
class RescheduleSuggestion extends RescheduleResult {
  const RescheduleSuggestion({
    required this.missedDays,
    required this.missedMinutes,
    required this.options,
  });

  final int missedDays;
  final double missedMinutes;
  final List<RecoveryOption> options;
}

/// Handles missed reading days after the fact.
///
/// * No deadline: missed days are a pause. The remaining readings keep their
///   order and slide one reading date later, so only the projected finish date
///   moves. This is automatic even for 2+ missed days.
/// * Deadline, 1 missed day: the missed readings move into the next days. The
///   next day may use up to [PlanningPolicy.catchUpLimitFactor] of its budget;
///   later days use the normal maximum. This is applied automatically. Catch-up
///   days never land on dates blocked by [blackouts], and extra days skip
///   blackout dates.
/// * Deadline, 2+ missed days: nothing changes. A [RescheduleSuggestion] with
///   extend/raise/trim options is returned for the user to decide.
RescheduleResult rescheduleAfterMiss({
  required PlanSchedule schedule,
  required Set<DateTime> missedDates,
  required DateTime today,
  PlanningPolicy policy = const PlanningPolicy(),
  BlackoutCalendar blackouts = const BlackoutCalendar(),
}) {
  final missed = {for (final date in missedDates) dateOnly(date)};
  final missedDays = schedule.days
      .where((day) => missed.contains(dateOnly(day.date)))
      .toList(growable: false);

  if (missedDays.isEmpty) {
    return RescheduleApplied(
      schedule: schedule,
      missedDays: 0,
      movedMinutes: 0,
    );
  }

  if (!schedule.hasDeadline) {
    var current = schedule;
    var movedMinutes = 0.0;
    final ordered = [...missedDays]..sort((a, b) => a.date.compareTo(b.date));
    for (final missedDay in ordered) {
      final index = current.days.indexWhere((day) => day.isOn(missedDay.date));
      if (index < 0) continue;
      current = _shiftNoDeadline(current, index, blackouts);
      movedMinutes += missedDay.minutesAssigned;
    }
    return RescheduleApplied(
      schedule: current,
      missedDays: ordered.length,
      movedMinutes: movedMinutes,
    );
  }

  if (missedDays.length >= 2) {
    return _suggestion(
      schedule: schedule,
      missedDays: missedDays,
      today: today,
    );
  }

  return _applySingleMiss(
    schedule: schedule,
    missedDay: missedDays.single,
    policy: policy,
    blackouts: blackouts,
  );
}

RescheduleSuggestion _suggestion({
  required PlanSchedule schedule,
  required List<ScheduledDay> missedDays,
  required DateTime today,
}) {
  final missedReadings = missedDays
      .expand((day) => day.readings)
      .toList(growable: false);
  final missedMinutes = missedReadings.fold(
    0.0,
    (total, reading) => total + reading.minutes,
  );
  final budget = schedule.dailyTarget ?? missedDays.first.minutesBudget;
  final safeBudget = budget <= 0 ? 1.0 : budget;

  final remainingDays = schedule.days
      .where((day) => dateOnly(day.date).isAfter(dateOnly(today)))
      .length;
  final daysForBudget = max(1, remainingDays);

  final extendDays = max(1, (missedMinutes / safeBudget).ceil());
  final raiseMinutes = max(1, (missedMinutes / daysForBudget).ceil());

  // No priority metadata exists yet, so every missed reading is a trim
  // candidate, smallest first.
  final trimCandidates = [...missedReadings]
    ..sort((a, b) => a.minutes.compareTo(b.minutes));

  return RescheduleSuggestion(
    missedDays: missedDays.length,
    missedMinutes: missedMinutes,
    options: List.unmodifiable([
      ExtendDeadlineOption(extendDays),
      RaiseDailyBudgetOption(raiseMinutes),
      TrimLowPriorityOption(
        List.unmodifiable(trimCandidates.map((reading) => reading.id)),
      ),
    ]),
  );
}

/// With no deadline, a missed day is just a pause: every later reading keeps
/// its order and moves one reading date forward, adding a new final day.
PlanSchedule _shiftNoDeadline(
  PlanSchedule schedule,
  int missedIndex,
  BlackoutCalendar blackouts,
) {
  final days = schedule.days;
  final newDays = <ScheduledDay>[...days.sublist(0, missedIndex)];

  for (var index = missedIndex; index < days.length - 1; index++) {
    newDays.add(
      ScheduledDay(
        date: days[index + 1].date,
        minutesBudget: days[index].minutesBudget,
        readings: days[index].readings,
      ),
    );
  }

  var finish = nextDay(days.last.date);
  while (blackouts.isBlackedOut(finish)) {
    finish = nextDay(finish);
  }
  newDays.add(
    ScheduledDay(
      date: finish,
      minutesBudget: days.last.minutesBudget,
      readings: days.last.readings,
    ),
  );

  return PlanSchedule(
    days: List.unmodifiable(newDays),
    requestedDayCount: null,
    extendsDeadline: false,
    dailyTarget: schedule.dailyTarget,
    pacingMode: schedule.pacingMode,
  );
}

RescheduleResult _applySingleMiss({
  required PlanSchedule schedule,
  required ScheduledDay missedDay,
  required PlanningPolicy policy,
  required BlackoutCalendar blackouts,
}) {
  final missedIndex = schedule.days.indexWhere(
    (day) => day.isOn(missedDay.date),
  );
  if (missedIndex < 0) {
    throw const PlanningException('The missed day is not part of the plan.');
  }
  if (missedIndex == schedule.days.length - 1) {
    throw const PlanningException('There is no day after the missed day.');
  }

  final budget = schedule.dailyTarget ?? missedDay.minutesBudget;
  final readingsByDay = [
    for (var index = 0; index < schedule.days.length; index++)
      index == missedIndex
          ? <PlannedReading>[]
          : List<PlannedReading>.of(schedule.days[index].readings),
  ];
  final dates = [for (final day in schedule.days) day.date];
  final budgets = [for (final day in schedule.days) day.minutesBudget];
  final movedByDay = <int, List<PlannedReading>>{};

  var target = missedIndex + 1;
  var movedMinutes = 0.0;

  double limitFor(int dayIndex) {
    final offset = dayIndex - missedIndex;
    final factor = offset == 1 ? policy.catchUpLimitFactor : policy.maxDayFill;
    return budget * factor;
  }

  DateTime nextReadingDate(DateTime from) {
    var candidate = nextDay(from);
    while (blackouts.isBlackedOut(candidate)) {
      candidate = nextDay(candidate);
    }
    return candidate;
  }

  for (final reading in missedDay.readings) {
    while (true) {
      if (target >= readingsByDay.length) {
        readingsByDay.add([]);
        dates.add(nextReadingDate(dates.last));
        budgets.add(budget);
      } else if (blackouts.isBlackedOut(dates[target])) {
        // Never spread readings onto a blackout date, even if the original
        // plan happened to contain one.
        target++;
        continue;
      }

      final existing = readingsByDay[target];
      final alreadyMoved = movedByDay[target] ?? const <PlannedReading>[];
      final used =
          existing.fold(0.0, (total, item) => total + item.minutes) +
          alreadyMoved.fold(0.0, (total, item) => total + item.minutes);
      final isEmpty = existing.isEmpty && alreadyMoved.isEmpty;
      final limit = limitFor(target);

      if (isEmpty || used + reading.minutes <= limit + 1e-9) {
        movedByDay.putIfAbsent(target, () => []).add(reading);
        movedMinutes += reading.minutes;
        break;
      }
      target++;
    }
  }

  final newDays = <ScheduledDay>[
    for (var index = 0; index < readingsByDay.length; index++)
      ScheduledDay(
        date: dates[index],
        minutesBudget: budgets[index],
        readings: List.unmodifiable([
          ...?movedByDay[index],
          ...readingsByDay[index],
        ]),
      ),
  ];

  return RescheduleApplied(
    schedule: PlanSchedule(
      days: List.unmodifiable(newDays),
      requestedDayCount: schedule.requestedDayCount,
      extendsDeadline:
          schedule.extendsDeadline || newDays.length > schedule.days.length,
      dailyTarget: schedule.dailyTarget,
      pacingMode: schedule.pacingMode,
      suggestions: schedule.suggestions,
    ),
    missedDays: 1,
    movedMinutes: movedMinutes,
  );
}
