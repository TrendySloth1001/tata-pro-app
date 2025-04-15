import 'dart:math' as math;
import '../models/trade_data.dart';
import 'storage_service.dart';

class TradeService {
  final StorageService _storage;
  
  TradeService(this._storage);

  Future<TradeData> executeTrade(double amount, bool isBuying) async {
    // In real implementation, this would make an API call
    final trade = TradeData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      buyRate: _getCurrentBuyRate(),
      sellRate: _getCurrentSellRate(),
      timestamp: DateTime.now(),
      volume: amount,
      isReal: false, // Mark as dummy data
      isBuy: isBuying,
      amount: amount,
    );

    await _storage.saveTradeData(trade);
    return trade;
  }

  Future<List<TradeData>> getTradeHistory({bool realData = false}) async {
    return _storage.getTradeHistory(isReal: realData);
  }

  double _getCurrentBuyRate() {
    final now = DateTime.now();
    final baseRate = 4.5;
    final hourlyVariation = math.sin(now.hour * math.pi / 12) * 0.5;
    final random = math.Random();
    final noise = random.nextDouble() * 0.2 - 0.1;
    return baseRate + hourlyVariation + noise;
  }

  double _getCurrentSellRate() {
    return _getCurrentBuyRate() * 0.9; // 10% spread
  }

  Future<Map<String, double>> getLimits() async {
    return {
      'dailyLimit': 500.0,    // Increased from 50.0
      'monthlyLimit': 5000.0, // Increased from 1000.0
      'minTrade': 0.1,
      'maxTrade': 100.0,      // Increased from 10.0
    };
  }
}
