import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gateletics/providers/providers.dart';

class ActiveFocusWaveWidget extends ConsumerStatefulWidget {
  final Color accentColor;
  final VoidCallback onTap;

  const ActiveFocusWaveWidget({
    super.key,
    required this.accentColor,
    required this.onTap,
  });

  @override
  ConsumerState<ActiveFocusWaveWidget> createState() => _ActiveFocusWaveWidgetState();
}

class _ActiveFocusWaveWidgetState extends ConsumerState<ActiveFocusWaveWidget> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    _pulseAnimation = Tween<double>(begin: 0.1, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _waveController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animType = ref.watch(focusAnimationProvider);

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.translucent,
      child: Container(
        height: 68,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _pulseAnimation.value,
                  child: Text(
                    "Focusing...",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 20,
              width: 100,
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  switch (animType) {
                    case FocusAnimationType.pulseDots:
                      return CustomPaint(
                        painter: _PulseDotsPainter(
                          phase: _waveController.value,
                          color: widget.accentColor.withValues(alpha: 0.7),
                        ),
                      );
                    case FocusAnimationType.sonicEqualizer:
                      return CustomPaint(
                        painter: _EqualizerPainter(
                          phase: _waveController.value,
                          color: widget.accentColor.withValues(alpha: 0.7),
                        ),
                      );
                    case FocusAnimationType.heartbeatECG:
                      return CustomPaint(
                        painter: _ECGPainter(
                          phase: _waveController.value,
                          color: widget.accentColor.withValues(alpha: 0.7),
                        ),
                      );
                    case FocusAnimationType.singleWave:
                      return CustomPaint(
                        painter: _WavePainter(
                          phase: _waveController.value,
                          color: widget.accentColor.withValues(alpha: 0.35),
                          isDouble: false,
                        ),
                      );
                    case FocusAnimationType.doubleWave:
                      return CustomPaint(
                        painter: _WavePainter(
                          phase: _waveController.value,
                          color: widget.accentColor.withValues(alpha: 0.35),
                          isDouble: true,
                        ),
                      );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double phase;
  final Color color;
  final bool isDouble;

  _WavePainter({required this.phase, required this.color, this.isDouble = true});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    final yCenter = size.height / 2;
    final waveLength = size.width;
    final amplitude = 12.0;

    path.moveTo(0, yCenter);

    for (double x = 0; x <= size.width; x++) {
      final y = yCenter + amplitude * sin((2 * pi * x / waveLength) - (phase * 2 * pi));
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    if (isDouble) {
      final secondaryPaint = Paint()
        ..color = color.withValues(alpha: color.a * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      final secondaryPath = Path();
      secondaryPath.moveTo(0, yCenter);
      for (double x = 0; x <= size.width; x++) {
        final y = yCenter + (amplitude * 0.7) * sin((2 * pi * x / (waveLength * 0.8)) - (phase * 2 * pi) + pi / 2);
        secondaryPath.lineTo(x, y);
      }
      canvas.drawPath(secondaryPath, secondaryPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.color != color || oldDelegate.isDouble != isDouble;
  }
}

class _PulseDotsPainter extends CustomPainter {
  final double phase;
  final Color color;

  _PulseDotsPainter({required this.phase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final dotCount = 3;
    final spacing = 16.0;
    final startX = (size.width - (dotCount - 1) * spacing) / 2;
    final yCenter = size.height / 2;

    for (int i = 0; i < dotCount; i++) {
      final dotPhase = (phase * 2 * pi - (i * pi / 1.5)) % (2 * pi);
      final scale = 0.4 + 0.6 * (0.5 + 0.5 * sin(dotPhase));
      final dotPaint = Paint()
        ..color = color.withValues(alpha: color.a * scale)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(startX + i * spacing, yCenter), 4.5 * scale, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PulseDotsPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.color != color;
  }
}

class _EqualizerPainter extends CustomPainter {
  final double phase;
  final Color color;

  _EqualizerPainter({required this.phase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final barCount = 4;
    final barWidth = 3.0;
    final barSpacing = 8.0;
    final totalWidth = barCount * barWidth + (barCount - 1) * barSpacing;
    final startX = (size.width - totalWidth) / 2;
    final bottom = size.height;

    for (int i = 0; i < barCount; i++) {
      final offset = (i * pi / 4);
      final heightFactor = 0.2 + 0.8 * (0.5 + 0.5 * sin(phase * 4 * pi + offset));
      final barHeight = size.height * heightFactor;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(startX + i * (barWidth + barSpacing), bottom - barHeight, barWidth, barHeight),
          const Radius.circular(1.5),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EqualizerPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.color != color;
  }
}

class _ECGPainter extends CustomPainter {
  final double phase;
  final Color color;

  _ECGPainter({required this.phase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final yCenter = size.height / 2;
    path.moveTo(0, yCenter);

    for (double x = 0; x <= size.width; x++) {
      final nx = x / size.width;
      final pulsePos = phase;
      final dist = (nx - pulsePos).abs();
      
      double y = yCenter;
      if (dist < 0.12) {
        final localX = (nx - pulsePos) / 0.12;
        double spike = 0.0;
        if (localX > -0.8 && localX < -0.4) {
          spike = -0.2 * sin((localX + 0.6) * pi / 0.2);
        } else if (localX >= -0.4 && localX <= 0.0) {
          spike = 1.0 * sin((localX + 0.2) * pi / 0.2);
        } else if (localX > 0.0 && localX < 0.3) {
          spike = -0.3 * sin((localX - 0.15) * pi / 0.15);
        } else if (localX >= 0.3 && localX < 0.7) {
          spike = 0.2 * sin((localX - 0.5) * pi / 0.2);
        }
        y = yCenter - spike * (size.height * 0.45);
      }
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ECGPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.color != color;
  }
}
