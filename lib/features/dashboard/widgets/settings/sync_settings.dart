import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../providers/sync_provider.dart';
import '../../../../providers/hide_download_banner_provider.dart';
import '../../../../providers/subject_provider.dart';
import '../shell_common.dart';

class SyncSettingsSection extends ConsumerStatefulWidget {
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final Color accentColor;

  const SyncSettingsSection({
    super.key,
    required this.titleStyle,
    required this.subtitleStyle,
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
                      color: Colors.white,
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
                color: Colors.white70,
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

  void _showSyncConflictDialog(BuildContext context, WidgetRef ref) {
    final accentColor = ref.read(overallProgressColorProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Sync Conflict Detected",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Both your local device and cloud backup contain study tracking progress. How would you like to resolve this conflict?",
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final localData = await ref.read(syncProvider.notifier).exportLocalData();
                  final cloudData = ref.read(syncProvider).pendingCloudData;
                  if (cloudData != null && context.mounted) {
                    showConflictDetailsDialog(context, localData, cloudData, accentColor);
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: accentColor.withValues(alpha: 0.1)),
                  foregroundColor: accentColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.compare_arrows_rounded, size: 16),
                label: Text(
                  "Compare Data (View Conflicts)",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              const SizedBox(height: 16),
              _buildDialogOption(
                context: context,
                title: "Merge Progress (Recommended)",
                subtitle: "Combine local and cloud progress (no data lost)",
                icon: Icons.merge_type_rounded,
                color: Colors.cyanAccent,
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(syncProvider.notifier).mergeCloudAndLocal();
                },
              ),
              const SizedBox(height: 12),
              _buildDialogOption(
                context: context,
                title: "Use Cloud Backup",
                subtitle: "Overwrite local data with your cloud backup",
                icon: Icons.cloud_download_rounded,
                color: Colors.greenAccent,
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(syncProvider.notifier).downloadCloudToLocal();
                },
              ),
              const SizedBox(height: 12),
              _buildDialogOption(
                context: context,
                title: "Keep Local Progress",
                subtitle: "Overwrite cloud data with your local progress",
                icon: Icons.cloud_upload_rounded,
                color: Colors.orangeAccent,
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(syncProvider.notifier).uploadLocalToCloud();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withAlpha(5),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10),
                  ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(8)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.cyanAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Cloud Sync is supported on Web & Android. To transfer data to/from this desktop app, please use the Local Backup & Restore tools below.",
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withAlpha(8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_off_rounded, color: Colors.white60),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Offline Mode Enabled",
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Your progress is stored locally on this device. Sign in with Google to enable automatic cloud sync and backups.",
                    style: GoogleFonts.outfit(
                      color: Colors.white30,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      try {
                        await ref.read(authProvider.notifier).signInWithGoogle();
                        final needsAction = await ref.read(syncProvider.notifier).initializeSync();
                        if (needsAction && context.mounted) {
                          _showSyncConflictDialog(context, ref);
                        } else if (context.mounted) {
                          final finalState = ref.read(syncProvider);
                          if (finalState.status == SyncStatus.success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✓ Signed in! Your local study progress is backed up to cloud.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Google Sign-in failed: $e')),
                          );
                        }
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: Text(
                      "SIGN IN WITH GOOGLE",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  _buildDownloadBanner(context, ref, widget.accentColor),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                      backgroundColor: widget.accentColor.withValues(alpha: 0.2),
                      child: user.photoURL == null ? const Icon(Icons.person, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName ?? "GATEletics User",
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            user.email ?? "",
                            style: GoogleFonts.outfit(
                              color: Colors.white30,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.white10),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Sync Status:",
                            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            syncState.status == SyncStatus.syncing
                                ? "Syncing..."
                                : syncState.status == SyncStatus.error
                                    ? "Sync Error"
                                    : syncState.lastSyncedAt != null
                                        ? "Last Synced: ${_formatSyncTime(syncState.lastSyncedAt!)}"
                                        : "Not synced",
                            style: GoogleFonts.outfit(
                              color: syncState.status == SyncStatus.error
                                  ? Colors.redAccent
                                  : widget.accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (syncState.status == SyncStatus.syncing)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: widget.accentColor),
                      )
                  ],
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
                          foregroundColor: Colors.black,
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
                                    backgroundColor: const Color(0xFF18181B),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    title: const Text("Restore Data from Cloud?"),
                                    content: const Text(
                                      "This will overwrite your local device progress with the cloud backup. This cannot be undone.",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        style: FilledButton.styleFrom(backgroundColor: widget.accentColor, foregroundColor: Colors.black),
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
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).signOut();
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    foregroundColor: Colors.white70,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: Text(
                    "SIGN OUT",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Center(
                  child: TextButton(
                    onPressed: () async {
                      // Step 1: Choice Dialog (Keep Local Data vs Delete Everything)
                      final choice = await showDialog<String>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF18181B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          title: Text(
                            'Delete Account',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
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
                                  'Deleting your account will permanently remove your cloud backups from our servers. How would you like to handle your local study progress on this device?',
                                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.5),
                                ),
                                const SizedBox(height: 16),
                                _buildDialogOption(
                                  context: context,
                                  title: "Keep Local Progress (Offline Mode)",
                                  subtitle: "Delete cloud backup, keep study data on phone in Offline Mode",
                                  icon: Icons.smartphone_rounded,
                                  color: Colors.cyanAccent,
                                  onTap: () => Navigator.pop(context, 'keepLocal'),
                                ),
                                const SizedBox(height: 12),
                                _buildDialogOption(
                                  context: context,
                                  title: "Delete Everything (Wipe Local Data)",
                                  subtitle: "Permanently delete cloud backup AND erase all local study data",
                                  icon: Icons.delete_forever_rounded,
                                  color: Colors.redAccent,
                                  onTap: () => Navigator.pop(context, 'wipeAll'),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
                            ),
                          ],
                        ),
                      );

                      if (choice == null || !context.mounted) return;

                      final isWipeAll = choice == 'wipeAll';

                      // Step 2: Final 'Are You Sure?' Confirmation Dialog
                      final confirmSecond = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF18181B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          title: Text(
                            'Are you sure?',
                            style: GoogleFonts.outfit(
                              color: isWipeAll ? Colors.redAccent : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          content: Text(
                            isWipeAll
                                ? 'This will permanently delete all your cloud backups AND permanently erase all local study progress on this device. This action CANNOT be undone.'
                                : 'This will permanently delete your cloud backups from the server. Your study progress will remain saved locally on this device in Offline Mode.',
                            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.5),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: FilledButton.styleFrom(
                                backgroundColor: isWipeAll ? Colors.redAccent : widget.accentColor,
                                foregroundColor: isWipeAll ? Colors.white : Colors.black,
                              ),
                              child: Text(
                                isWipeAll ? 'Yes, Delete Everything' : 'Yes, Delete Cloud Account',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirmSecond != true || !context.mounted) return;

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );

                      try {
                        if (isWipeAll) {
                          await ref.read(authProvider.notifier).deleteAccount();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✓ Account and all local study data deleted successfully.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } else {
                          await ref.read(authProvider.notifier).deleteServerAccountOnly();
                          await ref.read(authProvider.notifier).switchToOfflineAfterAccountDeletion();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✓ Cloud account deleted. Your study progress remains saved locally in Offline Mode.'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 4),
                              ),
                            );
                          }
                        }
                      } on FirebaseAuthException catch (e) {
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                        if (e.code == 'requires-recent-login' && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please sign out and sign in again to verify your identity before deleting your account.'),
                              backgroundColor: Colors.redAccent,
                              duration: Duration(seconds: 5),
                            ),
                          );
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.message}'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: Colors.redAccent,
                    ),
                    child: const Text(
                      "Delete Account",
                      style: TextStyle(
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.redAccent,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                _buildDownloadBanner(context, ref, widget.accentColor),
              ],
            ),
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
