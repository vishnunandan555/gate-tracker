import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_context_ext.dart';
import 'package:gateletics/providers/providers.dart';
import '../../../../utils/ui_scaling.dart';

class HomeResumePrepButton extends ConsumerWidget {
  final double progress;
  final bool hasStarted;
  final Color accentColor;
  final void Function(int) onNavigateToTab;

  const HomeResumePrepButton({
    super.key,
    required this.progress,
    required this.hasStarted,
    required this.accentColor,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buttonText = hasStarted ? "RESUME PREPARATION" : "START PREPARATION";
    final fillStyle = ref.watch(resumeFillStyleProvider);

    Widget progressWidget;
    Color labelColor = context.appColors.textPrimary;
    Color iconBgColor = accentColor;
    Color iconColor = context.appColors.onAccent;

    switch (fillStyle) {
      case ResumeFillStyle.rectangularFill:
        progressWidget = Positioned.fill(
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              color: accentColor,
            ),
          ),
        );
        labelColor = progress > 0.45 ? context.appColors.onAccent : context.appColors.textPrimary;
        iconBgColor = progress > 0.25 ? context.appColors.onAccent : accentColor;
        iconColor = progress > 0.25 ? accentColor : context.appColors.onAccent;
        break;

      case ResumeFillStyle.neonGradient:
        progressWidget = Positioned.fill(
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.45),
                    accentColor.withValues(alpha: 0.15),
                  ],
                ),
              ),
            ),
          ),
        );
        labelColor = context.appColors.textPrimary;
        iconBgColor = accentColor;
        iconColor = context.appColors.onAccent;
        break;

      case ResumeFillStyle.bottomMicroIndicator:
        progressWidget = Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: context.s(3.5),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: accentColor,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.6),
                    blurRadius: context.s(6),
                    offset: Offset(0, context.s(-1)),
                  ),
                ],
              ),
            ),
          ),
        );
        labelColor = context.appColors.textPrimary;
        iconBgColor = accentColor;
        iconColor = context.appColors.onAccent;
        break;
    }

    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.8,
        child: GestureDetector(
          onTap: () => onNavigateToTab(3),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(context.s(30)),
            child: Container(
              height: context.s(48),
              decoration: BoxDecoration(
                color: context.appColors.cardBackground,
                borderRadius: BorderRadius.circular(context.s(30)),
                border: Border.all(color: context.appColors.borderColor),
              ),
              child: Stack(
                children: [
                  progressWidget,
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(context.s(4)),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: iconBgColor,
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: iconColor,
                            size: context.s(16),
                          ),
                        ),
                        SizedBox(width: context.s(8)),
                        Text(
                          buttonText,
                          style: GoogleFonts.outfit(
                            color: labelColor,
                            fontWeight: FontWeight.bold,
                            fontSize: context.s(12),
                            letterSpacing: context.s(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
