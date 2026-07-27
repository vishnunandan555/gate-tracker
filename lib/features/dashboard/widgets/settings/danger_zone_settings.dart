import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

import '../../../../providers/agreement_provider.dart';
import '../../../../providers/setup_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/syllabus_provider.dart';
import '../../../../providers/focus_provider.dart';
import '../../../../providers/quotes_provider.dart';
import '../../../../providers/category_font_size_provider.dart';
import '../../../../providers/topic_font_size_provider.dart';
import '../../../../providers/task_font_size_provider.dart';
import '../../../../providers/overall_ui_scale_provider.dart';
import '../../../../providers/subject_provider.dart';
import '../../../../providers/sync_provider.dart';
import '../../../../providers/stats_provider.dart';
import '../../../../database/backup_service.dart';
import '../../../../providers/demo_guide_provider.dart';
import '../../../../providers/community_notifications_provider.dart';


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

      // Show loading indicator during restore (can take 1-4s on large backups)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final raw = utf8.decode(bytes);
        final payload = jsonDecode(raw);
        final db = ref.read(appDatabaseProvider);

        await BackupService.restoreDatabase(db, payload);
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

  Future<void> _performReset(BuildContext context, WidgetRef ref, {required bool everything}) async {
    final title = everything ? 'Reset Everything' : 'Reset Tracking Data';
    final content = everything
        ? 'This will clear ALL your sources, links, and progress. This cannot be undone.'
        : 'This will reset all your progress counts to zero but keep your sources and links.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title),
        content: Text(
          content,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      if (everything) {
        final db = ref.read(appDatabaseProvider);
        await db.delete(db.syllabusProgressLogs).go();
        await db.delete(db.syllabusTasks).go();
        await db.delete(db.syllabusTopics).go();
        await db.delete(db.syllabusCategories).go();
        await db.delete(db.focusSessions).go();
        await db.delete(db.dailyHistory).go();
        await db.delete(db.customTasks).go();

        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.clear();

        await ref.read(authProvider.notifier).resetAuthChoice();

        ref.invalidate(authProvider);
        ref.invalidate(syllabusProvider);
        ref.invalidate(progressLogsProvider);
        ref.read(focusProvider.notifier).resetState();
        ref.invalidate(todayFocusSessionsProvider);
        ref.invalidate(todayFocusDurationProvider);
        ref.invalidate(dailyFocusGoalProvider);
        ref.invalidate(focusQuotesEnabledProvider);

        ref.invalidate(agreementProvider);
        ref.invalidate(setupCompletedProvider);
        ref.invalidate(communityNotificationsProvider);
        ref.invalidate(categoryFontSizeProvider);
        ref.invalidate(topicFontSizeProvider);
        ref.invalidate(taskFontSizeProvider);
        ref.invalidate(overallUiScaleProvider);
        await ref.read(overallProgressColorProvider.notifier).setAutoMode();
      } else {
        await ref.read(syllabusControllerProvider.notifier).resetTrackingData();

        final db = ref.read(appDatabaseProvider);
        await db.delete(db.focusSessions).go();
        await db.delete(db.dailyHistory).go();
        await db.delete(db.customTasks).go();

        ref.invalidate(syllabusProvider);
        ref.invalidate(progressLogsProvider);
        ref.invalidate(todayFocusSessionsProvider);
        ref.invalidate(todayFocusDurationProvider);
        ref.invalidate(dailyFocusGoalProvider);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(everything ? 'System reset!' : 'Progress reset!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset failed: $e')),
        );
      }
    }
  }

  Future<void> _performRedoOnboarding(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Redo Onboarding Setup?'),
        content: const Text(
          'This will take you back to the initial configuration wizard to re-set your profile, daily goals, branch, and syllabus tracker.\n\nNote: Initializing a new syllabus branch will overwrite your current categories and tracking progress.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
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
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Redo Interactive Guide?'),
        content: const Text(
          'This will start the interactive demo. Note: During the guide, a sandbox session will run. Your active study logs, statistics, and checked tasks will be temporarily backed up and safely restored once the guide completes or is skipped.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.black),
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
    final isDesktop = screenWidth > 900;

    final resetDataContent = Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        iconColor: Colors.redAccent,
        collapsedIconColor: Colors.redAccent.withValues(alpha: 0.5),
        leading: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
        title: Text(
          'Reset Data',
          style: titleStyle.copyWith(color: Colors.redAccent),
        ),
        children: [
          ListTile(
            leading: const Icon(Icons.history_rounded, color: Colors.redAccent),
            title: Text('Reset Tracking Data', style: titleStyle),
            subtitle: Text(
              'Set all progress counts to zero',
              style: subtitleStyle,
            ),
            onTap: () => _performReset(context, ref, everything: false),
          ),
          const Divider(color: Colors.white10, height: 1),
          ListTile(
            leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            title: Text('Reset Everything', style: titleStyle),
            subtitle: Text(
              'Clear sources, links, and progress',
              style: subtitleStyle,
            ),
            onTap: () => _performReset(context, ref, everything: true),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const Icon(Icons.upload_file, color: Color(0xFF00E5FF)),
          title: Text('Export Data', style: titleStyle),
          subtitle: Text(
            'Save progress to JSON',
            style: subtitleStyle,
          ),
          onTap: () => _exportData(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.download, color: Color(0xFF69F0AE)),
          title: Text('Import Data', style: titleStyle),
          subtitle: Text(
            'Restore from JSON file',
            style: subtitleStyle,
          ),
          onTap: () => _importData(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.restart_alt_rounded, color: Color(0xFFFFD54F)),
          title: Text('Redo Onboarding Setup', style: titleStyle),
          subtitle: Text(
            'Reconfigure profile, daily goals, and branch presets',
            style: subtitleStyle,
          ),
          onTap: () => _performRedoOnboarding(context, ref),
        ),
        if (!isDesktop)
          ListTile(
            leading: const Icon(Icons.help_outline_rounded, color: Color(0xFFE040FB)),
            title: Text('Redo Demo Guide', style: titleStyle),
            subtitle: Text(
              'Re-run interactive walkthrough tutorial',
              style: subtitleStyle,
            ),
            onTap: () => _performRedoDemo(context, ref),
          ),
        resetDataContent,
      ],
    );
  }
}
