import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

import '../../../../core/theme/theme_context_ext.dart';
import 'package:gateletics/providers/providers.dart';
import '../../../../database/backup_service.dart';


class DangerZoneSettingsSection extends ConsumerWidget {
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final Color accentColor;

  const DangerZoneSettingsSection({
    super.key,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.accentColor,
  });

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final db = ref.read(appDatabaseProvider);
      final exportPayload = await BackupService.exportDatabase(db);
      final json = const JsonEncoder.withIndent('  ').convert(exportPayload);

      String? path;
      if (kIsWeb) {
        final bytes = Uint8List.fromList(utf8.encode(json));
        path = await FilePicker.saveFile(
          dialogTitle: 'Save backup to device',
          fileName: 'gateletics_backup.json',
          bytes: bytes,
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
      } else if (defaultTargetPlatform == TargetPlatform.android ||
                 defaultTargetPlatform == TargetPlatform.iOS) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/gateletics_backup.json');
        await tempFile.writeAsString(json);

        final params = SaveFileDialogParams(
          sourceFilePath: tempFile.path,
          fileName: 'gateletics_backup.json',
        );
        path = await FlutterFileDialog.saveFile(params: params);
      } else {
        final bytes = Uint8List.fromList(utf8.encode(json));
        path = await FilePicker.saveFile(
          dialogTitle: 'Save backup to device',
          fileName: 'gateletics_backup.json',
          bytes: bytes,
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
        if (path != null) {
          final file = File(path);
          await file.writeAsBytes(bytes);
        }
      }

      if (path != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data exported successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    try {
      Uint8List? bytes;
      if (kIsWeb ||
          (defaultTargetPlatform != TargetPlatform.android &&
           defaultTargetPlatform != TargetPlatform.iOS)) {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
        if (result == null || result.files.isEmpty) return;
        bytes = await result.files.single.readAsBytes();
      } else {
        final params = OpenFileDialogParams(
          dialogType: OpenFileDialogType.document,
          fileExtensionsFilter: ['json'],
        );
        final filePath = await FlutterFileDialog.pickFile(params: params);
        if (filePath == null) return;
        bytes = await File(filePath).readAsBytes();
      }

      if (!context.mounted) return;

      final importMode = await showDialog<ImportMode>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: context.appColors.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Select Restore Mode'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose which portion of the backup file to restore into your device database:',
                style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.inventory_2_rounded, color: context.appColors.primaryAccent),
                title: Text('Restore Everything', style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('Overwrites active syllabus, tasks, and focus history', style: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 11)),
                onTap: () => Navigator.pop(ctx, ImportMode.full),
              ),
              Divider(color: context.appColors.dividerColor),
              ListTile(
                leading: const Icon(Icons.topic_rounded, color: Colors.greenAccent),
                title: Text('Active Data Only', style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('Restores syllabus categories, topics, & checklists only', style: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 11)),
                onTap: () => Navigator.pop(ctx, ImportMode.activeOnly),
              ),
              Divider(color: context.appColors.dividerColor),
              ListTile(
                leading: const Icon(Icons.analytics_rounded, color: Colors.orangeAccent),
                title: Text('Passive Data Only', style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('Restores focus timer logs & study statistics history only', style: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 11)),
                onTap: () => Navigator.pop(ctx, ImportMode.passiveOnly),
              ),
            ],
          ),
        ),
      );

      if (importMode == null || !context.mounted) return;

      // Show loading indicator during restore (can take 1-4s on large backups)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Center(child: CircularProgressIndicator(color: accentColor)),
      );

      try {
        final raw = utf8.decode(bytes);
        final payload = jsonDecode(raw);
        final db = ref.read(appDatabaseProvider);

        await BackupService.restoreDatabase(db, payload, importMode: importMode);
        ref.read(syncProvider.notifier).clearDatabaseCaches();

        if (context.mounted) Navigator.of(context).pop(); // dismiss loading
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✓ Backup data successfully restored!')),
          );
        }
      } catch (e) {
        if (context.mounted) Navigator.of(context).pop(); // dismiss loading
        if (context.mounted) {
          String message = 'Import failed: $e';
          if (e is PlatformException && e.code == 'invalid_file_extension') {
            message = 'Invalid file type selected. Only JSON (.json) files are supported for importing backup files.';
          } else if (e is FormatException) {
            message = 'The selected file is not a valid JSON file. Please ensure you picked a valid backup file.';
          } else if (e is TypeError || e is StateError) {
            message = 'The selected file does not contain valid backup data.';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _performRedoOnboarding(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Redo Onboarding Setup?'),
        content: Text(
          'This will take you back to the initial configuration wizard to re-set your profile, daily goals, branch, and syllabus tracker.\n\nNote: Initializing a new syllabus branch will overwrite your current categories and tracking progress.',
          style: GoogleFonts.outfit(color: context.appColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: context.appColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: accentColor, foregroundColor: context.appColors.onAccent),
            child: const Text('Redo'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(setupCompletedProvider.notifier).resetSetup(forceOnboarding: true);
  }

  Future<void> _performRedoDemo(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Redo Interactive Guide?'),
        content: Text(
          'This will start the interactive demo. Note: During the guide, a sandbox session will run. Your active study logs, statistics, and checked tasks will be temporarily backed up and safely restored once the guide completes or is skipped.',
          style: GoogleFonts.outfit(color: context.appColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: context.appColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: accentColor, foregroundColor: context.appColors.onAccent),
            child: const Text('Start'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(demoGuideProvider.notifier).startDemo();
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 768;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: Icon(Icons.upload_file_rounded, color: accentColor),
          title: Text('Export Data', style: titleStyle),
          subtitle: Text(
            'Save progress to JSON backup file',
            style: subtitleStyle,
          ),
          onTap: () => _exportData(context, ref),
        ),
        Divider(color: context.appColors.dividerColor, height: 1),
        ListTile(
          leading: Icon(Icons.download_rounded, color: accentColor),
          title: Text('Import Data', style: titleStyle),
          subtitle: Text(
            'Restore from JSON backup file',
            style: subtitleStyle,
          ),
          onTap: () => _importData(context, ref),
        ),
        Divider(color: context.appColors.dividerColor, height: 1),
        ListTile(
          leading: Icon(Icons.restart_alt_rounded, color: accentColor),
          title: Text('Redo Onboarding Setup', style: titleStyle),
          subtitle: Text(
            'Reconfigure profile, daily goals, and branch presets',
            style: subtitleStyle,
          ),
          onTap: () => _performRedoOnboarding(context, ref),
        ),
        if (!isDesktop) ...[
          Divider(color: context.appColors.dividerColor, height: 1),
          ListTile(
            leading: Icon(Icons.help_outline_rounded, color: accentColor),
            title: Text('Redo Demo Guide', style: titleStyle),
            subtitle: Text(
              'Re-run interactive walkthrough tutorial',
              style: subtitleStyle,
            ),
            onTap: () => _performRedoDemo(context, ref),
          ),
        ],
      ],
    );
  }
}
