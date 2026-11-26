import 'package:luma/domain/entities/plan_day.dart';
import 'package:luma/domain/notifications/reminder_window.dart';

import 'notification_service.dart';
import 'reminder_copy.dart';
import 'reminder_manager.dart';
import 'reminder_preference_store.dart';

/// Loads pending plan days for an inclusive date range.
typedef PendingDaysLoader =
    Future<List<PlanDay>> Function(
      DateTime startInclusive,
      DateTime endInclusive,
    );

/// Keeps the rolling notification window in sync with plan days.
///
/// Platform calls are delegated to [NotificationService]. The loader lets the
/// app open path read plan days from drift without coupling this class to the
/// database.
class NotificationCoordinator implements ReminderManager {
  factory NotificationCoordinator({
    required NotificationService service,
    required PendingDaysLoader loadPendingDays,
    required ReminderPreferenceStore preferences,
    DateTime Function()? now,
  }) => NotificationCoordinator._(
    service,
    loadPendingDays,
    preferences,
    now ?? DateTime.now,
  );

  NotificationCoordinator._(
    this._service,
    this._loadPendingDays,
    this._preferences,
    this._now,
  );

  final NotificationService _service;
  final PendingDaysLoader _loadPendingDays;
  final ReminderPreferenceStore _preferences;
  final DateTime Function() _now;

  @override
  Future<NotificationPermissionStatus> permissionStatus() =>
      _service.permissionStatus();

  @override
  Future<bool> remindersEnabled() async {
    if (!await _preferences.loadEnabled()) return false;
    return await _service.permissionStatus() ==
        NotificationPermissionStatus.granted;
  }

  @override
  Future<NotificationPermissionStatus> requestPermission({
    required ReminderCopy copy,
  }) async {
    final status = await _service.requestPermission();
    if (status == NotificationPermissionStatus.granted) {
      try {
        await _preferences.saveEnabled(true);
      } on Exception {
        // Scheduling still works for this session if persistence fails.
      }
      await rescheduleUpcoming(copy: copy);
    } else {
      try {
        await _preferences.saveEnabled(false);
      } on Exception {
        // Ignore storage failures while turning reminders off.
      }
      await _service.cancelReminders();
    }
    return status;
  }

  @override
  Future<void> rescheduleUpcoming({
    required ReminderCopy copy,
    int hour = defaultReminderHour,
    int minute = defaultReminderMinute,
  }) async {
    if (!await _preferences.loadEnabled()) {
      await _service.cancelReminders();
      return;
    }
    final status = await _service.permissionStatus();
    if (status != NotificationPermissionStatus.granted) {
      await _service.cancelReminders();
      return;
    }

    final now = _now();
    final firstDay = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(
      firstDay.year,
      firstDay.month,
      firstDay.day + reminderWindowDays - 1,
    );
    final days = await _loadPendingDays(firstDay, lastDay);
    final slots = buildReminderWindow(
      readingDays: [
        for (final day in days)
          ReminderDay(date: day.date, minutes: day.minutesBudget.toDouble()),
      ],
      now: now,
      hour: hour,
      minute: minute,
    );

    await _service.scheduleReminders([
      for (final slot in slots)
        ReminderNotification(slot: slot, title: copy.title, body: copy.body),
    ]);
  }

  @override
  Future<void> disable() async {
    try {
      await _preferences.saveEnabled(false);
    } on Exception {
      // Still cancel now; the next open may retry the preference write.
    }
    await _service.cancelReminders();
  }

  @override
  Future<void> openNotificationSettings() =>
      _service.openNotificationSettings();

  @override
  Future<String?> takeLaunchPayload() => _service.takeLaunchPayload();

  @override
  Stream<String> get taps => _service.taps;
}
