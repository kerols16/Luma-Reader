enum PlanDayStatus { pending, done, missed }

class PlanDay {
  const PlanDay({
    required this.id,
    required this.planId,
    required this.date,
    required this.status,
    required this.minutesBudget,
  });

  final int id;
  final int planId;
  final DateTime date;
  final PlanDayStatus status;
  final int minutesBudget;

  @override
  bool operator ==(Object other) =>
      other is PlanDay &&
      other.id == id &&
      other.planId == planId &&
      other.date == date &&
      other.status == status &&
      other.minutesBudget == minutesBudget;

  @override
  int get hashCode => Object.hash(id, planId, date, status, minutesBudget);
}
