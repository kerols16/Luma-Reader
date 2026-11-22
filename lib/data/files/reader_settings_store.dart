import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../domain/entities/reader_settings.dart';

/// Persists reader settings between launches.
abstract interface class ReaderSettingsStore {
  Future<ReaderSettings> load();

  Future<void> save(ReaderSettings settings);
}

/// JSON file in the app support directory.
class FileReaderSettingsStore implements ReaderSettingsStore {
  static const _fileName = 'reader_settings.json';

  Future<File> _file() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}${Platform.pathSeparator}$_fileName');
  }

  @override
  Future<ReaderSettings> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return const ReaderSettings();
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, Object?>) return const ReaderSettings();
      return ReaderSettings.fromJson(decoded);
    } on Exception {
      return const ReaderSettings();
    }
  }

  @override
  Future<void> save(ReaderSettings settings) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(settings.toJson()), flush: true);
  }
}
