/// Links a unit to a plan day, with a stable reading order.
class PlanDayUnit {
  const PlanDayUnit({
    required this.planDayId,
    required this.unitId,
    required this.orderIndex,
  });

  final int planDayId;
  final int unitId;
  final int orderIndex;

  @override
  bool operator ==(Object other) =>
      other is PlanDayUnit &&
      other.planDayId == planDayId &&
      other.unitId == unitId &&
      other.orderIndex == orderIndex;

  @override
  int get hashCode => Object.hash(planDayId, unitId, orderIndex);
}
