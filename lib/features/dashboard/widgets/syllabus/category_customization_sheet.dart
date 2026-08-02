import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../database/app_database.dart';
import 'package:gateletics/providers/providers.dart';
import '../../../../utils/string_utils.dart';
import 'topic_customization_sheet.dart';

const List<int> neonPalette = [
  0xFFFF0000, // Red
  0xFF00F0FF, // Cyan
  0xFF39FF14, // Green
  0xFFE040FB, // Purple
  0xFFFFAD00, // Orange
  0xFFFF0055, // Hot Pink
  0xFF00FFCC, // Teal
  0xFFFFEA00, // Yellow
];

// Show Category Options Sheet
void showSyllabusCategoryOptionsSheet(
    BuildContext context, SyllabusCategory category, WidgetRef ref, List<SyllabusTopic> topics) {
  final color = Color(category.color);
  final isPinned = ref.read(pinnedCategoriesProvider).contains(category.id);
  final isWeak = ref.read(weakCategoriesProvider).contains(category.id);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF18181B),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        category.name.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10),
                ListTile(
                  leading: Icon(Icons.add_circle_outline_rounded, color: color),
                  title: Text('Add Topic', style: GoogleFonts.outfit(color: Colors.white)),
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -2),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    showAddSyllabusTopicDialog(context, category, ref);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.edit_rounded, color: color),
                  title: Text('Edit Category Details', style: GoogleFonts.outfit(color: Colors.white)),
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -2),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    showEditSyllabusCategoryDialog(context, category, ref);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.create_new_folder_outlined, color: color),
                  title: Text('Create New Category', style: GoogleFonts.outfit(color: Colors.white)),
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -2),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    showCreateSyllabusCategoryDialog(context, ref);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.check_circle_outline_rounded, color: color),
                  title: Text('Mark as Complete', style: GoogleFonts.outfit(color: Colors.white)),
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -2),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ref.read(syllabusControllerProvider.notifier).markCategoryCompleted(category.id);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.replay_rounded, color: color),
                  title: Text('Reset Stats', style: GoogleFonts.outfit(color: Colors.white)),
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -2),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ref.read(syllabusControllerProvider.notifier).resetCategoryStats(category.id);
                  },
                ),
                ListTile(
                  leading: Icon(isPinned ? Icons.pin_end_rounded : Icons.push_pin_rounded, color: color),
                  title: Text(isPinned ? 'Unpin Category' : 'Pin Category to Top', style: GoogleFonts.outfit(color: Colors.white)),
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -2),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ref.read(pinnedCategoriesProvider.notifier).toggle(category.id);
                  },
                ),
                ListTile(
                  leading: Icon(isWeak ? Icons.warning_rounded : Icons.warning_amber_rounded, color: isWeak ? Colors.amberAccent : color),
                  title: Text(isWeak ? 'Unmark Category as Weak' : 'Mark Category as Weak Area', style: GoogleFonts.outfit(color: Colors.white)),
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -2),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ref.read(weakCategoriesProvider.notifier).toggle(category.id);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.swap_vert_rounded, color: Colors.white70),
                  title: Text('Reorder Topics', style: GoogleFonts.outfit(color: Colors.white)),
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -2),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    showReorderSyllabusTopicsDialog(context, category, topics, ref);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.swap_vert_rounded, color: Colors.white70),
                  title: Text('Reorder Categories', style: GoogleFonts.outfit(color: Colors.white)),
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -2),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    final list = ref.read(syllabusCategoriesProvider).value;
                    if (list != null) {
                      showReorderSyllabusCategoriesDialog(context, List.from(list), ref);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  title: Text('Delete Category', style: GoogleFonts.outfit(color: Colors.redAccent)),
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -2),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showDeleteSyllabusCategoryConfirm(context, category, ref);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// Rename/Edit Category Details Dialog
void showEditSyllabusCategoryDialog(BuildContext context, SyllabusCategory category, WidgetRef ref) {
  final nameController = TextEditingController(text: category.name);
  int selectedColor = category.color;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'EDIT SYLLABUS CATEGORY',
          style: GoogleFonts.jersey15(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(selectedColor),
            letterSpacing: 0.8,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              onChanged: (val) {
                setState(() {});
              },
              style: GoogleFonts.outfit(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Category Name',
                labelStyle: GoogleFonts.outfit(color: Colors.white60),
                filled: true,
                fillColor: const Color(0xFF27272A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Short Name: ${getCategoryShortName(nameController.text)}',
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Accent Color',
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: neonPalette.map((colorVal) {
                final isSelected = selectedColor == colorVal;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedColor = colorVal;
                    });
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(colorVal),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Color(colorVal).withAlpha(150),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.white60, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                ref.read(syllabusControllerProvider.notifier).renameCategory(category.id, name, selectedColor);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(selectedColor),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('SAVE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ),
  );
}

// Delete Category Confirmation Dialog
void _showDeleteSyllabusCategoryConfirm(BuildContext context, SyllabusCategory category, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'DELETE SYLLABUS CATEGORY?',
        style: GoogleFonts.jersey15(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.redAccent,
          letterSpacing: 0.8,
        ),
      ),
      content: Text(
        'Are you sure you want to delete "${category.name}"? This will permanently delete ALL topics and tasks inside it. This cannot be undone.',
        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.white60, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: () {
            ref.read(syllabusControllerProvider.notifier).deleteCategory(category.id);
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

// Create Category Dialog
void showCreateSyllabusCategoryDialog(BuildContext context, WidgetRef ref) {
  final nameController = TextEditingController();
  int selectedColor = 0xFFFF0000; // Default Red

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'NEW SYLLABUS CATEGORY',
          style: GoogleFonts.jersey15(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.8,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              onChanged: (val) {
                setState(() {});
              },
              style: GoogleFonts.outfit(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Category Name',
                labelStyle: GoogleFonts.outfit(color: Colors.white60),
                filled: true,
                fillColor: const Color(0xFF27272A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Short Name: ${getCategoryShortName(nameController.text)}',
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Accent Color',
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: neonPalette.map((colorVal) {
                final isSelected = selectedColor == colorVal;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedColor = colorVal;
                    });
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(colorVal),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Color(colorVal).withAlpha(150),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.white60, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                ref.read(syllabusControllerProvider.notifier).addCategory(name, selectedColor);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(selectedColor),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('CREATE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ),
  );
}

// Reorder Categories Dialog
void showReorderSyllabusCategoriesDialog(
    BuildContext context, List<SyllabusCategory> categories, WidgetRef ref) {
  final scrollController = ScrollController();
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'REORDER CATEGORIES',
            style: GoogleFonts.jersey15(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
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
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return ListTile(
                    key: ValueKey(cat.id),
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle_rounded, color: Colors.white54),
                    ),
                    title: Text(
                      cat.name,
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    trailing: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(color: Color(cat.color), shape: BoxShape.circle),
                    ),
                  );
                },
                // ignore: deprecated_member_use
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = categories.removeAt(oldIndex);
                    categories.insert(newIndex, item);
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
                final orderedIds = categories.map((e) => e.id).toList();
                await ref.read(syllabusControllerProvider.notifier).reorderCategories(orderedIds);
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
