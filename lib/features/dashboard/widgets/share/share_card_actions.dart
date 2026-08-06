import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/theme_context_ext.dart';

class ShareCardActions extends StatelessWidget {
  final Color accentColor;
  final bool isSaving;
  final bool isSharing;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onClose;

  const ShareCardActions({
    super.key,
    required this.accentColor,
    required this.isSaving,
    required this.isSharing,
    required this.onSave,
    required this.onShare,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: onClose,
          child: Text(
            "Close",
            style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: (isSaving || isSharing) ? null : onSave,
          icon: isSaving
              ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: context.appColors.primaryAccent, strokeWidth: 1.5))
              : const Icon(Icons.download_rounded, size: 14),
          label: Text(
            isSaving ? "Saving..." : "Save",
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: accentColor,
            side: BorderSide(color: accentColor.withAlpha(120)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: (isSaving || isSharing) ? null : onShare,
          icon: isSharing
              ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: context.appColors.onAccent, strokeWidth: 1.5))
              : const Icon(Icons.share_rounded, size: 14),
          label: Text(
            isSharing ? "Sharing..." : "Share",
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: context.appColors.onAccent,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
