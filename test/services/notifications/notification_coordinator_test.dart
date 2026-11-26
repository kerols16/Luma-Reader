import 'package:flutter_test/flutter_test.dart';
import 'package:luma/domain/entities/plan_day.dart';
import 'package:luma/services/notifications/notification_coordinator.dart';
import 'package:luma/services/notifications/notification_service.dart';
import 'package:luma/services/notifications/reminder_copy.dart';
import 'package:luma/services/notifications/reminder_preference_store.dart';

const _copy = ReminderCopy(title: 'Quiet title', body: 'Quiet body');

PlanDay _day(DateTime date, {int minutes = 30}) => PlanDay(
  id: date.day,
  planId: 1,
  date: date,
  status: PlanDayStatus.pending,
  minutesBudget: minutes,
);

class _FakePreferences implements ReminderPreferenceStore {
  _FakePreferences([this.enabled = true]);

  bool enabled;

  @override
  Future<bool> loadEnabled() async => enabled;

  @override
  Future<void> saveEnabled(bool enabled) async {
    this.enabled = enabled;
  }
}

class _FakeNotificationService implements NotificationService {
  _FakeNotificationService({
    this.status = NotificationPermissionStatus.granted,
    this.requestResult = NotificationPermissionStatus.granted,
  });

  NotificationPermissionStatus status;
  NotificationPermissionStatus requestResult;

  int requestCalls = 0;
  int cancelCalls = 0;
  List<ReminderNotification>? scheduled;
  String? launchPayload;

  @override
  Future<void> initialize() async {}

  @override
  Future<NotificationPermissionStatus> permissionStatus() async => status;

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    requestCalls++;
    status = requestResult;
    return requestResult;
  }

  @override
  Future<void> scheduleReminders(List<ReminderNotification> reminders) async {
    scheduled = List.of(reminders);
  }

  @override
  Future<void> cancelReminders() async {
    cancelCalls++;
    scheduled = null;
  }

  @override
  Future<void> openNotificationSettings() async {}

  @override
  Future<String?> takeLaunchPayload() async {
    final payload = launchPayload;
    launchPayload = null;
    return payload;
  }

  @override
  Stream<String> get taps => const Stream.empty();

  @override
  Future<void> dispose() async {}
}

void main() {
  final now = DateTime(2026, 11, 23, 9);

  test('schedules the 14-day window when permission is granted', () async {
    final service = _FakeNotificationService();
    DateTime? requestedStart;
    DateTime? requestedEnd;
    final coordinator = NotificationCoordinator(
      service: service,
      preferences: _FakePreferences(),
      now: () => now,
      loadPendingDays: (start, end) async {
        requestedStart = start;
        requestedEnd = end;
        return [
          _day(DateTime(2026, 11, 23)),
          _day(DateTime(2026, 11, 25), minutes: 45),
        ];
      },
    );

    await coordinator.rescheduleUpcoming(copy: _copy);

    expect(requestedStart, DateTime(2026, 11, 23));
    expect(requestedEnd, DateTime(2026, 12, 6));
    expect(service.scheduled, hasLength(2));
    expect(service.scheduled!.first.title, 'Quiet title');
    expect(service.scheduled!.first.body, 'Quiet body');
    expect(service.scheduled!.map((reminder) => reminder.slot.scheduledAt), [
      DateTime(2026, 11, 23, 20),
      DateTime(2026, 11, 25, 20),
    ]);
  });

  test('cancels without reading plan days when permission is off', () async {
    final service = _FakeNotificationService(
      status: NotificationPermissionStatus.notDetermined,
    );
    var loaderCalls = 0;
    final coordinator = NotificationCoordinator(
      service: service,
      preferences: _FakePreferences(),
      now: () => now,
      loadPendingDays: (start, end) async {
        loaderCalls++;
        return [];
      },
    );

    await coordinator.rescheduleUpcoming(copy: _copy);

    expect(loaderCalls, 0);
    expect(service.cancelCalls, 1);
    expect(service.scheduled, isNull);
  });

  test('requests permission, then schedules when granted', () async {
    final service = _FakeNotificationService(
      status: NotificationPermissionStatus.notDetermined,
      requestResult: NotificationPermissionStatus.granted,
    );
    final coordinator = NotificationCoordinator(
      service: service,
      preferences: _FakePreferences(),
      now: () => now,
      loadPendingDays: (start, end) async => [_day(DateTime(2026, 11, 23))],
    );

    final result = await coordinator.requestPermission(copy: _copy);

    expect(result, NotificationPermissionStatus.granted);
    expect(service.requestCalls, 1);
    expect(service.scheduled, hasLength(1));
  });

  test('does not schedule when permission is denied', () async {
    final service = _FakeNotificationService(
      status: NotificationPermissionStatus.notDetermined,
      requestResult: NotificationPermissionStatus.denied,
    );
    var loaderCalls = 0;
    final coordinator = NotificationCoordinator(
      service: service,
      preferences: _FakePreferences(),
      now: () => now,
      loadPendingDays: (start, end) async {
        loaderCalls++;
        return [];
      },
    );

    final result = await coordinator.requestPermission(copy: _copy);

    expect(result, NotificationPermissionStatus.denied);
    expect(loaderCalls, 0);
    expect(service.cancelCalls, 1);
    expect(service.scheduled, isNull);
  });

  test('disable cancels pending reminders', () async {
    final service = _FakeNotificationService();
    final preferences = _FakePreferences();
    final coordinator = NotificationCoordinator(
      service: service,
      preferences: preferences,
      loadPendingDays: (start, end) async => [],
    );

    await coordinator.disable();

    expect(preferences.enabled, isFalse);
    expect(service.cancelCalls, 1);
  });

  test('user preference off prevents rescheduling on app open', () async {
    final service = _FakeNotificationService();
    var loaderCalls = 0;
    final coordinator = NotificationCoordinator(
      service: service,
      preferences: _FakePreferences(false),
      now: () => now,
      loadPendingDays: (start, end) async {
        loaderCalls++;
        return [_day(DateTime(2026, 11, 23))];
      },
    );

    await coordinator.rescheduleUpcoming(copy: _copy);

    expect(loaderCalls, 0);
    expect(service.cancelCalls, 1);
    expect(service.scheduled, isNull);
  });
}
