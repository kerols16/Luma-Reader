import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/files/reader_settings_store.dart';
import '../../domain/entities/reader_settings.dart';

/// Holds reader settings and persists every change.
class ReaderSettingsCubit extends Cubit<ReaderSettings> {
  ReaderSettingsCubit(
    this._store, {
    ReaderSettings initial = const ReaderSettings(),
  }) : super(initial);

  final ReaderSettingsStore _store;

  /// Restores saved settings. Safe to call once at startup.
  Future<void> load() async {
    final stored = await _store.load();
    if (!isClosed) emit(stored);
  }

  /// Applies [settings] immediately and saves them in the background.
  ///
  /// A storage failure must not block changing settings, so save errors are
  /// ignored.
  Future<void> update(ReaderSettings settings) async {
    if (settings == state) return;
    emit(settings);
    try {
      await _store.save(settings);
    } on Exception {
      // Non-fatal: the change applies for this session only.
    }
  }
}
