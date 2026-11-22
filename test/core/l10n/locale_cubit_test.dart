import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/l10n/locale_cubit.dart';
import 'package:luma/core/l10n/locale_preference.dart';

import '../../helpers/memory_stores.dart';

void main() {
  group('LocalePreference', () {
    test('maps to app locales, system has none', () {
      expect(LocalePreference.system.locale, isNull);
      expect(LocalePreference.en.locale?.languageCode, 'en');
      expect(LocalePreference.ar.locale?.languageCode, 'ar');
    });

    test('unknown stored values fall back to system', () {
      expect(LocalePreference.fromStorage('ar'), LocalePreference.ar);
      expect(LocalePreference.fromStorage('fr'), LocalePreference.system);
      expect(LocalePreference.fromStorage(null), LocalePreference.system);
    });
  });

  group('LocaleCubit', () {
    test('load restores the stored preference', () async {
      final store = MemoryLocaleStore(LocalePreference.ar);
      final cubit = LocaleCubit(store);

      await cubit.load();

      expect(cubit.state, LocalePreference.ar);
    });

    test('select emits immediately and persists', () async {
      final store = MemoryLocaleStore();
      final cubit = LocaleCubit(store);

      final states = <LocalePreference>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.select(LocalePreference.ar);
      await subscription.cancel();

      expect(states, [LocalePreference.ar]);
      expect(store.value, LocalePreference.ar);
      expect(store.saveCount, 1);
    });

    test('selecting the current preference does not save again', () async {
      final store = MemoryLocaleStore(LocalePreference.en);
      final cubit = LocaleCubit(store, initial: LocalePreference.en);

      await cubit.select(LocalePreference.en);

      expect(store.saveCount, 0);
    });
  });
}
