import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../providers/providers.dart';
import '../../../providers/sync/changelog_provider.dart';

void showChangelogDialog(BuildContext context, {String? version, Color? accentColor}) {
  showDialog(
    context: context,
    builder: (context) => ChangelogDialog(version: version, accentColor: accentColor),
  );
}

class ChangelogDialog extends ConsumerWidget {
  final String? version;
  final Color? accentColor;

  const ChangelogDialog({
    super.key,
    this.version,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color themeAccent = accentColor ?? ref.watch(overallProgressColorProvider);
    final changelogAsync = ref.watch(changelogFamilyProvider(version));

    final cleanVersion = version?.replaceFirst(RegExp(r'^v'), '').split('+').first ?? '1.3.0';

    return AlertDialog(
      backgroundColor: const Color(0xFF18181B),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: themeAccent.withAlpha(50), width: 1.5),
      ),
      contentPadding: EdgeInsets.zero,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(6),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                border: Border(bottom: BorderSide(color: Colors.white.withAlpha(12))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: themeAccent.withAlpha(25),
                      shape: BoxShape.circle,
                      border: Border.all(color: themeAccent.withAlpha(80)),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: themeAccent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "What's New",
                              style: GoogleFonts.orbitron(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: themeAccent.withAlpha(35),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: themeAccent.withAlpha(90)),
                              ),
                              child: Text(
                                "v$cleanVersion",
                                style: GoogleFonts.outfit(
                                  color: themeAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "GATEletics Release Notes",
                          style: GoogleFonts.outfit(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                    tooltip: 'Close',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Content Body
            Expanded(
              child: changelogAsync.when(
                loading: () => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: themeAccent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Loading release notes...",
                        style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                error: (err, stack) => Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          color: Colors.white38,
                          size: 36,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "No Internet Connection",
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Unable to fetch online release notes right now.",
                          style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                data: (changelog) {
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (changelog.title.isNotEmpty && changelog.title != "v$cleanVersion") ...[
                        Text(
                          changelog.title,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (changelog.date.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            "Released on ${changelog.date}",
                            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],

                      // Bullet changes
                      ...changelog.changes.map((changeLine) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: themeAccent,
                                  size: 15,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  changeLine,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withAlpha(230),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(4),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
                border: Border(top: BorderSide(color: Colors.white.withAlpha(10))),
              ),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final url = Uri.parse(
                        changelogAsync.value?.githubUrl ?? 'https://github.com/vishnunandan555/gateletics/releases',
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: Icon(Icons.open_in_new_rounded, size: 14, color: Colors.white54),
                    label: Text(
                      "GitHub Notes",
                      style: GoogleFonts.outfit(
                        color: Colors.white54,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeAccent,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    ),
                    child: Text(
                      "Got It",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
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
