/// Persists whether the user wants the daily reminder.
abstract interface class ReminderPreferenceStore {
  Future<bool> loadEnabled();

  Future<void> saveEnabled(bool enabled);
}
