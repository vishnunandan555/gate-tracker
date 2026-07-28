import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/sync_provider.dart';
import '../../providers/subject_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../dashboard/settings_screen.dart';
import '../dashboard/widgets/focus_screen.dart';
import '../../providers/focus_provider.dart';
import '../dashboard/widgets/shell_common.dart';
import 'desk_dashboard_screen.dart';
import '../../providers/overall_ui_scale_provider.dart';
import '../dashboard/home_screen.dart';
import '../../providers/desktop_update_provider.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    final progressColor = ref.watch(overallProgressColorProvider);

    ref.listen<SyncState>(syncProvider, (previous, next) {
      if (next.status == SyncStatus.requiresAction && next.pendingCloudData != null) {
        showSyncConflictDialog(context, ref, progressColor);
      }
    });

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
                        'A new GATEletics update (v${updateState.releaseInfo!.latestVersion}) is available!',
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
        color: const Color(0xFF131316),
        border: Border(
          right: BorderSide(color: Colors.white.withAlpha(12)),
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
                      'GATEletics',
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
            icon: Icons.settings_rounded,
            label: 'Settings',
            color: progressColor,
            isCompact: isCompact,
            onTap: onTabSelected,
          ),
          const Spacer(),
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
