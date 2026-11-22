import 'package:luma/domain/entities/book.dart';
import 'package:luma/domain/entities/reading_plan.dart';

/// Placeholder reading speeds until real usage calibrates them.
abstract final class ReadingSpeedDefaults {
  static const arabicWpm = 150;
  static const englishWpm = 220;

  static int forLanguage(BookLanguage language) => switch (language) {
    BookLanguage.ar => arabicWpm,
    BookLanguage.en => englishWpm,
  };
}

/// Multipliers from the planning brief.
double difficultyFactorFor(int difficulty) {
  if (difficulty <= 1) return 1.0;
  if (difficulty == 2) return 1.2;
  return 1.5;
}

/// How a deadline is paced.
enum PacingMode {
  /// Spread the content across the available days at a steady daily target.
  even,

  /// Read as fast as the daily budget allows and finish as early as possible.
  fastest,
}

/// Tunable packing rules. Kept explicit so the brief can evolve in one place.
class PlanningPolicy {
  const PlanningPolicy({
    this.minDayFill = 0.7,
    this.maxDayFill = 1.3,
    this.chapterSplitFactor = 1.5,
    this.novelChapterSplitFactor = 1.25,
    this.catchUpLimitFactor = 1.5,
  });

  /// Days should aim for at least this share of the budget.
  final double minDayFill;

  /// Never pack more than this share of the budget into one day.
  final double maxDayFill;

  /// Chapters above this share of the budget are split (general).
  final double chapterSplitFactor;

  /// Novels (goal = read) keep chapters whole up to this share.
  final double novelChapterSplitFactor;

  /// The next day after one missed day may go up to this share.
  final double catchUpLimitFactor;

  double splitFactorFor(ReadingGoal goal) =>
      goal == ReadingGoal.read ? novelChapterSplitFactor : chapterSplitFactor;
}

/// A planning rule was violated: no reading days, no content, no next day.
class PlanningException implements Exception {
  const PlanningException(this.message);

  final String message;

  @override
  String toString() => 'PlanningException: $message';
}
