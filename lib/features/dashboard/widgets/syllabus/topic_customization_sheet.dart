import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/topic_resource_data.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/syllabus_provider.dart';

// Add Syllabus Topic Dialog
void showAddSyllabusTopicDialog(BuildContext context, SyllabusCategory category, WidgetRef ref) {
  final controller = TextEditingController();
  final accentColor = Color(category.color);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'ADD TOPIC TO ${category.name.toUpperCase()}',
        style: GoogleFonts.jersey15(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: accentColor,
          letterSpacing: 0.8,
        ),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: GoogleFonts.outfit(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'e.g. Linear Algebra',
          hintStyle: GoogleFonts.outfit(color: Colors.white38),
          filled: true,
          fillColor: const Color(0xFF27272A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.white60, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: () {
            final name = controller.text.trim();
            if (name.isNotEmpty) {
              ref.read(syllabusControllerProvider.notifier).addTopic(category.id, name);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text('ADD', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

// Reorder Syllabus Topics Dialog
void showReorderSyllabusTopicsDialog(
    BuildContext context, SyllabusCategory category, List<SyllabusTopic> topics, WidgetRef ref) {
  final scrollController = ScrollController();
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'REORDER TOPICS (${category.name.toUpperCase()})',
            style: GoogleFonts.jersey15(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(category.color),
              letterSpacing: 0.8,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              child: ReorderableListView.builder(
                scrollController: scrollController,
                buildDefaultDragHandles: false,
                itemCount: topics.length,
                itemBuilder: (context, index) {
                  final topic = topics[index];
                  return ListTile(
                    key: ValueKey(topic.id),
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle_rounded, color: Colors.white54),
                    ),
                    title: Text(
                      topic.name,
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  );
                },
                // ignore: deprecated_member_use
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = topics.removeAt(oldIndex);
                    topics.insert(newIndex, item);
                  });
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.white60, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                final orderedIds = topics.map((e) => e.id).toList();
                await ref.read(syllabusControllerProvider.notifier).reorderTopics(category.id, orderedIds);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27272A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('SAVE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    ),
  );
}

// Rename Topic Dialog
void showRenameSyllabusTopicDialog(BuildContext context, SyllabusTopic topic, Color accentColor, WidgetRef ref) {
  final controller = TextEditingController(text: topic.name);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'RENAME TOPIC',
        style: GoogleFonts.jersey15(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: accentColor,
          letterSpacing: 0.8,
        ),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: GoogleFonts.outfit(color: Colors.white),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFF27272A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.white60, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: () {
            final name = controller.text.trim();
            if (name.isNotEmpty) {
              ref.read(syllabusControllerProvider.notifier).renameTopic(topic.id, name);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text('SAVE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

// Delete Topic Confirmation Dialog
void showDeleteSyllabusTopicConfirm(BuildContext context, SyllabusTopic topic, Color accentColor, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'DELETE TOPIC?',
        style: GoogleFonts.jersey15(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.redAccent,
          letterSpacing: 0.8,
        ),
      ),
      content: Text(
        'Are you sure you want to delete "${topic.name}"? All subtasks inside this topic will also be permanently deleted.',
        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.white60, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: () {
            ref.read(syllabusControllerProvider.notifier).deleteTopic(topic.id);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text('DELETE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

// Edit Topic Note Dialog
void showEditTopicNoteDialog(BuildContext context, SyllabusTopic topic, Color accentColor, WidgetRef ref) {
  final existingData = TopicResourceData.parse(topic.resourceUrl);
  final noteController = TextEditingController(text: existingData.note);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Icon(Icons.edit_note_rounded, color: accentColor, size: 22),
          const SizedBox(width: 8),
          Text(
            existingData.note.isEmpty ? 'ADD TOPIC NOTE' : 'EDIT TOPIC NOTE',
            style: GoogleFonts.jersey15(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accentColor,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attach custom study notes, formulas, or key reminders for "${topic.name}".',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: noteController,
            maxLines: 4,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'e.g., Focus on Eigenvalues & Cayley-Hamilton Theorem. See GateOverflow Q42.',
              hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF27272A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (existingData.note.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                tooltip: 'Clear Note',
                onPressed: () {
                  final updated = existingData.copyWith(note: '');
                  ref.read(syllabusControllerProvider.notifier).updateTopicResourceUrl(topic.id, updated.encode());
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cleared topic note')),
                  );
                },
              )
            else
              const SizedBox(width: 48),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.white60, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final newNote = noteController.text.trim();
                    final updated = existingData.copyWith(note: newNote);
                    ref.read(syllabusControllerProvider.notifier).updateTopicResourceUrl(topic.id, updated.encode());
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  ),
                  child: Text('SAVE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}
