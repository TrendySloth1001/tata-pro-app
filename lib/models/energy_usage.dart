class EnergyUsage {
  final String userId;
  final String unitId;
  final double consumption;
  final double available;
  final DateTime timestamp;
  final UsageType type;

  EnergyUsage({
    required this.userId,
    required this.unitId,
    required this.consumption,
    required this.available,
    required this.timestamp,
    required this.type,
  });
}

enum UsageType { consumed, generated, shared }
