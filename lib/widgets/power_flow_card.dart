import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class PowerFlowCard extends StatefulWidget {
  final double currentFlow;
  final double voltage;
  final double frequency;
  final PowerDirection direction;
  final double stability;

  const PowerFlowCard({
    super.key,
    required this.currentFlow,
    required this.voltage,
    required this.frequency,
    required this.direction,
    required this.stability,
  });

  @override
  State<PowerFlowCard> createState() => _PowerFlowCardState();
}

class _PowerFlowCardState extends State<PowerFlowCard> with SingleTickerProviderStateMixin {
  late AnimationController _flowAnimationController;

  @override
  void initState() {
    super.initState();
    _flowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // Slower animation
    )..repeat();
  }

  @override
  void dispose() {
    _flowAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppTheme.cardColor,
      shape: AppTheme.standardCardTheme.shape,
      child: Column(
        children: [
          _buildHeader(),
          SizedBox(
            height: 300,
            child: _buildFlowVisualization(),
          ),
          _buildMetricsGrid(),
          const Divider(color: Colors.white24),
          _buildDetailSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.darkSecondaryColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Power Flow',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          _buildStatusChip(),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.direction == PowerDirection.incoming
            ? AppTheme.darkSecondaryColor.withOpacity(0.2)
            : AppTheme.warningYellow.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.direction == PowerDirection.incoming
              ? AppTheme.darkSecondaryColor
              : AppTheme.warningYellow,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.direction == PowerDirection.incoming
                ? Icons.arrow_downward
                : Icons.arrow_upward,
            size: 16,
            color: widget.direction == PowerDirection.incoming
                ? AppTheme.darkSecondaryColor
                : AppTheme.warningYellow,
          ),
          const SizedBox(width: 4),
          Text(
            widget.direction == PowerDirection.incoming ? 'Buying' : 'Selling',
            style: TextStyle(
              color: widget.direction == PowerDirection.incoming
                  ? AppTheme.darkSecondaryColor
                  : AppTheme.warningYellow,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowVisualization() {
    return SizedBox(
      width: 200,
      height: 200,
      child: AnimatedBuilder(
        animation: _flowAnimationController,
        builder: (context, child) {
          return CustomPaint(
            painter: PowerFlowPainter(
              direction: widget.direction,
              flowRate: widget.currentFlow,
              animationValue: _flowAnimationController.value,
              stabilityLevel: widget.stability,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem('Voltage', '${widget.voltage.toStringAsFixed(1)}V', Icons.electric_bolt),
          _buildMetricItem('Frequency', '${widget.frequency.toStringAsFixed(2)}Hz', Icons.radio_button_checked),
          _buildMetricItem('Flow Rate', '${widget.currentFlow.toStringAsFixed(1)}kW', Icons.speed),
        ],
      ),
    );
  }

  Widget _buildDetailSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDetailsCard('Flow Details', [
            _buildDetailRow('Status', widget.direction == PowerDirection.incoming ? 'Active Import' : 'Active Export'),
            _buildDetailRow('Grid Load', '${(widget.currentFlow * 100 / widget.stability).toStringAsFixed(1)}%'),
            _buildDetailRow('Quality', '${(widget.stability * 100).toStringAsFixed(1)}%'),
          ]),
          const SizedBox(height: 16),
          _buildDetailsCard('Statistics', [
            _buildDetailRow('Power Quality', '${(widget.stability * 100).toStringAsFixed(1)}%'),
            _buildDetailRow('Grid Load', '${(widget.currentFlow * 100 / widget.stability).toStringAsFixed(1)}%'),
            _buildDetailRow('Peak Hours', widget.currentFlow > 4.0 ? 'Active' : 'Inactive'),
          ]),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkSecondaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
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
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.darkSecondaryColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class PowerFlowPainter extends CustomPainter {
  final PowerDirection direction;
  final double flowRate;
  final double animationValue;
  final double stabilityLevel;

  PowerFlowPainter({
    required this.direction,
    required this.flowRate,
    required this.animationValue,
    required this.stabilityLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw vertical information lines
    _drawTransferInfo(canvas, size);
    
    // Draw background glow
    _drawBackgroundGlow(canvas, size, center);
    
    // Draw main flow arrows and particles
    _drawFlowArrows(canvas, size, center);
    _drawFlowParticles(canvas, size, center);
  }

  void _drawTransferInfo(Canvas canvas, Size size) {
    final infoLinePaint = Paint()
      ..color = direction == PowerDirection.incoming
          ? AppTheme.darkSecondaryColor.withOpacity(0.5)
          : AppTheme.warningYellow.withOpacity(0.5)
      ..strokeWidth = 2;

    final textPaint = Paint()
      ..color = direction == PowerDirection.incoming
          ? AppTheme.darkSecondaryColor
          : AppTheme.warningYellow;

    // Left vertical line for power flow percentage
    final leftLine = Offset(size.width * 0.15, size.height * 0.2);
    canvas.drawLine(
      leftLine,
      Offset(leftLine.dx, size.height * 0.8),
      infoLinePaint,
    );

    // Calculate actual percentage based on flowRate
    final actualPercentage = (flowRate / 10.0) * 100; // Assuming max flow is 10kW
    final progress = math.min(actualPercentage / 100, 1.0); // Ensure we don't exceed 100%

    // Draw percentage markers with updated position indicator
    for (var i = 0; i <= 100; i += 20) {
      final y = size.height * (0.8 - (i / 100) * 0.6);
      canvas.drawLine(
        Offset(leftLine.dx - 5, y),
        Offset(leftLine.dx + 5, y),
        infoLinePaint,
      );

      // Create new ParagraphBuilder for each text
      final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
        fontSize: 12,
        textAlign: TextAlign.right,
      ))
        ..pushStyle(ui.TextStyle(color: textPaint.color))
        ..addText('$i%');

      final paragraph = paragraphBuilder.build()
        ..layout(const ui.ParagraphConstraints(width: 30));
      canvas.drawParagraph(
        paragraph,
        Offset(leftLine.dx - 35, y - paragraph.height / 2),
      );
    }

    // Draw current progress indicator based on actual flow
    final progressY = size.height * (0.8 - progress * 0.6);
    
    // Draw glow effect
    final glowPaint = Paint()
      ..color = textPaint.color.withOpacity(0.3)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8);
    
    // Draw larger glow circle
    canvas.drawCircle(
      Offset(leftLine.dx, progressY),
      6,
      glowPaint,
    );
    
    // Draw actual indicator
    canvas.drawCircle(
      Offset(leftLine.dx, progressY),
      4,
      Paint()..color = textPaint.color,
    );

    // Draw percentage text next to indicator
    final percentageBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      fontSize: 14,
      textAlign: TextAlign.left,
    ))
      ..pushStyle(ui.TextStyle(
        color: textPaint.color,
        fontWeight: ui.FontWeight.bold,
      ))
      ..addText('${actualPercentage.toStringAsFixed(1)}%');

    final percentageParagraph = percentageBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: 60));
    canvas.drawParagraph(
      percentageParagraph,
      Offset(leftLine.dx + 10, progressY - percentageParagraph.height / 2),
    );

    // Continue with right vertical line for amount
    final rightLine = Offset(size.width * 0.85, size.height * 0.2);
    canvas.drawLine(
      rightLine,
      Offset(rightLine.dx, size.height * 0.8),
      infoLinePaint,
    );

    // Draw amount markers
    final maxAmount = 1000.0;
    for (var i = 0; i <= maxAmount; i += 200) {
      final y = size.height * (0.8 - (i / maxAmount) * 0.6);
      canvas.drawLine(
        Offset(rightLine.dx - 5, y),
        Offset(rightLine.dx + 5, y),
        infoLinePaint,
      );

      // Create new ParagraphBuilder for each text
      final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
        fontSize: 12,
        textAlign: TextAlign.left,
      ))
        ..pushStyle(ui.TextStyle(color: textPaint.color))
        ..addText('₹$i');

      final paragraph = paragraphBuilder.build()
        ..layout(const ui.ParagraphConstraints(width: 50));
      canvas.drawParagraph(
        paragraph,
        Offset(rightLine.dx + 10, y - paragraph.height / 2),
      );
    }

    // Draw current amount indicator
    final amountProgress = (flowRate * 10) / maxAmount;
    final amountY = size.height * (0.8 - amountProgress * 0.6);
    canvas.drawCircle(
      Offset(rightLine.dx, amountY),
      4,
      Paint()..color = textPaint.color,
    );
  }

  void _drawBackgroundGlow(Canvas canvas, Size size, Offset center) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          direction == PowerDirection.incoming
              ? AppTheme.darkSecondaryColor.withOpacity(0.2)
              : AppTheme.warningYellow.withOpacity(0.2),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width / 2));

    canvas.drawCircle(center, size.width / 2, glowPaint);
  }

  void _drawFlowArrows(Canvas canvas, Size size, Offset center) {
    final arrowPaint = Paint()
      ..color = direction == PowerDirection.incoming
          ? AppTheme.darkSecondaryColor
          : AppTheme.warningYellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final arrowLength = size.height * 0.6;
    final arrowSpacing = size.width * 0.15;
    
    // Draw multiple parallel arrows
    for (int i = -1; i <= 1; i++) {
      final xOffset = i * arrowSpacing;
      final startY = center.dy - arrowLength / 2;
      final endY = center.dy + arrowLength / 2;
      
      if (direction == PowerDirection.incoming) {
        _drawDownwardArrow(canvas, center.dx + xOffset, startY, endY, arrowPaint);
      } else {
        _drawUpwardArrow(canvas, center.dx + xOffset, endY, startY, arrowPaint);
      }
    }
  }

  void _drawDownwardArrow(Canvas canvas, double x, double startY, double endY, Paint paint) {
    final path = Path()
      ..moveTo(x, startY)
      ..lineTo(x, endY - 15)
      ..moveTo(x - 10, endY - 15)
      ..lineTo(x, endY)
      ..lineTo(x + 10, endY - 15);
    canvas.drawPath(path, paint);
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

  void _drawFlowParticles(Canvas canvas, Size size, Offset center) {
    final particlePaint = Paint()
      ..color = direction == PowerDirection.incoming
          ? AppTheme.darkSecondaryColor
          : AppTheme.warningYellow;

    final particleGlowPaint = Paint()
      ..color = particlePaint.color.withOpacity(0.3)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);

    final arrowSpacing = size.width * 0.15;
    final arrowLength = size.height * 0.6;

    for (int i = -1; i <= 1; i++) {
      for (int j = 0; j < 3; j++) {
        final progress = (animationValue + j / 3) % 1.0;
        final x = center.dx + (i * arrowSpacing);
        final y = direction == PowerDirection.incoming
            ? _lerp(center.dy - arrowLength / 2, center.dy + arrowLength / 2, progress)
            : _lerp(center.dy + arrowLength / 2, center.dy - arrowLength / 2, progress);

        canvas.drawCircle(Offset(x, y), 6, particleGlowPaint);
        canvas.drawCircle(Offset(x, y), 3, particlePaint);
      }
    }
  }

  double _lerp(double start, double end, double progress) {
    return start + (end - start) * progress;
  }

  @override
  bool shouldRepaint(covariant PowerFlowPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.direction != direction ||
      oldDelegate.flowRate != flowRate ||
      oldDelegate.stabilityLevel != stabilityLevel;
}

enum PowerDirection { incoming, outgoing }
