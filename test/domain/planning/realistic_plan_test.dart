import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:luma/domain/entities/book.dart';
import 'package:luma/domain/entities/reading_plan.dart';
import 'package:luma/domain/planning/planning.dart';

import 'planning_test_helpers.dart';

/// A deliberately uneven 24-chapter Arabic book: two tiny chapters in a row,
/// several mid-size chapters, one 12k chapter, and one 20k chapter.
List<PlanningChapter> _arabicBook() {
  const sizes = [
    2200, 2600, 3400, 2800, 2000, 3800, 3100, 2400, //
    500, 700, 12000, 2900, 3300, 2100, 2300, 2500, //
    3600, 2200, 3500, 2700, 2500, 3000, 3900, 20000, //
  ];

  return [
    for (var chapterIndex = 0; chapterIndex < sizes.length; chapterIndex++)
      () {
        final chapterNumber = chapterIndex + 1;
        final totalWords = sizes[chapterIndex];
        final paragraphCount = chapterIndex == sizes.length - 1 ? 16 : 10;
        final base = totalWords ~/ paragraphCount;

        return PlanningChapter(
          id: 'ch$chapterNumber',
          title: 'Ch $chapterNumber',
          sectionId: 'book',
          difficulty: 1,
          paragraphs: [
            for (var index = 0; index < paragraphCount; index++)
              PlanningParagraph(
                words(
                  index == paragraphCount - 1
                      ? totalWords - base * (paragraphCount - 1)
                      : base,
                ),
                // The 20k chapter has sub-headings of its own.
                isSubHeading:
                    chapterIndex == sizes.length - 1 &&
                    index % 4 == 0 &&
                    index > 0,
              ),
          ],
        );
      }(),
  ];
}

String _chaptersLabel(ScheduledDay day) {
  final labels = <String>[];
  for (final reading in day.readings) {
    if (!labels.contains(reading.chapterTitle)) {
      labels.add(reading.chapterTitle);
    }
  }
  return labels.join(', ');
}

void _printPlan(String label, PlanSchedule schedule) {
  final minutes = schedule.days.map((day) => day.minutesAssigned).toList();
  final minMinutes = minutes.reduce((a, b) => a < b ? a : b);
  final maxMinutes = minutes.reduce((a, b) => a > b ? a : b);
  final average = minutes.reduce((a, b) => a + b) / minutes.length;

  stdout.writeln(
    '\n$label — target ${schedule.effectiveDailyTarget.toStringAsFixed(1)} '
    'min/day, ${schedule.totalDays} days, finish '
    '${schedule.projectedFinishDate!.toIso8601String().substring(0, 10)}',
  );
  stdout.writeln('Day | Chapters | Minutes');
  stdout.writeln('----|----------|--------');
  for (var index = 0; index < schedule.days.length; index++) {
    final day = schedule.days[index];
    stdout.writeln(
      '${index + 1} | ${_chaptersLabel(day)} | '
      '${day.minutesAssigned.toStringAsFixed(1)}',
    );
  }
  stdout.writeln(
    'min ${minMinutes.toStringAsFixed(1)} | '
    'max ${maxMinutes.toStringAsFixed(1)} | '
    'avg ${average.toStringAsFixed(1)}',
  );
}

void _expectBalanced(PlanSchedule schedule) {
  final target = schedule.effectiveDailyTarget;
  for (var index = 0; index < schedule.days.length; index++) {
    final day = schedule.days[index];
    final isFinal = index == schedule.days.length - 1;
    if (!isFinal) {
      expect(
        day.minutesAssigned,
        greaterThanOrEqualTo(target * 0.5 - 1e-9),
        reason: 'Day ${index + 1} is far below its target',
      );
    }
    if (day.minutesAssigned > target * 1.3 + 1e-9) {
      // Allowed only when a single indivisible reading is already over target.
      expect(
        day.readings.any((reading) => reading.minutes > target * 1.3 + 1e-9),
        isTrue,
        reason:
            'Day ${index + 1} exceeds 1.3x target without an indivisible '
            'reading',
      );
    }
  }
}

void main() {
  test('uneven Arabic book: no deadline, even deadline, fastest deadline', () {
    final chapters = _arabicBook();
    final totalWords = chapters.fold(
      0,
      (total, chapter) => total + chapter.wordCount,
    );
    expect(totalWords, 90000);
    expect(chapters, hasLength(24));
    expect(
      chapters.where((chapter) => chapter.wordCount == 20000),
      hasLength(1),
    );
    // The two smallest chapters are consecutive.
    expect(chapters[8].wordCount, 500);
    expect(chapters[9].wordCount, 700);

    final wpm = ReadingSpeedDefaults.forLanguage(BookLanguage.ar);
    expect(wpm, 150);

    final noDeadline = planDays(
      chapters: chapters,
      startDate: DateTime(2026, 11, 22),
      minutesPerDay: 60,
      readingSpeedWpm: wpm,
      goal: ReadingGoal.understand,
    );
    final even = planDays(
      chapters: chapters,
      startDate: DateTime(2026, 11, 22),
      dayCount: 30,
      minutesPerDay: 60,
      readingSpeedWpm: wpm,
      goal: ReadingGoal.understand,
    );
    final fastest = planDays(
      chapters: chapters,
      startDate: DateTime(2026, 11, 22),
      dayCount: 30,
      minutesPerDay: 60,
      readingSpeedWpm: wpm,
      goal: ReadingGoal.understand,
      pacing: PacingMode.fastest,
    );

    _printPlan('No deadline (60 min/day)', noDeadline);
    _printPlan('30-day deadline, even pacing', even);
    _printPlan('30-day deadline, fastest pacing', fastest);

    for (final schedule in [noDeadline, even, fastest]) {
      expect(
        schedule.days
            .expand((day) => day.readings)
            .fold(0, (total, reading) => total + reading.wordCount),
        90000,
      );
      expect(schedule.extendsDeadline, isFalse);
      _expectBalanced(schedule);
    }

    expect(noDeadline.hasDeadline, isFalse);
    expect(noDeadline.dailyTarget, 60);
    expect(even.hasDeadline, isTrue);
    expect(even.dailyTarget, closeTo(20, 1e-9));
    expect(even.requestedDayCount, 30);
    expect(fastest.dailyTarget, 60);
  });
}
