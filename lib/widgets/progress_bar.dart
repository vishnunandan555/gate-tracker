import 'package:flutter/material.dart';
import '../core/theme/theme_context_ext.dart';

class ProgressBar extends StatelessWidget {
  final double percentage;
  final double height;
  final Color? color;
  final List<Color>? gradientColors;
  final List<double>? gradientStops;
  final bool showTicks;
  final int tickCount;

  const ProgressBar({
    super.key,
    required this.percentage,
    this.height = 12.0,
    this.color,
    this.gradientColors,
    this.gradientStops,
    this.showTicks = false,
    this.tickCount = 8,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? context.appColors.primaryAccent;
    final clampedPercentage = percentage.clamp(0.0, 100.0);
    final effectiveColor = gradientColors?.first ?? activeColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final fillWidth = totalWidth * (clampedPercentage / 100);

        return SizedBox(
          height: height,
          child: Stack(
            children: [
              // Track
              Container(
                width: totalWidth,
                height: height,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.black.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),

              // Glow layer (behind fill)
              if (clampedPercentage > 0)
                Positioned(
                  left: 0,
                  child: Container(
                    width: fillWidth,
                    height: height,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(height / 2),
                      boxShadow: [
                        BoxShadow(
                          color: effectiveColor.withValues(alpha: 0.45),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),

              // Animated fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                width: fillWidth,
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        gradientColors ??
                        [effectiveColor.withValues(alpha: 0.75), effectiveColor],
                    stops: gradientStops,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),

              // Tick marks on the track
              if (showTicks)
                ...List.generate(tickCount - 1, (i) {
                  final x = totalWidth * (i + 1) / tickCount;
                  return Positioned(
                    left: x - 1,
                    top: height * 0.2,
                    child: Container(
                      width: 1.5,
                      height: height * 0.6,
                      color: context.appColors.dividerColor,
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
