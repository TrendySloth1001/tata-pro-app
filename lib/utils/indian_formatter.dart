import 'package:intl/intl.dart';
import 'dart:math' as math;

import 'app_theme.dart';

class IndianFormatter {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final _numberFormat = NumberFormat('#,##,##0.00', 'en_IN');
  
  static String formatCurrency(double amount) => _currencyFormat.format(amount);
  static String formatNumber(double number) => _numberFormat.format(number);
  
  static String formatPower(double kw) => '${formatNumber(kw)} kW';
  static String formatEnergy(double kwh) => '${formatNumber(kwh)} kWh';
  
  static String formatTime(DateTime time) => 
      DateFormat('dd MMM yyyy, hh:mm a').format(time);
  
  static String formatRate(double amount) {
    return '₹${_numberFormat.format(amount)}/hr';
  }
  
  static String formatDailyTotal(double units) {
    final amount = units * AppTheme.baseRatePerUnit;
    return '₹${_numberFormat.format(amount)}/day';
  }

  static String formatInstantPower(double kw) {
    if (kw < 1) {
      return '${(kw * 1000).toStringAsFixed(0)} W'; // Show in watts if less than 1 kW
    }
    return '${_numberFormat.format(kw)} kW';
  }

  static String formatHourlyRate(double rate, double units) {
    final hourlyAmount = rate * units;
    return '₹${_numberFormat.format(hourlyAmount)}/hr';
  }
}

class IndianTariffCalculator {
  static double calculateBillAmount(double units) {
    double amount = 0;
    
    // Slab 1
    if (units <= AppTheme.slab1Limit) {
      amount = units * AppTheme.slab1Rate;
    } 
    // Slab 2
    else if (units <= AppTheme.slab2Limit) {
      amount = (AppTheme.slab1Limit * AppTheme.slab1Rate) +
          ((units - AppTheme.slab1Limit) * AppTheme.slab2Rate);
    }
    // Slab 3
    else {
      amount = (AppTheme.slab1Limit * AppTheme.slab1Rate) +
          ((AppTheme.slab2Limit - AppTheme.slab1Limit) * AppTheme.slab2Rate) +
          ((units - AppTheme.slab2Limit) * AppTheme.slab3Rate);
    }
    
    return amount;
  }
  
  static String formatUnits(double units) {
    return '${IndianFormatter.formatNumber(units)} kWh';
  }
  
  static String getSlabInfo(double units) {
    if (units <= AppTheme.slab1Limit) return 'Slab 1 (0-100 units)';
    if (units <= AppTheme.slab2Limit) return 'Slab 2 (101-200 units)';
    return 'Slab 3 (>200 units)';
  }
  
  static double calculateHourlyRate(int hour) {
    // Base rate is ₹4/unit
    if (hour >= 6 && hour < 9) return 5.50; // Morning peak
    if (hour >= 18 && hour < 22) return 7.00; // Evening peak
    if (hour >= 23 || hour < 5) return 2.50; // Night off-peak
    return 4.00; // Normal hours
  }
  
  static double calculateCurrentBill(double units, DateTime time) {
    final hourlyRate = calculateHourlyRate(time.hour);
    return units * hourlyRate;
  }

  static double calculateInstantRate(double units, int hour, int minute) {
    final baseRate = calculateHourlyRate(hour);
    // Add small variations based on minutes
    final minuteVariation = math.sin(minute * math.pi / 30) * 0.2;
    return baseRate + (minuteVariation * baseRate);
  }
}

class MumbaiTariffCalculator {
  static double calculateSlabCharges(double units) {
    double totalAmount = 0.0;
    int remainingUnits = units.toInt();
    
    for (int i = 0; i < AppTheme.slabLimits.length && remainingUnits > 0; i++) {
      int slabLimit = i == 0 
          ? AppTheme.slabLimits[i] 
          : AppTheme.slabLimits[i] - AppTheme.slabLimits[i-1];
          
      int unitsInSlab = math.min(remainingUnits, slabLimit);
      totalAmount += unitsInSlab * AppTheme.slabRates[i];
      remainingUnits -= unitsInSlab;
    }
    
    // If there are still remaining units, apply the highest slab rate
    if (remainingUnits > 0) {
      totalAmount += remainingUnits * AppTheme.slabRates.last;
    }
    
    return totalAmount;
  }

  static Map<String, double> calculateDetailedBill(double units) {
    final energyCharges = calculateSlabCharges(units);
    final fac = units * AppTheme.fuelAdjustmentCharge;
    final dutyAmount = energyCharges * AppTheme.electricityDuty;
    final subTotal = energyCharges + AppTheme.fixedCharge + fac + dutyAmount;
    final tax = subTotal * AppTheme.taxRate;
    
    return {
      'energyCharges': energyCharges,
      'fixedCharge': AppTheme.fixedCharge,
      'fuelAdjustment': fac,
      'electricityDuty': dutyAmount,
      'tax': tax,
      'total': subTotal + tax,
    };
  }

  static String getSlabRate(double units) {
    for (int i = 0; i < AppTheme.slabLimits.length; i++) {
      if (units <= AppTheme.slabLimits[i]) {
        return '₹${AppTheme.slabRates[i].toStringAsFixed(2)}/unit';
      }
    }
    return '₹${AppTheme.slabRates.last.toStringAsFixed(2)}/unit';
  }

  static List<Map<String, dynamic>> getSlabBreakdown(double units) {
    List<Map<String, dynamic>> breakdown = [];
    int remainingUnits = units.toInt();
    int startUnit = 0;
    
    for (int i = 0; i < AppTheme.slabLimits.length && remainingUnits > 0; i++) {
      int slabLimit = i == 0 
          ? AppTheme.slabLimits[i] 
          : AppTheme.slabLimits[i] - AppTheme.slabLimits[i-1];
          
      int unitsInSlab = math.min(remainingUnits, slabLimit);
      double amount = unitsInSlab * AppTheme.slabRates[i];
      
      breakdown.add({
        'from': startUnit,
        'to': startUnit + unitsInSlab,
        'units': unitsInSlab,
        'rate': AppTheme.slabRates[i],
        'amount': amount,
      });
      
      remainingUnits -= unitsInSlab;
      startUnit += unitsInSlab;
    }
    
    return breakdown;
  }
}
