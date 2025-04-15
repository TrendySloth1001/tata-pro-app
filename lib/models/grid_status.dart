class GridStatus {
  final String buildingId;
  final double totalCapacity;
  final double currentLoad;
  final double sharedPool;
  final GridHealth health;
  final DateTime lastUpdated;

  GridStatus({
    required this.buildingId,
    required this.totalCapacity,
    required this.currentLoad,
    required this.sharedPool,
    required this.health,
    required this.lastUpdated,
  });
}

enum GridHealth { optimal, warning, critical }
