import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gateletics/providers/providers.dart';
import '../../../../utils/ui_scaling.dart';

class PieChartPainter extends CustomPainter {
  final List<CategoryStudyTime> sections;
  final double animValue;

  PieChartPainter({required this.sections, required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -pi / 2;

    for (final s in sections) {
      final sweepAngle = (s.percentage / 100) * 2 * pi * animValue;
      if (sweepAngle <= 0) continue;

      final paint = Paint()
        ..color = Color(s.colorValue)
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) {
    return oldDelegate.animValue != animValue || oldDelegate.sections != sections;
  }
}

class HistoryPieChart extends StatefulWidget {
  final List<CategoryStudyTime> categoriesStudy;
  final Color accentColor;

  const HistoryPieChart({
    super.key,
    required this.categoriesStudy,
    required this.accentColor,
  });

  @override
  State<HistoryPieChart> createState() => _HistoryPieChartState();
}

class _HistoryPieChartState extends State<HistoryPieChart> with SingleTickerProviderStateMixin {
  late AnimationController _chartDataAnimController;

  @override
  void initState() {
    super.initState();
    _chartDataAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _chartDataAnimController.forward();
  }

  @override
  void dispose() {
    _chartDataAnimController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HistoryPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoriesStudy != widget.categoriesStudy) {
      _chartDataAnimController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categoriesStudy.isEmpty) {
      return Container(
        padding: EdgeInsets.all(context.s(12)),
        decoration: BoxDecoration(
          color: const Color(0xFF131316),
          borderRadius: BorderRadius.circular(context.s(16)),
          border: Border.all(color: Colors.white.withAlpha(8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'FOCUS AREA DISTRIBUTION',
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: context.s(11),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            SizedBox(height: context.s(20)),
            Center(
              child: Text(
                'Complete syllabus tasks during your focus sessions to build your distribution chart.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: context.s(12),
                ),
              ),
            ),
            SizedBox(height: context.s(10)),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(context.s(12)),
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        borderRadius: BorderRadius.circular(context.s(16)),
        border: Border.all(color: Colors.white.withAlpha(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'FOCUS AREA DISTRIBUTION',
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: context.s(11),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          SizedBox(height: context.s(14)),
          Row(
            children: [
              SizedBox(
                width: context.s(90),
                height: context.s(90),
                child: AnimatedBuilder(
                  animation: _chartDataAnimController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: PieChartPainter(
                        sections: widget.categoriesStudy,
                        animValue: _chartDataAnimController.value,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: context.s(16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.categoriesStudy.take(4).map((c) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: context.s(3)),
                      child: Row(
                        children: [
                          Container(
                            width: context.s(8),
                            height: context.s(8),
                            decoration: BoxDecoration(
                              color: Color(c.colorValue),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: context.s(6)),
                          Expanded(
                            child: Text(
                              c.name,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: context.s(11),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: context.s(6)),
                          Text(
                            '${c.percentage.toStringAsFixed(0)}%',
                            style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: context.s(11),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
