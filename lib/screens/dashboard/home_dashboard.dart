import 'package:flutter/material.dart';
import '../../models/energy_usage.dart';
import '../../utils/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/prediction_service.dart';
import '../../services/weather_service.dart';
import '../../services/gamification_service.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../widgets/power_flow_card.dart';
import 'package:intl/intl.dart';
import '../../widgets/calculation_details_card.dart';
import '../../utils/indian_formatter.dart';
import '../../services/storage_service.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  final PredictionService _predictionService = PredictionService();
  final WeatherService _weatherService = WeatherService();
  final GamificationService _gamificationService = GamificationService();
  final StorageService _storageService = StorageService();
  List<double> _predictions = [];
  WeatherData? _weatherData;
  Timer? _updateTimer;
  List<double> _realtimeData = [];
  int _userScore = 0;
  Timer? _powerFlowTimer;
  double _currentFlow = 0;
  double _voltage = 220;
  double _frequency = 50;
  double _stability = 0.85;
  PowerDirection _flowDirection = PowerDirection.incoming;
  bool _showCostOverlay = false;
  final List<double> _costPredictions = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _loadData();
    _startRealtimeUpdates();
    _startPowerFlowUpdates();
    _loadStoredData();
  }

  Future<void> _loadData() async {
    try {
      final weather = await _weatherService.getWeather('YourCity');
      setState(() => _weatherData = weather);
      
      // Simulate historical data for now
      List<EnergyUsage> historicalData = _generateDummyData();
      _predictions = _predictionService.predictHourlyUsage(historicalData);
      
      _slideController.forward();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _startRealtimeUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      setState(() {
        // Generate more dynamic usage data with faster fluctuations
        _realtimeData = List.generate(24, (i) {
          final hour = DateTime.now().hour;
          final baseLoad = _getBaseLoadForHour(i);
          final random = math.Random();
          final fluctuation = random.nextDouble() * 2.0 - 1.0; // -1.0 to +1.0
          return baseLoad + (fluctuation * baseLoad * 0.2); // 20% fluctuation
        });
      });
    });
  }

  double _getBaseLoadForHour(int hour) {
    // Morning peak (6 AM - 9 AM)
    if (hour >= 6 && hour < 9) {
      return 4.0 + (hour - 6) * 0.5; // Gradual increase
    }
    // Evening peak (6 PM - 10 PM)
    if (hour >= 18 && hour < 22) {
      return 5.0 + (hour - 18) * 0.8; // Steeper increase
    }
    // Night time (11 PM - 5 AM)
    if (hour >= 22 || hour < 6) {
      return 2.0;
    }
    // Regular daytime
    return 3.0 + math.sin(hour * math.pi / 12) * 0.5; // Sinusoidal variation
  }

  void _startPowerFlowUpdates() {
    _powerFlowTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      setState(() {
        final now = DateTime.now();
        final random = math.Random();
        final baseLoad = _getBaseLoadForHour(now.hour);
        
        // Add short-term fluctuations
        final shortTermFluctuation = random.nextDouble() * 0.4 - 0.2; // ±0.2
        final timeBasedVariation = math.sin(now.minute * math.pi / 30) * 0.3; // Sinusoidal variation
        
        _currentFlow = baseLoad + shortTermFluctuation + timeBasedVariation;
        _currentFlow = double.parse(_currentFlow.toStringAsFixed(2)); // Round to 2 decimals
        
        // Update related metrics
        _voltage = 230 + random.nextDouble() * 4 - 2;
        _frequency = 49.95 + random.nextDouble() * 0.1;
      });
    });
  }

  double _calculateCurrentRate() {
    final now = DateTime.now().hour;
    if (now >= AppTheme.peakHourStart && now < AppTheme.peakHourEnd) {
      return AppTheme.peakHourRate;
    }
    return AppTheme.baseRatePerUnit;
  }

  double _calculateMonthlyUnits() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final hoursInMonth = now.difference(monthStart).inHours;
    return _currentFlow * hoursInMonth;
  }

  Future<void> _loadStoredData() async {
    try {
      final storedPredictions = await _storageService.getCostPredictions();
      if (storedPredictions.isNotEmpty) {
        setState(() {
          _costPredictions.clear();
          _costPredictions.addAll(storedPredictions);
        });
      } else {
        _generateCostPredictions();
      }
    } catch (e) {
      debugPrint('Error loading stored data: $e');
    }
  }

  void _generateCostPredictions() async {
    final random = math.Random();
    _costPredictions.clear();
    
    // Ensure we generate exactly 24 predictions
    for (int i = 0; i < 24; i++) {
      double baseRate = 1.0; // Base rate ₹1/kW
      
      // Higher rates during peak hours
      if (i >= 6 && i < 9) baseRate = 2.0; // Morning peak
      if (i >= 18 && i < 22) baseRate = 2.5; // Evening peak
      if (i >= 23 || i < 5) baseRate = 0.8; // Night off-peak
      
      // Add small random variation (±₹0.2)
      _costPredictions.add(baseRate + (random.nextDouble() * 0.4 - 0.2));
    }
    
    // Save predictions only if we have all 24 hours
    if (_costPredictions.length == 24) {
      await _storageService.saveCostPredictions(_costPredictions);
    }
  }

  double _calculateDailyUsage() {
    final now = DateTime.now();
    // Calculate units based on time of day
    double baseLoad = 0.3; // Base load in kW
    
    if (now.hour >= 6 && now.hour < 9) { // Morning peak
      baseLoad = 0.6;
    } else if (now.hour >= 18 && now.hour < 22) { // Evening peak
      baseLoad = 0.8;
    } else if (now.hour >= 23 || now.hour < 5) { // Night off-peak
      baseLoad = 0.2;
    }
    
    return baseLoad * _currentFlow;
  }

  List<FlSpot> _generate24HourData() {
    final spots = <FlSpot>[];
    final now = DateTime.now();
    final random = math.Random();
    
    for (int i = 0; i < 24; i++) {
      double value;
      if (i >= 6 && i < 9) { // Morning peak
        value = 0.4 + random.nextDouble() * 0.2; // 0.4-0.6 kW
      } else if (i >= 18 && i < 22) { // Evening peak
        value = 0.6 + random.nextDouble() * 0.3; // 0.6-0.9 kW
      } else if (i >= 23 || i < 5) { // Night off-peak
        value = 0.1 + random.nextDouble() * 0.1; // 0.1-0.2 kW
      } else { // Normal hours
        value = 0.3 + random.nextDouble() * 0.2; // 0.3-0.5 kW
      }
      spots.add(FlSpot(i.toDouble(), value));
    }
    return spots;
  }

  Future<void> _saveCalculation() async {
    final calculation = {
      'timestamp': DateTime.now().toIso8601String(),
      'currentFlow': _currentFlow,
      'cost': _calculateCurrentRate() * _currentFlow,
      'direction': _flowDirection.toString(),
    };
    
    await _storageService.saveCalculation(calculation);
  }

  void _viewCalculationHistory() async {
    final calculations = await _storageService.getCalculations();
    // Show history in dialog/screen
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _powerFlowTimer?.cancel();
    super.dispose();
  }

  List<EnergyUsage> _generateDummyData() {
    // Generate 7 days of hourly data
    return List.generate(24 * 7, (i) {
      return EnergyUsage(
        userId: 'user1',
        unitId: 'unit1',
        consumption: 50 + (i % 24) * 2.5, // Simulate daily pattern
        available: 150.0,
        timestamp: DateTime.now().subtract(Duration(hours: i)),
        type: UsageType.consumed,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildAppBar(), // AppBar will stay fixed at top
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    _buildUsageCard(),
                    const SizedBox(height: 20),
                    CalculationDetailsCard(
                      consumedUnits: _currentFlow,
                      ratePerUnit: AppTheme.electricityTariff,
                      hours: 1,
                    ),
                    const SizedBox(height: 20),
                    _buildCostAnalysisCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkSecondaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkPrimaryColor.withOpacity(0.2),
            AppTheme.backgroundColor,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back To',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'TATA Smart Energy Dashboard',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16), // Added spacing
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.darkSecondaryColor.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.darkSecondaryColor.withOpacity(0.1),
                          AppTheme.darkSecondaryColor.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt,
                          color: AppTheme.darkSecondaryColor,
                          size: 18, // Reduced icon size
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_currentFlow.toStringAsFixed(1)} kW',
                          style: TextStyle(
                            color: AppTheme.darkSecondaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14, // Reduced font size
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCostAnalysisCard() {
    return Card(
      margin: EdgeInsets.zero,
      color: AppTheme.cardColor,
      shape: AppTheme.standardCardTheme.shape,
      child: Container(
        decoration: AppTheme.cardDecoration.copyWith(
          color: AppTheme.backgroundColor,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cost Analysis',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.fullscreen),
                    color: AppTheme.darkSecondaryColor,
                    onPressed: () => _showFullScreenGraph(context, 'Cost'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildCostBreakdown(),
              const SizedBox(height: 16),
              _buildOptimalTimeChip(),
              const SizedBox(height: 16),
              SizedBox(
                height: 300, // Increased from 200 to 300
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                  child: LineChart(_createCostChartData()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsageCard() {
    return Card(
      margin: EdgeInsets.zero,
      color: AppTheme.cardColor,
      shape: AppTheme.standardCardTheme.shape,
      child: Container(
        decoration: AppTheme.cardDecoration.copyWith(
          color: AppTheme.backgroundColor,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Real-time Energy Usage',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_currentFlow.toStringAsFixed(1)} kW',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.darkSecondaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.fullscreen),
                    color: AppTheme.darkSecondaryColor,
                    onPressed: () => _showFullScreenGraph(context, 'Usage'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 250,
                child: LineChart(_createChartData()),
              ),
              const SizedBox(height: 16),
              _buildUsageStats(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptimalTimeChip() {
    final now = DateTime.now();
    final optimalHour = _findOptimalUsageTime();
    
    return Chip(
      avatar: const Icon(Icons.access_time, size: 16),
      backgroundColor: AppTheme.darkSecondaryColor.withOpacity(0.1),
      side: BorderSide(color: AppTheme.darkSecondaryColor.withOpacity(0.2)),
      label: Text(
        'Best time to use: ${NumberFormat("00").format(optimalHour)}:00',
        style: TextStyle(color: AppTheme.darkSecondaryColor),
      ),
    );
  }

  Widget _buildCostOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cost Analysis',
            style: TextStyle(
              color: AppTheme.darkSecondaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildCostBreakdown(),
        ],
      ),
    );
  }

  Widget _buildCostBreakdown() {
    final now = DateTime.now();
    final currentHour = now.hour;
    
    // Add bounds checking for cost predictions
    double currentHourCost = 0.0;
    double avgCost = 0.0;
    
    if (_costPredictions.isNotEmpty) {
      currentHourCost = _costPredictions[currentHour % _costPredictions.length];
      avgCost = _costPredictions.reduce((a, b) => a + b) / _costPredictions.length;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Rate: \₹${currentHourCost.toStringAsFixed(2)}/kW',
          style: const TextStyle(color: Colors.white),
        ),
        Text(
          'Average Rate: \₹${avgCost.toStringAsFixed(2)}/kW',
          style: const TextStyle(color: Colors.white70),
        ),
        if (currentHourCost > avgCost)
          Text(
            'Consider shifting usage to off-peak hours',
            style: TextStyle(color: AppTheme.warningYellow),
          ),
      ],
    );
  }

  int _findOptimalUsageTime() {
    if (_costPredictions.isEmpty) return 0;
    
    int optimalHour = 0;
    double lowestCost = _costPredictions[0];
    
    for (int i = 1; i < _costPredictions.length; i++) {
      if (_costPredictions[i] < lowestCost) {
        lowestCost = _costPredictions[i];
        optimalHour = i;
      }
    }
    
    return optimalHour;
  }

  LineChartData _createChartData({bool fullScreen = false}) {
    return LineChartData(
      backgroundColor: AppTheme.chartBackgroundColor,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: AppTheme.darkPrimaryColor.withOpacity(0.05),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: AppTheme.darkPrimaryColor.withOpacity(0.05),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: fullScreen,
            interval: 10,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()} kW',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 0.2, // Show marks every 0.2 kW
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(1),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              );
            },
          ),
          axisNameWidget: const Text(
            'Power Usage (kW)',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: fullScreen ? 2 : 6,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}:00',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              );
            },
          ),
          axisNameWidget: const Text(
            'Time of Day (hours)',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: _generate24HourData(),
          isCurved: true,
          color: AppTheme.darkSecondaryColor,
          barWidth: 3,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppTheme.darkSecondaryColor.withOpacity(0.1),
          ),
        ),
      ],
      minY: 0,
      maxY: 1.0, // Set maximum Y to 1 kW for better visibility
      minX: 0,
      maxX: 23,
      clipData: FlClipData.all(),
      // Enable touch interactions
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (List<LineBarSpot> spots) {
            return spots.map((spot) {
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(2)} kW\n${spot.x.toInt()}:00',
                const TextStyle(color: Colors.white),
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true, // Enable built-in touch handling
      ),
    );
  }

  LineChartData _createCostChartData({bool fullScreen = false}) {
    return LineChartData(
      backgroundColor: AppTheme.chartBackgroundColor,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: AppTheme.darkPrimaryColor.withOpacity(0.05),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: fullScreen,
            interval: 2,
            getTitlesWidget: (value, meta) {
              return Text(
                '₹${value.toInt()}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 0.5, // Show marks every ₹0.5
            getTitlesWidget: (value, meta) {
              return Text(
                '₹${value.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              );
            },
          ),
          axisNameWidget: const Text(
            'Cost per Unit (₹/kWh)',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: fullScreen ? 2 : 6,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}:00',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              );
            },
          ),
          axisNameWidget: const Text(
            'Time of Day (hours)',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: _costPredictions.asMap().entries.map((e) {
            return FlSpot(e.key.toDouble(), e.value);
          }).toList(),
          isCurved: true,
          color: AppTheme.warningYellow,
          barWidth: 3,
          dotData: FlDotData(show: false), // Changed to hide dots
          belowBarData: BarAreaData(
            show: true,
            color: AppTheme.warningYellow.withOpacity(0.1),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.warningYellow.withOpacity(0.2),
                AppTheme.warningYellow.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ],
      minX: 0,
      maxX: 23,
      minY: 0,
      maxY: 5.0, // Set maximum Y to ₹5 for better visibility
      clipData: FlClipData.all(),
      // Enable touch interactions
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (List<LineBarSpot> spots) {
            return spots.map((spot) {
              return LineTooltipItem(
                '₹${spot.y.toStringAsFixed(2)}\n${spot.x.toInt()}:00',
                const TextStyle(color: Colors.white),
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true, // Enable built-in touch handling
      ),
    );
  }

  void _showFullScreenGraph(BuildContext context, String title) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: AppBar(
              title: Text('$title Graph'),
              backgroundColor: AppTheme.backgroundColor,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      // Refresh data
                      if (title == 'Usage') {
                        _generate24HourData();
                      } else {
                        _generateCostPredictions();
                      }
                    });
                  },
                ),
              ],
            ),
            body: SafeArea(
              child: GestureDetector(
                onScaleUpdate: (ScaleUpdateDetails details) {
                  // Handle custom zoom if needed
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LineChart(
                    title == 'Usage' 
                        ? _createChartData(fullScreen: true)
                        : _createCostChartData(fullScreen: true),
                  ),
                ),
              ),
            ),
          );
        },
        fullscreenDialog: true,
      ),
    );
  }

  Widget _buildUsageStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Monthly Allocation: 200 kW',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          'Available: ${(200 - _currentFlow).toStringAsFixed(1)} kW',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.darkSecondaryColor,
          ),
        ),
      ],
    );
  }
}
