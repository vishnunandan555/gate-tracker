import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../core/theme/theme_context_ext.dart';
import 'package:gateletics/providers/providers.dart';

Future<void> showSignOutConfirmationDialog(BuildContext context, WidgetRef ref) async {
  final choice = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: context.appColors.dialogBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Sign Out',
        style: GoogleFonts.outfit(
          color: context.appColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'How would you like to handle your local study progress on this device when signing out?',
              style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => Navigator.pop(ctx, 'keepLocal'),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: context.appColors.borderColor),
                  borderRadius: BorderRadius.circular(16),
                  color: context.appColors.surfaceColor,
                ),
                child: Row(
                  children: [
                    Icon(Icons.smartphone_rounded, color: context.appColors.primaryAccent, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Keep Local Progress (Offline Mode)',
                            style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Preserve study data on device and switch to Offline Mode',
                            style: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => Navigator.pop(ctx, 'wipeData'),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.redAccent.withValues(alpha: 0.05),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reset & Wipe Local Data',
                            style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sign out and permanently erase all local study progress',
                            style: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Cancel', style: GoogleFonts.outfit(color: context.appColors.textMuted)),
        ),
      ],
    ),
  );

  if (choice == null || !context.mounted) return;

  final keepLocal = choice == 'keepLocal';
  await ref.read(authProvider.notifier).signOut(keepLocalData: keepLocal);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          keepLocal
              ? '✓ Signed out. Switched to Offline Mode (local data preserved).'
              : '✓ Signed out and local study data reset.',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
}
