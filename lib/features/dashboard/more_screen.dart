import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/config/brand_config.dart';
import '../../core/theme/theme_context_ext.dart';
import 'package:gateletics/providers/providers.dart';
import '../../utils/ui_scaling.dart';
import '../more/screens/about_screen.dart';
import '../more/screens/accounts_screen.dart';
import '../more/screens/contribute_screen.dart';
import '../more/screens/customize_ui_screen.dart';
import '../resources/resource_explorer_screen.dart';
import 'settings_screen.dart';

/// The "More" hub screen — replaces the old Settings tab.
class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen>
    with TickerProviderStateMixin {
  late final AnimationController _headerCtrl;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  final List<AnimationController> _itemCtrlList = [];
  final List<Animation<double>> _itemFadeList = [];
  final List<Animation<Offset>> _itemSlideList = [];

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));

    _headerCtrl.forward();
  }

  void _ensureItemControllers(int targetCount) {
    while (_itemCtrlList.length < targetCount) {
      final idx = _itemCtrlList.length;
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 480),
      );
      _itemCtrlList.add(ctrl);
      _itemFadeList.add(
        CurvedAnimation(parent: ctrl, curve: Curves.easeOut),
      );
      _itemSlideList.add(
        Tween<Offset>(
          begin: const Offset(0, 0.18),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic)),
      );

      Future.delayed(Duration(milliseconds: 100 + idx * 60), () {
        if (mounted && idx < _itemCtrlList.length) {
          _itemCtrlList[idx].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    for (final c in _itemCtrlList) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = context.appColors.primaryAccent;
    final packageInfo = ref.watch(packageInfoProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 768;

    final items = _buildMenuItems(accentColor, isDesktop, context, ref);
    _ensureItemControllers(items.length);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _headerFade,
                child: SlideTransition(
                  position: _headerSlide,
                  child: _MoreHeader(
                    accentColor: accentColor,
                    version: packageInfo.version,
                    isDesktop: isDesktop,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : context.s(16),
                vertical: isDesktop ? 6 : context.s(4),
              ),
              sliver: SliverReorderableList(
                itemCount: items.length,
                // ignore: deprecated_member_use
                onReorder: (oldIndex, newIndex) {
                  ref.read(moreItemOrderProvider.notifier).reorder(oldIndex, newIndex);
                },
                proxyDecorator: (Widget child, int index, Animation<double> animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      final double animValue = Curves.easeInOut.transform(animation.value);
                      final item = items[index];
                      return Transform.scale(
                        scale: lerpDouble(1.0, 1.02, animValue)!,
                        child: Material(
                          color: Colors.transparent,
                          child: _MoreMenuItem(
                            item: item,
                            accentColor: accentColor,
                            isDesktop: isDesktop,
                            isDragging: true,
                          ),
                        ),
                      );
                    },
                    child: child,
                  );
                },
                itemBuilder: (context, index) {
                  final item = items[index];
                  final fadeAnim = index < _itemFadeList.length
                      ? _itemFadeList[index]
                      : const AlwaysStoppedAnimation(1.0);
                  final slideAnim = index < _itemSlideList.length
                      ? _itemSlideList[index]
                      : const AlwaysStoppedAnimation(Offset.zero);

                  return ReorderableDelayedDragStartListener(
                    key: ValueKey(item.id),
                    index: index,
                    child: FadeTransition(
                      opacity: fadeAnim,
                      child: SlideTransition(
                        position: slideAnim,
                        child: _MoreMenuItem(
                          item: item,
                          accentColor: accentColor,
                          isDesktop: isDesktop,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(
                  top: isDesktop ? 16 : context.s(8),
                  bottom: isDesktop ? 24 : context.s(24),
                ),
                child: Center(
                  child: Text(
                    '${BrandConfig.appName} v${packageInfo.version}',
                    style: GoogleFonts.outfit(
                      color: context.appColors.textMuted,
                      fontSize: isDesktop ? 11 : context.s(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_MoreMenuItemData> _buildMenuItems(
    Color accentColor,
    bool isDesktop,
    BuildContext context,
    WidgetRef ref,
  ) {
    final navBarSlots = ref.watch(navBarSlotsProvider);
    final savedOrder = ref.watch(moreItemOrderProvider);

    final Map<String, _MoreMenuItemData> rawMap = {
      'customizer': _MoreMenuItemData(
        id: 'customizer',
        icon: Icons.tune_rounded,
        label: 'Customize UI',
        subtitle: 'Theme color, fonts, animations & navigation',
        color: accentColor,
        comingSoon: false,
        onTap: (ctx) => _pushPage(ctx, const CustomizeUiScreen()),
      ),
      'accounts': _MoreMenuItemData(
        id: 'accounts',
        icon: Icons.manage_accounts_rounded,
        label: 'Account and Sync',
        subtitle: 'Cloud sync, account details and security',
        color: accentColor,
        comingSoon: false,
        onTap: (ctx) => _pushPage(ctx, const AccountsScreen()),
      ),
      'settings': _MoreMenuItemData(
        id: 'settings',
        icon: Icons.settings_rounded,
        label: 'Settings',
        subtitle: 'Explore app settings, backup & data controls',
        color: accentColor,
        comingSoon: false,
        onTap: (ctx) => _pushPage(ctx, const SettingsScreen()),
      ),
      'contribute': _MoreMenuItemData(
        id: 'contribute',
        icon: Icons.volunteer_activism_rounded,
        label: 'Contribute to Community',
        subtitle: 'Contribute on GitHub and report issues',
        color: accentColor,
        comingSoon: false,
        onTap: (ctx) => _pushPage(ctx, const ContributeScreen()),
      ),
      'about': _MoreMenuItemData(
        id: 'about',
        icon: Icons.info_outline_rounded,
        label: 'About ${BrandConfig.appName}',
        subtitle: 'App info, developer details and credits',
        color: accentColor,
        comingSoon: false,
        onTap: (ctx) => _pushPage(ctx, const AboutScreen()),
      ),
      'socials': _MoreMenuItemData(
        id: 'socials',
        icon: Icons.group_rounded,
        label: 'Friends & Socials',
        subtitle: 'Study groups and accountability partners',
        color: accentColor,
        comingSoon: true,
        onTap: (ctx) => _showPreviewModal(
          ctx,
          'Friends & Socials',
          'Study groups, accountability partners, and friend leaderboards will be available in an upcoming release!',
          accentColor,
        ),
      ),
      'resources': _MoreMenuItemData(
        id: 'resources',
        icon: Icons.library_books_rounded,
        label: 'Resource Explorer',
        subtitle: 'Curated playlists, courses & study resources',
        color: accentColor,
        comingSoon: false,
        onTap: (ctx) => _pushPage(ctx, const ResourceExplorerScreen()),
      ),
      'planner': _MoreMenuItemData(
        id: 'planner',
        icon: Icons.edit_calendar_rounded,
        label: 'Revision Planner',
        subtitle: 'Spaced repetition planner and calendars',
        color: accentColor,
        comingSoon: true,
        onTap: (ctx) => _showPreviewModal(
          ctx,
          'Revision Planner',
          'Automated spaced-repetition revision schedules and exam countdowns are coming in the next update!',
          accentColor,
        ),
      ),
      'notifications': _MoreMenuItemData(
        id: 'notifications',
        icon: Icons.notifications_active_rounded,
        label: 'Notifications & Reminders',
        subtitle: 'Configure reminders and custom study alerts',
        color: accentColor,
        comingSoon: true,
        onTap: (ctx) => _showPreviewModal(
          ctx,
          'Notifications & Reminders',
          'Custom daily study reminders and revision alerts will be configurable in an upcoming update!',
          accentColor,
        ),
      ),
    };

    final List<_MoreMenuItemData> result = [];

    // Add saved order items if not in bottom nav bar
    for (final id in savedOrder) {
      if (rawMap.containsKey(id) && !navBarSlots.contains(id)) {
        result.add(rawMap[id]!);
      }
    }

    // Add any remaining items not yet in result and not in bottom nav bar
    for (final entry in rawMap.entries) {
      if (!navBarSlots.contains(entry.key) && !result.any((item) => item.id == entry.key)) {
        result.add(entry.value);
      }
    }

    return result;
  }

  void _pushPage(BuildContext context, Widget targetScreen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => targetScreen),
    );
  }

  void _showPreviewModal(
      BuildContext context, String title, String message, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                    color: context.appColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.outfit(
              color: context.appColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Got it',
                style: GoogleFonts.outfit(
                    color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _MoreHeader extends ConsumerWidget {
  final Color accentColor;
  final String version;
  final bool isDesktop;

  const _MoreHeader({
    required this.accentColor,
    required this.version,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 32 : context.s(20),
        isDesktop ? 36 : context.s(32), // Increased top gap above logo
        isDesktop ? 32 : context.s(20),
        isDesktop ? 12 : context.s(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Centered Header Logo & App Title (Perfect Vertical & Horizontal Alignment)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo_trans_cropped.png',
                width: isDesktop ? 48 : context.s(42),
                height: isDesktop ? 48 : context.s(42),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.app_shortcut_rounded,
                  size: isDesktop ? 48 : context.s(42),
                  color: accentColor,
                ),
              ),
              SizedBox(width: isDesktop ? 10 : context.s(8)),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'GATE',
                    style: GoogleFonts.boldonse(
                      fontSize: isDesktop ? 24 : context.s(22),
                      color: context.appColors.textPrimary,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'LETICS',
                    style: GoogleFonts.orbitron(
                      fontSize: isDesktop ? 24 : context.s(22),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: context.appColors.textPrimary,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Centered Version tag
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'v$version  ',
                style: GoogleFonts.outfit(
                  color: context.appColors.textMuted,
                  fontSize: isDesktop ? 11 : context.s(10),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(5),
                  border:
                      Border.all(color: accentColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  'Beta',
                  style: GoogleFonts.outfit(
                    color: accentColor,
                    fontSize: isDesktop ? 9.5 : context.s(8.5),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 20 : context.s(18)),

          // Centered Category Section Header
          Center(
            child: Text(
              'MORE OPTIONS & FEATURES',
              style: GoogleFonts.outfit(
                color: context.appColors.textSecondary,
                fontSize: isDesktop ? 12 : context.s(11),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          SizedBox(height: isDesktop ? 6 : context.s(4)),
        ],
      ),
    );
  }
}

// ── Menu item data ─────────────────────────────────────────────────────────────

class _MoreMenuItemData {
  final String id;
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool comingSoon;
  final void Function(BuildContext context)? onTap;

  const _MoreMenuItemData({
    required this.id,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.comingSoon,
    required this.onTap,
  });
}

// ── Menu item widget ───────────────────────────────────────────────────────────

class _MoreMenuItem extends ConsumerStatefulWidget {
  final _MoreMenuItemData item;
  final Color accentColor;
  final bool isDesktop;
  final bool isDragging;

  const _MoreMenuItem({
    required this.item,
    required this.accentColor,
    required this.isDesktop,
    this.isDragging = false,
  });

  @override
  ConsumerState<_MoreMenuItem> createState() => _MoreMenuItemState();
}

class _MoreMenuItemState extends ConsumerState<_MoreMenuItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;

  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDesktop = widget.isDesktop;
    final isDisabled = item.comingSoon;
    final boxStyle = ref.watch(iconBoxStyleProvider);

    final cardHeight = isDesktop ? 64.0 : context.s(60.0);
    final iconBoxSize = isDesktop ? 44.0 : context.s(42.0);
    final iconSize = isDesktop ? 22.0 : context.s(20.0);
    final borderRadius = BorderRadius.circular(isDesktop ? 14 : context.s(14));

    if (boxStyle == IconBoxStyle.separated) {
      // Separated External Icon Layout (Image 2 style)
      return Padding(
        padding: EdgeInsets.only(bottom: isDesktop ? 10 : context.s(8)),
        child: AnimatedBuilder(
          animation: _pressCtrl,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: GestureDetector(
                onTapDown: isDisabled
                    ? null
                    : (_) {
                        setState(() => _pressed = true);
                        _pressCtrl.forward();
                      },
                onTapUp: isDisabled
                    ? null
                    : (_) {
                        setState(() => _pressed = false);
                        _pressCtrl.reverse();
                        item.onTap?.call(context);
                      },
                onTapCancel: isDisabled
                    ? null
                    : () {
                        setState(() => _pressed = false);
                        _pressCtrl.reverse();
                      },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Standalone icon outside the box on the left - perfectly centered
                    SizedBox(
                      width: isDesktop ? 40 : context.s(36),
                      height: cardHeight,
                      child: Center(
                        child: Icon(
                          item.icon,
                          color: isDisabled
                              ? item.color.withValues(alpha: 0.45)
                              : item.color,
                          size: isDesktop ? 30 : context.s(26),
                        ),
                      ),
                    ),
                    SizedBox(width: isDesktop ? 10 : context.s(8)),
                    // Card Box containing Title/Subtitle & Circular Action Arrow Button
                    Expanded(
                      child: Container(
                        height: cardHeight,
                        decoration: BoxDecoration(
                          color: isDisabled
                              ? context.appColors.cardBackground
                              : context.appColors.surfaceColor,
                          borderRadius: borderRadius,
                          border: Border.all(
                            color: (_pressed || widget.isDragging)
                                ? item.color.withValues(alpha: 0.45)
                                : context.appColors.borderColor,
                            width: 1.0,
                          ),
                          boxShadow: [
                            if (_pressed || widget.isDragging)
                              BoxShadow(
                                color: item.color.withValues(alpha: 0.45),
                                blurRadius: 22,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 16 : context.s(14),
                          vertical: isDesktop ? 8 : context.s(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          item.label,
                                          style: GoogleFonts.outfit(
                                            color: isDisabled
                                                ? context.appColors.textMuted
                                                : context.appColors.textPrimary,
                                            fontSize: isDesktop ? 15 : context.s(14),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (item.comingSoon) ...[
                                        SizedBox(width: context.s(7)),
                                        _ComingSoonBadge(
                                          color: item.color,
                                          isDesktop: isDesktop,
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.subtitle,
                                    style: GoogleFonts.outfit(
                                      color: context.appColors.textSecondary.withValues(
                                          alpha: isDisabled ? 0.5 : 1.0),
                                      fontSize: isDesktop ? 11 : context.s(10.5),
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: isDesktop ? 8 : context.s(6)),
                            // Solid accent-colored circle button with ON-ACCENT color arrow inside
                            Container(
                              width: isDesktop ? 32 : context.s(28),
                              height: isDesktop ? 32 : context.s(28),
                              decoration: BoxDecoration(
                                color: isDisabled
                                    ? item.color.withValues(alpha: 0.35)
                                    : item.color,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: isDisabled ? context.appColors.textMuted : context.appColors.onAccent,
                                  size: isDesktop ? 18 : context.s(16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    // Integrated / Outlined / Minimal Card Layouts
    return Padding(
      padding: EdgeInsets.only(bottom: isDesktop ? 10 : context.s(8)),
      child: AnimatedBuilder(
        animation: _pressCtrl,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: GestureDetector(
              onTapDown: isDisabled
                  ? null
                  : (_) {
                      setState(() => _pressed = true);
                      _pressCtrl.forward();
                    },
              onTapUp: isDisabled
                  ? null
                  : (_) {
                      setState(() => _pressed = false);
                      _pressCtrl.reverse();
                      item.onTap?.call(context);
                    },
              onTapCancel: isDisabled
                  ? null
                  : () {
                      setState(() => _pressed = false);
                      _pressCtrl.reverse();
                    },
              child: Container(
                height: cardHeight,
                decoration: BoxDecoration(
                  color: isDisabled
                      ? context.appColors.cardBackground
                      : context.appColors.surfaceColor,
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: (_pressed || widget.isDragging)
                        ? item.color.withValues(alpha: 0.45)
                        : context.appColors.borderColor,
                    width: 1.0,
                  ),
                  boxShadow: [
                    if (_pressed || widget.isDragging)
                      BoxShadow(
                        color: item.color.withValues(alpha: 0.45),
                        blurRadius: 22,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 14 : context.s(12),
                  vertical: isDesktop ? 8 : context.s(8),
                ),
                child: Row(
                  children: [
                    _buildIconWidget(boxStyle, item, isDisabled, iconBoxSize, iconSize, isDesktop),
                    SizedBox(width: isDesktop ? 14 : context.s(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  item.label,
                                  style: GoogleFonts.outfit(
                                    color: isDisabled
                                        ? context.appColors.textMuted
                                        : context.appColors.textPrimary,
                                    fontSize: isDesktop ? 14 : context.s(13.5),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (item.comingSoon) ...[
                                SizedBox(width: context.s(7)),
                                _ComingSoonBadge(
                                  color: item.color,
                                  isDesktop: isDesktop,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            style: GoogleFonts.outfit(
                              color: isDisabled ? context.appColors.textMuted : context.appColors.textSecondary,
                              fontSize: isDesktop ? 11 : context.s(10.5),
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: isDesktop ? 8 : context.s(6)),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDisabled
                          ? context.appColors.textMuted
                          : context.appColors.textSecondary,
                      size: isDesktop ? 20 : context.s(18),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIconWidget(
    IconBoxStyle boxStyle,
    _MoreMenuItemData item,
    bool isDisabled,
    double iconBoxSize,
    double iconSize,
    bool isDesktop,
  ) {
    switch (boxStyle) {
      case IconBoxStyle.outlined:
        return Container(
          width: iconBoxSize,
          height: iconBoxSize,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(isDesktop ? 11 : context.s(10)),
            border: Border.all(
              color: item.color.withValues(alpha: isDisabled ? 0.20 : 0.55),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(
              item.icon,
              color: isDisabled ? item.color.withValues(alpha: 0.45) : item.color,
              size: iconSize,
            ),
          ),
        );
      case IconBoxStyle.minimal:
        return SizedBox(
          width: iconBoxSize * 0.8,
          height: iconBoxSize,
          child: Center(
            child: Icon(
              item.icon,
              color: isDisabled ? item.color.withValues(alpha: 0.45) : item.color,
              size: iconSize * 1.15,
            ),
          ),
        );
      case IconBoxStyle.filled:
      default:
        return Container(
          width: iconBoxSize,
          height: iconBoxSize,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: isDisabled ? 0.08 : 0.14),
            borderRadius: BorderRadius.circular(isDesktop ? 11 : context.s(10)),
            border: Border.all(
              color: item.color.withValues(alpha: isDisabled ? 0.15 : 0.28),
              width: 1.0,
            ),
          ),
          child: Center(
            child: Icon(
              item.icon,
              color: isDisabled ? item.color.withValues(alpha: 0.45) : item.color,
              size: iconSize,
            ),
          ),
        );
    }
  }
}

// ── "Coming Soon" badge ────────────────────────────────────────────────────────

class _ComingSoonBadge extends StatelessWidget {
  final Color color;
  final bool isDesktop;

  const _ComingSoonBadge({required this.color, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 6 : context.s(5),
        vertical: isDesktop ? 2 : context.s(2),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        'SOON',
        style: GoogleFonts.outfit(
          color: color.withValues(alpha: 0.70),
          fontSize: isDesktop ? 8.5 : context.s(8),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
