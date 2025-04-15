import 'package:flutter/material.dart';
import '../../models/grid_status.dart';
import '../../utils/app_theme.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math' as math;

class GridAdminScreen extends StatefulWidget {
  const GridAdminScreen({super.key});

  @override
  State<GridAdminScreen> createState() => _GridAdminScreenState();
}

class _GridAdminScreenState extends State<GridAdminScreen> {
  final List<HouseholdData> _allHouseholds = List.generate(
    20,
    (i) => HouseholdData(
      uid: 'TPC${(i + 1).toString().padLeft(3, '0')}',
      address: '${i + 101}, Tata Residency, Block ${String.fromCharCode(65 + (i ~/ 5))}',
      currentUsage: (math.Random().nextDouble() * 5).roundToDouble(),
      monthlyAllocation: 150,
      status: i % 7 == 0 
          ? ConnectionStatus.warning 
          : i % 11 == 0 
              ? ConnectionStatus.inactive 
              : ConnectionStatus.active,
      powerQuality: 0.85 + (math.Random().nextDouble() * 0.15),
    ),
  );

  String _searchQuery = '';
  ConnectionStatus? _statusFilter;
  String? _blockFilter;
  bool _isLoading = false;
  Timer? _updateTimer;
  GridStatus? _gridStatus;
  Map<String, List<double>> _hourlyUsage = {};
  final Map<String, List<double>> _powerQualityData = {};
  final Map<String, List<double>> _voltageData = {};
  final Map<String, List<double>> _frequencyData = {};

  // Add new metrics maps
  final Map<String, List<HouseholdMetrics>> _dailyMetrics = {};
  final Map<String, double> _efficiencyScores = {};
  final Map<String, ConsumptionPattern> _consumptionPatterns = {};

  @override
  void initState() {
    super.initState();
    _loadGridStatus();
    _startRealtimeUpdates();
    _initializeMetrics();
    _analyzePowerUsage();
  }

  Future<void> _loadGridStatus() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call
    setState(() {
      _gridStatus = GridStatus(
        buildingId: 'BLDG001',
        totalCapacity: 1000.0,
        currentLoad: 750.0,
        sharedPool: 100.0,
        health: GridHealth.optimal,
        lastUpdated: DateTime.now(),
      );
      _isLoading = false;
    });
  }

  void _startRealtimeUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateUsageData();
    });
  }

  void _updateUsageData() {
    setState(() {
      for (var household in _allHouseholds) {
        final random = math.Random();
        final baseUsage = household.currentUsage;
        final fluctuation = (random.nextDouble() - 0.5) * 0.5; // ±0.25 kW
        
        _hourlyUsage.putIfAbsent(household.uid, () => []);
        _hourlyUsage[household.uid]!.add(baseUsage + fluctuation);
        
        if (_hourlyUsage[household.uid]!.length > 24) {
          _hourlyUsage[household.uid]!.removeAt(0);
        }
      }

      _gridStatus = GridStatus(
        buildingId: 'BLDG001',
        totalCapacity: 1000.0,
        currentLoad: _calculateTotalLoad(),
        sharedPool: _calculateSharedPool(),
        health: _determineGridHealth(),
        lastUpdated: DateTime.now(),
      );
    });
  }

  double _calculateTotalLoad() {
    return _allHouseholds
        .where((h) => h.status != ConnectionStatus.inactive)
        .fold(0.0, (sum, h) => sum + h.currentUsage);
  }

  double _calculateSharedPool() {
    return _allHouseholds
        .where((h) => h.status == ConnectionStatus.active)
        .fold(0.0, (sum, h) => sum + (h.monthlyAllocation - h.currentUsage))
        .clamp(0.0, double.infinity);
  }

  GridHealth _determineGridHealth() {
    final totalLoad = _calculateTotalLoad();
    final capacity = 1000.0;
    final loadFactor = totalLoad / capacity;
    
    if (loadFactor > 0.9) return GridHealth.critical;
    if (loadFactor > 0.7) return GridHealth.warning;
    return GridHealth.optimal;
  }

  void _initializeMetrics() {
    // Generate 24 hours of sample data for each metric
    final random = math.Random();
    for (var household in _allHouseholds) {
      _powerQualityData[household.uid] = List.generate(24, (i) => 
        0.95 + (random.nextDouble() * 0.1 - 0.05)); // 90-100% range
      
      _voltageData[household.uid] = List.generate(24, (i) => 
        230.0 + (random.nextDouble() * 10 - 5)); // 225-235V range
      
      _frequencyData[household.uid] = List.generate(24, (i) => 
        50.0 + (random.nextDouble() * 0.4 - 0.2)); // 49.8-50.2Hz range
    }
  }

  void _analyzePowerUsage() {
    for (var household in _allHouseholds) {
      // Calculate efficiency score (0-100)
      _efficiencyScores[household.uid] = _calculateEfficiencyScore(household);
      
      // Analyze consumption patterns
      _consumptionPatterns[household.uid] = _analyzeConsumptionPattern(household);
      
      // Generate daily metrics
      _dailyMetrics[household.uid] = List.generate(7, (index) {
        return _generateDailyMetrics(household, index);
      });
    }
  }

  double _calculateEfficiencyScore(HouseholdData household) {
    double score = 100.0;
    
    // Deduct points for high usage relative to allocation
    final usageRatio = household.currentUsage / household.monthlyAllocation;
    if (usageRatio > 0.8) score -= 20;
    if (usageRatio > 0.9) score -= 20;
    
    // Deduct points for poor power quality
    if (household.powerQuality < 0.95) score -= 15;
    if (household.powerQuality < 0.9) score -= 15;
    
    // Adjust for status
    if (household.status == ConnectionStatus.warning) score -= 25;
    if (household.status == ConnectionStatus.inactive) score -= 50;
    
    return math.max(0, score);
  }

  ConsumptionPattern _analyzeConsumptionPattern(HouseholdData household) {
    final hourlyData = _hourlyUsage[household.uid] ?? [];
    if (hourlyData.isEmpty) {
      return ConsumptionPattern.unknown;
    }

    int peakHours = 0;
    int offPeakHours = 0;

    for (var i = 0; i < hourlyData.length; i++) {
      final hour = i % 24;
      final usage = hourlyData[i];

      if (hour >= 9 && hour <= 17) { // Daytime hours
        if (usage > household.monthlyAllocation / 30 / 24 * 1.5) {
          peakHours++;
        }
      } else if ((hour >= 23 || hour <= 5)) { // Night hours
        if (usage < household.monthlyAllocation / 30 / 24 * 0.5) {
          offPeakHours++;
        }
      }
    }

    if (peakHours > offPeakHours * 2) {
      return ConsumptionPattern.dayPeaked;
    } else if (offPeakHours > peakHours * 2) {
      return ConsumptionPattern.nightPeaked;
    }
    return ConsumptionPattern.balanced;
  }

  HouseholdMetrics _generateDailyMetrics(HouseholdData household, int daysAgo) {
    final random = math.Random(household.uid.hashCode + daysAgo);
    return HouseholdMetrics(
      date: DateTime.now().subtract(Duration(days: daysAgo)),
      peakUsage: household.currentUsage * (1 + random.nextDouble() * 0.3),
      avgUsage: household.currentUsage * (0.7 + random.nextDouble() * 0.3),
      powerFactor: 0.9 + random.nextDouble() * 0.1,
      cost: household.currentUsage * 3.8 * 24 * (0.8 + random.nextDouble() * 0.4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  if (_gridStatus != null) ...[
                    _buildGridStatusCard(),
                    const SizedBox(height: 16),
                    _buildSupplyOverviewCard(),
                    const SizedBox(height: 16),
                  ],
                  _buildFilterChips(),
                ],
              ),
            ),
          ),
          _buildHouseholdsList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddHouseholdDialog(),
        backgroundColor: AppTheme.darkSecondaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppTheme.backgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Grid Administration'),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkPrimaryColor.withOpacity(0.6),
                AppTheme.backgroundColor,
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => setState(() {}),
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () => _showFilterDialog(),
        ),
      ],
    );
  }

  Widget _buildGridStatusCard() {
    return Card(
      color: AppTheme.cardColor,
      shape: AppTheme.standardCardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Grid Status',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(GridHealth.optimal),
              ],
            ),
            const SizedBox(height: 16),
            _buildLoadIndicator(
              'Total Load',
              0.75,
              '750 kW / 1000 kW',
              AppTheme.darkSecondaryColor,
            ),
            const SizedBox(height: 8),
            _buildLoadIndicator(
              'Power Quality',
              0.95,
              '95%',
              AppTheme.warningYellow,
            ),
            const Divider(color: Colors.white24),
            _buildPowerQualityMetrics(),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplyOverviewCard() {
    return Card(
      color: AppTheme.cardColor,
      shape: AppTheme.standardCardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supply Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricBox(
                  'Active\nConnections',
                  '48',
                  Icons.power,
                  AppTheme.darkSecondaryColor,
                ),
                _buildMetricBox(
                  'Current\nDemand',
                  '750 kW',
                  Icons.show_chart,
                  AppTheme.warningYellow,
                ),
                _buildMetricBox(
                  'Peak\nLoad',
                  '850 kW',
                  Icons.trending_up,
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHouseholdsList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Connected Households',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }
          final household = _filteredHouseholds[index - 1];
          return _buildHouseholdCard(household);
        },
        childCount: _filteredHouseholds.length + 1,
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search by UID or Address',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppTheme.cardColor,
      ),
      onChanged: (value) {
        setState(() => _searchQuery = value);
      },
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      children: [
        FilterChip(
          label: const Text('All'),
          selected: _statusFilter == null,
          onSelected: (selected) {
            setState(() => _statusFilter = null);
          },
        ),
        FilterChip(
          label: const Text('Active'),
          selected: _statusFilter == ConnectionStatus.active,
          onSelected: (selected) {
            setState(() => _statusFilter = selected ? ConnectionStatus.active : null);
          },
        ),
        FilterChip(
          label: const Text('Warning'),
          selected: _statusFilter == ConnectionStatus.warning,
          onSelected: (selected) {
            setState(() => _statusFilter = selected ? ConnectionStatus.warning : null);
          },
        ),
        FilterChip(
          label: const Text('Inactive'),
          selected: _statusFilter == ConnectionStatus.inactive,
          onSelected: (selected) {
            setState(() => _statusFilter = selected ? ConnectionStatus.inactive : null);
          },
        ),
      ],
    );
  }

  List<HouseholdData> get _filteredHouseholds {
    return _allHouseholds.where((household) {
      final matchesSearch = household.uid.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          household.address.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _statusFilter == null || household.status == _statusFilter;
      final matchesBlock = _blockFilter == null || 
                          household.address.contains('Block $_blockFilter');
      return matchesSearch && matchesStatus && matchesBlock;
    }).toList();
  }

  void _showAddHouseholdDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        title: const Text('Add New Household'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'UID'),
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Monthly Allocation (kW)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Implement household addition
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        title: const Text('Filter Households'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add filter options here
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHouseholdDetails(HouseholdData household) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        title: Row(
          children: [
            Icon(
              Icons.account_circle,
              color: AppTheme.darkSecondaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(household.uid),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildDetailGroup('Location', [
                _buildDetailItem('Address', household.address),
                _buildDetailItem('Block', household.address.split('Block ').last),
              ]),
              const SizedBox(height: 16),
              _buildDetailGroup('Power Usage', [
                _buildDetailItem('Current Usage', 
                    '${household.currentUsage.toStringAsFixed(1)} kW'),
                _buildDetailItem('Monthly Allocation', 
                    '${household.monthlyAllocation.toStringAsFixed(1)} kW'),
                _buildDetailItem('Power Quality', 
                    '${(household.powerQuality * 100).toStringAsFixed(1)}%'),
              ]),
              const SizedBox(height: 16),
              _buildDetailGroup('Statistics', [
                _buildDetailItem('Peak Usage Today', 
                    '${(_hourlyUsage[household.uid]?.reduce(math.max) ?? 0).toStringAsFixed(1)} kW'),
                _buildDetailItem('Average Usage', 
                    '${(_hourlyUsage[household.uid]?.average ?? 0).toStringAsFixed(1)} kW'),
              ]),
              if (_hourlyUsage[household.uid] != null) ...[
                const SizedBox(height: 16),
                _buildUsageGraph(household.uid),
              ],
              const SizedBox(height: 16),
              _buildConsumptionPatternCard(household),
              const SizedBox(height: 16),
              _buildComparisonMetrics(household),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _showActionSheet(context, household),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.admin_panel_settings, 
                    color: AppTheme.darkSecondaryColor),
                const SizedBox(width: 8),
                const Text('Actions'),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseholdCard(HouseholdData household) {
    final statusColors = {
      ConnectionStatus.active: AppTheme.darkSecondaryColor,
      ConnectionStatus.inactive: Colors.grey,
      ConnectionStatus.warning: AppTheme.warningYellow,
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.cardColor,
      shape: AppTheme.standardCardTheme.shape,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Icon(
              Icons.circle,
              size: 12,
              color: statusColors[household.status],
            ),
            const SizedBox(width: 8),
            Text(
              household.uid, // Only show UID
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${household.currentUsage.toStringAsFixed(1)} kW',
              style: TextStyle(color: AppTheme.darkSecondaryColor),
            ),
            Text(
              'PQ: ${(household.powerQuality * 100).toStringAsFixed(0)}%',
              style: TextStyle(color: AppTheme.warningYellow),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showHouseholdDetails(household),
        ),
      ),
    );
  }

  Widget _buildStatusChip(GridHealth status) {
    final labels = {
      GridHealth.optimal: 'Optimal',
      GridHealth.warning: 'Warning',
      GridHealth.critical: 'Critical',
    };

    final colors = {
      GridHealth.optimal: AppTheme.darkSecondaryColor,
      GridHealth.warning: AppTheme.warningYellow,
      GridHealth.critical: Colors.red,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors[status]!.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors[status]!.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 12,
            color: colors[status],
          ),
          const SizedBox(width: 6),
          Text(
            labels[status]!,
            style: TextStyle(
              color: colors[status],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadIndicator(String label, double value, String text, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              text,
              style: TextStyle(color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildMetricBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showActionSheet(BuildContext context, HouseholdData household) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundColor,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.power_settings_new),
              title: const Text('Toggle Power'),
              onTap: () {
                // Implement power toggle
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Allocation'),
              onTap: () {
                Navigator.pop(context);
                _showAllocationDialog(household);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.warning_amber,
                color: AppTheme.warningYellow,
              ),
              title: const Text('Send Warning'),
              onTap: () {
                Navigator.pop(context);
                _showWarningDialog(household);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAllocationDialog(HouseholdData household) {
    final controller = TextEditingController(
      text: household.monthlyAllocation.toString()
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        title: const Text('Edit Monthly Allocation'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Monthly Allocation (kW)',
            suffix: Text('kW'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // Implement allocation update
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showWarningDialog(HouseholdData household) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        title: Row(
          children: [
            Icon(
              Icons.warning_amber,
              color: AppTheme.warningYellow,
            ),
            const SizedBox(width: 8),
            const Text('Send Warning'),
          ],
        ),
        content: const TextField(
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Warning Message',
            hintText: 'Enter warning message...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // Implement warning send
              Navigator.pop(context);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Widget _buildDetailGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppTheme.darkSecondaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
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
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageGraph(String householdId) {
    final usage = _hourlyUsage[householdId] ?? [];
    if (usage.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 200,
      child: CustomPaint(
        painter: UsageGraphPainter(
          data: usage,
          maxValue: usage.reduce(math.max),
          color: AppTheme.darkSecondaryColor,
        ),
      ),
    );
  }

  Widget _buildPowerQualityMetrics() {
    final avgVoltage = _calculateAverageVoltage();
    final avgFrequency = _calculateAverageFrequency();
    final avgPowerFactor = _calculateAveragePowerFactor();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Power Quality Metrics',
            style: TextStyle(
              color: AppTheme.darkSecondaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQualityMetric(
                'Voltage',
                '${avgVoltage.toStringAsFixed(1)}V',
                _getVoltageStatus(avgVoltage),
              ),
              _buildQualityMetric(
                'Frequency',
                '${avgFrequency.toStringAsFixed(2)}Hz',
                _getFrequencyStatus(avgFrequency),
              ),
              _buildQualityMetric(
                'Power Factor',
                avgPowerFactor.toStringAsFixed(2),
                _getPowerFactorStatus(avgPowerFactor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQualityMetric(String label, String value, MetricStatus status) {
    final colors = {
      MetricStatus.good: AppTheme.darkSecondaryColor,
      MetricStatus.warning: AppTheme.warningYellow,
      MetricStatus.critical: Colors.red,
    };

    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: colors[status],
            fontWeight: FontWeight.bold,
          ),
        ),
        Icon(
          status == MetricStatus.good ? Icons.check_circle :
          status == MetricStatus.warning ? Icons.warning :
          Icons.error,
          color: colors[status],
          size: 16,
        ),
      ],
    );
  }

  double _calculateAverageVoltage() {
    if (_voltageData.isEmpty) return 230.0;
    final allReadings = _voltageData.values
        .expand((readings) => readings)
        .toList();
    return allReadings.reduce((a, b) => a + b) / allReadings.length;
  }

  double _calculateAverageFrequency() {
    if (_frequencyData.isEmpty) return 50.0;
    final allReadings = _frequencyData.values
        .expand((readings) => readings)
        .toList();
    return allReadings.reduce((a, b) => a + b) / allReadings.length;
  }

  double _calculateAveragePowerFactor() {
    if (_powerQualityData.isEmpty) return 0.95;
    final allReadings = _powerQualityData.values
        .expand((readings) => readings)
        .toList();
    return allReadings.reduce((a, b) => a + b) / allReadings.length;
  }

  MetricStatus _getVoltageStatus(double voltage) {
    if (voltage < 220 || voltage > 240) return MetricStatus.critical;
    if (voltage < 225 || voltage > 235) return MetricStatus.warning;
    return MetricStatus.good;
  }

  MetricStatus _getFrequencyStatus(double frequency) {
    if (frequency < 49.5 || frequency > 50.5) return MetricStatus.critical;
    if (frequency < 49.8 || frequency > 50.2) return MetricStatus.warning;
    return MetricStatus.good;
  }

  MetricStatus _getPowerFactorStatus(double pf) {
    if (pf < 0.85) return MetricStatus.critical;
    if (pf < 0.9) return MetricStatus.warning;
    return MetricStatus.good;
  }

  // Add new widget to show consumption patterns
  Widget _buildConsumptionPatternCard(HouseholdData household) {
    final pattern = _consumptionPatterns[household.uid] ?? ConsumptionPattern.unknown;
    final metrics = _dailyMetrics[household.uid] ?? [];
    
    return Card(
      color: AppTheme.cardColor,
      shape: AppTheme.standardCardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consumption Analysis',
              style: TextStyle(
                color: AppTheme.darkSecondaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPatternIndicator(pattern),
            const SizedBox(height: 16),
            if (metrics.isNotEmpty) _buildUsageTrendGraph(metrics),
            const SizedBox(height: 16),
            _buildEfficiencyScore(household),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternIndicator(ConsumptionPattern pattern) {
    final labels = {
      ConsumptionPattern.balanced: 'Balanced',
      ConsumptionPattern.dayPeaked: 'Day Peaked',
      ConsumptionPattern.nightPeaked: 'Night Peaked',
      ConsumptionPattern.unknown: 'Unknown',
    };

    final colors = {
      ConsumptionPattern.balanced: AppTheme.darkSecondaryColor,
      ConsumptionPattern.dayPeaked: AppTheme.warningYellow,
      ConsumptionPattern.nightPeaked: Colors.blue,
      ConsumptionPattern.unknown: Colors.grey,
    };

    return Row(
      children: [
        Icon(
          Icons.circle,
          size: 12,
          color: colors[pattern],
        ),
        const SizedBox(width: 8),
        Text(
          labels[pattern]!,
          style: TextStyle(
            color: colors[pattern],
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildUsageTrendGraph(List<HouseholdMetrics> metrics) {
    return SizedBox(
      height: 200,
      child: CustomPaint(
        painter: UsageTrendGraphPainter(
          data: metrics,
          color: AppTheme.darkSecondaryColor,
        ),
      ),
    );
  }

  Widget _buildEfficiencyScore(HouseholdData household) {
    final score = _efficiencyScores[household.uid] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Efficiency Score',
          style: TextStyle(
            color: AppTheme.darkSecondaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: score / 100,
          backgroundColor: AppTheme.darkSecondaryColor.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.darkSecondaryColor),
        ),
        const SizedBox(height: 8),
        Text(
          '${score.toStringAsFixed(1)} / 100',
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildComparisonMetrics(HouseholdData household) {
    final avgUsage = _calculateAverageUsage();
    final householdUsage = household.currentUsage;
    final percentDiff = ((householdUsage - avgUsage) / avgUsage * 100).abs();
    
    return Card(
      color: AppTheme.cardColor,
      shape: AppTheme.standardCardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparison Metrics',
              style: TextStyle(
                color: AppTheme.darkSecondaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildComparisonRow(
              'vs. Building Average',
              householdUsage,
              avgUsage,
              percentDiff,
            ),
            const SizedBox(height: 8),
            _buildEfficiencyRanking(household),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(String label, double value1, double value2, double percentDiff) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            '${value1.toStringAsFixed(1)} kW',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Text(
            '${percentDiff.toStringAsFixed(1)}%',
            style: TextStyle(
              color: percentDiff > 0 ? Colors.red : AppTheme.darkSecondaryColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildEfficiencyRanking(HouseholdData household) {
    final score = _efficiencyScores[household.uid] ?? 0.0;
    final rank = _calculateEfficiencyRank(household);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Efficiency Ranking',
          style: TextStyle(
            color: AppTheme.darkSecondaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Rank: $rank',
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: score / 100,
          backgroundColor: AppTheme.darkSecondaryColor.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.darkSecondaryColor),
        ),
        const SizedBox(height: 8),
        Text(
          '${score.toStringAsFixed(1)} / 100',
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  double _calculateAverageUsage() {
    if (_allHouseholds.isEmpty) return 0.0;
    final totalUsage = _allHouseholds.fold(0.0, (sum, h) => sum + h.currentUsage);
    return totalUsage / _allHouseholds.length;
  }

  int _calculateEfficiencyRank(HouseholdData household) {
    final scores = _efficiencyScores.values.toList()..sort((a, b) => b.compareTo(a));
    return scores.indexOf(_efficiencyScores[household.uid]!) + 1;
  }
}

// Add new classes at the end of the file
class HouseholdData {
  final String uid;
  final String address;
  final double currentUsage;
  final double monthlyAllocation;
  final ConnectionStatus status;
  final double powerQuality;

  HouseholdData({
    required this.uid,
    required this.address,
    required this.currentUsage,
    required this.monthlyAllocation,
    required this.status,
    required this.powerQuality,
  });
}

enum ConnectionStatus { active, inactive, warning }

extension ListAverage on List<double> {
  double get average => isEmpty ? 0 : reduce((a, b) => a + b) / length;
}

class UsageGraphPainter extends CustomPainter {
  final List<double> data;
  final double maxValue;
  final Color color;

  UsageGraphPainter({
    required this.data,
    required this.maxValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final xStep = width / (data.length - 1);

    for (var i = 0; i < data.length; i++) {
      final x = i * xStep;
      final y = height - (data[i] / maxValue * height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw the line
    canvas.drawPath(path, paint);

    // Draw area under the line
    final areaPath = Path.from(path)
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();

    canvas.drawPath(
      areaPath,
      Paint()
        ..color = color.withOpacity(0.1)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant UsageGraphPainter oldDelegate) =>
      data != oldDelegate.data ||
      maxValue != oldDelegate.maxValue ||
      color != oldDelegate.color;
}

enum MetricStatus { good, warning, critical }

enum ConsumptionPattern {
  balanced,
  dayPeaked,
  nightPeaked,
  unknown
}

class HouseholdMetrics {
  final DateTime date;
  final double peakUsage;
  final double avgUsage;
  final double powerFactor;
  final double cost;

  HouseholdMetrics({
    required this.date,
    required this.peakUsage,
    required this.avgUsage,
    required this.powerFactor,
    required this.cost,
  });
}

class UsageTrendGraphPainter extends CustomPainter {
  final List<HouseholdMetrics> data;
  final Color color;

  UsageTrendGraphPainter({
    required this.data,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final xStep = width / (data.length - 1);

    for (var i = 0; i < data.length; i++) {
      final x = i * xStep;
      final y = height - (data[i].avgUsage / data.map((e) => e.avgUsage).reduce(math.max) * height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw the line
    canvas.drawPath(path, paint);

    // Draw area under the line
    final areaPath = Path.from(path)
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();

    canvas.drawPath(
      areaPath,
      Paint()
        ..color = color.withOpacity(0.1)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant UsageTrendGraphPainter oldDelegate) =>
      data != oldDelegate.data ||
      color != oldDelegate.color;
}
