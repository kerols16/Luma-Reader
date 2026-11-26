import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/l10n/gen/app_localizations.dart';
import 'package:luma/features/settings/notification_permission_page.dart';
import 'package:luma/services/notifications/notification_service.dart';
import 'package:luma/services/notifications/reminder_copy.dart';
import 'package:luma/services/notifications/reminder_manager.dart';

const _copy = ReminderCopy(title: 'Quiet title', body: 'Quiet body');

class _FakeReminderManager implements ReminderManager {
  _FakeReminderManager(this.requestResult);

  final NotificationPermissionStatus requestResult;
  int requestCalls = 0;
  int settingsCalls = 0;

  @override
  Future<NotificationPermissionStatus> permissionStatus() async =>
      NotificationPermissionStatus.notDetermined;

  @override
  Future<bool> remindersEnabled() async => false;

  @override
  Future<NotificationPermissionStatus> requestPermission({
    required ReminderCopy copy,
  }) async {
    requestCalls++;
    return requestResult;
  }

  @override
  Future<void> rescheduleUpcoming({
    required ReminderCopy copy,
    int hour = 20,
    int minute = 0,
  }) async {}

  @override
  Future<void> disable() async {}

  @override
  Future<void> openNotificationSettings() async {
    settingsCalls++;
  }

  @override
  Future<String?> takeLaunchPayload() async => null;

  @override
  Stream<String> get taps => const Stream.empty();
}

Future<void> _pumpPage(WidgetTester tester, ReminderManager manager) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: NotificationPermissionPage(manager: manager, copy: _copy),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('explains why before asking the operating system', (
    tester,
  ) async {
    final manager = _FakeReminderManager(NotificationPermissionStatus.granted);
    await _pumpPage(tester, manager);

    expect(find.text('A gentle daily nudge'), findsOneWidget);
    expect(find.textContaining('No streaks, no pressure'), findsOneWidget);
    expect(manager.requestCalls, 0);

    await tester.tap(find.text('Turn on reminders'));
    await tester.pumpAndSettle();

    expect(manager.requestCalls, 1);
  });

  testWidgets('shows a recovery path when permission is denied', (
    tester,
  ) async {
    final manager = _FakeReminderManager(NotificationPermissionStatus.denied);
    await _pumpPage(tester, manager);

    await tester.tap(find.text('Turn on reminders'));
    await tester.pumpAndSettle();

    expect(manager.requestCalls, 1);
    expect(find.textContaining('Notifications are off'), findsOneWidget);

    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();

    expect(manager.settingsCalls, 1);
  });
}
