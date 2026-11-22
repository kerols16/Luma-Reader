import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/l10n/locale_cubit.dart';
import 'package:luma/core/l10n/locale_preference.dart';
import 'package:luma/core/theme/reader_settings_cubit.dart';
import 'package:luma/domain/entities/reader_settings.dart';
import 'package:luma/features/settings/settings_page.dart';
import 'package:luma/main.dart';

import 'helpers/memory_stores.dart';

Future<(LocaleCubit, ReaderSettingsCubit)> _pumpApp(
  WidgetTester tester, {
  LocalePreference locale = LocalePreference.en,
  ReaderSettings settings = const ReaderSettings(),
}) async {
  final localeCubit = LocaleCubit(MemoryLocaleStore(locale), initial: locale);
  final settingsCubit = ReaderSettingsCubit(
    MemoryReaderSettingsStore(settings),
    initial: settings,
  );
  await tester.pumpWidget(
    LumaApp(localeCubit: localeCubit, readerSettingsCubit: settingsCubit),
  );
  await tester.pumpAndSettle();
  return (localeCubit, settingsCubit);
}

TextDirection _appDirection(WidgetTester tester) =>
    Directionality.of(tester.element(find.byType(SettingsPage)));

void main() {
  testWidgets('English locale renders left to right', (tester) async {
    await _pumpApp(tester);

    expect(_appDirection(tester), TextDirection.ltr);
  });

  testWidgets('Arabic locale renders right to left', (tester) async {
    await _pumpApp(tester, locale: LocalePreference.ar);

    expect(_appDirection(tester), TextDirection.rtl);
  });

  testWidgets('language menu flips direction immediately', (tester) async {
    await _pumpApp(tester);
    expect(_appDirection(tester), TextDirection.ltr);

    await tester.tap(find.byType(DropdownButton<LocalePreference>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arabic').last);
    await tester.pumpAndSettle();

    expect(_appDirection(tester), TextDirection.rtl);
    expect(find.text('الإعدادات'), findsOneWidget);
  });

  testWidgets('reader theme applies to the whole app', (tester) async {
    final (_, settingsCubit) = await _pumpApp(tester);

    await settingsCubit.update(const ReaderSettings(theme: ReaderTheme.dark));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(SettingsPage));
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
