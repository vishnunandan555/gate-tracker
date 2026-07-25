import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/subject_provider.dart';
import '../../providers/package_info_provider.dart';
import '../../providers/desktop_update_provider.dart';

void showAboutTrackerDialog(BuildContext context, WidgetRef ref) {
  final accentColor = ref.read(overallProgressColorProvider);
  final packageInfo = ref.read(packageInfoProvider);

  showDialog(
    context: context,
    barrierColor: Colors.black.withAlpha(210),
    builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0E0E11),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withAlpha(14), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withAlpha(28),
                  blurRadius: 48,
                  spreadRadius: 0,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header hero area ──────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accentColor.withAlpha(20),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: Column(
                      children: [
                        // Icon
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: accentColor.withAlpha(60), width: 2),
                            boxShadow: [
                              BoxShadow(color: accentColor.withAlpha(40), blurRadius: 20, spreadRadius: 0),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset('assets/icon.png', fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // App name
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'GATE',
                              style: GoogleFonts.boldonse(
                                fontSize: 24,
                                height: 1.0,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'LETICS',
                              style: GoogleFonts.orbitron(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                height: 1.15,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Tagline
                        Text(
                          'GATE Exam Preparation & Progress Tracker',
                          style: GoogleFonts.outfit(
                            color: Colors.white54,
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),

                        // Version + build badges row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _Badge(label: 'v${packageInfo.version}', color: accentColor),
                            const SizedBox(width: 8),
                            _Badge(label: 'Build ${packageInfo.buildNumber}', color: Colors.white24),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Link row ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _LinkButton(
                            icon: Icons.language_rounded,
                            label: 'Website',
                            url: 'https://vishnunandan555.github.io/gateletics/',
                            accentColor: accentColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _LinkButton(
                            assetIcon: 'assets/github.png',
                            label: 'GitHub',
                            url: 'https://github.com/vishnunandan555/gateletics',
                            accentColor: accentColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _LinkButton(
                            icon: Icons.shop_rounded,
                            label: 'Play Store',
                            url: 'https://play.google.com/store/apps/details?id=com.vishnunandan.gateletics',
                            accentColor: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Divider ───────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Divider(color: Colors.white.withAlpha(12), height: 1),
                  ),

                  // ── Info rows ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.person_rounded,
                          label: 'Developer',
                          value: 'Vishnu Nandan',
                          accentColor: accentColor,
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.business_center_rounded,
                          label: 'Package',
                          value: 'com.vishnunandan.gateletics',
                          accentColor: accentColor,
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.code_rounded,
                          label: 'Framework',
                          value: 'Flutter (Dart)',
                          accentColor: accentColor,
                        ),
                      ],
                    ),
                  ),

                  // ── Legal ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withAlpha(10)),
                      ),
                      child: Text(
                        'GATEletics is an independent educational tool and is not affiliated with, authorized by, or associated with GATE or its organizing institutes (IISc, IITs, or NCB-GATE).',
                        style: GoogleFonts.outfit(
                          color: Colors.white30,
                          fontSize: 10.5,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  // ── ToS / Privacy ─────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _TextLink(
                          label: 'Terms of Service',
                          url: 'https://vishnunandan555.github.io/gateletics/terms.html',
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('·', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 14)),
                        ),
                        _TextLink(
                          label: 'Privacy Policy',
                          url: 'https://vishnunandan555.github.io/gateletics/privacy.html',
                        ),
                      ],
                    ),
                  ),

                  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux))
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
                      child: _DesktopAboutUpdateTile(),
                    ),

                  // ── Close button ─────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'CLOSE',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
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
            '🔥 GATEletics v${updateState.releaseInfo!.latestVersion} is available!',
            style: GoogleFonts.outfit(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12),
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
        style: GoogleFonts.outfit(color: Colors.greenAccent, fontWeight: FontWeight.w600, fontSize: 11.5),
      );
    } else if (updateState.status == DesktopUpdateStatus.error) {
      statusContent = Text(
        updateState.errorMessage ?? 'Could not check for updates',
        style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 11),
      );
    } else {
      statusContent = OutlinedButton.icon(
        onPressed: () {
          ref.read(desktopUpdateProvider.notifier).checkManually();
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: accentColor.withValues(alpha: 0.4)),
          foregroundColor: accentColor,
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
        color: Colors.white.withAlpha(4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: statusContent,
    );
  }
}

// ── Private helper widgets ─────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: color == Colors.white24 ? Colors.white54 : color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  final String label;
  final String url;
  final Color accentColor;
  final IconData? icon;
  final String? assetIcon;

  const _LinkButton({
    required this.label,
    required this.url,
    required this.accentColor,
    this.icon,
    this.assetIcon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: accentColor.withAlpha(12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withAlpha(35), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (assetIcon != null)
              Image.asset(assetIcon!, width: 18, height: 18, color: accentColor)
            else
              Icon(icon, size: 18, color: accentColor),
            const SizedBox(height: 5),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: accentColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: accentColor.withAlpha(16),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: accentColor),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10.5),
            ),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TextLink extends StatelessWidget {
  final String label;
  final String url;
  const _TextLink({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: Colors.cyanAccent.withAlpha(180),
          fontSize: 11.5,
          decoration: TextDecoration.underline,
          decorationColor: Colors.cyanAccent.withAlpha(100),
        ),
      ),
    );
  }
}
