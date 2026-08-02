import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/theme_context_ext.dart';
import '../../../../../providers/sync/sync_models.dart';

class SyncStatusCardWidget extends StatelessWidget {
  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final String? errorMessage;
  final Color accentColor;

  const SyncStatusCardWidget({
    super.key,
    required this.status,
    required this.lastSyncedAt,
    required this.errorMessage,
    required this.accentColor,
  });

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final isToday = time.year == now.year && time.month == now.month && time.day == now.day;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    if (isToday) return "$hour:$minute";
    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    return "$day/$month $hour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    IconData statusIcon;
    Color statusColor;
    String statusTitle;

    switch (status) {
      case SyncStatus.syncing:
        statusIcon = Icons.sync_rounded;
        statusColor = accentColor;
        statusTitle = 'Syncing Cloud Data...';
        break;
      case SyncStatus.success:
        statusIcon = Icons.cloud_done_rounded;
        statusColor = Colors.greenAccent;
        statusTitle = lastSyncedAt != null ? 'Synced at ${_formatTime(lastSyncedAt!)}' : 'Cloud Sync Up-to-Date';
        break;
      case SyncStatus.error:
        statusIcon = Icons.cloud_off_rounded;
        statusColor = Colors.redAccent;
        statusTitle = errorMessage ?? 'Sync Failed';
        break;
      case SyncStatus.requiresAction:
        statusIcon = Icons.cloud_upload_rounded;
        statusColor = Colors.amberAccent;
        statusTitle = 'Conflict Detected — Merge Needed';
        break;
      case SyncStatus.idle:
      default:
        statusIcon = Icons.cloud_queue_rounded;
        statusColor = appColors.textSecondary;
        statusTitle = 'Cloud Sync Ready';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CLOUD SYNC STATUS',
                  style: GoogleFonts.outfit(
                    color: appColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusTitle,
                  style: GoogleFonts.outfit(
                    color: appColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
