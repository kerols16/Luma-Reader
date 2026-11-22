import 'dart:math' as math;

import 'package:luma/domain/entities/reading_plan.dart';
import 'package:luma/domain/planning/blackout_calendar.dart';
import 'package:luma/domain/planning/planning_models.dart';
import 'package:luma/domain/planning/planning_policy.dart';
import 'package:luma/domain/planning/recovery_options.dart';
import 'package:luma/domain/planning/schedule_models.dart';

const _epsilon = 1e-9;

/// Splits [chapters] into reading pieces and packs them into daily budgets.
///
/// No deadline (`endDate` and `dayCount` both omitted): every day is packed up
/// to [minutesPerDay] and the plan simply finishes when the content ends.
///
/// With a deadline, exactly one of [endDate] and [dayCount] must be supplied.
/// [PacingMode.even] spreads the content over the available reading days using
/// `totalMinutes / availableDays` (capped at [minutesPerDay]); [PacingMode.fastest]
/// fills each day up to [minutesPerDay] and finishes as early as possible.
///
/// Blackout weekdays/dates are skipped. If a deadline cannot be met, the plan
/// continues on extra days, [PlanSchedule.extendsDeadline] becomes true, and
/// [PlanSchedule.suggestions] contains recovery options.
PlanSchedule planDays({
  required List<PlanningChapter> chapters,
  required DateTime startDate,
  DateTime? endDate,
  int? dayCount,
  int minutesPerDay = 60,
  required int readingSpeedWpm,
  ReadingGoal goal = ReadingGoal.read,
  BlackoutCalendar blackouts = const BlackoutCalendar(),
  PlanningPolicy policy = const PlanningPolicy(),
  PacingMode pacing = PacingMode.even,
}) {
  if (endDate != null && dayCount != null) {
    throw ArgumentError('Provide at most one of endDate or dayCount.');
  }
  if (minutesPerDay <= 0) {
    throw ArgumentError.value(minutesPerDay, 'minutesPerDay', 'Must be > 0');
  }
  if (readingSpeedWpm <= 0) {
    throw ArgumentError.value(
      readingSpeedWpm,
      'readingSpeedWpm',
      'Must be > 0',
    );
  }
  if (dayCount != null && dayCount <= 0) {
    throw ArgumentError.value(dayCount, 'dayCount', 'Must be > 0');
  }

  final content = chapters.where((chapter) => chapter.wordCount > 0).toList();
  if (content.isEmpty) {
    throw const PlanningException('No readable content to plan.');
  }

  final hasDeadline = endDate != null || dayCount != null;
  final availableDays = hasDeadline
      ? _readingDays(
          startDate: startDate,
          endDate: endDate,
          dayCount: dayCount,
          blackouts: blackouts,
        )
      : const <DateTime>[];
  if (hasDeadline && availableDays.isEmpty) {
    throw const PlanningException('No reading days are available.');
  }

  final totalMinutes = _totalMinutes(content, readingSpeedWpm: readingSpeedWpm);
  final cap = minutesPerDay.toDouble();
  var target = cap;
  if (hasDeadline && pacing == PacingMode.even) {
    final evenTarget = totalMinutes / availableDays.length;
    if (evenTarget < target) target = evenTarget;
  }

  final maxPerDay = target * policy.maxDayFill;
  final cannotFitEven =
      hasDeadline &&
      pacing == PacingMode.even &&
      totalMinutes > availableDays.length * maxPerDay + _epsilon;
  final balancePieces =
      hasDeadline &&
      pacing == PacingMode.even &&
      !cannotFitEven &&
      availableDays.length > 1;

  final pieces = <PlannedReading>[
    for (final chapter in content)
      ..._chapterPieces(
        chapter: chapter,
        budget: target,
        readingSpeedWpm: readingSpeedWpm,
        goal: goal,
        policy: policy,
        evenPacing: balancePieces,
      ),
  ];

  final source = _ReadingDateSource(
    startDate: startDate,
    blackouts: blackouts,
    fixedDays: availableDays,
  );

  final days = hasDeadline && pacing == PacingMode.even && !cannotFitEven
      ? _packEven(
          pieces: pieces,
          source: source,
          target: target,
          availableDays: availableDays.length,
          policy: policy,
        )
      : _packFastest(
          pieces: pieces,
          source: source,
          target: target,
          policy: policy,
        );

  if (!hasDeadline || pacing == PacingMode.fastest || cannotFitEven) {
    _mergeShortDays(days, target: target, policy: policy);
  }
  _smoothTail(days, target: target, policy: policy);

  final extendsDeadline =
      hasDeadline && (days.length > availableDays.length || cannotFitEven);
  final suggestions = extendsDeadline
      ? _overflowSuggestions(
          pieces: pieces,
          totalMinutes: totalMinutes,
          availableDays: availableDays.length,
          cap: cap,
          plannedDays: days.length,
        )
      : const <RecoveryOption>[];

  return PlanSchedule(
    days: List.unmodifiable(days),
    requestedDayCount: hasDeadline ? availableDays.length : null,
    extendsDeadline: extendsDeadline,
    dailyTarget: target,
    pacingMode: pacing,
    suggestions: List.unmodifiable(suggestions),
  );
}

double _totalMinutes(
  List<PlanningChapter> chapters, {
  required int readingSpeedWpm,
}) {
  return chapters.fold(0.0, (total, chapter) {
    return total +
        chapter.wordCount /
            readingSpeedWpm *
            difficultyFactorFor(chapter.difficulty);
  });
}

/// Generates scheduled dates: the fixed window first, then extra days that skip
/// blackout dates. With no fixed days (no deadline) it starts at [startDate].
class _ReadingDateSource {
  _ReadingDateSource({
    required DateTime startDate,
    required this.blackouts,
    required List<DateTime> fixedDays,
  }) : _start = dateOnly(startDate),
       _fixed = fixedDays;

  final DateTime _start;
  final BlackoutCalendar blackouts;
  final List<DateTime> _fixed;
  int _index = 0;
  DateTime? _last;

  DateTime next() {
    if (_index < _fixed.length) {
      final date = _fixed[_index++];
      _last = date;
      return date;
    }

    var candidate = _last == null ? _start : nextDay(_last!);
    while (blackouts.isBlackedOut(candidate)) {
      candidate = nextDay(candidate);
    }
    _last = candidate;
    return candidate;
  }
}

/// Greedy packing up to 1.3x the target per day.
List<ScheduledDay> _packFastest({
  required List<PlannedReading> pieces,
  required _ReadingDateSource source,
  required double target,
  required PlanningPolicy policy,
}) {
  final maxDay = target * policy.maxDayFill;
  final days = <ScheduledDay>[];
  var current = <PlannedReading>[];
  var currentMinutes = 0.0;
  var currentSection = '';

  void flushDay() {
    if (current.isEmpty) return;
    days.add(
      ScheduledDay(
        date: source.next(),
        minutesBudget: target,
        readings: List.unmodifiable(current),
      ),
    );
    current = [];
    currentMinutes = 0;
  }

  for (final piece in pieces) {
    if (current.isNotEmpty) {
      final sectionChanged = piece.sectionId != currentSection;
      final overBudget = currentMinutes + piece.minutes > maxDay + _epsilon;
      if (sectionChanged || overBudget) flushDay();
    }
    if (current.isEmpty) currentSection = piece.sectionId;
    current.add(piece);
    currentMinutes += piece.minutes;
  }
  flushDay();

  return days;
}

/// Distributes pieces over as many days as the window allows, minimizing the
/// heaviest day. Dynamic programming keeps piece order and section boundaries.
List<ScheduledDay> _packEven({
  required List<PlannedReading> pieces,
  required _ReadingDateSource source,
  required double target,
  required int availableDays,
  required PlanningPolicy policy,
}) {
  final count = pieces.length;
  final dayCount = math.min(availableDays, count);
  if (dayCount == 0) return [];

  final prefix = List<double>.filled(count + 1, 0);
  for (var index = 0; index < count; index++) {
    prefix[index + 1] = prefix[index] + pieces[index].minutes;
  }

  // A group ending at [index] may not start before this offset, which keeps
  // each day inside a single section.
  final sectionStart = List<int>.filled(count + 1, 0);
  var start = 0;
  for (var index = 1; index <= count; index++) {
    if (index >= 2 &&
        pieces[index - 1].sectionId != pieces[index - 2].sectionId) {
      start = index - 1;
    }
    sectionStart[index] = start;
  }

  var previous = List<double>.filled(count + 1, double.infinity);
  previous[0] = 0;
  final choices = List.generate(
    dayCount + 1,
    (_) => List<int>.filled(count + 1, -1),
  );

  for (var day = 1; day <= dayCount; day++) {
    final current = List<double>.filled(count + 1, double.infinity);
    for (var end = day; end <= count; end++) {
      final firstStart = math.max(day - 1, sectionStart[end]);
      for (var groupStart = firstStart; groupStart < end; groupStart++) {
        final before = previous[groupStart];
        if (before.isInfinite) continue;
        final groupMinutes = prefix[end] - prefix[groupStart];
        final candidate = math.max(before, groupMinutes);
        if (candidate < current[end] - _epsilon) {
          current[end] = candidate;
          choices[day][end] = groupStart;
        }
      }
    }
    previous = current;
  }

  if (previous[count].isInfinite) {
    return _packFastest(
      pieces: pieces,
      source: source,
      target: target,
      policy: policy,
    );
  }

  final bounds = <({int start, int end})>[];
  var end = count;
  for (var day = dayCount; day >= 1; day--) {
    final start = choices[day][end];
    bounds.add((start: start, end: end));
    end = start;
  }
  final ordered = bounds.reversed.toList(growable: false);

  return [
    for (final bound in ordered)
      ScheduledDay(
        date: source.next(),
        minutesBudget: target,
        readings: List.unmodifiable(pieces.sublist(bound.start, bound.end)),
      ),
  ];
}

/// Merges a short day into an adjacent day in the same section when the
/// combined load still fits the upper tolerance. This removes stray 5-minute
/// days caused by an indivisible chapter that follows them.
void _mergeShortDays(
  List<ScheduledDay> days, {
  required double target,
  required PlanningPolicy policy,
}) {
  final minDay = target * policy.minDayFill;
  final maxDay = target * policy.maxDayFill;

  var index = 1;
  while (index < days.length) {
    final day = days[index];
    if (day.minutesAssigned + _epsilon >= minDay) {
      index++;
      continue;
    }

    final previous = days[index - 1];
    final previousFits =
        previous.minutesAssigned + day.minutesAssigned <= maxDay + _epsilon;
    final previousSectionOk =
        previous.readings.isEmpty ||
        day.readings.isEmpty ||
        previous.readings.last.sectionId == day.readings.first.sectionId;
    if (previousFits && previousSectionOk) {
      days[index - 1] = previous.copyWith(
        readings: List.unmodifiable([...previous.readings, ...day.readings]),
      );
      days.removeAt(index);
      continue;
    }

    if (index < days.length - 1) {
      final next = days[index + 1];
      final nextFits =
          next.minutesAssigned + day.minutesAssigned <= maxDay + _epsilon;
      final nextSectionOk =
          day.readings.isEmpty ||
          next.readings.isEmpty ||
          day.readings.last.sectionId == next.readings.first.sectionId;
      if (nextFits && nextSectionOk) {
        days[index + 1] = next.copyWith(
          readings: List.unmodifiable([...day.readings, ...next.readings]),
        );
        days.removeAt(index);
        continue;
      }
    }

    // Whole-day merging is impossible (often because the next reading is one
    // huge indivisible chapter). Pull the previous day's last readings forward
    // until this day reaches the lower tolerance.
    var borrowed = false;
    while (days[index].minutesAssigned < minDay - _epsilon &&
        days[index - 1].readings.length > 1) {
      final previous = days[index - 1];
      final current = days[index];
      final piece = previous.readings.last;
      final sectionOk =
          current.readings.isEmpty ||
          previous.readings.last.sectionId == current.readings.first.sectionId;
      final currentFits =
          current.minutesAssigned + piece.minutes <= maxDay + _epsilon;
      final previousStaysUsable =
          previous.minutesAssigned - piece.minutes >= target * 0.5 - _epsilon;
      if (!sectionOk || !currentFits || !previousStaysUsable) break;

      days[index - 1] = previous.copyWith(
        readings: List.unmodifiable(
          previous.readings.sublist(0, previous.readings.length - 1),
        ),
      );
      days[index] = current.copyWith(
        readings: List.unmodifiable([piece, ...current.readings]),
      );
      borrowed = true;
    }

    if (!borrowed && index < days.length - 1) {
      while (days[index].minutesAssigned < minDay - _epsilon &&
          days[index + 1].readings.length > 1) {
        final current = days[index];
        final next = days[index + 1];
        final piece = next.readings.first;
        final sectionOk =
            current.readings.isEmpty ||
            next.readings.first.sectionId == current.readings.last.sectionId;
        final currentFits =
            current.minutesAssigned + piece.minutes <= maxDay + _epsilon;
        final nextStaysUsable =
            next.minutesAssigned - piece.minutes >= target * 0.5 - _epsilon;
        if (!sectionOk || !currentFits || !nextStaysUsable) break;

        days[index] = current.copyWith(
          readings: List.unmodifiable([...current.readings, piece]),
        );
        days[index + 1] = next.copyWith(
          readings: List.unmodifiable(next.readings.sublist(1)),
        );
        borrowed = true;
      }
    }

    if (borrowed) {
      index++;
      continue;
    }

    index++;
  }
}

/// Balances the final day against its predecessor: first move readings forward
/// when the final day is much heavier than the target, then pull readings back
/// when it is too light. Never crosses a section boundary.
void _smoothTail(
  List<ScheduledDay> days, {
  required double target,
  required PlanningPolicy policy,
}) {
  final minDay = target * policy.minDayFill;
  final maxDay = target * policy.maxDayFill;

  while (days.length >= 2) {
    final lastIndex = days.length - 1;
    final last = days[lastIndex];
    final previous = days[lastIndex - 1];

    if (last.minutesAssigned > target + _epsilon && last.readings.isNotEmpty) {
      final piece = last.readings.first;
      final sectionOk =
          previous.readings.isEmpty ||
          previous.readings.last.sectionId == piece.sectionId;
      final fits =
          previous.minutesAssigned + piece.minutes <= maxDay + _epsilon;
      final balances =
          previous.minutesAssigned + piece.minutes <
          last.minutesAssigned - _epsilon;
      if (sectionOk && fits && balances) {
        days[lastIndex - 1] = previous.copyWith(
          readings: List.unmodifiable([...previous.readings, piece]),
        );
        final remaining = last.readings.sublist(1);
        if (remaining.isEmpty) {
          days.removeLast();
        } else {
          days[lastIndex] = last.copyWith(
            readings: List.unmodifiable(remaining),
          );
        }
        continue;
      }
    }

    if (last.minutesAssigned < minDay - _epsilon) {
      if (previous.readings.isEmpty) {
        days.removeAt(lastIndex - 1);
        continue;
      }
      final piece = previous.readings.last;
      final sectionOk =
          last.readings.isEmpty ||
          last.readings.first.sectionId == piece.sectionId;
      final keepsPreviousFilled =
          previous.minutesAssigned - piece.minutes >= minDay - _epsilon;
      if (sectionOk && keepsPreviousFilled) {
        days[lastIndex - 1] = previous.copyWith(
          readings: List.unmodifiable(
            previous.readings.sublist(0, previous.readings.length - 1),
          ),
        );
        days[lastIndex] = last.copyWith(
          readings: List.unmodifiable([piece, ...last.readings]),
        );
        continue;
      }
    }

    break;
  }
}

/// Recovery options when the content does not fit the requested window.
List<RecoveryOption> _overflowSuggestions({
  required List<PlannedReading> pieces,
  required double totalMinutes,
  required int availableDays,
  required double cap,
  required int plannedDays,
}) {
  final extraDays = math.max(1, plannedDays - availableDays);
  final neededMinutes = totalMinutes - availableDays * cap;
  final raiseMinutes = neededMinutes <= 0
      ? 1
      : math.max(1, (neededMinutes / availableDays).ceil());

  final smallestFirst = [...pieces]
    ..sort((a, b) => a.minutes.compareTo(b.minutes));
  final trimIds = <String>[];
  var trimmedMinutes = 0.0;
  for (final piece in smallestFirst) {
    if (trimmedMinutes + _epsilon >= neededMinutes) break;
    trimIds.add(piece.id);
    trimmedMinutes += piece.minutes;
  }

  return [
    ExtendDeadlineOption(extraDays),
    RaiseDailyBudgetOption(raiseMinutes),
    TrimLowPriorityOption(List.unmodifiable(trimIds)),
  ];
}

List<DateTime> _readingDays({
  required DateTime startDate,
  required DateTime? endDate,
  required int? dayCount,
  required BlackoutCalendar blackouts,
}) {
  final start = dateOnly(startDate);
  final days = <DateTime>[];

  if (endDate != null) {
    final end = dateOnly(endDate);
    if (end.isBefore(start)) {
      throw const PlanningException('The end date is before the start date.');
    }
    var cursor = start;
    while (!cursor.isAfter(end)) {
      if (!blackouts.isBlackedOut(cursor)) days.add(cursor);
      cursor = nextDay(cursor);
    }
    return days;
  }

  if (blackouts.weekdays.length >= 7) {
    throw const PlanningException('Every weekday is blacked out.');
  }

  var cursor = start;
  var scanned = 0;
  while (days.length < dayCount!) {
    if (!blackouts.isBlackedOut(cursor)) days.add(cursor);
    cursor = nextDay(cursor);
    scanned++;
    if (scanned > 3660) {
      throw const PlanningException('No reading days are available.');
    }
  }
  return days;
}

List<PlannedReading> _chapterPieces({
  required PlanningChapter chapter,
  required double budget,
  required int readingSpeedWpm,
  required ReadingGoal goal,
  required PlanningPolicy policy,
  bool evenPacing = false,
}) {
  final factor = difficultyFactorFor(chapter.difficulty);
  double minutesFor(int wordCount) => wordCount / readingSpeedWpm * factor;

  final wholeWords = chapter.wordCount;
  final whole = _reading(
    chapter: chapter,
    paragraphStart: 0,
    paragraphEnd: chapter.paragraphs.length - 1,
    wordCount: wholeWords,
    minutes: minutesFor(wholeWords),
  );

  final thresholdFactor = evenPacing ? 0.6 : policy.splitFactorFor(goal);
  final threshold = budget * thresholdFactor;
  if (minutesFor(wholeWords) <= threshold + _epsilon) return [whole];

  // Prefer split points before sub-headings.
  final groups = <({int start, int end})>[];
  var groupStart = 0;
  for (var index = 1; index < chapter.paragraphs.length; index++) {
    if (chapter.paragraphs[index].isSubHeading) {
      groups.add((start: groupStart, end: index - 1));
      groupStart = index;
    }
  }
  groups.add((start: groupStart, end: chapter.paragraphs.length - 1));

  final pieces = <PlannedReading>[];
  final maxPiece = budget * policy.maxDayFill;
  for (final group in groups) {
    final groupWords = _wordsBetween(chapter, group.start, group.end);
    final groupMinutes = minutesFor(groupWords);
    final shouldSplit = evenPacing
        ? groupMinutes > threshold + _epsilon
        : groupMinutes > maxPiece + _epsilon ||
              groupMinutes > threshold + _epsilon;
    if (!shouldSplit) {
      pieces.add(
        _reading(
          chapter: chapter,
          paragraphStart: group.start,
          paragraphEnd: group.end,
          wordCount: groupWords,
          minutes: minutesFor(groupWords),
        ),
      );
    } else {
      pieces.addAll(
        _splitAtParagraphs(
          chapter: chapter,
          start: group.start,
          end: group.end,
          // Even pacing aims for two or more pieces per day, which lets the
          // balancer pack whole chapters without leaving tiny days.
          budget: evenPacing ? budget * 0.5 : budget,
          maxPiece: maxPiece,
          minutesFor: minutesFor,
        ),
      );
    }
  }
  return pieces;
}

/// Splits at paragraph boundaries nearest the target size; never inside one.
List<PlannedReading> _splitAtParagraphs({
  required PlanningChapter chapter,
  required int start,
  required int end,
  required double budget,
  required double maxPiece,
  required double Function(int wordCount) minutesFor,
}) {
  final pieces = <PlannedReading>[];
  final groupMinutes = minutesFor(_wordsBetween(chapter, start, end));
  final pieceCount = math.max(1, (groupMinutes / budget).ceil());
  final pieceTarget = groupMinutes / pieceCount;
  var pieceStart = start;
  var pieceMinutes = 0.0;

  for (var index = start; index <= end; index++) {
    final paragraphMinutes = minutesFor(chapter.paragraphs[index].wordCount);
    final addingBreaksTarget =
        pieceMinutes >= pieceTarget - _epsilon ||
        pieceMinutes + paragraphMinutes > maxPiece + _epsilon;

    if (index > pieceStart && addingBreaksTarget) {
      pieces.add(
        _reading(
          chapter: chapter,
          paragraphStart: pieceStart,
          paragraphEnd: index - 1,
          wordCount: _wordsBetween(chapter, pieceStart, index - 1),
          minutes: pieceMinutes,
        ),
      );
      pieceStart = index;
      pieceMinutes = 0;
    }
    pieceMinutes += paragraphMinutes;
  }

  pieces.add(
    _reading(
      chapter: chapter,
      paragraphStart: pieceStart,
      paragraphEnd: end,
      wordCount: _wordsBetween(chapter, pieceStart, end),
      minutes: minutesFor(_wordsBetween(chapter, pieceStart, end)),
    ),
  );
  return pieces;
}

PlannedReading _reading({
  required PlanningChapter chapter,
  required int paragraphStart,
  required int paragraphEnd,
  required int wordCount,
  required double minutes,
}) {
  return PlannedReading(
    id: '${chapter.id}:$paragraphStart-$paragraphEnd',
    chapterId: chapter.id,
    chapterTitle: chapter.title,
    sectionId: chapter.sectionId,
    paragraphStart: paragraphStart,
    paragraphEnd: paragraphEnd,
    wordCount: wordCount,
    minutes: minutes,
    isWholeChapter:
        paragraphStart == 0 && paragraphEnd == chapter.paragraphs.length - 1,
  );
}

int _wordsBetween(PlanningChapter chapter, int start, int end) {
  var total = 0;
  for (var index = start; index <= end; index++) {
    total += chapter.paragraphs[index].wordCount;
  }
  return total;
}
