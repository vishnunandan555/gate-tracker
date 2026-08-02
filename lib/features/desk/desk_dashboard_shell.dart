import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../dashboard/settings_screen.dart';
import '../dashboard/widgets/focus_screen.dart';
import '../dashboard/widgets/shell_common.dart';
import 'desk_dashboard_screen.dart';
import '../dashboard/home_screen.dart';
import '../dashboard/progress_history_screen.dart';
import '../dashboard/more_screen.dart';
import '../../core/config/brand_config.dart';
import '../dashboard/widgets/focus/focus_recovery_dialog.dart';
import '../../core/theme/theme_context_ext.dart';
import 'package:gateletics/providers/providers.dart';
import 'package:url_launcher/url_launcher.dart';

class DeskDashboardShell extends ConsumerStatefulWidget {
  const DeskDashboardShell({super.key});

  @override
  ConsumerState<DeskDashboardShell> createState() => _DeskDashboardShellState();
}

class _DeskDashboardShellState extends ConsumerState<DeskDashboardShell> {
  int _currentIndex = 0;
  bool _updateBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAndInitSync(ref);
      checkAppVersionUpdate(context, ref);
      ref.read(desktopUpdateProvider.notifier).checkOnLaunchSilently();
    });
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
    ref.read(categoryOrderLockProvider.notifier).unlockAndResort();
    ref.read(syncProvider.notifier).syncIfPending();
  }

  @override
  Widget build(BuildContext context) {
    final progressColor = context.appColors.primaryAccent;

    ref.listen<SyncState>(syncProvider, (previous, next) {
      if (next.status == SyncStatus.requiresAction && next.pendingCloudData != null) {
        showSyncConflictDialog(context, ref, progressColor);
      }
    });

    ref.listen<FocusRecoveryData?>(
      focusProvider.select((s) => s.pendingRecoveryData),
      (previous, next) {
        if (next != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              showFocusRecoveryDialog(context, next, progressColor, ref);
            }
          });
        }
      },
    );

    final overallScale = ref.watch(overallUiScaleProvider).scaleFactor;
    final updateState = ref.watch(desktopUpdateProvider);
    final isUpdateAvailable = !_updateBannerDismissed &&
        updateState.status == DesktopUpdateStatus.updateAvailable &&
        updateState.releaseInfo != null;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(overallScale),
      ),
      child: Scaffold(
        body: Column(
          children: [
            if (isUpdateAvailable)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.15),
                  border: Border(bottom: BorderSide(color: progressColor.withValues(alpha: 0.3))),
                ),
                child: Row(
                  children: [
                    Icon(Icons.system_update_rounded, color: progressColor, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'A new ${BrandConfig.appName} update (v${updateState.releaseInfo!.latestVersion}) is available!',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        final Uri url = Uri.parse(updateState.releaseInfo!.htmlUrl);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Text(
                          'DOWNLOAD UPDATE',
                          style: GoogleFonts.outfit(
                            color: progressColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 16),
                      onPressed: () {
                        setState(() => _updateBannerDismissed = true);
                      },
                      tooltip: 'Dismiss',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Row(
                children: [
                  _DeskSidebar(
                    currentIndex: _currentIndex,
                    progressColor: progressColor,
                    onTabSelected: _onTabSelected,
                    onMobileUiTap: () => context.go('/'),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _DeskHeaderBar(
                          progressColor: progressColor,
                          onTabSelected: _onTabSelected,
                        ),
                        Expanded(
                          child: IndexedStack(
                            index: _currentIndex,
                            children: [
                              KeepAliveWrapper(
                                child: HomeScreen(
                                  onNavigate: _onTabSelected,
                                ),
                              ),
                              const KeepAliveWrapper(child: DeskDashboardScreen()),
                              KeepAliveWrapper(child: FocusScreen(progressColor: progressColor)),
                              const KeepAliveWrapper(child: ProgressHistoryScreen()),
                              const KeepAliveWrapper(child: MoreScreen()),
                              const KeepAliveWrapper(child: SettingsScreen()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeskSidebar extends StatelessWidget {
  final int currentIndex;
  final Color progressColor;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onMobileUiTap;

  const _DeskSidebar({
    required this.currentIndex,
    required this.progressColor,
    required this.onTabSelected,
    required this.onMobileUiTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 768;

    return Container(
      width: isCompact ? 76 : 220,
      decoration: BoxDecoration(
        color: context.appColors.cardBackground,
        border: Border(
          right: BorderSide(color: context.appColors.borderColor),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: isCompact
                ? const EdgeInsets.symmetric(vertical: 24)
                : const EdgeInsets.fromLTRB(16, 28, 12, 24),
            child: GestureDetector(
              onTap: () => onTabSelected(1), // Navigate to Completion screen (index 1)
              behavior: HitTestBehavior.translucent,
              child: Row(
                mainAxisAlignment: isCompact ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  Image.asset('assets/logo_trans_cropped.png', width: 28, height: 28),
                  if (!isCompact) ...[
                    const SizedBox(width: 8),
                    Text(
                      BrandConfig.appName,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4), width: 1),
                      ),
                      child: Text(
                        'BETA',
                        style: GoogleFonts.outfit(
                          color: Colors.cyanAccent,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _SidebarNavItem(
            index: 0,
            currentIndex: currentIndex,
            icon: Icons.home_rounded,
            label: 'Home',
            color: progressColor,
            isCompact: isCompact,
            onTap: onTabSelected,
          ),
          _SidebarNavItem(
            index: 1,
            currentIndex: currentIndex,
            icon: Icons.percent_rounded,
            label: 'Completion',
            color: progressColor,
            isCompact: isCompact,
            onTap: onTabSelected,
          ),
          _SidebarNavItem(
            index: 2,
            currentIndex: currentIndex,
            icon: Icons.hourglass_empty_rounded,
            label: 'Focus',
            color: progressColor,
            isCompact: isCompact,
            onTap: onTabSelected,
          ),
          _SidebarNavItem(
            index: 3,
            currentIndex: currentIndex,
            icon: Icons.analytics_rounded,
            label: 'Analytics',
            color: progressColor,
            isCompact: isCompact,
            onTap: onTabSelected,
          ),
          _SidebarNavItem(
            index: 4,
            currentIndex: currentIndex,
            icon: Icons.grid_view_rounded,
            label: 'More',
            color: progressColor,
            isCompact: isCompact,
            onTap: onTabSelected,
          ),
          _SidebarNavItem(
            index: 5,
            currentIndex: currentIndex,
            icon: Icons.settings_rounded,
            label: 'Settings',
            color: progressColor,
            isCompact: isCompact,
            onTap: onTabSelected,
          ),
          const Spacer(),
          _DeskProfileFooter(
            progressColor: progressColor,
            isCompact: isCompact,
            onTapProfile: () => onTabSelected(4),
          ),
          if (kIsWeb)
            Padding(
              padding: isCompact
                  ? const EdgeInsets.fromLTRB(8, 0, 8, 24)
                  : const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: InkWell(
                onTap: onMobileUiTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: isCompact
                      ? const EdgeInsets.symmetric(vertical: 12)
                      : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withAlpha(8)),
                  ),
                  child: Row(
                    mainAxisAlignment: isCompact ? MainAxisAlignment.center : MainAxisAlignment.start,
                    children: [
                      Icon(Icons.phone_android_rounded, color: Colors.white38, size: 18),
                      if (!isCompact) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Mobile UI',
                            style: GoogleFonts.outfit(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white24, size: 16),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends ConsumerWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final String label;
  final Color color;
  final bool isCompact;
  final ValueChanged<int> onTap;

  const _SidebarNavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.label,
    required this.color,
    required this.isCompact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = currentIndex == index;

    IconData displayIcon = icon;
    String displayLabel = label;
    Color displayColor = isSelected ? color : Colors.white30;

    Widget? timerBadge;

    if (index == 2) {
      final sessionState = ref.watch(focusProvider);
      final hasActiveSession = sessionState.status != FocusStatus.idle;
      displayIcon = Icons.hourglass_empty_rounded;
      displayLabel = 'Focus';

      if (hasActiveSession) {
        if (sessionState.status == FocusStatus.focusing) {
          displayColor = color;
        } else {
          displayColor = Colors.white;
        }

        final isCountUp = sessionState.details.isCountUp;
        final displaySeconds = isCountUp
            ? sessionState.totalSecondsFocused
            : (sessionState.isBreakActive
                ? max(0, sessionState.currentTargetSeconds - sessionState.elapsedSeconds)
                : max(0, sessionState.currentTargetSeconds - sessionState.elapsedSeconds));

        final timeStr = formatDuration(displaySeconds, isCountUp);
        timerBadge = Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: displayColor, width: 1),
          ),
          child: Text(
            timeStr,
            style: GoogleFonts.outfit(
              color: displayColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }
    }

    return Padding(
      padding: isCompact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: isCompact
                ? const EdgeInsets.symmetric(vertical: 14)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? color.withAlpha(25) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: color.withAlpha(60))
                  : null,
            ),
            child: Row(
              mainAxisAlignment: isCompact ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  displayIcon,
                  color: isSelected ? (index == 2 ? displayColor : color) : (index == 2 ? displayColor.withAlpha(150) : Colors.white30),
                  size: 22,
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      displayLabel,
                      style: GoogleFonts.outfit(
                        color: isSelected ? (index == 2 ? displayColor : color) : (index == 2 ? displayColor.withAlpha(150) : Colors.white30),
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ?timerBadge,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String formatDuration(int seconds, bool isCountUp) {
    if (isCountUp) {
      final h = (seconds / 3600).floor();
      final m = ((seconds % 3600) / 60).floor();
      final s = seconds % 60;
      if (h > 0) {
        return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}";
      }
      return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    } else {
      final m = (seconds / 60).floor();
      final s = seconds % 60;
      return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    }
  }
}

class _DeskHeaderBar extends ConsumerWidget {
  final Color progressColor;
  final ValueChanged<int> onTabSelected;

  const _DeskHeaderBar({
    required this.progressColor,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completionAsync = ref.watch(completionStatsProvider);
    final completionPct = completionAsync.value?.percentage ?? 0.0;
    final syncState = ref.watch(syncProvider);
    final profile = ref.watch(profileProvider);
    final authState = ref.watch(authProvider);
    final streak = ref.watch(checkInStreakProvider);

    final user = authState.value?.user;
    final String displayName = (profile.customDisplayName != null && profile.customDisplayName!.trim().isNotEmpty)
        ? profile.customDisplayName!.trim()
        : (user?.displayName != null && user!.displayName!.trim().isNotEmpty
            ? user.displayName!.trim()
            : 'GATE Aspirant');

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: context.appColors.cardBackground,
        border: Border(
          bottom: BorderSide(color: context.appColors.borderColor),
        ),
      ),
      child: Row(
        children: [
          // Header Preparation Quick Metrics
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: progressColor.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: progressColor.withAlpha(60)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pie_chart_rounded, color: progressColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${completionPct.toStringAsFixed(1)}% Prepared',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.withAlpha(60)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department_rounded, color: Colors.amberAccent, size: 16),
                const SizedBox(width: 6),
                Text(
                  '$streak Day Streak',
                  style: GoogleFonts.outfit(
                    color: Colors.amberAccent,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Sync Status Chip with 1-tap sync trigger
          GestureDetector(
            onTap: () {
              ref.read(syncProvider.notifier).syncIfPending();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withAlpha(15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (syncState.status == SyncStatus.syncing) ...[
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Syncing...',
                      style: GoogleFonts.outfit(color: progressColor, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ] else ...[
                    Icon(
                      syncState.status == SyncStatus.error ? Icons.sync_problem_rounded : Icons.cloud_done_rounded,
                      color: syncState.status == SyncStatus.error ? Colors.redAccent : Colors.cyanAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      syncState.status == SyncStatus.error ? 'Sync Error' : 'Cloud Synced',
                      style: GoogleFonts.outfit(
                        color: syncState.status == SyncStatus.error ? Colors.redAccent : Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // User Profile Quick Tile
          GestureDetector(
            onTap: () => onTabSelected(4), // Navigate to More Hub
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: progressColor.withAlpha(40),
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'G',
                      style: GoogleFonts.outfit(color: progressColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    displayName,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeskProfileFooter extends ConsumerWidget {
  final Color progressColor;
  final bool isCompact;
  final VoidCallback onTapProfile;

  const _DeskProfileFooter({
    required this.progressColor,
    required this.isCompact,
    required this.onTapProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final authState = ref.watch(authProvider);

    final user = authState.value?.user;
    final String displayName = (profile.customDisplayName != null && profile.customDisplayName!.trim().isNotEmpty)
        ? profile.customDisplayName!.trim()
        : (user?.displayName != null && user!.displayName!.trim().isNotEmpty
            ? user.displayName!.trim()
            : 'GATE Aspirant');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: GestureDetector(
        onTap: onTapProfile,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisAlignment: isCompact ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: progressColor.withAlpha(40),
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'G',
                style: GoogleFonts.outfit(color: progressColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            if (!isCompact) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'GATE Aspirant',
                      style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.white30, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}
