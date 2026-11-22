import 'package:luma/core/l10n/locale_preference.dart';
import 'package:luma/core/l10n/locale_store.dart';
import 'package:luma/data/files/reader_settings_store.dart';
import 'package:luma/domain/entities/reader_settings.dart';

class MemoryLocaleStore implements LocaleStore {
  MemoryLocaleStore([this.value = LocalePreference.system]);

  LocalePreference value;
  int saveCount = 0;

  @override
  Future<LocalePreference> load() async => value;

  @override
  Future<void> save(LocalePreference preference) async {
    value = preference;
    saveCount++;
  }
}

class MemoryReaderSettingsStore implements ReaderSettingsStore {
  MemoryReaderSettingsStore([this.value = const ReaderSettings()]);

  ReaderSettings value;
  int saveCount = 0;

  @override
  Future<ReaderSettings> load() async => value;

  @override
  Future<void> save(ReaderSettings settings) async {
    value = settings;
    saveCount++;
  }
}
