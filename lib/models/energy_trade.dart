class EnergyTrade {
  final String id;
  final String senderId;
  final String receiverId;
  final double amount;
  final DateTime timestamp;
  final TradeStatus status;
  final double price;

  EnergyTrade({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.amount,
    required this.timestamp,
    required this.status,
    required this.price,
  });
}

enum TradeStatus { pending, completed, cancelled }
