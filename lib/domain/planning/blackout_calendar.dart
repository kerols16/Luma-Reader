/// Weekdays and specific dates on which no reading is scheduled.
///
/// [weekdays] uses `DateTime.monday` … `DateTime.sunday` (1–7).
class BlackoutCalendar {
  const BlackoutCalendar({this.weekdays = const {}, this.dates = const {}});

  final Set<int> weekdays;
  final Set<DateTime> dates;

  bool isBlackedOut(DateTime date) {
    if (weekdays.contains(date.weekday)) return true;
    return dates.any((blocked) => isSameDay(blocked, date));
  }
}

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime nextDay(DateTime date) =>
    DateTime(date.year, date.month, date.day + 1);
