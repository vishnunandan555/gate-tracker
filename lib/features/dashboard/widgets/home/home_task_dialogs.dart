import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/theme_context_ext.dart';
import '../../../../database/app_database.dart';
import 'package:gateletics/providers/providers.dart';

void showTaskOptionsDialog(BuildContext context, WidgetRef ref, CustomTask task) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: context.appColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.appColors.borderColor),
        ),
        title: Text(
          "Task Options",
          style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit_rounded, color: context.appColors.primaryAccent),
              title: Text("Edit Task", style: GoogleFonts.outfit(color: context.appColors.textPrimary)),
              onTap: () {
                Navigator.pop(dialogContext);
                showEditTaskDialog(context, ref, task);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.redAccent),
              title: Text("Delete Task", style: GoogleFonts.outfit(color: context.appColors.textPrimary)),
              onTap: () {
                ref.read(customTasksNotifierProvider.notifier).deleteTask(task.id);
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      );
    },
  );
}

void showEditTaskDialog(BuildContext context, WidgetRef ref, CustomTask task) {
  final controller = TextEditingController(text: task.content);
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: context.appColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.appColors.borderColor),
        ),
        title: Text(
          "Edit Task",
          style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          style: GoogleFonts.outfit(color: context.appColors.textPrimary),
          decoration: InputDecoration(
            hintText: "Enter task details...",
            hintStyle: GoogleFonts.outfit(color: context.appColors.textMuted),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.appColors.borderColor)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.appColors.primaryAccent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.outfit(color: context.appColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(customTasksNotifierProvider.notifier).editTask(task.id, controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: Text("Save", style: GoogleFonts.outfit(color: context.appColors.primaryAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    },
  );
}
