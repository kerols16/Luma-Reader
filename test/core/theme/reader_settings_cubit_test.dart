import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/theme/reader_settings_cubit.dart';
import 'package:luma/domain/entities/reader_settings.dart';

import '../../helpers/memory_stores.dart';

void main() {
  group('ReaderSettingsCubit', () {
    test('load restores stored settings', () async {
      const stored = ReaderSettings(
        theme: ReaderTheme.sepia,
        arabicDigits: true,
      );
      final store = MemoryReaderSettingsStore(stored);
      final cubit = ReaderSettingsCubit(store);

      await cubit.load();

      expect(cubit.state, stored);
    });

    test('update emits immediately and persists', () async {
      final store = MemoryReaderSettingsStore();
      final cubit = ReaderSettingsCubit(store);

      final states = <ReaderSettings>[];
      final subscription = cubit.stream.listen(states.add);

      const next = ReaderSettings(fontScale: 1.3, theme: ReaderTheme.dark);
      await cubit.update(next);
      await subscription.cancel();

      expect(states, [next]);
      expect(store.value, next);
      expect(store.saveCount, 1);
    });

    test('updating with the same settings does not save', () async {
      const initial = ReaderSettings(theme: ReaderTheme.dark);
      final store = MemoryReaderSettingsStore(initial);
      final cubit = ReaderSettingsCubit(store, initial: initial);

      await cubit.update(initial);

      expect(store.saveCount, 0);
    });
  });
}
