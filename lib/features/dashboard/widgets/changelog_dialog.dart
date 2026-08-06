import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/brand_config.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/widgets/app_loading_indicator.dart';
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
    final Color themeAccent = accentColor ?? context.appColors.primaryAccent;
    final changelogAsync = ref.watch(changelogFamilyProvider(version));

    final cleanVersion = version?.replaceFirst(RegExp(r'^v'), '').split('+').first ?? '1.3.0';

    return AlertDialog(
      backgroundColor: context.appColors.dialogBackground,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: themeAccent.withAlpha(50), width: 1.5),
      ),
      contentPadding: EdgeInsets.zero,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 580),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
              decoration: BoxDecoration(
                color: context.appColors.surfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                border: Border(bottom: BorderSide(color: context.appColors.borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: themeAccent.withAlpha(25),
                      shape: BoxShape.circle,
                      border: Border.all(color: themeAccent.withAlpha(80)),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: themeAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "What's New",
                          style: GoogleFonts.orbitron(
                            color: context.appColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${BrandConfig.appName} Release Notes",
                          style: GoogleFonts.outfit(
                            color: context.appColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: context.appColors.textMuted, size: 20),
                    tooltip: 'Close',
                    padding: const EdgeInsets.all(4),
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
                        child: AppLoadingIndicator(
                          strokeWidth: 2.5,
                          color: themeAccent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Loading release notes...",
                        style: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 12),
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
                          color: context.appColors.textMuted,
                          size: 36,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "No Internet Connection",
                          style: GoogleFonts.outfit(
                            color: context.appColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Unable to fetch online release notes right now.",
                          style: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                data: (changelog) {
                  return SelectionArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Version pill badge & date bar
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 10,
                            runSpacing: 6,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: themeAccent.withAlpha(30),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: themeAccent.withAlpha(80)),
                                ),
                                child: Text(
                                  "v$cleanVersion",
                                  style: GoogleFonts.outfit(
                                    color: themeAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              if (changelog.date.isNotEmpty)
                                Text(
                                  "Released on ${changelog.date}",
                                  style: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 12),
                                ),
                            ],
                          ),

                          if (changelog.title.isNotEmpty &&
                              changelog.title != "v$cleanVersion" &&
                              changelog.title != "${BrandConfig.appName} v$cleanVersion") ...[
                            const SizedBox(height: 12),
                            Text(
                              changelog.title,
                              style: GoogleFonts.outfit(
                                color: context.appColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],

                          const SizedBox(height: 14),

                          // Markdown Body
                          MarkdownBody(
                            data: changelog.body,
                            selectable: false,
                            onTapLink: (text, href, title) async {
                              if (href != null && href.isNotEmpty) {
                                final uri = Uri.parse(href);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              }
                            },
                            styleSheet: MarkdownStyleSheet(
                              p: GoogleFonts.outfit(
                                color: context.appColors.textSecondary,
                                fontSize: 13,
                                height: 1.45,
                              ),
                              h1: GoogleFonts.outfit(
                                color: context.appColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                height: 1.3,
                              ),
                              h2: GoogleFonts.outfit(
                                color: context.appColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                height: 1.3,
                              ),
                              h3: GoogleFonts.outfit(
                                color: context.appColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                height: 1.3,
                              ),
                              h4: GoogleFonts.outfit(
                                color: context.appColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              listBullet: GoogleFonts.outfit(
                                color: themeAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              listBulletPadding: const EdgeInsets.only(right: 6),
                              code: GoogleFonts.firaCode(
                                color: themeAccent,
                                backgroundColor: context.appColors.surfaceColor,
                                fontSize: 11.5,
                              ),
                              codeblockDecoration: BoxDecoration(
                                color: context.appColors.cardBackground,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: context.appColors.borderColor),
                              ),
                              codeblockPadding: const EdgeInsets.all(12),
                              blockquote: GoogleFonts.outfit(
                                color: context.appColors.textSecondary,
                                fontStyle: FontStyle.italic,
                                fontSize: 12.5,
                              ),
                              blockquoteDecoration: BoxDecoration(
                                color: themeAccent.withAlpha(15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border(left: BorderSide(color: themeAccent, width: 3)),
                              ),
                              blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              horizontalRuleDecoration: BoxDecoration(
                                border: Border(top: BorderSide(color: context.appColors.dividerColor, width: 1)),
                              ),
                              a: GoogleFonts.outfit(
                                color: themeAccent,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: context.appColors.surfaceColor,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
                border: Border(top: BorderSide(color: context.appColors.borderColor)),
              ),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final url = Uri.parse(
                        changelogAsync.value?.githubUrl ?? BrandConfig.githubReleasesUrl,
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: Icon(Icons.open_in_new_rounded, size: 14, color: context.appColors.textSecondary),
                    label: Text(
                      "GitHub",
                      style: GoogleFonts.outfit(
                        color: context.appColors.textSecondary,
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
                      foregroundColor: context.appColors.onAccent,
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
