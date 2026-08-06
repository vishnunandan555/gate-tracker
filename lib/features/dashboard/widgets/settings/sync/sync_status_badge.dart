import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../core/theme/theme_context_ext.dart';
import 'package:gateletics/providers/providers.dart';

class SyncStatusBadge extends StatelessWidget {
  final SyncState syncState;
  final Color accentColor;
  final String Function(DateTime) formatSyncTime;

  const SyncStatusBadge({
    super.key,
    required this.syncState,
    required this.accentColor,
    required this.formatSyncTime,
  });

  @override
  Widget build(BuildContext context) {
    final isSyncing = syncState.status == SyncStatus.syncing;
    final isError = syncState.status == SyncStatus.error;
    final isSynced = syncState.lastSyncedAt != null && syncState.status == SyncStatus.success;

    final isOfflinePause = isError && (syncState.errorMessage?.contains('internet') == true || syncState.errorMessage?.contains('paused') == true);

    final Color badgeColor = isOfflinePause
        ? Colors.amber.shade700
        : isError
            ? Colors.redAccent
            : (isSyncing || isSynced)
                ? accentColor
                : context.appColors.textMuted;

    final String label = isOfflinePause
        ? (syncState.errorMessage ?? 'No Internet — Sync Paused')
        : isError
            ? 'Sync Error'
            : isSyncing
                ? 'Syncing…'
                : isSynced
                    ? 'Synced ${formatSyncTime(syncState.lastSyncedAt!)}'
                    : 'Not synced';

    final IconData icon = isOfflinePause
        ? Icons.wifi_off_rounded
        : isError
            ? Icons.cloud_off_rounded
            : isSyncing
                ? Icons.sync_rounded
                : isSynced
                    ? Icons.cloud_done_rounded
                    : Icons.cloud_queue_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: badgeColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: badgeColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class CloudStatusConfig {
  final String label;
  final Color color;
  final IconData icon;

  CloudStatusConfig({
    required this.label,
    required this.color,
    required this.icon,
  });
}

CloudStatusConfig getCloudStatusConfig(double sizeKb, Color accentColor) {
  if (sizeKb >= 1024) {
    return CloudStatusConfig(
      label: 'Sync Blocked',
      color: Colors.red,
      icon: Icons.block_rounded,
    );
  } else if (sizeKb >= 1000) {
    return CloudStatusConfig(
      label: 'Payload Warning',
      color: Colors.redAccent,
      icon: Icons.error_outline_rounded,
    );
  } else if (sizeKb >= 900) {
    return CloudStatusConfig(
      label: 'Limit Nearing',
      color: Colors.deepOrangeAccent,
      icon: Icons.warning_amber_rounded,
    );
  } else if (sizeKb >= 800) {
    return CloudStatusConfig(
      label: 'Critical',
      color: Colors.orangeAccent,
      icon: Icons.warning_amber_rounded,
    );
  } else if (sizeKb >= 700) {
    return CloudStatusConfig(
      label: 'Attention',
      color: Colors.amber.shade700,
      icon: Icons.info_outline_rounded,
    );
  } else if (sizeKb >= 600) {
    return CloudStatusConfig(
      label: 'Moderate',
      color: Colors.amber.shade600,
      icon: Icons.info_outline_rounded,
    );
  } else if (sizeKb >= 500) {
    return CloudStatusConfig(
      label: 'Fair',
      color: accentColor,
      icon: Icons.check_circle_outline_rounded,
    );
  } else {
    return CloudStatusConfig(
      label: 'All Good',
      color: accentColor,
      icon: Icons.check_circle_rounded,
    );
  }
}

String getRecommendationText(double sizeKb, bool syncStatsEnabled, bool syncCompressed) {
  if (sizeKb >= 1024) {
    return '1024 KB limit reached! Prune historical stats or disable passive stats sync immediately to resume cloud backup.';
  } else if (sizeKb >= 1000) {
    return 'Critical payload warning! Prune old records or disable passive stats sync to avoid sync blockage.';
  } else if (sizeKb >= 800) {
    if (!syncCompressed) {
      return 'Payload size is critical. Enable GZip Payload Compression immediately or prune historical stats.';
    } else {
      return 'Payload is near limit despite compression. Prune historical stats (older than 6M/1Y) or disable passive stats sync.';
    }
  } else if (sizeKb >= 500) {
    if (!syncCompressed) {
      return 'Enable GZip Payload Compression to reduce cloud storage usage by ~80%.';
    } else {
      return 'Compression is active and payload size is stable.';
    }
  } else {
    return 'Storage is healthy. No action required.';
  }
}
