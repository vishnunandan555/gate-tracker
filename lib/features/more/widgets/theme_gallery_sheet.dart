import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/models/app_theme_model.dart';
import '../../../core/theme/presets/handcrafted_presets.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../providers/providers.dart';
import 'custom_theme_editor_dialog.dart';

class ThemeGallerySheet extends ConsumerWidget {
  const ThemeGallerySheet({super.key});

  void _showEditor(BuildContext context, {AppThemeDataModel? themeToEdit}) {
    showDialog(
      context: context,
      builder: (_) => CustomThemeEditorDialog(initialThemeToEdit: themeToEdit),
    );
  }

  Future<void> _exportTheme(BuildContext context, WidgetRef ref, String customId, String name) async {
    final jsonStr = ref.read(themeEngineProvider.notifier).exportCustomThemeJson(customId);
    if (jsonStr == null) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final sanitizedName = name.replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(' ', '_').toLowerCase();
      final filePath = '${dir.path}/$sanitizedName.gt-theme';
      final file = File(filePath);
      await file.writeAsString(jsonStr);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported theme to: $filePath')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export theme: $e')),
        );
      }
    }
  }

  Future<void> _importTheme(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        final file = File(result.files.first.path!);
        final jsonStr = await file.readAsString();
        final success = ref.read(themeEngineProvider.notifier).importCustomThemeJson(jsonStr);

        if (context.mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Custom theme imported successfully!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to import. Check format or max 3 custom themes limit.')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  Widget _buildThemeCard(
    BuildContext context, {
    required AppThemeDataModel model,
    required bool isSelected,
    required VoidCallback onTap,
    Widget? trailingActions,
  }) {
    final cardBg = context.appColors.cardBackground;
    final scaffoldBg = model.scaffoldBackgroundColor;
    final primaryAccent = context.appColors.primaryAccent;
    final swatchAccent = model.primaryAccentColor;
    final textPrimary = context.appColors.textPrimary;
    final textSecondary = context.appColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryAccent : context.appColors.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Preview Swatch Circle
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: scaffoldBg,
                shape: BoxShape.circle,
                border: Border.all(color: swatchAccent, width: 2),
              ),
              child: Center(
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: swatchAccent,
                    shape: BoxShape.circle,
                  ),
                ),
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
                        model.name,
                        style: GoogleFonts.outfit(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.check_circle_rounded, color: primaryAccent, size: 16),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    model.description,
                    style: GoogleFonts.outfit(
                      color: textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ?trailingActions,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeEngineProvider);
    final themeNotifier = ref.read(themeEngineProvider.notifier);

    final standardModes = [
      {'id': 'dark', 'name': 'Dark Mode', 'mode': 'dark', 'model': HandcraftedPresets.zincDark.copyWith(name: 'Dark Mode', description: 'Classic deep zinc dark surface')},
      {'id': 'light', 'name': 'Light Mode', 'mode': 'light', 'model': HandcraftedPresets.paperLight.copyWith(name: 'Light Mode', description: 'Soft, anti-flashbang warm paper surface')},
      {'id': 'system', 'name': 'System Dynamic', 'mode': 'system', 'model': HandcraftedPresets.zincDark.copyWith(name: 'System Dynamic', description: 'Auto matches device light/dark setting')},
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Base Modes ───────────────────────────────────────────────
          Text(
            'THEME MODES',
            style: GoogleFonts.outfit(
              color: context.appColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          ...standardModes.map((item) {
            final modeStr = item['mode'] as String;
            final isSelected = themeState.themeMode == modeStr;
            final model = item['model'] as AppThemeDataModel;

            return _buildThemeCard(
              context,
              model: model,
              isSelected: isSelected,
              onTap: () => themeNotifier.setStandardMode(modeStr),
            );
          }),

          const SizedBox(height: 16),
          // ── 2. Custom Theme Option ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CUSTOM THEME',
                style: GoogleFonts.outfit(
                  color: context.appColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.file_upload_outlined, color: context.appColors.primaryAccent, size: 18),
                    tooltip: 'Import Theme (.gt-theme)',
                    onPressed: () => _importTheme(context, ref),
                  ),
                  IconButton(
                    icon: Icon(Icons.palette_outlined, color: context.appColors.primaryAccent, size: 20),
                    tooltip: 'Create / Edit Custom Theme',
                    onPressed: () {
                      final existing = themeState.customThemes.isNotEmpty ? themeState.customThemes.first : null;
                      _showEditor(context, themeToEdit: existing);
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          if (themeState.customThemes.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.appColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.appColors.borderColor),
              ),
              child: Column(
                children: [
                  Icon(Icons.palette_outlined, color: context.appColors.textSecondary, size: 28),
                  const SizedBox(height: 8),
                  Text('No Custom Theme Created Yet', style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Tap "Create Custom Theme" to customize colors, curvature, and styling!', style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 11), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showEditor(context),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: const Text('Create Custom Theme'),
                  ),
                ],
              ),
            )
          else
            ...themeState.customThemes.map((custom) {
              final isSelected = themeState.themeMode == 'custom' && themeState.activeThemeId == custom.id;
              return _buildThemeCard(
                context,
                model: custom,
                isSelected: isSelected,
                onTap: () => themeNotifier.selectCustomTheme(custom.id),
                trailingActions: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      onPressed: () => _showEditor(context, themeToEdit: custom),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download_outlined, size: 16),
                      onPressed: () => _exportTheme(context, ref, custom.id, custom.name),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                      onPressed: () => themeNotifier.deleteCustomTheme(custom.id),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
