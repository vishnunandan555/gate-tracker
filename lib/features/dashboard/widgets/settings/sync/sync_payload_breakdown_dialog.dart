import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/theme_context_ext.dart';
import 'package:gateletics/providers/providers.dart';

Future<void> showPayloadBreakdownDialog(BuildContext context, WidgetRef ref, Color accentColor) async {
  final notifier = ref.read(syncProvider.notifier);
  final data = await notifier.exportLocalData();

  int getBytes(dynamic val) => utf8.encode(jsonEncode(val ?? [])).length;

  final tasksList = data['syllabusTasks'] as List? ?? [];
  final topicsList = data['syllabusTopics'] as List? ?? [];
  final catsList = data['syllabusCategories'] as List? ?? [];
  final focusList = data['focusSessions'] as List? ?? [];
  final historyList = data['dailyHistory'] as List? ?? [];
  final logsList = data['syllabusProgressLogs'] as List? ?? [];

  final tasksBytes = getBytes(tasksList);
  final topicsBytes = getBytes(topicsList);
  final catsBytes = getBytes(catsList);
  final focusBytes = getBytes(focusList);
  final historyBytes = getBytes(historyList);
  final logsBytes = getBytes(logsList);
  final totalBytes = utf8.encode(jsonEncode(data)).length;

  double toKb(int b) => b / 1024.0;
  double toPct(int b) => totalBytes > 0 ? (b / totalBytes) * 100 : 0;

  if (!context.mounted) return;

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: context.appColors.dialogBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Icon(Icons.analytics_rounded, color: accentColor, size: 22),
          const SizedBox(width: 10),
          Text(
            'Payload Breakdown',
            style: GoogleFonts.outfit(
              color: context.appColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'GATEletics comes pre-seeded with the full GATE syllabus structure. Here is how your ${toKb(totalBytes).toStringAsFixed(1)} KB payload is distributed:',
              style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 16),
            _buildBreakdownItem(
              context: context,
              label: 'Checklist Tasks (${tasksList.length} items)',
              sizeKb: toKb(tasksBytes),
              pct: toPct(tasksBytes),
              color: accentColor,
              icon: Icons.checklist_rounded,
            ),
            const SizedBox(height: 8),
            _buildBreakdownItem(
              context: context,
              label: 'Syllabus Topics (${topicsList.length} topics)',
              sizeKb: toKb(topicsBytes),
              pct: toPct(topicsBytes),
              color: accentColor.withValues(alpha: 0.8),
              icon: Icons.topic_rounded,
            ),
            const SizedBox(height: 8),
            _buildBreakdownItem(
              context: context,
              label: 'Subject Categories (${catsList.length} subjects)',
              sizeKb: toKb(catsBytes),
              pct: toPct(catsBytes),
              color: accentColor.withValues(alpha: 0.6),
              icon: Icons.folder_copy_rounded,
            ),
            const SizedBox(height: 8),
            _buildBreakdownItem(
              context: context,
              label: 'Focus Timer Sessions (${focusList.length} sessions)',
              sizeKb: toKb(focusBytes),
              pct: toPct(focusBytes),
              color: Colors.orangeAccent,
              icon: Icons.timer_rounded,
            ),
            const SizedBox(height: 8),
            _buildBreakdownItem(
              context: context,
              label: 'Daily Study History (${historyList.length} days)',
              sizeKb: toKb(historyBytes),
              pct: toPct(historyBytes),
              color: Colors.greenAccent,
              icon: Icons.calendar_today_rounded,
            ),
            const SizedBox(height: 8),
            _buildBreakdownItem(
              context: context,
              label: 'Progress Logs & Settings',
              sizeKb: toKb(logsBytes + 1500),
              pct: toPct(logsBytes + 1500),
              color: context.appColors.textMuted,
              icon: Icons.history_toggle_off_rounded,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Close', style: GoogleFonts.outfit(color: accentColor, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

Widget _buildBreakdownItem({
  required BuildContext context,
  required String label,
  required double sizeKb,
  required double pct,
  required Color color,
  required IconData icon,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: context.appColors.surfaceColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: context.appColors.borderColor),
    ),
    child: Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          '${sizeKb.toStringAsFixed(1)} KB (${pct.toStringAsFixed(0)}%)',
          style: GoogleFonts.outfit(color: color, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}
