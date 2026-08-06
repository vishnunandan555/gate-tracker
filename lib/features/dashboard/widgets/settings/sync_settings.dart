import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/theme_context_ext.dart';
import 'package:gateletics/providers/providers.dart';
import '../../../more/screens/sync_optimization_screen.dart';
import 'sync/sync_payload_breakdown_dialog.dart';
import 'sync/sync_status_badge.dart';
import 'sync/sync_web_banner.dart';

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
                SyncWebBanner(accentColor: widget.accentColor),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SyncStatusBadge(
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
              Consumer(
                builder: (context, ref, child) {
                  final sizeAsync = ref.watch(syncPayloadSizeProvider);
                  return sizeAsync.when(
                    data: (sizeMb) {
                      final sizeKb = (sizeMb * 1024).toStringAsFixed(1);
                      final fraction = (sizeMb / 1.0).clamp(0.0, 1.0);
                      final isNearLimit = sizeMb > 0.8;
                      final payloadColor = isNearLimit ? Colors.amberAccent : widget.accentColor;
                      final percentStr = (fraction * 100).toStringAsFixed(1);

                      return InkWell(
                        onTap: () => showPayloadBreakdownDialog(context, ref, widget.accentColor),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.dns_rounded, size: 13, color: context.appColors.textMuted),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Local Data Storage',
                                    style: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 11),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.info_outline_rounded, size: 11, color: context.appColors.textMuted),
                                  const Spacer(),
                                  Text(
                                    '$sizeKb KB',
                                    style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: fraction,
                                  backgroundColor: context.appColors.dividerColor,
                                  valueColor: AlwaysStoppedAnimation<Color>(widget.accentColor),
                                  minHeight: 4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    isNearLimit ? Icons.warning_amber_rounded : Icons.cloud_upload_rounded,
                                    size: 13,
                                    color: isNearLimit ? Colors.amber : context.appColors.textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Cloud Sync Payload (1 MB Limit)',
                                    style: GoogleFonts.outfit(
                                      color: isNearLimit ? Colors.amber : context.appColors.textMuted,
                                      fontSize: 11,
                                      fontWeight: isNearLimit ? FontWeight.bold : FontWeight.w400,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '$sizeKb KB / 1024 KB ($percentStr%)',
                                    style: GoogleFonts.outfit(
                                      color: isNearLimit ? Colors.amber : context.appColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: isNearLimit ? FontWeight.bold : FontWeight.w500,
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
                                  valueColor: AlwaysStoppedAnimation<Color>(payloadColor),
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
              Consumer(
                builder: (context, ref, child) {
                  final syncStatsEnabled = ref.watch(syncStatsEnabledProvider);
                  final syncCompressed = ref.watch(syncCompressedProvider);
                  final asyncPayloadSize = ref.watch(syncPayloadSizeProvider);

                  final sizeKb = asyncPayloadSize.maybeWhen(
                    data: (sizeMb) => sizeMb * 1024,
                    orElse: () => 0.0,
                  );

                  final statusConfig = getCloudStatusConfig(sizeKb, widget.accentColor);
                  final recommendationText = getRecommendationText(sizeKb, syncStatsEnabled, syncCompressed);
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
                            style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
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
                                          style: GoogleFonts.outfit(color: statusConfig.color, fontWeight: FontWeight.bold, fontSize: 11.5),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
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
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: recColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: recColor.withValues(alpha: 0.2)),
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
                                            style: GoogleFonts.outfit(color: recColor, fontWeight: FontWeight.bold, fontSize: 11),
                                          ),
                                          TextSpan(
                                            text: recommendationText,
                                            style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 11),
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
                                    const SnackBar(content: Text('✓ Progress successfully saved to cloud!'), backgroundColor: Colors.green),
                                  );
                                } else if (finalState.status == SyncStatus.error) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('✗ Cloud upload failed: ${finalState.errorMessage ?? "Unknown error"}'), backgroundColor: Colors.redAccent),
                                  );
                                }
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.accentColor,
                        foregroundColor: context.appColors.onAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                      label: Text("Sync", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11)),
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
                                  content: Text("This will overwrite your local device progress with the cloud backup. This cannot be undone.", style: GoogleFonts.outfit(color: context.appColors.textSecondary)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.outfit(color: context.appColors.textSecondary))),
                                    FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: widget.accentColor, foregroundColor: context.appColors.onAccent), child: const Text('Restore')),
                                  ],
                                ),
                              );
                              if (confirmed != true) return;
                              await ref.read(syncProvider.notifier).downloadCloudToLocal();
                            },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: widget.accentColor),
                        foregroundColor: widget.accentColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.cloud_download_rounded, size: 16),
                      label: Text("Restore Data", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ),
                ],
              ),
              SyncWebBanner(accentColor: widget.accentColor),
            ],
          ),
        );
      },
      loading: () => Center(child: CircularProgressIndicator(color: widget.accentColor)),
      error: (err, _) => Text('Auth Error: $err', style: const TextStyle(color: Colors.redAccent)),
    );
  }
}
