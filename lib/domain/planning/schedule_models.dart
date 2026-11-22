import 'package:luma/domain/planning/blackout_calendar.dart';
import 'package:luma/domain/planning/planning_policy.dart';
import 'package:luma/domain/planning/recovery_options.dart';

/// A read portion of a chapter, produced by splitting where needed.
class PlannedReading {
  const PlannedReading({
    required this.id,
    required this.chapterId,
    required this.chapterTitle,
    required this.sectionId,
    required this.paragraphStart,
    required this.paragraphEnd,
    required this.wordCount,
    required this.minutes,
    required this.isWholeChapter,
  });

  final String id;
  final String chapterId;
  final String chapterTitle;
  final String sectionId;

  /// Inclusive paragraph range within the source chapter.
  final int paragraphStart;
  final int paragraphEnd;
  final int wordCount;
  final double minutes;
  final bool isWholeChapter;

  @override
  bool operator ==(Object other) =>
      other is PlannedReading &&
      other.id == id &&
      other.chapterId == chapterId &&
      other.chapterTitle == chapterTitle &&
      other.sectionId == sectionId &&
      other.paragraphStart == paragraphStart &&
      other.paragraphEnd == paragraphEnd &&
      other.wordCount == wordCount &&
      other.minutes == minutes &&
      other.isWholeChapter == isWholeChapter;

  @override
  int get hashCode => Object.hash(
    id,
    chapterId,
    chapterTitle,
    sectionId,
    paragraphStart,
    paragraphEnd,
    wordCount,
    minutes,
    isWholeChapter,
  );
}

/// One scheduled reading day.
class ScheduledDay {
  const ScheduledDay({
    required this.date,
    required this.minutesBudget,
    required this.readings,
  });

  final DateTime date;
  final double minutesBudget;
  final List<PlannedReading> readings;

  double get minutesAssigned =>
      readings.fold(0.0, (total, reading) => total + reading.minutes);

  /// UI-facing "minutes done / minutes budget" for the day.
  DayReadingProgress progress({required double minutesDone}) =>
      DayReadingProgress(
        minutesDone: minutesDone,
        minutesBudget: minutesBudget,
      );

  /// Progress computed from completed reading ids.
  DayReadingProgress progressFor(Set<String> completedReadingIds) {
    final done = readings
        .where((reading) => completedReadingIds.contains(reading.id))
        .fold(0.0, (total, reading) => total + reading.minutes);
    return progress(minutesDone: done);
  }

  ScheduledDay copyWith({List<PlannedReading>? readings}) => ScheduledDay(
    date: date,
    minutesBudget: minutesBudget,
    readings: readings ?? this.readings,
  );

  bool get isReadingDay => readings.isNotEmpty;

  bool isOn(DateTime date) => isSameDay(this.date, date);
}

/// "minutes done / minutes budget" for one day.
class DayReadingProgress {
  const DayReadingProgress({
    required this.minutesDone,
    required this.minutesBudget,
  });

  final double minutesDone;
  final double minutesBudget;

  double get ratio {
    if (minutesBudget <= 0) return 0;
    return (minutesDone / minutesBudget).clamp(0.0, 1.0);
  }

  bool get isDone => minutesDone + 1e-9 >= minutesBudget;

  bool get isOverBudget => minutesDone > minutesBudget + 1e-9;

  double get remainingMinutes {
    final remaining = minutesBudget - minutesDone;
    return remaining < 0 ? 0 : remaining;
  }
}

/// The full schedule produced by [planDays].
class PlanSchedule {
  const PlanSchedule({
    required this.days,
    this.requestedDayCount,
    this.extendsDeadline = false,
    this.dailyTarget,
    this.pacingMode = PacingMode.even,
    this.suggestions = const [],
  });

  final List<ScheduledDay> days;

  /// Reading days originally available inside the requested window.
  final int? requestedDayCount;

  /// True when the content did not fit and extra days were added.
  final bool extendsDeadline;

  /// Minutes aimed for per day. In even mode this can be below the cap.
  final double? dailyTarget;

  final PacingMode pacingMode;

  /// Recovery options when a deadline cannot be met. Empty otherwise.
  final List<RecoveryOption> suggestions;

  bool get hasDeadline => requestedDayCount != null;

  DateTime? get projectedFinishDate => days.isEmpty ? null : days.last.date;

  int get totalDays => days.length;

  /// The target used for tolerance checks, falling back to the first day.
  double get effectiveDailyTarget {
    if (dailyTarget != null) return dailyTarget!;
    if (days.isEmpty) return 0;
    return days.first.minutesBudget;
  }

  bool get isEmpty => days.isEmpty;

  List<ScheduledDay> get readingDays =>
      days.where((day) => day.isReadingDay).toList(growable: false);

  double get totalMinutesAssigned =>
      days.fold(0.0, (total, day) => total + day.minutesAssigned);

  /// The day matching [date], if the plan covers it.
  ScheduledDay? dayFor(DateTime date) {
    for (final day in days) {
      if (day.isOn(date)) return day;
    }
    return null;
  }
}
