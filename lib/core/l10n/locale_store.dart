import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'locale_preference.dart';

/// Persists the UI language choice.
abstract interface class LocaleStore {
  Future<LocalePreference> load();

  Future<void> save(LocalePreference preference);
}

/// Stores the choice in a small file inside the app support directory.
///
/// A file keeps the app dependency-free; it is created on first save.
class FileLocaleStore implements LocaleStore {
  static const _fileName = 'locale.txt';

  Future<File> _file() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}${Platform.pathSeparator}$_fileName');
  }

  @override
  Future<LocalePreference> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return LocalePreference.system;
      return LocalePreference.fromStorage((await file.readAsString()).trim());
    } on FileSystemException {
      return LocalePreference.system;
    }
  }

  @override
  Future<void> save(LocalePreference preference) async {
    final file = await _file();
    await file.writeAsString(preference.name, flush: true);
  }
}
