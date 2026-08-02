import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/theme_context_ext.dart';

class SyncActionButtonsWidget extends StatelessWidget {
  final VoidCallback onUpload;
  final VoidCallback onDownload;
  final VoidCallback onMerge;
  final bool isSyncing;

  const SyncActionButtonsWidget({
    super.key,
    required this.onUpload,
    required this.onDownload,
    required this.onMerge,
    required this.isSyncing,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final accentColor = appColors.primaryAccent;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isSyncing ? null : onUpload,
            icon: const Icon(Icons.cloud_upload_rounded, size: 16),
            label: Text(
              'Upload Local',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: accentColor,
              side: BorderSide(color: accentColor.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isSyncing ? null : onDownload,
            icon: const Icon(Icons.cloud_download_rounded, size: 16),
            label: Text(
              'Download Cloud',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: appColors.textPrimary,
              side: BorderSide(color: appColors.borderColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isSyncing ? null : onMerge,
            icon: const Icon(Icons.merge_type_rounded, size: 16),
            label: Text(
              'Merge Both',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: appColors.onAccent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
