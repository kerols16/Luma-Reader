import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:luma/domain/notifications/reminder_window.dart';

import 'notification_service.dart';

/// `flutter_local_notifications` implementation of [NotificationService].
class LocalNotificationService implements NotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'daily_reading';
  static const _notificationIcon = 'ic_stat_luma';

  final FlutterLocalNotificationsPlugin _plugin;
  final _tapController = StreamController<String>.broadcast();

  bool _initialized = false;
  String? _launchPayload;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    final deviceZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(deviceZone.identifier));

    const settings = InitializationSettings(
      android: AndroidInitializationSettings(_notificationIcon),
      iOS: IOSInitializationSettings(
        requestAlertPermission: false,
        requestSoundPermission: false,
        requestBadgePermission: false,
        defaultPresentBadge: false,
      ),
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _handleResponse,
    );

    final launch = await _plugin.getNotificationAppLaunchDetails();
    final payload = launch?.notificationResponse?.payload;
    if ((launch?.didNotificationLaunchApp ?? false) &&
        payload != null &&
        payload.isNotEmpty) {
      _launchPayload = payload;
    }
    _initialized = true;
  }

  @override
  Future<NotificationPermissionStatus> permissionStatus() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final enabled = await _android?.areNotificationsEnabled();
      return enabled == true
          ? NotificationPermissionStatus.granted
          : NotificationPermissionStatus.notDetermined;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final options = await _ios?.checkPermissions();
      return options?.isEnabled == true
          ? NotificationPermissionStatus.granted
          : NotificationPermissionStatus.notDetermined;
    }
    return NotificationPermissionStatus.notDetermined;
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final granted = await _android?.requestNotificationsPermission();
      return granted == true
          ? NotificationPermissionStatus.granted
          : NotificationPermissionStatus.denied;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final granted = await _ios?.requestPermissions(
        alert: true,
        sound: true,
        badge: false,
      );
      return granted == true
          ? NotificationPermissionStatus.granted
          : NotificationPermissionStatus.denied;
    }
    return NotificationPermissionStatus.notDetermined;
  }

  @override
  Future<void> scheduleReminders(List<ReminderNotification> reminders) async {
    await initialize();
    await _plugin.cancelAllPendingNotifications();
    for (final reminder in reminders) {
      final at = reminder.slot.scheduledAt;
      await _plugin.zonedSchedule(
        id: reminder.slot.id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: tz.TZDateTime(
          tz.local,
          at.year,
          at.month,
          at.day,
          at.hour,
          at.minute,
        ),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            reminder.title,
            channelDescription: reminder.body,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: const DarwinNotificationDetails(presentBadge: false),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: todayReminderPayload,
      );
    }
  }

  @override
  Future<void> cancelReminders() async {
    await initialize();
    await _plugin.cancelAllPendingNotifications();
  }

  @override
  Future<void> openNotificationSettings() async {
    await _plugin.openAppNotificationSettings();
  }

  @override
  Future<String?> takeLaunchPayload() async {
    final payload = _launchPayload;
    _launchPayload = null;
    return payload;
  }

  @override
  Stream<String> get taps => _tapController.stream;

  @override
  Future<void> dispose() => _tapController.close();

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  void _handleResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    _tapController.add(payload);
  }
}
