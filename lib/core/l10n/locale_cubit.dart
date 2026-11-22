import 'package:flutter_bloc/flutter_bloc.dart';

import 'locale_preference.dart';
import 'locale_store.dart';

/// Holds the current UI language and persists changes.
class LocaleCubit extends Cubit<LocalePreference> {
  LocaleCubit(this._store, {LocalePreference initial = LocalePreference.system})
    : super(initial);

  final LocaleStore _store;

  /// Restores the saved preference. Safe to call once at startup.
  Future<void> load() async {
    final stored = await _store.load();
    if (!isClosed) emit(stored);
  }

  /// Applies [preference] immediately, then saves it in the background.
  ///
  /// A storage failure must not block switching, so save errors are ignored.
  Future<void> select(LocalePreference preference) async {
    if (preference == state) return;
    emit(preference);
    try {
      await _store.save(preference);
    } on Exception {
      // Non-fatal: the choice applies for this session only.
    }
  }
}
