/// Recovery options offered when a plan or a missed day needs a decision.
library;

sealed class RecoveryOption {
  const RecoveryOption();
}

class ExtendDeadlineOption extends RecoveryOption {
  const ExtendDeadlineOption(this.days);

  final int days;
}

class RaiseDailyBudgetOption extends RecoveryOption {
  const RaiseDailyBudgetOption(this.minutes);

  final int minutes;
}

class TrimLowPriorityOption extends RecoveryOption {
  const TrimLowPriorityOption(this.unitIds);

  /// Reading-unit ids that could be dropped. Sorted by size, smallest first.
  final List<String> unitIds;
}
