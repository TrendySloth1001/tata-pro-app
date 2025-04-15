import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/indian_formatter.dart';
import '../../services/trade_service.dart';
import '../../models/trade_data.dart';
import '../../widgets/power_flow_card.dart';

class TradeScreen extends StatefulWidget {
  const TradeScreen({super.key});

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _tradeAmount = 0;
  bool _isSellingActive = false;
  final TextEditingController _unitsController = TextEditingController();
  late final TradeService _tradeService;
  final StorageService _storageService = StorageService();
  List<TradeData> _tradeHistory = [];
  bool _showRealData = false;
  Map<String, double> _tradingLimits = {
    'dailyLimit': 50.0,
    'monthlyLimit': 1000.0,
    'minTrade': 0.1,
    'maxTrade': 10.0,
  };
  double _usedDailyLimit = 0.0;
  double _usedMonthlyLimit = 0.0;

  // Add new calculation variables
  double _perMinuteEarnings = 0.0;
  double _hourlyEarnings = 0.0;
  double _dailyProjection = 0.0;
  DateTime? _startTime;

  // Add new state variables
  bool _hasExecutedTrade = false;
  double _remainingAmount = 0.0;
  Timer? _sellTimer;

  // Add simulation interval constant
  static const int _simulationInterval = 60; // seconds

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tradeService = TradeService(_storageService);
    _loadLimits();
    _loadTradeHistory();
  }

  Future<void> _loadLimits() async {
    final limits = await _tradeService.getLimits();
    final history = await _tradeService.getTradeHistory();
    
    // Calculate used limits
    final now = DateTime.now();
    _usedDailyLimit = history
        .where((t) => t.timestamp.day == now.day)
        .fold(0.0, (sum, t) => sum + t.amount);
        
    _usedMonthlyLimit = history
        .where((t) => t.timestamp.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    setState(() {
      _tradingLimits = limits;
    });
  }

  Future<void> _loadTradeHistory() async {
    final history = await _tradeService.getTradeHistory(realData: _showRealData);
    setState(() => _tradeHistory = history);
  }

  double _calculateAmount(double units) {
    const sellRate = 3.80; // Fixed sell rate
    return units * sellRate;
  }

  Future<void> _executeTrade() async {
    if (_tradeAmount < 0.1) {
      _showError('Minimum trade amount is 0.1 kW');
      return;
    }

    try {
      final trade = await _tradeService.executeTrade(_tradeAmount, false);
      await _loadTradeHistory();
      await _loadLimits();
      setState(() {
        _hasExecutedTrade = true;
        _remainingAmount = 0;
        _isSellingActive = false;
      });
      _showSaleCompleteDialog(trade);
    } catch (e) {
      _showError('Trade failed: ${e.toString()}');
    }
  }

  void _showSaleCompleteDialog(TradeData trade) {
    // Calculate total earnings properly
    final totalEarnings = trade.amount * trade.sellRate;
    
    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) => Container(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutBack,
        );

        return ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: AlertDialog(
              backgroundColor: AppTheme.backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: AppTheme.warningYellow.withOpacity(0.3),
                  width: 2,
                ),
              ),
              title: Stack(
                children: [
                  // Background power flow animation
                  SizedBox(
                    height: 300,
                    child: CustomPaint(
                      painter: SaleCompletePainter(
                        animation: curvedAnimation,
                        color: AppTheme.warningYellow,
                      ),
                    ),
                  ),
                  // Success content with animation
                  Column(
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1000),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: Icon(
                          Icons.check_circle_outline,
                          color: AppTheme.warningYellow,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.5),
                          end: Offset.zero,
                        ).animate(curvedAnimation),
                        child: Text(
                          'Sale Complete',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.warningYellow,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              content: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(curvedAnimation),
                child: FadeTransition(
                  opacity: animation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Amount Sold', '${trade.amount.toStringAsFixed(2)} kW'),
                      _buildDetailRow('Rate', '₹${trade.sellRate.toStringAsFixed(2)}/kW'),
                      _buildDetailRow('Total Earnings', '₹${totalEarnings.toStringAsFixed(2)}'),
                      const SizedBox(height: 16),
                      const Text(
                        'Your sale has been completed successfully.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.warningYellow,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _resetTradeForm();
                  },
                  child: const Text('Done', style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 800),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.warningYellow,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _resetTradeForm() {
    setState(() {
      _tradeAmount = 0;
      _hasExecutedTrade = false;
      _remainingAmount = 0;
      _isSellingActive = false;
      _unitsController.clear();
    });
    _sellTimer?.cancel();
    _sellTimer = null;
  }

  void _startSellingSimulation() {
    setState(() {
      _isSellingActive = true;
      _remainingAmount = _tradeAmount;
      _hasExecutedTrade = false;
    });
    
    _sellTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isSellingActive || _remainingAmount <= 0) {
        _sellTimer?.cancel();
        _executeTrade();
        return;
      }

      setState(() {
        _remainingAmount = math.max(0, _remainingAmount - (_tradeAmount / 60));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        title: const Text('Energy Trading'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear Cache',
            onPressed: () => _clearCache(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Trade'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTradeTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Future<void> _clearCache(BuildContext context) async {
    try {
      await _storageService.clearTradeHistory(isReal: false);
      await _storageService.clearTradeHistory(isReal: true);
      setState(() {
        _tradeHistory.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trade history cleared')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing cache: $e')),
        );
      }
    }
  }

  Widget _buildTradeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          PowerFlowCard(
            currentFlow: _tradeAmount,
            voltage: 230.0,
            frequency: 50.0,
            direction: PowerDirection.outgoing, // Always outgoing
            stability: 0.95,
          ),
          const SizedBox(height: 16),
          _buildTradeForm(),
          const SizedBox(height: 16),
          _buildLimitsCard(),
        ],
      ),
    );
  }

  Widget _buildTradeForm() {
    return Card(
      margin: EdgeInsets.zero,
      color: AppTheme.cardColor,
      shape: AppTheme.standardCardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sell Your Excess Power',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.warningYellow,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Current Sellback Rate: ₹3.80/kW',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _unitsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Units to Sell (kW)',
                border: const OutlineInputBorder(),
                suffixIcon: Icon(
                  Icons.bolt,
                  color: AppTheme.warningYellow,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _tradeAmount = double.tryParse(value) ?? 0;
                  _updateCalculations();
                });
              },
            ),
            if (_tradeAmount > 0) _buildCalculationDetails(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _isSellingActive 
                      ? AppTheme.warningYellow 
                      : AppTheme.warningYellow.withOpacity(0.3),
                ),
                onPressed: _tradeAmount > 0 ? _toggleSelling : null,
                child: Text(
                  _isSellingActive ? 'Stop Selling' : 'Start Selling',
                  style: TextStyle(
                    color: _isSellingActive ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (_isSellingActive) ...[
              const SizedBox(height: 16),
              _buildSellProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationDetails() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warningYellow.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Earnings Projection',
            style: TextStyle(
              color: AppTheme.warningYellow,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildEarningRow('Per Minute', _perMinuteEarnings),
          _buildEarningRow('Per Hour', _hourlyEarnings),
          _buildEarningRow('Per Day', _dailyProjection),
          if (_isSellingActive && _startTime != null) ...[
            const Divider(color: Colors.white24),
            _buildEarningRow(
              'Current Session',
              _calculateSessionEarnings(),
              subtitle: _getSessionDuration(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEarningRow(String label, double amount, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white70.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: AppTheme.warningYellow,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellProgressIndicator() {
    final progress = 1 - (_remainingAmount / _tradeAmount);
    final earnings = _calculateAmount(_tradeAmount);
    final hourlyEarnings = earnings * (60 / _simulationInterval);

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.warningYellow),
          backgroundColor: Colors.black12,
        ),
        const SizedBox(height: 8),
        Text(
          'Selling in progress... ${(_remainingAmount).toStringAsFixed(2)} kW remaining',
          style: TextStyle(color: AppTheme.warningYellow),
        ),
        Text(
          'Earning ₹${hourlyEarnings.toStringAsFixed(2)}/hr',
          style: TextStyle(
            color: AppTheme.warningYellow,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _toggleSelling() {
    setState(() {
      _isSellingActive = !_isSellingActive;
      if (_isSellingActive) {
        _startTime = DateTime.now();
        _startSellingSimulation();
      } else {
        _stopSellingSimulation();
        _startTime = null;
      }
    });
  }

  void _stopSellingSimulation() {
    setState(() {
      _isSellingActive = false;
    });
  }

  Widget _buildCurrentRateCard() {
    return Card(
      margin: EdgeInsets.zero,
      color: AppTheme.cardColor,
      shape: AppTheme.standardCardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Trading Rates',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildRateInfo('Buy Rate', '₹4.50/kW', Colors.green),
                _buildRateInfo('Sell Rate', '₹3.80/kW', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateInfo(String label, String rate, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        Text(
          rate,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLimitsCard() {
    return Card(
      margin: EdgeInsets.zero,
      color: AppTheme.cardColor,
      shape: AppTheme.standardCardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trading Limits',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildLimitRow(
              'Daily Limit',
              '${_tradingLimits['dailyLimit']?.toStringAsFixed(1)} kW',
              _usedDailyLimit / _tradingLimits['dailyLimit']!,
            ),
            _buildLimitRow(
              'Monthly Limit',
              '${_tradingLimits['monthlyLimit']?.toStringAsFixed(1)} kW',
              _usedMonthlyLimit / _tradingLimits['monthlyLimit']!,
            ),
            const Divider(color: Colors.white24),
            Text(
              'Min Trade: ${_tradingLimits['minTrade']?.toStringAsFixed(1)} kW',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Max Trade: ${_tradingLimits['maxTrade']?.toStringAsFixed(1)} kW',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitRow(String label, String limit, double used) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text('${used.toStringAsFixed(1)}/$limit', style: const TextStyle(color: Colors.white)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: used,
          backgroundColor: AppTheme.darkSecondaryColor.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.darkSecondaryColor),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Show Real Data'),
          value: _showRealData,
          onChanged: (value) {
            setState(() {
              _showRealData = value;
              _loadTradeHistory();
            });
          },
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _tradeHistory.length,
            itemBuilder: (context, index) => _buildTradeHistoryItem(
              trade: _tradeHistory[index],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTradeHistoryItem({required TradeData trade}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppTheme.cardColor,
      shape: AppTheme.standardCardTheme.shape,
      child: ListTile(
        leading: Icon(
          trade.isBuy ? Icons.arrow_downward : Icons.arrow_upward,
          color: trade.isBuy ? Colors.green : Colors.orange,
        ),
        title: Text(
          '${trade.isBuy ? "Bought" : "Sold"} ${trade.amount.toStringAsFixed(1)} kW',
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          IndianFormatter.formatTime(trade.timestamp), // Changed from date to timestamp
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Text(
          '₹${(trade.amount * (trade.isBuy ? 4.5 : 3.8)).toStringAsFixed(2)}',
          style: TextStyle(
            color: trade.isBuy ? Colors.green : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        title: const Text(
          'Error',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _updateCalculations() {
    if (_tradeAmount <= 0) return;

    final baseEarnings = _calculateEarnings(_tradeAmount);
    setState(() {
      // One minute earnings = base rate per kW for one minute
      _perMinuteEarnings = baseEarnings / 60; // Convert hourly rate to per minute
      _hourlyEarnings = baseEarnings; // Base earnings is already per hour
      _dailyProjection = baseEarnings * 24; // Multiply hourly by 24 for daily
    });
  }

  double _calculateEarnings(double units) {
    const sellRate = 3.80; // ₹3.80 per kWh
    return units * sellRate; // This gives hourly earnings
  }

  double _calculateSessionEarnings() {
    if (_startTime == null) return 0.0;
    final duration = DateTime.now().difference(_startTime!);
    final hoursElapsed = duration.inMinutes / 60.0; // Convert minutes to hours
    return _hourlyEarnings * hoursElapsed; // Multiply hourly rate by elapsed hours
  }

  String _getSessionDuration() {
    if (_startTime == null) return '';
    final duration = DateTime.now().difference(_startTime!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return 'Duration: ${hours}h ${minutes}m';
  }

  @override
  void dispose() {
    _sellTimer?.cancel();
    _startTime = null;
    super.dispose();
  }
}

class SaleCompletePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  SaleCompletePainter({required this.animation, required this.color}) 
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw electric current flow effect
    _drawElectricFlow(canvas, size, center);
    
    // Draw success circle with glow
    _drawSuccessCircle(canvas, center, size);
    
    // Draw particles
    _drawParticles(canvas, size, center);
  }

  void _drawElectricFlow(Canvas canvas, Size size, Offset center) {
    final flowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final arrowLength = size.height * 0.6;
    final arrowSpacing = size.width * 0.15;

    // Draw multiple parallel arrows like PowerFlowCard
    for (int i = -1; i <= 1; i++) {
      final xOffset = i * arrowSpacing;
      final startY = center.dy - arrowLength / 2;
      final endY = center.dy + arrowLength / 2;
      
      _drawUpwardArrow(canvas, center.dx + xOffset, endY, startY, flowPaint);
    }

    // Draw particles
    final particlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final particleGlowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);

    for (int i = -1; i <= 1; i++) {
      for (int j = 0; j < 3; j++) {
        final progress = (animation.value + j / 3) % 1.0;
        final x = center.dx + (i * arrowSpacing);
        final y = _lerp(center.dy + arrowLength / 2, center.dy - arrowLength / 2, progress);

        canvas.drawCircle(Offset(x, y), 6, particleGlowPaint);
        canvas.drawCircle(Offset(x, y), 3, particlePaint);
      }
    }
  }

  void _drawUpwardArrow(Canvas canvas, double x, double startY, double endY, Paint paint) {
    final path = Path()
      ..moveTo(x, startY)
      ..lineTo(x, endY + 15)
      ..moveTo(x - 10, endY + 15)
      ..lineTo(x, endY)
      ..lineTo(x + 10, endY + 15);
    canvas.drawPath(path, paint);
  }

  double _lerp(double start, double end, double progress) {
    return start + (end - start) * progress;
  }

  void _drawSuccessCircle(Canvas canvas, Offset center, Size size) {
    final circlePaint = Paint()
      ..color = color.withOpacity(animation.value * 0.2)
      ..style = PaintingStyle.fill;
    
    final glowPaint = Paint()
      ..color = color.withOpacity(animation.value * 0.1)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 20);
    
    final radius = size.width * 0.25 * animation.value;
    canvas.drawCircle(center, radius + 10, glowPaint);
    canvas.drawCircle(center, radius, circlePaint);
  }

  void _drawParticles(Canvas canvas, Size size, Offset center) {
    final particlePaint = Paint()
      ..color = color.withOpacity(animation.value)
      ..style = PaintingStyle.fill;

    final radius = size.width * 0.3;
    
    for (var i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi;
      final progress = (animation.value + i / 12) % 1.0;
      final distance = radius * progress;
      
      final position = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );
      
      canvas.drawCircle(position, 2, particlePaint);
    }
  }

  @override
  bool shouldRepaint(SaleCompletePainter oldDelegate) => true;
}
