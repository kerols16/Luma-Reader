import 'package:flutter_test/flutter_test.dart';
import 'package:luma/domain/notifications/reminder_window.dart';

ReminderDay _day(DateTime date, [double minutes = 30]) =>
    ReminderDay(date: date, minutes: minutes);

void main() {
  group('buildReminderWindow', () {
    test('includes today when the reminder time is still ahead', () {
      final now = DateTime(2026, 11, 23, 9);
      final slots = buildReminderWindow(
        readingDays: [_day(DateTime(2026, 11, 23))],
        now: now,
      );

      expect(slots, hasLength(1));
      expect(slots.single.scheduledAt, DateTime(2026, 11, 23, 20));
      expect(slots.single.minutes, 30);
    });

    test('skips today when the reminder time has already passed', () {
      final now = DateTime(2026, 11, 23, 21);
      final slots = buildReminderWindow(
        readingDays: [
          _day(DateTime(2026, 11, 23)),
          _day(DateTime(2026, 11, 24)),
        ],
        now: now,
      );

      expect(slots, hasLength(1));
      expect(slots.single.scheduledAt, DateTime(2026, 11, 24, 20));
    });

    test('covers exactly fourteen calendar days including today', () {
      final now = DateTime(2026, 11, 23, 9);
      final slots = buildReminderWindow(
        readingDays: [
          for (var offset = 0; offset < 20; offset++)
            _day(DateTime(2026, 11, 23 + offset)),
        ],
        now: now,
      );

      expect(slots, hasLength(reminderWindowDays));
      expect(slots.first.scheduledAt, DateTime(2026, 11, 23, 20));
      expect(slots.last.scheduledAt, DateTime(2026, 12, 6, 20));
      expect(
        slots.map((slot) => slot.scheduledAt),
        isNot(contains(DateTime(2026, 12, 7, 20))),
      );
    });

    test('keeps only reading days and ignores zero-minute days', () {
      final now = DateTime(2026, 11, 23, 9);
      final slots = buildReminderWindow(
        readingDays: [
          _day(DateTime(2026, 11, 23)),
          _day(DateTime(2026, 11, 24), 0),
          _day(DateTime(2026, 11, 26)),
        ],
        now: now,
      );

      expect(slots.map((slot) => slot.scheduledAt), [
        DateTime(2026, 11, 23, 20),
        DateTime(2026, 11, 26, 20),
      ]);
    });

    test('returns an empty window when there are no reading days', () {
      expect(
        buildReminderWindow(readingDays: const [], now: DateTime(2026, 11, 23)),
        isEmpty,
      );
    });

    test('returns an empty window for a non-positive window size', () {
      expect(
        buildReminderWindow(
          readingDays: [_day(DateTime(2026, 11, 23))],
          now: DateTime(2026, 11, 23, 9),
          windowDays: 0,
        ),
        isEmpty,
      );
    });

    test('uses stable, unique ids and sorts unsorted input by date', () {
      final now = DateTime(2026, 12, 31, 9);
      final slots = buildReminderWindow(
        readingDays: [
          _day(DateTime(2027, 1, 2)),
          _day(DateTime(2026, 12, 31)),
          _day(DateTime(2027, 1, 1)),
        ],
        now: now,
      );

      expect(slots.map((slot) => slot.scheduledAt), [
        DateTime(2026, 12, 31, 20),
        DateTime(2027, 1, 1, 20),
        DateTime(2027, 1, 2, 20),
      ]);
      expect(slots.map((slot) => slot.id).toSet(), hasLength(3));
      expect(slots.first.id, reminderIdForDate(DateTime(2026, 12, 31)));
      expect(slots.last.id, reminderIdForDate(DateTime(2027, 1, 2)));
    });

    test('honours a custom reminder time and skips an exactly-now slot', () {
      final now = DateTime(2026, 11, 23, 7, 30);
      final slots = buildReminderWindow(
        readingDays: [_day(DateTime(2026, 11, 23))],
        now: now,
        hour: 7,
        minute: 30,
      );

      expect(slots, isEmpty);
    });
  });
}
