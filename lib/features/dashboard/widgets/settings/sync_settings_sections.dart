import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gateletics/providers/providers.dart';
import '../../../../core/theme/theme_context_ext.dart';

class SyncDownloadBanner extends ConsumerWidget {
  final Color accentColor;

  const SyncDownloadBanner({
    super.key,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        child: Row(
          children: [
            Icon(Icons.system_update_rounded, color: accentColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Desktop & Mobile Apps Available',
                    style: GoogleFonts.outfit(
                      color: context.appColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Get native performance, local backups & offline mode.',
                    style: GoogleFonts.outfit(
                      color: context.appColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () async {
                final uri = Uri.parse('https://vishnunandan555.github.io/gateletics/downloads.html');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: accentColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Get App', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            IconButton(
              icon: Icon(Icons.close_rounded, color: context.appColors.textMuted, size: 16),
              onPressed: () {
                ref.read(hideDownloadBannerProvider.notifier).setHidden(true);
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 16,
            ),
          ],
        ),
      ),
    );
  }
}
