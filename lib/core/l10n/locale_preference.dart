import 'package:flutter/widgets.dart';

/// User's choice of UI language, persisted between launches.
enum LocalePreference {
  system,
  en,
  ar;

  /// The locale to hand to `MaterialApp`, or `null` to follow the device.
  Locale? get locale => switch (this) {
    LocalePreference.system => null,
    LocalePreference.en => const Locale('en'),
    LocalePreference.ar => const Locale('ar'),
  };

  /// Parses a persisted value, falling back to [system] for unknown data.
  static LocalePreference fromStorage(String? value) {
    for (final preference in LocalePreference.values) {
      if (preference.name == value) return preference;
    }
    return LocalePreference.system;
  }
}
