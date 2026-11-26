/// A reading day that may receive a reminder.
class ReminderDay {
  const ReminderDay({required this.date, required this.minutes});

  final DateTime date;
  final double minutes;
}

/// One local notification that should be scheduled.
class ReminderSlot {
  const ReminderSlot({
    required this.id,
    required this.scheduledAt,
    required this.minutes,
  });

  /// Stable notification id, derived from the calendar date.
  final int id;

  /// Local date and time the reminder should be shown.
  final DateTime scheduledAt;

  final double minutes;

  @override
  bool operator ==(Object other) =>
      other is ReminderSlot &&
      other.id == id &&
      other.scheduledAt == scheduledAt &&
      other.minutes == minutes;

  @override
  int get hashCode => Object.hash(id, scheduledAt, minutes);
}

/// Rolling window size. Kept well below the 64 pending-notification limit on
/// iOS and short enough to be refreshed on every app open.
const int reminderWindowDays = 14;

/// A calm evening default; the time is intentionally not tied to a deadline.
const int defaultReminderHour = 20;
const int defaultReminderMinute = 0;

/// Payload delivered when a reminder is tapped. The app maps this to Today.
const String todayReminderPayload = 'luma://today';

/// Stable Android/iOS notification id for [date].
int reminderIdForDate(DateTime date) =>
    date.year * 10000 + date.month * 100 + date.day;

/// Builds the next [windowDays] reminders from reading days.
///
/// Rules:
/// - Only reading days with a positive minute budget are included.
/// - Today is included only if [hour]:[minute] is still in the future.
/// - The window covers today plus the following [windowDays] - 1 days.
/// - Days without reading are skipped, so blackout days produce no reminder.
/// - Ids are stable per calendar date and unique inside the window.
List<ReminderSlot> buildReminderWindow({
  required Iterable<ReminderDay> readingDays,
  required DateTime now,
  int hour = defaultReminderHour,
  int minute = defaultReminderMinute,
  int windowDays = reminderWindowDays,
}) {
  assert(hour >= 0 && hour < 24, 'hour must be a valid local hour');
  assert(minute >= 0 && minute < 60, 'minute must be a valid local minute');
  if (windowDays <= 0) return const [];

  final byDate = <int, ReminderDay>{};
  for (final day in readingDays) {
    if (!day.minutes.isFinite || day.minutes <= 0) continue;
    byDate.putIfAbsent(_dateKey(day.date), () => day);
  }
  if (byDate.isEmpty) return const [];

  final start = DateTime(now.year, now.month, now.day);
  final slots = <ReminderSlot>[];
  for (var offset = 0; offset < windowDays; offset++) {
    final calendarDate = DateTime(start.year, start.month, start.day + offset);
    final day = byDate[_dateKey(calendarDate)];
    if (day == null) continue;

    final scheduledAt = DateTime(
      calendarDate.year,
      calendarDate.month,
      calendarDate.day,
      hour,
      minute,
    );
    if (!scheduledAt.isAfter(now)) continue;

    slots.add(
      ReminderSlot(
        id: reminderIdForDate(calendarDate),
        scheduledAt: scheduledAt,
        minutes: day.minutes,
      ),
    );
  }
  return List.unmodifiable(slots);
}

int _dateKey(DateTime date) => date.year * 10000 + date.month * 100 + date.day;
