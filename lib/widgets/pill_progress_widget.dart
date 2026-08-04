import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/theme_context_ext.dart';
import 'package:gateletics/providers/providers.dart';
import '../utils/ui_scaling.dart';

class PillProgressWidget extends ConsumerStatefulWidget {
  final double percentage;
  final int totalCompleted;
  final int totalVideos;

  const PillProgressWidget({
    super.key,
    required this.percentage,
    required this.totalCompleted,
    required this.totalVideos,
  });

  @override
  ConsumerState<PillProgressWidget> createState() => _PillProgressWidgetState();
}

class _PillProgressWidgetState extends ConsumerState<PillProgressWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = Tween<double>(
      begin: 0,
      end: widget.percentage / 100,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(PillProgressWidget old) {
    super.didUpdateWidget(old);
    if (old.percentage != widget.percentage) {
      _anim = Tween<double>(
        begin: _anim.value,
        end: widget.percentage / 100,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _cycleColor() {
    ref.read(overallProgressColorProvider.notifier).next();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _cycleColor,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final screenWidth = MediaQuery.of(context).size.width;
          final w = (screenWidth * 0.75).clamp(240.0, 400.0);
          final h = context.s(140.0);
          final fontSize = context.s(44.0);
          final color = context.appColors.primaryAccent;
          final progress = _anim.value;
          final selectedFont = ref.watch(progressFontProvider);

          TextStyle getPercentageStyle() {
            final baseStyle = TextStyle(
              fontSize: fontSize,
              color: color,
              height: 1.0,
              letterSpacing: context.s(2),
              shadows: context.appColors.isLight
                  ? null
                  : [
                      Shadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: context.s(16),
                      ),
                      Shadow(
                        color: color.withValues(alpha: 0.28),
                        blurRadius: context.s(55),
                      ),
                      Shadow(
                        color: color.withValues(alpha: 0.15),
                        blurRadius: context.s(95),
                      ),
                    ],
            );

            switch (selectedFont) {
              case ProgressFont.jersey15:
                return GoogleFonts.jersey15(
                  textStyle: baseStyle.copyWith(
                    fontSize: fontSize + context.s(15),
                  ),
                  fontWeight: FontWeight.w900,
                );
              case ProgressFont.jersey10:
                return GoogleFonts.jersey10(
                  textStyle: baseStyle.copyWith(
                    fontSize: fontSize + context.s(15),
                  ),
                  fontWeight: FontWeight.w900,
                );
              case ProgressFont.tektur:
                return GoogleFonts.tektur(
                  textStyle: baseStyle.copyWith(
                    fontSize: fontSize + context.s(10),
                  ),
                  fontWeight: FontWeight.w900,
                );
              case ProgressFont.odibeeSans:
                return GoogleFonts.odibeeSans(
                  textStyle: baseStyle.copyWith(
                    fontSize: fontSize + context.s(10),
                  ),
                  fontWeight: FontWeight.w900,
                );
              case ProgressFont.pressStart2P:
                return GoogleFonts.pressStart2p(
                  textStyle: baseStyle.copyWith(fontSize: fontSize - context.s(10)),
                  fontWeight: FontWeight.w900,
                );
              case ProgressFont.boldonse:
                return GoogleFonts.boldonse(
                  textStyle: baseStyle.copyWith(
                    fontSize: fontSize - context.s(10),
                    height: 1.6,
                  ),
                  fontWeight: FontWeight.w900,
                );
              case ProgressFont.orbitron:
                return GoogleFonts.orbitron(
                  textStyle: baseStyle,
                  fontWeight: FontWeight.w900,
                );
            }
          }

          return Center(
            child: SizedBox(
              width: w,
              height: h,
              child: CustomPaint(
                painter: _SquircleRingPainter(
                  progress: progress,
                  color: color,
                  trackColor: context.appColors.dividerColor,
                  strokeWidth: context.s(10),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.totalVideos == 0 ? '?' : '${(progress * 100).toStringAsFixed(2)}%',
                        style: getPercentageStyle(),
                      ),
                      SizedBox(height: context.s(4)),
                      Text(
                        'Total Syllabus Completion',
                        style: TextStyle(
                          fontSize: context.s(13),
                          color: context.appColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SquircleRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _SquircleRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  Path _bottomCenterStartRoundedRectPath(Rect rect, double radius) {
    final path = Path();
    final left = rect.left;
    final top = rect.top;
    final width = rect.width;
    final height = rect.height;

    // Start at bottom center
    final startX = left + width / 2;
    final startY = top + height;

    path.moveTo(startX, startY);

    // 1. Line left to bottom-left start
    path.lineTo(left + radius, top + height);

    // 2. Arc to bottom-left end
    path.arcToPoint(
      Offset(left, top + height - radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    // 3. Line up to top-left start
    path.lineTo(left, top + radius);

    // 4. Arc to top-left end
    path.arcToPoint(
      Offset(left + radius, top),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    // 5. Line right to top-right start
    path.lineTo(left + width - radius, top);

    // 6. Arc to top-right end
    path.arcToPoint(
      Offset(left + width, top + radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    // 7. Line down to bottom-right start
    path.lineTo(left + width, top + height - radius);

    // 8. Arc to bottom-right end
    path.arcToPoint(
      Offset(left + width - radius, top + height),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    // 9. Line back to bottom center
    path.lineTo(startX, startY);

    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2 + 1;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );

    final fullPath = _bottomCenterStartRoundedRectPath(rect, 24);

    // Track (full dim ring)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(fullPath, trackPaint);

    if (progress < 0.005) return;

    // Measure and extract progress portion
    final metric = fullPath.computeMetrics().first;
    final progressPath = metric.extractPath(0, metric.length * progress);

    // Progress ring — clean, no glow
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(progressPath, progressPaint);
  }

  @override
  bool shouldRepaint(_SquircleRingPainter old) =>
      old.progress != progress || old.color != color;
}
