import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/theme_context_ext.dart';
import 'package:gateletics/providers/providers.dart';
import 'sync/sync_payload_breakdown_dialog.dart';

class SyncSettingsSection extends ConsumerStatefulWidget {
  final Color accentColor;

  const SyncSettingsSection({
    super.key,
    required this.accentColor,
  });

  @override
  ConsumerState<SyncSettingsSection> createState() => _SyncSettingsSectionState();
}

class _SyncSettingsSectionState extends ConsumerState<SyncSettingsSection> {
  String _formatSyncTime(DateTime time) {
    final now = DateTime.now();
    final isToday = time.year == now.year && time.month == now.month && time.day == now.day;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    if (isToday) {
      return "$hour:$minute";
    } else {
      final day = time.day.toString().padLeft(2, '0');
      final month = time.month.toString().padLeft(2, '0');
      return "$day/$month $hour:$minute";
    }
  }

  Widget _buildDownloadBanner(BuildContext context, WidgetRef ref, Color accentColor) {
    final hideBanner = ref.watch(hideDownloadBannerProvider);
    if (!kIsWeb || hideBanner) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.devices_rounded, color: accentColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Get GATEletics on all devices',
                    style: GoogleFonts.outfit(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Sync your prep status seamlessly! GATEletics is also available as a native app for Android, Windows, and Linux.',
              style: GoogleFonts.outfit(
                color: context.appColors.textSecondary,
                fontSize: 11,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () async {
                final url = Uri.parse('https://vishnunandan555.github.io/gateletics/');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Download Now',
                    style: GoogleFonts.outfit(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.open_in_new_rounded, color: accentColor, size: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isFirebaseSupported()) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: context.appColors.primaryAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Cloud Sync is supported on Web & Android. To transfer data to/from this desktop app, please use the Local Backup & Restore tools below.",
                style: GoogleFonts.outfit(
                  color: context.appColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final authAsync = ref.watch(authProvider);
    final syncState = ref.watch(syncProvider);

    return authAsync.when(
      data: (authState) {
        final user = authState.user;
        final isOffline = authState.isOfflineMode;

        if (user == null || isOffline) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.appColors.surfaceColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.appColors.borderColor),
                      ),
                      child: Icon(Icons.cloud_off_rounded, color: context.appColors.textSecondary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cloud Sync Disabled',
                            style: GoogleFonts.outfit(
                              color: context.appColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sign in to enable automatic cloud backups.',
                            style: GoogleFonts.outfit(
                              color: context.appColors.textMuted,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                _buildDownloadBanner(context, ref, widget.accentColor),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Sync status badge row ─────────────────────────
                Row(
                  children: [
                    _SyncStatusBadge(
                      syncState: syncState,
                      accentColor: widget.accentColor,
                      formatSyncTime: _formatSyncTime,
                    ),
                    const Spacer(),
                    if (syncState.status == SyncStatus.syncing)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: widget.accentColor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                // ── Dual Payload & Storage progress bars ──────────
                Consumer(
                  builder: (context, ref, child) {
                    final sizeAsync = ref.watch(syncPayloadSizeProvider);
                    return sizeAsync.when(
                      data: (sizeMb) {
                        final sizeKb = (sizeMb * 1024).toStringAsFixed(1);
                        final fraction = (sizeMb / 1.0).clamp(0.0, 1.0);
                        final isNearLimit = sizeMb > 0.8;
                        final payloadColor = isNearLimit
                            ? Colors.amberAccent
                            : widget.accentColor;
                        final percentStr = (fraction * 100).toStringAsFixed(1);

                        return InkWell(
                          onTap: () => showPayloadBreakdownDialog(context, ref, widget.accentColor),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Bar 1: Local Device Storage
                                Row(
                                  children: [
                                    Icon(
                                      Icons.dns_rounded,
                                      size: 13,
                                      color: context.appColors.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Local Data Storage',
                                      style: GoogleFonts.outfit(
                                        color: context.appColors.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 11,
                                      color: context.appColors.textMuted,
                                    ),
                                    const Spacer(),
                                    Text(
                                      '$sizeKb KB',
                                      style: GoogleFonts.outfit(
                                        color: context.appColors.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: fraction,
                                    backgroundColor:
                                        context.appColors.dividerColor,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(widget.accentColor),
                                    minHeight: 4,
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Bar 2: Cloud Sync Payload Size (1 MB Limit)
                                Row(
                                  children: [
                                    Icon(
                                      isNearLimit
                                          ? Icons.warning_amber_rounded
                                          : Icons.cloud_upload_rounded,
                                      size: 13,
                                      color: isNearLimit
                                          ? Colors.amber
                                          : context.appColors.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Cloud Sync Payload (1 MB Limit)',
                                      style: GoogleFonts.outfit(
                                        color: isNearLimit
                                            ? Colors.amber
                                            : context.appColors.textMuted,
                                        fontSize: 11,
                                        fontWeight: isNearLimit
                                            ? FontWeight.bold
                                            : FontWeight.w400,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '$sizeKb KB / 1024 KB ($percentStr%)',
                                      style: GoogleFonts.outfit(
                                        color: isNearLimit
                                            ? Colors.amber
                                            : context.appColors.textSecondary,
                                        fontSize: 11,
                                        fontWeight: isNearLimit
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: fraction,
                                    backgroundColor: context.appColors.dividerColor,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(payloadColor),
                                    minHeight: 5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (err, stack) => const SizedBox.shrink(),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // ── Cloud Storage Controls Status Card ──
                Consumer(
                  builder: (context, ref, child) {
                    final syncStatsEnabled = ref.watch(syncStatsEnabledProvider);
                    final syncCompressed = ref.watch(syncCompressedProvider);
                    final asyncPayloadSize = ref.watch(syncPayloadSizeProvider);

                    final sizeKb = asyncPayloadSize.maybeWhen(
                      data: (sizeMb) => sizeMb * 1024,
                      orElse: () => 0.0,
                    );

                    final statusConfig = _getCloudStatusConfig(sizeKb, widget.accentColor);
                    final recommendationText = _getRecommendationText(sizeKb, syncStatsEnabled, syncCompressed);

                    final isHealthy = sizeKb < 500;
                    final recColor = isHealthy ? context.appColors.textMuted : statusConfig.color;

                    return Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.appColors.surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.appColors.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cloud Storage Controls',
                              style: GoogleFonts.outfit(
                                color: context.appColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                // Dynamic 1-2 Word Status Badge (50% Equal Width, 34px Height)
                                Expanded(
                                  child: Container(
                                    height: 34,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: statusConfig.color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: statusConfig.color.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(statusConfig.icon, size: 14, color: statusConfig.color),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            statusConfig.label,
                                            style: GoogleFonts.outfit(
                                              color: statusConfig.color,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11.5,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Premium Filled Optimize Button (50% Equal Width, 34px Height)
                                Expanded(
                                  child: SizedBox(
                                    height: 34,
                                    child: FilledButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => SyncOptimizationScreen(accentColor: widget.accentColor),
                                          ),
                                        );
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: widget.accentColor,
                                        foregroundColor: context.appColors.onAccent,
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                      icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                                      label: Text(
                                        'Optimize',
                                        style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (!isHealthy) ...[
                              const SizedBox(height: 10),
                              // Dynamic Recommendation Area
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: recColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: recColor.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.lightbulb_outline_rounded, size: 14, color: recColor),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: 'Recommendation: ',
                                              style: GoogleFonts.outfit(
                                                color: recColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                            TextSpan(
                                              text: recommendationText,
                                              style: GoogleFonts.outfit(
                                                color: context.appColors.textSecondary,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: syncState.status == SyncStatus.syncing
                            ? null
                            : () async {
                                await ref.read(syncProvider.notifier).uploadLocalToCloud();
                                if (context.mounted) {
                                  final finalState = ref.read(syncProvider);
                                  if (finalState.status == SyncStatus.success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('✓ Progress successfully saved to cloud!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else if (finalState.status == SyncStatus.error) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('✗ Cloud upload failed: ${finalState.errorMessage ?? "Unknown error"}'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: widget.accentColor,
                          foregroundColor: context.appColors.onAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                        label: Text(
                          "Sync",
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: syncState.status == SyncStatus.syncing
                            ? null
                            : () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: context.appColors.surfaceColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    title: Text("Restore Data from Cloud?", style: GoogleFonts.outfit(color: context.appColors.textPrimary)),
                                    content: Text(
                                      "This will overwrite your local device progress with the cloud backup. This cannot be undone.",
                                      style: GoogleFonts.outfit(color: context.appColors.textSecondary),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: Text('Cancel', style: GoogleFonts.outfit(color: context.appColors.textSecondary)),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        style: FilledButton.styleFrom(backgroundColor: widget.accentColor, foregroundColor: context.appColors.onAccent),
                                        child: const Text('Restore'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed != true) return;

                                await ref.read(syncProvider.notifier).downloadCloudToLocal();
                                if (context.mounted) {
                                  final finalState = ref.read(syncProvider);
                                  if (finalState.status == SyncStatus.success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('✓ Cloud data successfully restored!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else if (finalState.status == SyncStatus.error) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('✗ Cloud download failed: ${finalState.errorMessage ?? "Unknown error"}'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: widget.accentColor),
                          foregroundColor: widget.accentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.cloud_download_rounded, size: 16),
                        label: Text(
                          "Restore Data",
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
                _buildDownloadBanner(context, ref, widget.accentColor),
              ],
            ),
          );
      },
      loading: () => Center(
        child: CircularProgressIndicator(color: widget.accentColor),
      ),
      error: (err, _) => Text(
        'Auth Error: $err',
        style: const TextStyle(color: Colors.redAccent),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sync Status Badge widget
// ─────────────────────────────────────────────────────────────────────────────

class _SyncStatusBadge extends StatelessWidget {
  final SyncState syncState;
  final Color accentColor;
  final String Function(DateTime) formatSyncTime;

  const _SyncStatusBadge({
    required this.syncState,
    required this.accentColor,
    required this.formatSyncTime,
  });

  @override
  Widget build(BuildContext context) {
    final isSyncing = syncState.status == SyncStatus.syncing;
    final isError = syncState.status == SyncStatus.error;
    final isSynced = syncState.lastSyncedAt != null &&
        syncState.status == SyncStatus.success;

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

Future<void> showSignOutConfirmationDialog(BuildContext context, WidgetRef ref) async {
  final choice = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: context.appColors.dialogBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Sign Out',
        style: GoogleFonts.outfit(
          color: context.appColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'How would you like to handle your local study progress on this device when signing out?',
              style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => Navigator.pop(ctx, 'keepLocal'),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: context.appColors.borderColor),
                  borderRadius: BorderRadius.circular(16),
                  color: context.appColors.surfaceColor,
                ),
                child: Row(
                  children: [
                    Icon(Icons.smartphone_rounded, color: context.appColors.primaryAccent, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Keep Local Progress (Offline Mode)',
                            style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Preserve study data on device and switch to Offline Mode',
                            style: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => Navigator.pop(ctx, 'wipeData'),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.redAccent.withValues(alpha: 0.05),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reset & Wipe Local Data',
                            style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sign out and permanently erase all local study progress',
                            style: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Cancel', style: GoogleFonts.outfit(color: context.appColors.textMuted)),
        ),
      ],
    ),
  );

  if (choice == null || !context.mounted) return;

  final keepLocal = choice == 'keepLocal';
  await ref.read(authProvider.notifier).signOut(keepLocalData: keepLocal);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          keepLocal
              ? '✓ Signed out. Switched to Offline Mode (local data preserved).'
              : '✓ Signed out and local study data reset.',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class _CloudStatusConfig {
  final String label;
  final Color color;
  final IconData icon;

  _CloudStatusConfig({
    required this.label,
    required this.color,
    required this.icon,
  });
}

_CloudStatusConfig _getCloudStatusConfig(double sizeKb, Color accentColor) {
  if (sizeKb >= 1024) {
    return _CloudStatusConfig(
      label: 'Sync Blocked',
      color: Colors.red,
      icon: Icons.block_rounded,
    );
  } else if (sizeKb >= 1000) {
    return _CloudStatusConfig(
      label: 'Payload Warning',
      color: Colors.redAccent,
      icon: Icons.error_outline_rounded,
    );
  } else if (sizeKb >= 900) {
    return _CloudStatusConfig(
      label: 'Limit Nearing',
      color: Colors.deepOrangeAccent,
      icon: Icons.warning_amber_rounded,
    );
  } else if (sizeKb >= 800) {
    return _CloudStatusConfig(
      label: 'Critical',
      color: Colors.orangeAccent,
      icon: Icons.warning_amber_rounded,
    );
  } else if (sizeKb >= 700) {
    return _CloudStatusConfig(
      label: 'Attention',
      color: Colors.amber.shade700,
      icon: Icons.info_outline_rounded,
    );
  } else if (sizeKb >= 600) {
    return _CloudStatusConfig(
      label: 'Moderate',
      color: Colors.amber.shade600,
      icon: Icons.info_outline_rounded,
    );
  } else if (sizeKb >= 500) {
    return _CloudStatusConfig(
      label: 'Fair',
      color: accentColor,
      icon: Icons.check_circle_outline_rounded,
    );
  } else {
    return _CloudStatusConfig(
      label: 'All Good',
      color: accentColor,
      icon: Icons.check_circle_rounded,
    );
  }
}

String _getRecommendationText(double sizeKb, bool syncStatsEnabled, bool syncCompressed) {
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
