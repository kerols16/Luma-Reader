/// Reading progress for one unit.
class UnitProgress {
  const UnitProgress({
    required this.unitId,
    required this.scrollOffset,
    this.completedAt,
  });

  final int unitId;

  /// Scroll position within the reader, in logical pixels.
  final double scrollOffset;
  final DateTime? completedAt;

  bool get isCompleted => completedAt != null;

  @override
  bool operator ==(Object other) =>
      other is UnitProgress &&
      other.unitId == unitId &&
      other.scrollOffset == scrollOffset &&
      other.completedAt == completedAt;

  @override
  int get hashCode => Object.hash(unitId, scrollOffset, completedAt);
}
