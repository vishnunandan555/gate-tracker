import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/subject_provider.dart';
import '../../providers/package_info_provider.dart';
import '../../utils/ui_scaling.dart';
import '../more/screens/about_screen.dart';
import '../more/screens/accounts_screen.dart';
import '../more/screens/contribute_screen.dart';
import '../more/screens/customize_nav_bar_screen.dart';
import 'settings_screen.dart';

enum IconBoxStyle {
  subtleFillOutline, // Tinted fill + colored outline + colored icon (default)
  noFillOutline,     // Transparent fill + colored outline + colored icon
  darkFillNoOutline, // Dark 0xFF131316 background + no outline + colored icon
  solidAccentFill,   // Full accent fill + dark 0xFF131316 icon inside
  noBoxMinimal,      // No square box container, icon sits directly on left
}

class IconBoxStyleNotifier extends Notifier<IconBoxStyle> {
  @override
  IconBoxStyle build() => IconBoxStyle.darkFillNoOutline;

  void cycleNext() {
    final nextIndex = (state.index + 1) % IconBoxStyle.values.length;
    state = IconBoxStyle.values[nextIndex];
  }
}

final iconBoxStyleProvider =
    NotifierProvider<IconBoxStyleNotifier, IconBoxStyle>(() {
  return IconBoxStyleNotifier();
});

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

  static const int _itemCount = 9;

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

    for (int i = 0; i < _itemCount; i++) {
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
    }

    _headerCtrl.forward();
    for (int i = 0; i < _itemCount; i++) {
      Future.delayed(Duration(milliseconds: 100 + i * 60), () {
        if (mounted && i < _itemCtrlList.length) _itemCtrlList[i].forward();
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
    final accentColor = ref.watch(overallProgressColorProvider);
    final packageInfo = ref.watch(packageInfoProvider);
    final currentStyle = ref.watch(iconBoxStyleProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth > 900;

    final items = _buildMenuItems(accentColor, isDesktop, context, ref);

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
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = items[index];
                    final fadeAnim = index < _itemFadeList.length
                        ? _itemFadeList[index]
                        : const AlwaysStoppedAnimation(1.0);
                    final slideAnim = index < _itemSlideList.length
                        ? _itemSlideList[index]
                        : const AlwaysStoppedAnimation(Offset.zero);

                    return FadeTransition(
                      opacity: fadeAnim,
                      child: SlideTransition(
                        position: slideAnim,
                        child: _MoreMenuItem(
                          item: item,
                          accentColor: accentColor,
                          isDesktop: isDesktop,
                          boxStyle: currentStyle,
                        ),
                      ),
                    );
                  },
                  childCount: items.length,
                ),
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
                    'GATEletics v${packageInfo.version}',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.22),
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
    return [
      _MoreMenuItemData(
        icon: Icons.tune_rounded,
        label: 'Customize Nav Bar',
        subtitle: 'Personalize navigation layout, tabs and scale',
        color: const Color(0xFF00F0FF),
        comingSoon: false,
        onTap: (ctx) => _pushPage(ctx, const CustomizeNavBarScreen()),
      ),
      _MoreMenuItemData(
        icon: Icons.manage_accounts_rounded,
        label: 'Accounts and Sign In',
        subtitle: 'Cloud sync, account details and security',
        color: const Color(0xFFE040FB),
        comingSoon: false,
        onTap: (ctx) => _pushPage(ctx, const AccountsScreen()),
      ),
      _MoreMenuItemData(
        icon: Icons.settings_rounded,
        label: 'Settings',
        subtitle: 'Explore app settings, backup & data controls',
        color: accentColor,
        comingSoon: false,
        onTap: (ctx) => _pushPage(ctx, const SettingsScreen()),
      ),
      _MoreMenuItemData(
        icon: Icons.volunteer_activism_rounded,
        label: 'Contribute to Community',
        subtitle: 'Contribute on GitHub and report issues',
        color: const Color(0xFFFF5E00),
        comingSoon: false,
        onTap: (ctx) => _pushPage(ctx, const ContributeScreen()),
      ),
      _MoreMenuItemData(
        icon: Icons.info_outline_rounded,
        label: 'About GATEletics',
        subtitle: 'App info, developer details and credits',
        color: const Color(0xFF39FF14),
        comingSoon: false,
        onTap: (ctx) => _pushPage(ctx, const AboutScreen()),
      ),
      _MoreMenuItemData(
        icon: Icons.group_rounded,
        label: 'Friends & Socials',
        subtitle: 'Study groups and accountability partners',
        color: const Color(0xFF4C73FF),
        comingSoon: true,
        onTap: (ctx) => _showPreviewModal(
          ctx,
          'Friends & Socials',
          'Study groups, accountability partners, and friend leaderboards will be available in an upcoming release!',
          const Color(0xFF4C73FF),
        ),
      ),
      _MoreMenuItemData(
        icon: Icons.library_books_rounded,
        label: 'Resource Explorer',
        subtitle: 'Curated revision resources and formulas',
        color: const Color(0xFF00B0FF),
        comingSoon: true,
        onTap: (ctx) => _showPreviewModal(
          ctx,
          'Resource Explorer',
          'Community-curated formulas, PYQ solutions, and recommended lecture notes will be released soon!',
          const Color(0xFF00B0FF),
        ),
      ),
      _MoreMenuItemData(
        icon: Icons.edit_calendar_rounded,
        label: 'Revision Planner',
        subtitle: 'Spaced repetition planner and calendars',
        color: const Color(0xFF00FFCC),
        comingSoon: true,
        onTap: (ctx) => _showPreviewModal(
          ctx,
          'Revision Planner',
          'Automated spaced-repetition revision schedules and exam countdowns are coming in the next update!',
          const Color(0xFF00FFCC),
        ),
      ),
      _MoreMenuItemData(
        icon: Icons.notifications_active_rounded,
        label: 'Notifications & Reminders',
        subtitle: 'Configure reminders and custom study alerts',
        color: const Color(0xFFFFAD00),
        comingSoon: true,
        onTap: (ctx) => _showPreviewModal(
          ctx,
          'Notifications & Reminders',
          'Custom daily study reminders and revision alerts will be configurable in an upcoming update!',
          const Color(0xFFFFAD00),
        ),
      ),
    ];
  }

  void _pushPage(BuildContext context, Widget targetScreen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (ctx, anim, secondaryAnim) => targetScreen,
        transitionsBuilder: (ctx, anim, secondaryAnim, child) {
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showPreviewModal(
      BuildContext context, String title, String message, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.outfit(
              color: Colors.white70, fontSize: 13, height: 1.4),
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
                width: isDesktop ? 34 : context.s(30),
                height: isDesktop ? 34 : context.s(30),
                fit: BoxFit.contain,
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
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'LETICS',
                    style: GoogleFonts.orbitron(
                      fontSize: isDesktop ? 24 : context.s(22),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Colors.white,
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
                  color: Colors.white38,
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
                color: Colors.white.withValues(alpha: 0.70),
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
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool comingSoon;
  final void Function(BuildContext context)? onTap;

  const _MoreMenuItemData({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.comingSoon,
    required this.onTap,
  });
}

// ── Menu item widget ───────────────────────────────────────────────────────────

class _MoreMenuItem extends StatefulWidget {
  final _MoreMenuItemData item;
  final Color accentColor;
  final bool isDesktop;
  final IconBoxStyle boxStyle;

  const _MoreMenuItem({
    required this.item,
    required this.accentColor,
    required this.isDesktop,
    required this.boxStyle,
  });

  @override
  State<_MoreMenuItem> createState() => _MoreMenuItemState();
}

class _MoreMenuItemState extends State<_MoreMenuItem>
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
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
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

    final cardSize = isDesktop ? 64.0 : context.s(58.0);
    final iconSize = isDesktop ? 30.0 : context.s(28.0);
    final borderRadius = BorderRadius.circular(isDesktop ? 12 : context.s(10));

    return Padding(
      padding: EdgeInsets.only(bottom: isDesktop ? 9 : context.s(8)),
      child: AnimatedBuilder(
        animation: _pressCtrl,
        builder: (context, child) {
          final glowOpacity = _pressCtrl.value * 0.28;
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
              child: SizedBox(
                height: cardSize,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon Container Box (Styled according to boxStyle selection)
                    _buildIconBox(cardSize, iconSize, borderRadius, isDisabled,
                        glowOpacity),
                    SizedBox(width: isDesktop ? 12 : context.s(10)),
                    // Content Rectangle Card (No colored border outline, clean dark fill)
                    Expanded(
                      child: Container(
                        height: cardSize,
                        decoration: BoxDecoration(
                          color: isDisabled
                              ? const Color(0xFF131316)
                              : const Color(0xFF1B1B22),
                          borderRadius: borderRadius,
                          border: Border.all(
                            color: _pressed
                                ? item.color.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.05),
                            width: 1.0,
                          ),
                          boxShadow: [
                            if (_pressed)
                              BoxShadow(
                                color: item.color.withValues(alpha: glowOpacity),
                                blurRadius: 20,
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 14 : context.s(12),
                          vertical: isDesktop ? 4 : context.s(3),
                        ),
                        child: Row(
                          children: [
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
                                                ? Colors.white.withValues(alpha: 0.4)
                                                : Colors.white,
                                            fontSize: isDesktop
                                                ? 14
                                                : context.s(13.5),
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
                                  const SizedBox(height: 1),
                                  Text(
                                    item.subtitle,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white.withValues(
                                          alpha: isDisabled ? 0.25 : 0.45),
                                      fontSize: isDesktop ? 11 : context.s(10.5),
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: isDesktop ? 8 : context.s(6)),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: isDisabled
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.white.withValues(alpha: 0.35),
                              size: isDesktop ? 16 : context.s(14),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildIconBox(double cardSize, double iconSize,
      BorderRadius borderRadius, bool isDisabled, double glowOpacity) {
    final item = widget.item;

    switch (widget.boxStyle) {
      case IconBoxStyle.subtleFillOutline:
        // Style 1: Tinted fill + colored outline + colored icon
        return Container(
          width: cardSize,
          height: cardSize,
          decoration: BoxDecoration(
            color: isDisabled
                ? item.color.withValues(alpha: 0.12)
                : item.color.withValues(alpha: 0.22),
            borderRadius: borderRadius,
            border: Border.all(
              color: _pressed
                  ? item.color
                  : item.color.withValues(alpha: isDisabled ? 0.20 : 0.45),
              width: 1.2,
            ),
            boxShadow: [
              if (_pressed)
                BoxShadow(
                  color: item.color.withValues(alpha: glowOpacity),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Center(
            child: Icon(
              item.icon,
              color: isDisabled
                  ? item.color.withValues(alpha: 0.45)
                  : item.color,
              size: iconSize,
            ),
          ),
        );

      case IconBoxStyle.noFillOutline:
        // Style 2: Transparent fill + colored outline + colored icon
        return Container(
          width: cardSize,
          height: cardSize,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: borderRadius,
            border: Border.all(
              color: _pressed
                  ? item.color
                  : item.color.withValues(alpha: isDisabled ? 0.20 : 0.55),
              width: 1.5,
            ),
            boxShadow: [
              if (_pressed)
                BoxShadow(
                  color: item.color.withValues(alpha: glowOpacity),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Center(
            child: Icon(
              item.icon,
              color: isDisabled
                  ? item.color.withValues(alpha: 0.45)
                  : item.color,
              size: iconSize,
            ),
          ),
        );

      case IconBoxStyle.darkFillNoOutline:
        // Style 3: Dark 0xFF131316 fill + no outline + colored icon
        return Container(
          width: cardSize,
          height: cardSize,
          decoration: BoxDecoration(
            color: const Color(0xFF131316),
            borderRadius: borderRadius,
            border: Border.all(
              color: _pressed
                  ? item.color.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.05),
              width: 1.0,
            ),
          ),
          child: Center(
            child: Icon(
              item.icon,
              color: isDisabled
                  ? item.color.withValues(alpha: 0.45)
                  : item.color,
              size: iconSize,
            ),
          ),
        );

      case IconBoxStyle.solidAccentFill:
        // Style 4: Solid accent fill + dark icon inside
        final fillColor =
            isDisabled ? item.color.withValues(alpha: 0.35) : item.color;
        final iconColor =
            isDisabled ? Colors.white38 : const Color(0xFF131316);
        return Container(
          width: cardSize,
          height: cardSize,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: borderRadius,
            boxShadow: [
              if (_pressed)
                BoxShadow(
                  color: item.color.withValues(alpha: glowOpacity * 1.5),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Center(
            child: Icon(
              item.icon,
              color: iconColor,
              size: iconSize,
            ),
          ),
        );

      case IconBoxStyle.noBoxMinimal:
        // Style 5: No square box container at all, icon directly on left
        return SizedBox(
          width: cardSize * 0.75,
          height: cardSize,
          child: Center(
            child: Icon(
              item.icon,
              color: isDisabled
                  ? item.color.withValues(alpha: 0.45)
                  : item.color,
              size: iconSize * 1.15,
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
