import 'package:flutter/material.dart';

class AppTheme {
  static const primaryColor = Color(0xFF1E88E5);
  static const secondaryColor = Color(0xFF00C853);
  static const errorRed = Color(0xFFD50000);
  static const warningYellow = Color(0xFFFFD600);
  
  static const darkPrimaryColor = Color(0xFF1565C0);
  static const darkSecondaryColor = Color(0xFF00E676);
  static const backgroundColor = Color(0xFF000000); // Pure black
  static const surfaceColor = Color(0xFF000000); // Pure black
  static const cardColor = Color(0xFF000000); // Pure black
  
  static const cardGradientStart = Color(0xFF1565C0);
  static const cardGradientEnd = Color(0xFF00E676);
  static const chartBackgroundColor = Color(0xFF000000); // Pure black
  
  // Indian currency symbol and formatting
  static const rupeesSymbol = '₹';
  static const indianNumberFormat = '##,##,###.##';
  static const electricityTariff = 8.5; // ₹/kWh for example
  static const gstRate = 0.18; // 18% GST
  
  // Indian Electricity Rate Constants
  static const baseRatePerUnit = 4.0; // ₹/unit (kWh)
  static const peakHourRate = 6.0; // ₹/unit during peak hours
  static const offPeakRate = 3.0; // ₹/unit during off-peak
  static const maxUnitsPerMonth = 300.0; // Average monthly allocation
  
  // Peak Hours (24-hour format)
  static const peakHourStart = 18; // 6 PM
  static const peakHourEnd = 22; // 10 PM
  
  // Slabs (units in kWh)
  static const slab1Limit = 100; // 0-100 units
  static const slab2Limit = 200; // 101-200 units
  static const slab3Limit = 300; // 201-300 units
  
  static const slab1Rate = 3.5; // ₹/unit
  static const slab2Rate = 4.0; // ₹/unit
  static const slab3Rate = 5.0; // ₹/unit
  
  // Mumbai Electricity Tariff Constants (MSEDCL)
  static const List<int> slabLimits = [50, 100, 150, 250, 500, 800];
  static const List<double> slabRates = [2.00, 2.50, 2.75, 5.25, 6.30, 7.10, 7.10];
  
  // Additional Charges
  static const double fixedCharge = 100.0; // Example fixed charge
  static const double fuelAdjustmentCharge = 0.15; // per unit
  static const double electricityDuty = 0.16; // 16%
  static const double taxRate = 0.18; // 18% tax
  
  // Distribution Companies
  static const List<String> distributors = [
    'MSEDCL',
    'BEST',
    'Tata Power',
    'Adani Electricity'
  ];
  
  // Chart Constants
  static const chartAxisLabelColor = Colors.white70;
  static const chartGridColor = Color(0xFF2C2C2C);
  static const chartLabelTextStyle = TextStyle(
    color: chartAxisLabelColor,
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );
  
  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      secondary: secondaryColor,
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
  
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: darkPrimaryColor,
      secondary: darkSecondaryColor,
      background: backgroundColor,
      surface: surfaceColor,
      onSurface: Colors.white,
      onBackground: Colors.white,
    ),
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundColor,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: backgroundColor,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      color: cardColor,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide.none,
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: backgroundColor,
      elevation: 0,
    ),
  );

  static BoxDecoration get cardDecoration => BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    color: backgroundColor,
    border: Border.all(
      color: darkSecondaryColor.withOpacity(0.3),
      width: 1.5,
    ),
  );

  static CardTheme get standardCardTheme => CardTheme(
    elevation: 0,
    color: backgroundColor,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: darkSecondaryColor.withOpacity(0.3),
        width: 1.5,
      ),
    ),
  );
}
