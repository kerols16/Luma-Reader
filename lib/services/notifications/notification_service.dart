import 'package:luma/domain/notifications/reminder_window.dart';

/// Permission state for local notifications.
enum NotificationPermissionStatus { granted, denied, notDetermined }

/// A reminder ready to hand to the platform implementation.
class ReminderNotification {
  const ReminderNotification({
    required this.slot,
    required this.title,
    required this.body,
  });

  final ReminderSlot slot;
  final String title;
  final String body;
}

/// Local-notification boundary. Platform calls stay behind this interface.
abstract interface class NotificationService {
  /// Initialises the plugin and the device timezone. Safe to call repeatedly.
  Future<void> initialize();

  Future<NotificationPermissionStatus> permissionStatus();

  /// Asks the OS for permission. The friendly explanation is shown by the UI
  /// before this is called.
  Future<NotificationPermissionStatus> requestPermission();

  /// Replaces all pending reminders with [reminders].
  Future<void> scheduleReminders(List<ReminderNotification> reminders);

  Future<void> cancelReminders();

  Future<void> openNotificationSettings();

  /// Payload that launched the app from a notification, consumed once.
  Future<String?> takeLaunchPayload();

  /// Taps received while the app is running.
  Stream<String> get taps;

  Future<void> dispose();
}
