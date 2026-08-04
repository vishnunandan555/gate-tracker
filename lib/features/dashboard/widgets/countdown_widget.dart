import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_context_ext.dart';
import 'package:gateletics/providers/providers.dart';

class CountdownWidget extends ConsumerWidget {
  const CountdownWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disableCountdown = ref.watch(disableCountdownProvider);
    if (disableCountdown) return const SizedBox.shrink();

    final targetDate = ref.watch(targetDateProvider);
    final progressColor = context.appColors.primaryAccent;
    final selectedFont = ref.watch(progressFontProvider);
    final now = DateTime.now();
    final difference = targetDate.difference(now);
    final daysLeft = difference.inDays > 0 ? difference.inDays : 0;

    TextStyle getDaysStyle(double size, Color col) {
      final base = TextStyle(
        fontSize: size,
        fontWeight: FontWeight.bold,
        color: col,
        height: 1.0,
      );

      switch (selectedFont) {
        case ProgressFont.jersey15:
          return GoogleFonts.jersey15(textStyle: base.copyWith(fontSize: size + 8));
        case ProgressFont.jersey10:
          return GoogleFonts.jersey10(textStyle: base.copyWith(fontSize: size + 8));
        case ProgressFont.tektur:
          return GoogleFonts.tektur(textStyle: base);
        case ProgressFont.odibeeSans:
          return GoogleFonts.odibeeSans(textStyle: base.copyWith(fontSize: size + 4));
        case ProgressFont.pressStart2P:
          return GoogleFonts.pressStart2p(textStyle: base.copyWith(fontSize: size - 8));
        case ProgressFont.boldonse:
          return GoogleFonts.boldonse(textStyle: base.copyWith(fontSize: size - 2, height: 1.2));
        case ProgressFont.orbitron:
          return GoogleFonts.orbitron(textStyle: base);
      }
    }

    return GestureDetector(
      onLongPress: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: targetDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (selected != null) {
          ref.read(targetDateProvider.notifier).setDate(selected);
        }
      },
      child: Container(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.only(left: 12, right: 0, top: 4, bottom: 4),
        color: Colors.transparent,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$daysLeft',
                style: getDaysStyle(32, progressColor).copyWith(
                  shadows: context.appColors.isLight
                      ? null
                      : [Shadow(color: progressColor.withValues(alpha: 0.8), blurRadius: 10)],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'DAYS LEFT',
                style: getDaysStyle(10, context.appColors.textSecondary).copyWith(
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
