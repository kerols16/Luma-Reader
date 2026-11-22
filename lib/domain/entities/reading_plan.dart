/// Why the user is reading. Shapes how aggressively units are split.
enum ReadingGoal { read, understand, review }

class ReadingPlan {
  const ReadingPlan({
    required this.id,
    required this.bookId,
    required this.startDate,
    required this.endDate,
    required this.minutesPerDay,
    required this.goal,
    required this.readingSpeedWpm,
  });

  final int id;
  final int bookId;
  final DateTime startDate;
  final DateTime endDate;
  final int minutesPerDay;
  final ReadingGoal goal;

  /// Words per minute used to estimate unit duration.
  final int readingSpeedWpm;

  @override
  bool operator ==(Object other) =>
      other is ReadingPlan &&
      other.id == id &&
      other.bookId == bookId &&
      other.startDate == startDate &&
      other.endDate == endDate &&
      other.minutesPerDay == minutesPerDay &&
      other.goal == goal &&
      other.readingSpeedWpm == readingSpeedWpm;

  @override
  int get hashCode => Object.hash(
    id,
    bookId,
    startDate,
    endDate,
    minutesPerDay,
    goal,
    readingSpeedWpm,
  );
}
