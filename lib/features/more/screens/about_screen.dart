import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/brand_config.dart';
import '../../../core/theme/theme_context_ext.dart';
import 'package:gateletics/providers/providers.dart';
import '../../../utils/ui_scaling.dart';
import '../../dashboard/widgets/changelog_dialog.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageInfo = ref.watch(packageInfoProvider);

    return Scaffold(
      backgroundColor: context.appColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.appColors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.appColors.textPrimary, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'About ${BrandConfig.appName}',
          style: GoogleFonts.outfit(
            color: context.appColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(context.s(16)),
          children: [
            // ── Top Hero Header Section ────────────────────────────────────
            _AnimatedCard(
              padding: EdgeInsets.symmetric(horizontal: context.s(20), vertical: context.s(24)),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: [
                  // App Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: Image.asset(
                        'assets/icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.cyanAccent.withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Colors.cyanAccent,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Brand Typography
                  Text(
                    BrandConfig.appName,
                    style: GoogleFonts.orbitron(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      height: 1.0,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tagline
                  Text(
                    BrandConfig.appTagline,
                    style: GoogleFonts.outfit(
                      color: context.appColors.textMuted,
                      fontSize: context.s(12),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Version + Build Info badges row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Badge(
                        label: 'v${packageInfo.version} • What\'s New',
                        onTap: () => showChangelogDialog(context, version: packageInfo.version),
                      ),
                      const SizedBox(width: 8),
                      _Badge(label: 'Build ${packageInfo.buildNumber}'),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: context.s(12)),

            // ── Link Buttons Row ───────────────────────────────────────────
            Row(
              children: [
                const Expanded(
                  child: _LinkButton(
                    icon: Icons.language_rounded,
                    label: 'Website',
                    url: BrandConfig.docsUrl,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: _LinkButton(
                    assetIcon: 'assets/github.png',
                    label: 'GitHub',
                    url: BrandConfig.githubRepoUrl,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: _LinkButton(
                    icon: Icons.shop_rounded,
                    label: 'Play Store',
                    url: BrandConfig.playStoreUrl,
                  ),
                ),
              ],
            ),

            SizedBox(height: context.s(12)),

            // ── Application Info Card ──────────────────────────────────────
            _AnimatedCard(
              padding: EdgeInsets.all(context.s(18)),
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.person_rounded,
                    label: 'Developer',
                    value: BrandConfig.companyName,
                  ),
                  Divider(color: context.appColors.dividerColor, height: 24),
                  _InfoRow(
                    icon: Icons.business_center_rounded,
                    label: 'Package',
                    value: BrandConfig.androidPackageId,
                  ),
                  Divider(color: context.appColors.dividerColor, height: 24),
                  _InfoRow(
                    icon: Icons.code_rounded,
                    label: 'Framework',
                    value: 'Flutter (Dart)',
                  ),
                ],
              ),
            ),

            SizedBox(height: context.s(12)),

            // ── Legal Disclaimer Card ─────────────────────────────────────
            _AnimatedCard(
              padding: const EdgeInsets.all(14),
              borderRadius: BorderRadius.circular(14),
              child: Text(
                BrandConfig.legalDisclaimer,
                style: GoogleFonts.outfit(
                  color: context.appColors.textMuted,
                  fontSize: context.s(11),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: context.s(16)),

            // ── ToS & Privacy Policy ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _TextLink(
                  label: 'Terms of Service',
                  url: BrandConfig.termsUrl,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('·', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 14)),
                ),
                const _TextLink(
                  label: 'Privacy Policy',
                  url: BrandConfig.privacyUrl,
                ),
              ],
            ),

            if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux)) ...[
              SizedBox(height: context.s(16)),
              const _DesktopAboutUpdateTile(),
            ],

            SizedBox(height: context.s(24)),
          ],
        ),
      ),
    );
  }
}

class _DesktopAboutUpdateTile extends ConsumerWidget {
  const _DesktopAboutUpdateTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = ref.watch(overallProgressColorProvider);
    final updateState = ref.watch(desktopUpdateProvider);

    Widget statusContent;
    if (updateState.status == DesktopUpdateStatus.checking) {
      statusContent = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: accentColor),
          ),
          const SizedBox(width: 8),
          Text(
            'Checking for updates...',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11.5),
          ),
        ],
      );
    } else if (updateState.status == DesktopUpdateStatus.updateAvailable && updateState.releaseInfo != null) {
      statusContent = Column(
        children: [
          Text(
            'GATEletics v${updateState.releaseInfo!.latestVersion} is available!',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final Uri url = Uri.parse(updateState.releaseInfo!.htmlUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: Text(
              'Download Update',
              style: GoogleFonts.outfit(color: accentColor, fontWeight: FontWeight.bold, fontSize: 11.5, decoration: TextDecoration.underline),
            ),
          ),
        ],
      );
    } else if (updateState.status == DesktopUpdateStatus.upToDate) {
      statusContent = Text(
        '✓ You are using the latest version',
        style: GoogleFonts.outfit(color: Colors.greenAccent.withValues(alpha: 0.8), fontWeight: FontWeight.w600, fontSize: 11.5),
      );
    } else if (updateState.status == DesktopUpdateStatus.error) {
      statusContent = Text(
        updateState.errorMessage ?? 'Could not check for updates',
        style: GoogleFonts.outfit(color: Colors.redAccent.withValues(alpha: 0.8), fontSize: 11),
      );
    } else {
      statusContent = OutlinedButton.icon(
        onPressed: () {
          ref.read(desktopUpdateProvider.notifier).checkManually();
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white24),
          foregroundColor: Colors.white70,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(Icons.system_update_rounded, size: 14),
        label: Text(
          'CHECK FOR UPDATES',
          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: statusContent,
    );
  }
}

class _Badge extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  const _Badge({required this.label, this.onTap});

  @override
  State<_Badge> createState() => _BadgeState();
}

class _BadgeState extends State<_Badge> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: context.appColors.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.appColors.borderColor, width: 1),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.outfit(
              color: context.appColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkButton extends StatefulWidget {
  final String label;
  final String url;
  final IconData? icon;
  final String? assetIcon;

  const _LinkButton({
    required this.label,
    required this.url,
    this.icon,
    this.assetIcon,
  });

  @override
  State<_LinkButton> createState() => _LinkButtonState();
}

class _LinkButtonState extends State<_LinkButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.94 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Material(
        color: context.appColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.white.withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.04),
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: () async {
            final uri = Uri.parse(widget.url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.appColors.borderColor, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.assetIcon != null)
                  Image.asset(widget.assetIcon!, width: 20, height: 20, color: context.appColors.textSecondary)
                else
                  Icon(widget.icon, size: 20, color: context.appColors.textSecondary),
                const SizedBox(height: 6),
                Text(
                  widget.label,
                  style: GoogleFonts.outfit(
                    color: context.appColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: context.appColors.surfaceColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: context.appColors.textSecondary),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 11),
            ),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: context.appColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TextLink extends ConsumerStatefulWidget {
  final String label;
  final String url;
  const _TextLink({required this.label, required this.url});

  @override
  ConsumerState<_TextLink> createState() => _TextLinkState();
}

class _TextLinkState extends ConsumerState<_TextLink> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final accentColor = ref.watch(overallProgressColorProvider);
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () async {
        final uri = Uri.parse(widget.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: _isPressed ? 0.6 : 1.0,
          child: Text(
            widget.label,
            style: GoogleFonts.outfit(
              color: accentColor,
              fontSize: 12,
              decoration: TextDecoration.underline,
              decorationColor: accentColor.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const _AnimatedCard({
    required this.child,
    this.padding,
    this.borderRadius,
  });

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: context.appColors.cardBackground,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
            border: Border.all(
              color: _isPressed
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
