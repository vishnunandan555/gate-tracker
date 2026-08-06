import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme_context_ext.dart';
import 'package:gateletics/providers/providers.dart';
import '../../../utils/ui_scaling.dart';
import '../../dashboard/widgets/settings/sync_settings.dart';
import '../../dashboard/widgets/settings/sync/sync_account_card.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = context.appColors.primaryAccent;
    final authAsync = ref.watch(authProvider);
    final user = authAsync.value?.user;
    final isSignedIn = user != null;

    return Scaffold(
      backgroundColor: context.appColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.appColors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: context.appColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Account & Sync',
          style: GoogleFonts.outfit(
            color: context.appColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(
              horizontal: context.s(16), vertical: context.s(8)),
          children: [
            // ── Zone 1: Hero Identity Card ──────────────────────────
            _HeroProfileCard(accentColor: accentColor, isSignedIn: isSignedIn),

            SizedBox(height: context.s(20)),

            // ── Zone 2: Cloud Sync Card ──────────────────────────────
            _SectionLabel(label: 'CLOUD SYNC'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: context.appColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.appColors.borderColor),
              ),
              child: SyncSettingsSection(accentColor: accentColor),
            ),

            // ── Zone 3: Danger Zone ──────────────────────────────────
            SizedBox(height: context.s(20)),
            _SectionLabel(label: 'DANGER ZONE'),
            const SizedBox(height: 8),
            _DangerZoneCard(accentColor: accentColor, isSignedIn: isSignedIn),

            SizedBox(height: context.s(24)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Profile Card
// ─────────────────────────────────────────────────────────────────────────────

class _HeroProfileCard extends ConsumerWidget {
  final Color accentColor;
  final bool isSignedIn;

  const _HeroProfileCard(
      {required this.accentColor, required this.isSignedIn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final displayName = ref.watch(displayNameProvider);
    final displayImage = ref.watch(displayProfileImageProvider);
    final authAsync = ref.watch(authProvider);
    final user = authAsync.value?.user;
    final isGoogleUser = user != null;

    final resolvedName = profile.customDisplayName?.isNotEmpty == true
        ? profile.customDisplayName!
        : (displayName ?? 'Guest Scholar');

    final emailText = isSignedIn ? (user?.email ?? '') : 'Offline / Local Storage';

    return Container(
      padding: EdgeInsets.all(context.s(20)),
      decoration: BoxDecoration(
        color: context.appColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appColors.borderColor),
      ),
      child: Column(
        children: [
          // ── Avatar + Status Badge ───────────────────────────────
          Stack(
            alignment: Alignment.center,
            children: [
              // Tappable avatar
              GestureDetector(
                onTap: () => _showPhotoOptions(
                    context, ref, isGoogleUser, accentColor),
                child: Container(
                  width: context.s(80),
                  height: context.s(80),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.4),
                      width: 2.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: context.s(38),
                    backgroundImage: displayImage,
                    onBackgroundImageError: displayImage != null ? (e, s) {} : null,
                    backgroundColor: context.appColors.surfaceColor,
                    child: displayImage == null
                        ? Text(
                            isSignedIn
                                ? (user?.email?.isNotEmpty == true
                                    ? user!.email![0].toUpperCase()
                                    : 'G')
                                : 'G',
                            style: GoogleFonts.outfit(
                              color: context.appColors.textPrimary,
                              fontSize: context.s(28),
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              // Camera icon overlay
              Positioned(
                bottom: 0,
                right: MediaQuery.sizeOf(context).width * 0.5 - context.s(56),
                child: GestureDetector(
                  onTap: () => _showPhotoOptions(
                      context, ref, isGoogleUser, accentColor),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.appColors.scaffoldBackground, width: 2),
                    ),
                    child: Icon(Icons.photo_camera_rounded,
                        color: context.appColors.onAccent, size: 14),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: context.s(14)),

          // ── Name row (tappable to edit) ─────────────────────────
          GestureDetector(
            onTap: () => _showEditNameDialog(context, ref, profile, displayName, accentColor),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    resolvedName,
                    style: GoogleFonts.outfit(
                      color: context.appColors.textPrimary,
                      fontSize: context.s(18),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.edit_rounded,
                    size: context.s(14), color: context.appColors.textMuted),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // ── Email / mode subtitle ───────────────────────────────
          Text(
            emailText,
            style: GoogleFonts.outfit(
              color: context.appColors.textMuted,
              fontSize: context.s(12),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 10),

          // ── Status pill ─────────────────────────────────────────
          Consumer(
            builder: (context, ref, _) {
              final badgeColor = accentColor;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: badgeColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isSignedIn ? 'Signed In via Google' : 'Offline Mode',
                      style: GoogleFonts.outfit(
                        color: badgeColor,
                        fontSize: context.s(11),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ── Sign-in CTA (only when offline) ────────────────────
          if (!isSignedIn) ...[
            SizedBox(height: context.s(16)),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: authAsync.isLoading
                    ? null
                    : () async {
                        try {
                          await ref.read(authProvider.notifier).signInWithGoogle();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Sign in failed: ${e.toString()}'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      },
                icon: authAsync.isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: context.appColors.onAccent),
                      )
                    : Icon(Icons.login_rounded, color: context.appColors.onAccent, size: 18),
                label: Text(
                  authAsync.isLoading ? 'Signing In…' : 'Sign In with Google',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: context.appColors.onAccent,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showEditNameDialog(
    BuildContext context,
    WidgetRef ref,
    ProfileState profile,
    String? displayName,
    Color accentColor,
  ) async {
    final controller = TextEditingController(
        text: profile.customDisplayName ?? displayName ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.dialogBackground,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Set Display Name',
            style: GoogleFonts.outfit(
                color: context.appColors.textPrimary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: GoogleFonts.outfit(color: context.appColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter name',
            hintStyle: GoogleFonts.outfit(color: context.appColors.textMuted),
            focusedBorder:
                UnderlineInputBorder(borderSide: BorderSide(color: accentColor)),
          ),
          maxLength: 30,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Cancel', style: GoogleFonts.outfit(color: context.appColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              ref.read(profileProvider.notifier).setCustomDisplayName(null);
              Navigator.pop(ctx);
            },
            child: const Text('Reset',
                style: TextStyle(color: Colors.redAccent)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: context.appColors.onAccent,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      await ref.read(profileProvider.notifier).setCustomDisplayName(result);
    }
  }

  void _showPhotoOptions(
    BuildContext context,
    WidgetRef ref,
    bool isGoogleUser,
    Color accentColor,
  ) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: context.appColors.dialogBackground,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appColors.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Profile Photo',
                style: GoogleFonts.outfit(
                    color: context.appColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            _PhotoOption(
              icon: Icons.photo_library_rounded,
              label: 'Choose Custom Photo',
              color: context.appColors.primaryAccent,
              onTap: () async {
                Navigator.pop(ctx);
                final result = await FilePicker.pickFiles(
                  type: FileType.image,
                );
                if (result != null && result.files.isNotEmpty) {
                  final file = result.files.first;
                  final bytes = await file.readAsBytes();
                  String savedPath;
                  if (file.path != null && !kIsWeb) {
                    savedPath = file.path!;
                  } else {
                    savedPath =
                        'data:image/png;base64,${base64Encode(bytes)}';
                  }
                  await ref
                      .read(profileProvider.notifier)
                      .setCustomProfilePhotoPath(savedPath);
                  await ref
                      .read(profileProvider.notifier)
                      .setProfilePhotoMode('custom');
                }
              },
            ),
            if (isGoogleUser) ...[
              const SizedBox(height: 10),
              _PhotoOption(
                icon: Icons.account_circle_rounded,
                label: 'Use Google Photo',
                color: context.appColors.primaryAccent,
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref
                      .read(profileProvider.notifier)
                      .setProfilePhotoMode('google');
                },
              ),
            ],
            const SizedBox(height: 10),
            _PhotoOption(
              icon: Icons.delete_rounded,
              label: 'Remove Photo',
              color: Colors.redAccent,
              onTap: () async {
                Navigator.pop(ctx);
                await ref
                    .read(profileProvider.notifier)
                    .setProfilePhotoMode('none');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PhotoOption(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Text(label,
                style: GoogleFonts.outfit(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Danger Zone Card (signed-in only)
// ─────────────────────────────────────────────────────────────────────────────

class _DangerZoneCard extends ConsumerWidget {
  final Color accentColor;
  final bool isSignedIn;

  const _DangerZoneCard({
    required this.accentColor,
    required this.isSignedIn,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.borderColor),
      ),
      child: Column(
        children: [
          const _ResetDataRow(),
          if (isSignedIn) ...[
            Divider(height: 1, color: context.appColors.borderColor),
            // Sign Out row
            InkWell(
              onTap: () => showSignOutConfirmationDialog(context, ref),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.appColors.surfaceColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.logout_rounded,
                          color: context.appColors.textSecondary, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text('Sign Out',
                          style: GoogleFonts.outfit(
                              color: context.appColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: context.appColors.textMuted, size: 20),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: context.appColors.borderColor),
            // Delete Account row
            _DeleteAccountRow(accentColor: accentColor),
          ],
        ],
      ),
    );
  }
}

class _ResetDataRow extends ConsumerWidget {
  const _ResetDataRow();

  Future<void> _performReset(BuildContext context, WidgetRef ref, {required bool everything}) async {
    final title = everything ? 'Reset Everything' : 'Reset Tracking Data';
    final content = everything
        ? 'This will clear ALL your sources, links, and progress. This cannot be undone.'
        : 'This will reset all your progress counts to zero but keep your sources and links.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.dialogBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          content,
          style: GoogleFonts.outfit(color: context.appColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: context.appColors.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('Reset', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      if (everything) {
        final isDark = !context.appColors.isLight;
        final db = ref.read(appDatabaseProvider);
        await db.wipeDatabaseData();

        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.clear();

        await ref.read(authProvider.notifier).resetAuthChoice();

        ref.invalidate(authProvider);
        ref.invalidate(syllabusProvider);
        ref.invalidate(progressLogsProvider);
        await ref.read(focusProvider.notifier).resetState();
        ref.invalidate(todayFocusSessionsProvider);
        ref.invalidate(todayFocusDurationProvider);
        ref.invalidate(dailyFocusGoalProvider);
        ref.invalidate(focusQuotesEnabledProvider);

        ref.invalidate(agreementProvider);
        ref.invalidate(setupCompletedProvider);
        ref.invalidate(communityNotificationsProvider);
        ref.invalidate(categoryFontSizeProvider);
        ref.invalidate(topicFontSizeProvider);
        ref.invalidate(taskFontSizeProvider);
        ref.invalidate(overallUiScaleProvider);
        await ref.read(overallProgressColorProvider.notifier).setAutoMode(isDark: isDark);
      } else {
        await ref.read(syllabusControllerProvider.notifier).resetTrackingData();

        final db = ref.read(appDatabaseProvider);
        await db.delete(db.focusSessions).go();
        await db.delete(db.dailyHistory).go();
        await db.delete(db.customTasks).go();

        ref.invalidate(syllabusProvider);
        ref.invalidate(progressLogsProvider);
        ref.invalidate(todayFocusSessionsProvider);
        ref.invalidate(todayFocusDurationProvider);
        ref.invalidate(dailyFocusGoalProvider);

        try {
          final syncNotifier = ref.read(syncProvider.notifier);
          await syncNotifier.uploadLocalToCloud();
        } catch (_) {}
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(everything ? 'System reset!' : 'Progress reset!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleStyle = GoogleFonts.outfit(color: context.appColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13);
    final subtitleStyle = GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 11);

    return ExpansionTile(
      iconColor: Colors.redAccent,
      collapsedIconColor: Colors.redAccent,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 18),
      ),
      title: Text(
        'Reset Data',
        style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 14),
      ),
      children: [
        ListTile(
          leading: const Icon(Icons.history_rounded, color: Colors.redAccent, size: 20),
          title: Text('Reset Tracking Data', style: titleStyle),
          subtitle: Text('Set all progress counts to zero', style: subtitleStyle),
          onTap: () => _performReset(context, ref, everything: false),
        ),
        Divider(color: context.appColors.borderColor, height: 1),
        ListTile(
          leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 20),
          title: Text('Reset Everything', style: titleStyle),
          subtitle: Text('Clear sources, links, and progress', style: subtitleStyle),
          onTap: () => _performReset(context, ref, everything: true),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _DeleteAccountRow extends ConsumerStatefulWidget {
  final Color accentColor;

  const _DeleteAccountRow({required this.accentColor});

  @override
  ConsumerState<_DeleteAccountRow> createState() => _DeleteAccountRowState();
}

class _DeleteAccountRowState extends ConsumerState<_DeleteAccountRow> {
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
          border: Border.all(color: context.appColors.borderColor),
          borderRadius: BorderRadius.circular(16),
          color: context.appColors.surfaceColor,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.outfit(
                          color: context.appColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style:
                          GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 10)),
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
    return InkWell(
      borderRadius:
          const BorderRadius.vertical(bottom: Radius.circular(16)),
      onTap: () async {
        final choice = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: context.appColors.dialogBackground,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text('Delete Account',
                style: GoogleFonts.outfit(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Deleting your account will permanently remove your cloud backups from our servers. How would you like to handle your local study progress on this device?',
                    style: GoogleFonts.outfit(
                        color: context.appColors.textSecondary, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  _buildDialogOption(
                    context: context,
                    title: 'Keep Local Progress (Offline Mode)',
                    subtitle:
                        'Delete cloud backup, keep study data on phone in Offline Mode',
                    icon: Icons.smartphone_rounded,
                    color: context.appColors.primaryAccent,
                    onTap: () => Navigator.pop(context, 'keepLocal'),
                  ),
                  const SizedBox(height: 12),
                  _buildDialogOption(
                    context: context,
                    title: 'Delete Everything (Wipe Local Data)',
                    subtitle:
                        'Permanently delete cloud backup AND erase all local study data',
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
                child: Text('Cancel',
                    style: GoogleFonts.outfit(color: context.appColors.textMuted)),
              ),
            ],
          ),
        );

        if (choice == null || !context.mounted) return;
        final isWipeAll = choice == 'wipeAll';

        final confirmSecond = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: context.appColors.dialogBackground,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text('Are you sure?',
                style: GoogleFonts.outfit(
                    color: isWipeAll ? Colors.redAccent : context.appColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            content: Text(
              isWipeAll
                  ? 'This will permanently delete all your cloud backups AND permanently erase all local study progress on this device. This action CANNOT be undone.'
                  : 'This will permanently delete your cloud backups from the server. Your study progress will remain saved locally on this device in Offline Mode.',
              style: GoogleFonts.outfit(
                  color: context.appColors.textSecondary, fontSize: 13, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel',
                    style: GoogleFonts.outfit(color: context.appColors.textMuted)),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      isWipeAll ? Colors.redAccent : widget.accentColor,
                  foregroundColor:
                      isWipeAll ? Colors.white : context.appColors.onAccent,
                ),
                child: Text(
                  isWipeAll
                      ? 'Yes, Delete Everything'
                      : 'Yes, Delete Cloud Account',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );

        if (confirmSecond != true || !context.mounted) return;

        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                Center(child: CircularProgressIndicator(color: context.appColors.primaryAccent)),
          );
        }

        try {
          if (isWipeAll) {
            await ref.read(authProvider.notifier).deleteAccount();
            if (context.mounted) Navigator.of(context).pop();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      '✓ Account and all local study data deleted successfully.'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            await ref
                .read(authProvider.notifier)
                .deleteServerAccountOnly();
            await ref
                .read(authProvider.notifier)
                .switchToOfflineAfterAccountDeletion();
            if (context.mounted) Navigator.of(context).pop();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      '✓ Cloud account deleted. Your study progress remains saved locally in Offline Mode.'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 4),
                ),
              );
            }
          }
        } catch (e) {
          if (context.mounted) Navigator.of(context).pop();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.redAccent),
            );
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_forever_rounded,
                  color: Colors.redAccent, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text('Delete Account',
                  style: GoogleFonts.outfit(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ),
            Icon(Icons.chevron_right_rounded,
                color: context.appColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        color: context.appColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
    );
  }
}
