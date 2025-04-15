class TradeData {
  final String id;
  final double buyRate;
  final double sellRate;
  final DateTime timestamp;
  final double volume;
  final bool isReal;
  final bool isBuy;
  final double amount;

  TradeData({
    required this.id,
    required this.buyRate,
    required this.sellRate,
    required this.timestamp,
    required this.volume,
    this.isReal = false,
    required this.isBuy,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'buyRate': buyRate,
    'sellRate': sellRate,
    'timestamp': timestamp.toIso8601String(),
    'volume': volume,
    'isReal': isReal,
    'isBuy': isBuy,
    'amount': amount,
  };

  factory TradeData.fromJson(Map<String, dynamic> json) => TradeData(
    id: json['id'],
    buyRate: json['buyRate'],
    sellRate: json['sellRate'],
    timestamp: DateTime.parse(json['timestamp']),
    volume: json['volume'],
    isReal: json['isReal'] ?? false,
    isBuy: json['isBuy'] ?? false,
    amount: json['amount'],
  );
}
