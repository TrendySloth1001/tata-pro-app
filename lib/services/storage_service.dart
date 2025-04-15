import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trade_data.dart';

class StorageService {
  static const String _costPredictionsKey = 'cost_predictions';
  static const String _usageHistoryKey = 'usage_history';
  static const String _calculationsKey = 'calculations';
  static const String _tradeHistoryKey = 'trade_history';
  static const String _realTradeHistoryKey = 'real_trade_history';

  // Add cache keys and expiry times
  static const String _lastUpdateKey = 'last_update';
  static const Duration _cacheExpiry = Duration(hours: 24);
  static const int _maxCacheItems = 1000;

  Future<void> saveCostPredictions(List<double> predictions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = predictions.map((e) => e.toString()).toList();
      
      // Save timestamp with data
      await Future.wait([
        prefs.setStringList(_costPredictionsKey, data),
        prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String()),
      ]);
      
      debugPrint('Saved cost predictions: ${data.length} items');
    } catch (e) {
      debugPrint('Error saving cost predictions: $e');
      rethrow;
    }
  }

  Future<List<double>> getCostPredictions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getStringList(_costPredictionsKey);
      final lastUpdate = prefs.getString(_lastUpdateKey);

      // Check cache expiry
      if (lastUpdate != null) {
        final lastUpdateTime = DateTime.parse(lastUpdate);
        if (DateTime.now().difference(lastUpdateTime) > _cacheExpiry) {
          await prefs.remove(_costPredictionsKey);
          return [];
        }
      }

      if (data == null) return [];
      return data.map((e) => double.tryParse(e) ?? 0.0).toList();
    } catch (e) {
      debugPrint('Error getting cost predictions: $e');
      return [];
    }
  }

  Future<void> saveCalculation(Map<String, dynamic> calculation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final calculations = await getCalculations();
      
      // Validate calculation data
      if (!_isValidCalculation(calculation)) {
        throw Exception('Invalid calculation data');
      }

      calculations.insert(0, calculation); // Add at beginning
      
      // Limit cache size
      if (calculations.length > _maxCacheItems) {
        calculations.removeLast();
      }
      
      await prefs.setString(_calculationsKey, jsonEncode(calculations));
      debugPrint('Saved calculation, total: ${calculations.length}');
    } catch (e) {
      debugPrint('Error saving calculation: $e');
      rethrow;
    }
  }

  bool _isValidCalculation(Map<String, dynamic> calculation) {
    return calculation.containsKey('timestamp') &&
           calculation.containsKey('units') &&
           calculation.containsKey('rate') &&
           calculation.containsKey('total');
  }

  Future<List<Map<String, dynamic>>> getCalculations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_calculationsKey);
      
      if (data == null) return [];
      
      final List<dynamic> jsonData = jsonDecode(data);
      return jsonData.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      debugPrint('Error getting calculations: $e');
      return [];
    }
  }

  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('Cleared all stored data');
    } catch (e) {
      debugPrint('Error clearing all data: $e');
      rethrow;
    }
  }

  Future<void> saveTradeData(TradeData trade) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = trade.isReal ? _realTradeHistoryKey : _tradeHistoryKey;
      final trades = await getTradeHistory(isReal: trade.isReal);
      
      // Convert and validate trade data
      final tradeJson = trade.toJson();
      trades.insert(0, TradeData.fromJson(tradeJson)); // Validate by converting back
      
      // Keep only recent trades
      if (trades.length > _maxCacheItems) {
        trades.removeLast();
      }
      
      // Save as JSON string
      final tradesJson = trades.map((t) => t.toJson()).toList();
      await prefs.setString(key, jsonEncode(tradesJson));
      
      debugPrint('Saved trade data, total: ${trades.length}');
    } catch (e) {
      debugPrint('Error saving trade data: $e');
      rethrow;
    }
  }

  Future<List<TradeData>> getTradeHistory({bool isReal = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = isReal ? _realTradeHistoryKey : _tradeHistoryKey;
      final data = prefs.getString(key);
      
      if (data == null) return [];
      
      final List<dynamic> jsonData = jsonDecode(data);
      final trades = jsonData
          .map((json) => TradeData.fromJson(Map<String, dynamic>.from(json)))
          .where((trade) => trade != null) // Filter out invalid trades
          .toList();
      
      debugPrint('Retrieved ${trades.length} trades');
      return trades;
    } catch (e) {
      debugPrint('Error getting trade history: $e');
      return [];
    }
  }

  Future<void> clearTradeHistory({bool isReal = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = isReal ? _realTradeHistoryKey : _tradeHistoryKey;
      await prefs.remove(key);
      debugPrint('Cleared trade history (isReal: $isReal)');
    } catch (e) {
      debugPrint('Error clearing trade history: $e');
      rethrow;
    }
  }
}
