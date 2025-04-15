import 'package:flutter/material.dart';
import '../models/energy_usage.dart';
import 'weather_service.dart';
import 'dart:math' as math;

class PredictionService {
  List<double> predictHourlyUsage(List<EnergyUsage> historicalData) {
    // Simple moving average prediction
    List<double> predictions = [];
    const int windowSize = 24; // 24 hour window

    for (int i = 0; i < 24; i++) {
      double sum = 0;
      int count = 0;
      
      // Calculate average for the same hour in previous days
      for (int j = i; j < historicalData.length; j += 24) {
        sum += historicalData[j].consumption;
        count++;
        if (count >= windowSize) break;
      }
      
      predictions.add(sum / count);
    }

    return predictions;
  }

  double calculateOptimalUsageTime(WeatherData weather, List<double> predictions) {
    // Consider weather conditions and historical usage
    if (weather.sunshine > 70) {
      return 14.0; // 2 PM when solar generation is high
    }
    
    // Find the hour with lowest predicted usage
    int lowestUsageHour = 0;
    double lowestUsage = double.infinity;
    
    for (int i = 0; i < predictions.length; i++) {
      if (predictions[i] < lowestUsage) {
        lowestUsage = predictions[i];
        lowestUsageHour = i;
      }
    }
    
    return lowestUsageHour.toDouble();
  }

  List<double> predictUsageWithExponentialSmoothing(List<EnergyUsage> historicalData) {
    const double alpha = 0.3; // Smoothing factor
    List<double> predictions = [];
    double lastPrediction = historicalData.first.consumption;
    
    for (int i = 1; i < 24; i++) {
      double observed = historicalData[i].consumption;
      double newPrediction = alpha * observed + (1 - alpha) * lastPrediction;
      predictions.add(newPrediction);
      lastPrediction = newPrediction;
    }
    
    return predictions;
  }

  List<double> generateRealtimeData() {
    final random = math.Random();
    final now = DateTime.now();
    final hour = now.hour;
    
    // Base load pattern
    List<double> basePattern = List.generate(24, (i) {
      // Morning peak
      if (i >= 6 && i <= 9) return 80.0 + random.nextDouble() * 20;
      // Evening peak
      if (i >= 18 && i <= 21) return 90.0 + random.nextDouble() * 30;
      // Night/early morning
      return 40.0 + random.nextDouble() * 15;
    });
    
    // Add random variations
    return basePattern.map((value) {
      return value * (1 + (random.nextDouble() - 0.5) * 0.2);
    }).toList();
  }

  Map<String, double> calculateEfficiencyMetrics(List<EnergyUsage> usage) {
    double peakUsage = 0;
    double totalUsage = 0;
    double avgUsage = 0;
    
    for (var data in usage) {
      if (data.consumption > peakUsage) peakUsage = data.consumption;
      totalUsage += data.consumption;
    }
    avgUsage = totalUsage / usage.length;
    
    return {
      'peak': peakUsage,
      'average': avgUsage,
      'efficiency': avgUsage / peakUsage,
    };
  }
}
