import 'package:flutter/material.dart';
import 'package:luma/core/l10n/gen/app_localizations.dart';
import 'package:luma/services/notifications/notification_service.dart';
import 'package:luma/services/notifications/reminder_copy.dart';
import 'package:luma/services/notifications/reminder_manager.dart';

/// Friendly explanation shown before the operating system permission prompt.
class NotificationPermissionPage extends StatefulWidget {
  const NotificationPermissionPage({
    super.key,
    required this.manager,
    required this.copy,
  });

  final ReminderManager manager;
  final ReminderCopy copy;

  /// Opens the page and returns whether reminders ended up enabled.
  static Future<bool> show(
    BuildContext context, {
    required ReminderManager manager,
    required ReminderCopy copy,
  }) async {
    final enabled = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            NotificationPermissionPage(manager: manager, copy: copy),
      ),
    );
    return enabled ?? false;
  }

  @override
  State<NotificationPermissionPage> createState() =>
      _NotificationPermissionPageState();
}

class _NotificationPermissionPageState
    extends State<NotificationPermissionPage> {
  bool _requesting = false;
  bool _denied = false;

  Future<void> _enable() async {
    setState(() {
      _requesting = true;
      _denied = false;
    });
    try {
      final status = await widget.manager.requestPermission(copy: widget.copy);
      if (!mounted) return;
      if (status == NotificationPermissionStatus.granted) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(() {
        _requesting = false;
        _denied = true;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _requesting = false;
        _denied = true;
      });
    }
  }

  Future<void> _openSettings() => widget.manager.openNotificationSettings();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationsSection)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.notificationPermissionTitle,
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.notificationPermissionBody,
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  if (_denied) ...[
                    const SizedBox(height: 20),
                    Text(
                      l10n.notificationPermissionDenied,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _requesting ? null : _enable,
                    child: _requesting
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.notificationPermissionEnable),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _requesting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: Text(l10n.notificationPermissionNotNow),
                  ),
                  if (_denied)
                    TextButton(
                      onPressed: _openSettings,
                      child: Text(l10n.notificationOpenSettings),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
