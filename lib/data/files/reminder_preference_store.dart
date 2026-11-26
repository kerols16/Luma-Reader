import 'dart:io';

import 'package:luma/services/notifications/reminder_preference_store.dart';
import 'package:path_provider/path_provider.dart';

/// Stores the choice in a small file inside the app support directory.
class FileReminderPreferenceStore implements ReminderPreferenceStore {
  static const _fileName = 'reminders_enabled.txt';

  Future<File> _file() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}${Platform.pathSeparator}$_fileName');
  }

  @override
  Future<bool> loadEnabled() async {
    try {
      final file = await _file();
      if (!await file.exists()) return false;
      return (await file.readAsString()).trim() == 'true';
    } on FileSystemException {
      return false;
    }
  }

  @override
  Future<void> saveEnabled(bool enabled) async {
    final file = await _file();
    await file.writeAsString(enabled ? 'true' : 'false', flush: true);
  }
}
