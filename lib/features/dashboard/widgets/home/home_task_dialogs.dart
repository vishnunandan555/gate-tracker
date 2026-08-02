import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../database/app_database.dart';
import 'package:gateletics/providers/providers.dart';

void showTaskOptionsDialog(BuildContext context, WidgetRef ref, CustomTask task) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: const Color(0xFF131316),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withAlpha(12)),
        ),
        title: Text(
          "Task Options",
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: Colors.cyanAccent),
              title: Text("Edit Task", style: GoogleFonts.outfit(color: Colors.white)),
              onTap: () {
                Navigator.pop(dialogContext);
                showEditTaskDialog(context, ref, task);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.redAccent),
              title: Text("Delete Task", style: GoogleFonts.outfit(color: Colors.white)),
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
        backgroundColor: const Color(0xFF131316),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withAlpha(12)),
        ),
        title: Text(
          "Edit Task",
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          style: GoogleFonts.outfit(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter task details...",
            hintStyle: GoogleFonts.outfit(color: Colors.white30),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: ref.watch(overallProgressColorProvider))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.outfit(color: Colors.white30)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(customTasksNotifierProvider.notifier).editTask(task.id, controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: Text("Save", style: GoogleFonts.outfit(color: Colors.cyanAccent)),
          ),
        ],
      );
    },
  );
}
