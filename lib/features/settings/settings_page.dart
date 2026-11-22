import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:luma/core/l10n/gen/app_localizations.dart';
import 'package:luma/core/l10n/locale_cubit.dart';
import 'package:luma/core/l10n/locale_preference.dart';
import 'package:luma/core/theme/reader_palette.dart';
import 'package:luma/core/theme/reader_settings_cubit.dart';
import 'package:luma/core/theme/reading_column.dart';
import 'package:luma/domain/entities/reader_settings.dart';

/// App settings: language and reader preferences.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localePreference = context.watch<LocaleCubit>().state;
    final settings = context.watch<ReaderSettingsCubit>().state;
    final palette = ReaderPalette.of(settings.theme);
    final isArabicUi = Localizations.localeOf(context).languageCode == 'ar';
    final settingsCubit = context.read<ReaderSettingsCubit>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
        children: [
          ListTile(
            title: Text(l10n.appLanguage),
            trailing: DropdownButton<LocalePreference>(
              value: localePreference,
              onChanged: (value) {
                if (value == null) return;
                context.read<LocaleCubit>().select(value);
              },
              items: [
                for (final option in LocalePreference.values)
                  DropdownMenuItem(
                    value: option,
                    child: Text(_languageLabel(option, l10n)),
                  ),
              ],
            ),
          ),
          const Divider(),
          _SectionHeader(title: l10n.readerSettings),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
            child: ReadingColumn(
              child: ReadingText(
                l10n.readerPreviewText,
                isArabic: isArabicUi,
                settings: settings,
                color: palette.text,
              ),
            ),
          ),
          _SliderTile(
            label: l10n.fontSize,
            value: settings.fontScale,
            min: ReaderSettings.minFontScale,
            max: ReaderSettings.maxFontScale,
            divisions: 8,
            onChanged: (value) =>
                settingsCubit.update(settings.copyWith(fontScale: value)),
          ),
          _SliderTile(
            label: l10n.lineHeight,
            value: settings.lineHeight,
            min: ReaderSettings.minLineHeight,
            max: ReaderSettings.maxLineHeight,
            divisions: 10,
            onChanged: (value) =>
                settingsCubit.update(settings.copyWith(lineHeight: value)),
          ),
          ListTile(title: Text(l10n.theme)),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            child: SegmentedButton<ReaderTheme>(
              showSelectedIcon: false,
              segments: [
                for (final theme in ReaderTheme.values)
                  ButtonSegment(
                    value: theme,
                    label: Text(_themeLabel(theme, l10n)),
                  ),
              ],
              selected: {settings.theme},
              onSelectionChanged: (selection) => settingsCubit.update(
                settings.copyWith(theme: selection.first),
              ),
            ),
          ),
          SwitchListTile(
            title: Text(l10n.arabicDigits),
            value: settings.arabicDigits,
            onChanged: (value) =>
                settingsCubit.update(settings.copyWith(arabicDigits: value)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(title: Text(label)),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          label: '${(value * 100).round()}%',
          onChanged: onChanged,
        ),
      ],
    );
  }
}

String _languageLabel(LocalePreference preference, AppLocalizations l10n) =>
    switch (preference) {
      LocalePreference.system => l10n.languageSystem,
      LocalePreference.en => l10n.languageEnglish,
      LocalePreference.ar => l10n.languageArabic,
    };

String _themeLabel(ReaderTheme theme, AppLocalizations l10n) => switch (theme) {
  ReaderTheme.light => l10n.themeLight,
  ReaderTheme.sepia => l10n.themeSepia,
  ReaderTheme.dark => l10n.themeDark,
};
