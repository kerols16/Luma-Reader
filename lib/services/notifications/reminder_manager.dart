import 'package:luma/domain/notifications/reminder_window.dart';

import 'notification_service.dart';
import 'reminder_copy.dart';

/// App-facing reminder boundary used by settings and the notification tap
/// handler.
abstract interface class ReminderManager {
  Future<NotificationPermissionStatus> permissionStatus();

  /// True only when the user turned reminders on and the OS still allows them.
  Future<bool> remindersEnabled();

  Future<NotificationPermissionStatus> requestPermission({
    required ReminderCopy copy,
  });

  /// Rebuilds the rolling window from the current plan days.
  Future<void> rescheduleUpcoming({
    required ReminderCopy copy,
    int hour = defaultReminderHour,
    int minute = defaultReminderMinute,
  });

  Future<void> disable();

  Future<void> openNotificationSettings();

  Future<String?> takeLaunchPayload();

  Stream<String> get taps;
}
