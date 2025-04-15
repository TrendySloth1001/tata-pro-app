import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/indian_formatter.dart';
import '../services/storage_service.dart';

class CalculationDetailsCard extends StatelessWidget {
  final double consumedUnits;
  final double ratePerUnit;
  final double hours;
  final StorageService _storageService = StorageService();

   CalculationDetailsCard({
    super.key,
    required this.consumedUnits,
    required this.ratePerUnit,
    required this.hours,
  });

  Future<void> _saveCalculation(double total) async {
    final calculation = {
      'timestamp': DateTime.now().toIso8601String(),
      'units': consumedUnits,
      'rate': ratePerUnit,
      'hours': hours,
      'total': total,
    };
    
    await _storageService.saveCalculation(calculation);
  }

  @override
  Widget build(BuildContext context) {
    final bill = MumbaiTariffCalculator.calculateDetailedBill(consumedUnits);
    final slabBreakdown = MumbaiTariffCalculator.getSlabBreakdown(consumedUnits);

    // Save calculation when widget is built
    _saveCalculation(bill['total']!);

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
              Text(
                'Bill Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              
              // Slab Breakdown
              ...slabBreakdown.map((slab) => _buildSlabRow(
                '${slab['from']}-${slab['to']} units @ ₹${slab['rate'].toStringAsFixed(2)}',
                slab['amount'].toDouble(),
              )),
              
              const Divider(color: Colors.white24),
              _buildDetailRow(
                'Energy Charges',
                IndianFormatter.formatCurrency(bill['energyCharges']!),
              ),
              _buildDetailRow(
                'Fixed Charges',
                IndianFormatter.formatCurrency(bill['fixedCharge']!),
              ),
              _buildDetailRow(
                'Fuel Adjustment',
                IndianFormatter.formatCurrency(bill['fuelAdjustment']!),
              ),
              _buildDetailRow(
                'Electricity Duty',
                IndianFormatter.formatCurrency(bill['electricityDuty']!),
              ),
              _buildDetailRow(
                'Tax',
                IndianFormatter.formatCurrency(bill['tax']!),
              ),
              const Divider(color: Colors.white24),
              _buildDetailRow(
                'Total Amount',
                IndianFormatter.formatCurrency(bill['total']!),
                isTotal: true,
              ),
              const SizedBox(height: 8),
              _buildSavingsTips(bill['total']!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? AppTheme.darkSecondaryColor : Colors.white,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlabRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Text(
            IndianFormatter.formatCurrency(amount),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsTips(double amount) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.darkSecondaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.tips_and_updates,
            color: AppTheme.darkSecondaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You could save up to ${IndianFormatter.formatCurrency(amount * 0.3)} '
              'by shifting usage to off-peak hours',
              style: TextStyle(
                color: AppTheme.darkSecondaryColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
