import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../providers/focus/focus_provider.dart';

void showFocusRecoveryDialog(
  BuildContext context,
  FocusRecoveryData recoveryData,
  Color accentColor,
  WidgetRef ref,
) {
  final details = focusMethodsData[recoveryData.method]!;

  String formatSecs(int sec) {
    if (sec <= 0) return "0m";
    if (sec < 60) return "${sec}s";
    final totalMins = (sec / 60).floor();
    if (totalMins < 60) return "${totalMins}m";
    final hrs = (totalMins / 60).floor();
    final remMins = totalMins % 60;
    if (remMins == 0) return "${hrs}h";
    return "${hrs}h ${remMins}m";
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: const Color(0xFF131316),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: accentColor.withAlpha(60), width: 1.5),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Tag
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: accentColor.withAlpha(80)),
                        ),
                        child: Text(
                          "Interrupted Session Detected",
                          style: GoogleFonts.outfit(
                            color: accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      "Session Recovery Breakdown",
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "You started a ${details.name} session. Review the time breakdown below to choose how to log it.",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.white54,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Metric 1: Active Focus Time
                    _buildMetricCard(
                      context,
                      icon: Icons.play_circle_fill_rounded,
                      iconColor: accentColor,
                      title: "Active Focus Time",
                      subtitle: "Logged while app was running",
                      value: formatSecs(recoveryData.activeSeconds),
                      valueColor: accentColor,
                    ),
                    const SizedBox(height: 10),

                    // Metric 2: Time App Was Closed
                    _buildMetricCard(
                      context,
                      icon: Icons.phonelink_off_rounded,
                      iconColor: Colors.orangeAccent,
                      title: "Time App Was Closed",
                      subtitle: "Elapsed while app was closed",
                      value: formatSecs(recoveryData.closedSeconds),
                      valueColor: Colors.orangeAccent,
                    ),
                    const SizedBox(height: 10),

                    // Metric 3: Total Duration
                    _buildMetricCard(
                      context,
                      icon: Icons.timer_outlined,
                      iconColor: Colors.white,
                      title: "Total Session Duration",
                      subtitle: "Active + Closed duration",
                      value: formatSecs(recoveryData.totalSeconds),
                      valueColor: Colors.white,
                      isHighlighted: true,
                    ),
                    const SizedBox(height: 24),

                    // Option 1: Keep Active Focus Only
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        ref.read(focusProvider.notifier).resolveRecoveryKeepActive();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        "Keep Active Focus Only (${formatSecs(recoveryData.activeSeconds)})",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Option 2: Keep Full Duration
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        ref.read(focusProvider.notifier).resolveRecoveryKeepFull();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: Colors.white24),
                      ),
                      child: Text(
                        "Keep Full Duration (${formatSecs(recoveryData.totalSeconds)})",
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Option 3: Discard Session
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        ref.read(focusProvider.notifier).resolveRecoveryDiscard();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(
                        "Discard Session",
                        style: GoogleFonts.outfit(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildMetricCard(
  BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required String title,
  required String subtitle,
  required String value,
  required Color valueColor,
  bool isHighlighted = false,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: isHighlighted ? Colors.white.withAlpha(12) : const Color(0xFF1B1B22),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isHighlighted ? Colors.white.withAlpha(20) : Colors.white.withAlpha(5),
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: valueColor,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
