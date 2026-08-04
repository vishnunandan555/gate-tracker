import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/topic_resource_data.dart';
import '../../../../database/app_database.dart';
import '../../../../core/theme/theme_context_ext.dart';
import 'package:gateletics/providers/providers.dart';

bool _isResourceMatchingCategory(StudyResource res, String categoryName) {
  final cat = categoryName.toLowerCase().trim();
  final subj = res.subject.toLowerCase().trim();

  if (cat.isEmpty) return true;
  if (cat == subj || cat.contains(subj) || subj.contains(cat)) return true;

  final ignoreWords = {'and', 'the', '&', 'of', 'in', 'for'};
  final catWords = cat.split(RegExp(r'[\s&/,-]+')).where((w) => w.length > 2 && !ignoreWords.contains(w)).toList();
  final subjWords = subj.split(RegExp(r'[\s&/,-]+')).where((w) => w.length > 2 && !ignoreWords.contains(w)).toList();

  for (final cw in catWords) {
    for (final sw in subjWords) {
      if (cw == sw || cw.contains(sw) || sw.contains(cw)) {
        return true;
      }
    }
  }

  return false;
}

/// Resource Picker Modal for selecting a resource from Resource Explorer
void _showResourcePickerModal(
    BuildContext context,
    SyllabusTopic topic,
    Color accentColor,
    WidgetRef ref,
    void Function(StudyResource resource) onSelected) {
  showModalBottomSheet(
    context: context,
    backgroundColor: context.appColors.dialogBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return Consumer(
        builder: (context, modalRef, child) {
          final resourcesAsync = modalRef.watch(resourcesProvider);
          final categoriesVal = modalRef.watch(syllabusProvider).value;

          String categoryName = '';
          if (categoriesVal != null) {
            for (final catWithTopics in categoriesVal) {
              if (catWithTopics.category.id == topic.categoryId) {
                categoryName = catWithTopics.category.name;
                break;
              }
            }
          }

          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.library_add_rounded, color: accentColor, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'SELECT STUDY RESOURCE',
                      style: GoogleFonts.jersey15(color: context.appColors.textPrimary, fontSize: 18, letterSpacing: 1.0),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: context.appColors.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Text(
                  categoryName.isNotEmpty
                      ? 'Showing resources for "$categoryName":'
                      : 'Choose a resource from Resource Explorer catalog:',
                  style: GoogleFonts.outfit(color: accentColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: resourcesAsync.when(
                    loading: () => Center(child: CircularProgressIndicator(color: accentColor)),
                    error: (e, s) => const Text('Failed to load resources', style: TextStyle(color: Colors.redAccent)),
                    data: (resourceList) {
                      final filtered = categoryName.isNotEmpty
                          ? resourceList.where((res) => _isResourceMatchingCategory(res, categoryName)).toList()
                          : resourceList;
                      final displayList = filtered.isNotEmpty ? filtered : resourceList;

                      if (displayList.isEmpty) {
                        return Text('No resources available for this category.', style: GoogleFonts.outfit(color: context.appColors.textMuted));
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: displayList.length,
                        itemBuilder: (c, i) {
                          final res = displayList[i];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            leading: CircleAvatar(
                              backgroundColor: accentColor.withAlpha(40),
                              child: Icon(Icons.video_library_rounded, color: accentColor, size: 18),
                            ),
                            title: Text(res.title, style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              'by ${res.source} • ${res.platform}${res.lectureCount > 0 ? ' • ${res.lectureCount} lectures' : ''}',
                              style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 11),
                            ),
                            trailing: Icon(Icons.add_circle_outline_rounded, color: accentColor),
                            onTap: () {
                              onSelected(res);
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

// Convert To Counter Card Dialog
void showConvertToCounterCardDialog(
    BuildContext context, SyllabusTopic topic, Color accentColor, WidgetRef ref) {
  final countController = TextEditingController(
      text: topic.maxCount > 0 ? topic.maxCount.toString() : '10');

  final existingData = TopicResourceData.parse(topic.resourceUrl);
  final urlController = TextEditingController(text: existingData.url);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: context.appColors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: context.appColors.borderColor),
      ),
      title: Row(
        children: [
          Icon(Icons.calculate_rounded, color: accentColor, size: 22),
          const SizedBox(width: 8),
          Text(
            'CONVERT TO COUNTER CARD',
            style: GoogleFonts.jersey15(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accentColor,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Convert "${topic.name}" into a numeric progress counter (e.g. 0/10 Question Sets or 0/15 Lectures).',
              style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: countController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.outfit(color: context.appColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Target Total Count',
                labelStyle: GoogleFonts.outfit(color: context.appColors.textMuted),
                hintText: 'e.g. 10, 15, 20',
                hintStyle: GoogleFonts.outfit(color: context.appColors.textMuted),
                filled: true,
                fillColor: context.appColors.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: context.appColors.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: context.appColors.borderColor),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              style: GoogleFonts.outfit(color: context.appColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Resource Link (Optional)',
                labelStyle: GoogleFonts.outfit(color: context.appColors.textMuted),
                hintText: 'e.g. https://youtube.com/playlist?... or course link',
                hintStyle: GoogleFonts.outfit(color: context.appColors.textMuted),
                filled: true,
                fillColor: context.appColors.surfaceColor,
                suffixIcon: IconButton(
                  icon: Icon(Icons.add_circle_rounded, color: accentColor),
                  tooltip: 'Pick from Resource Explorer',
                  onPressed: () {
                    _showResourcePickerModal(context, topic, accentColor, ref, (selectedResource) {
                      urlController.text = selectedResource.url;
                      if (selectedResource.lectureCount > 0) {
                        countController.text = selectedResource.lectureCount.toString();
                      }
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: context.appColors.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: context.appColors.borderColor),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('CANCEL', style: GoogleFonts.outfit(color: context.appColors.textMuted, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    final maxC = int.tryParse(countController.text.trim()) ?? 10;
                    final urlInput = urlController.text.trim();
                    if (maxC > 0) {
                      final updated = existingData.copyWith(url: urlInput);
                      ref.read(syllabusControllerProvider.notifier).convertToCounterCard(
                            topic.id,
                            topic.name,
                            maxC,
                            updated.encode(),
                          );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: context.appColors.onAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('CONVERT', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// Edit Counter Card Dialog
void showEditCounterCardDialog(
    BuildContext context, SyllabusTopic topic, Color accentColor, WidgetRef ref) {
  final currentCountController =
      TextEditingController(text: topic.currentCount.toString());
  final maxCountController =
      TextEditingController(text: topic.maxCount.toString());

  final existingData = TopicResourceData.parse(topic.resourceUrl);
  final urlController = TextEditingController(text: existingData.url);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: context.appColors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: context.appColors.borderColor),
      ),
      title: Row(
        children: [
          Icon(Icons.edit_note_rounded, color: accentColor, size: 22),
          const SizedBox(width: 8),
          Text(
            'EDIT COUNTER CARD',
            style: GoogleFonts.jersey15(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accentColor,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: currentCountController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.outfit(color: context.appColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Completed',
                      labelStyle: GoogleFonts.outfit(color: context.appColors.textMuted),
                      filled: true,
                      fillColor: context.appColors.surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: context.appColors.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: context.appColors.borderColor),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: maxCountController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.outfit(color: context.appColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Target Total',
                      labelStyle: GoogleFonts.outfit(color: context.appColors.textMuted),
                      filled: true,
                      fillColor: context.appColors.surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: context.appColors.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: context.appColors.borderColor),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              style: GoogleFonts.outfit(color: context.appColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Resource Link (Optional)',
                labelStyle: GoogleFonts.outfit(color: context.appColors.textMuted),
                hintText: 'e.g. https://youtube.com/playlist?... or course link',
                hintStyle: GoogleFonts.outfit(color: context.appColors.textMuted),
                filled: true,
                fillColor: context.appColors.surfaceColor,
                suffixIcon: IconButton(
                  icon: Icon(Icons.add_circle_rounded, color: accentColor),
                  tooltip: 'Pick from Resource Explorer',
                  onPressed: () {
                    _showResourcePickerModal(context, topic, accentColor, ref, (selectedResource) {
                      urlController.text = selectedResource.url;
                      if (selectedResource.lectureCount > 0) {
                        maxCountController.text = selectedResource.lectureCount.toString();
                      }
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: context.appColors.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: context.appColors.borderColor),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Centered Cancel and Save buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('CANCEL', style: GoogleFonts.outfit(color: context.appColors.textMuted, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    final cur = int.tryParse(currentCountController.text.trim()) ?? topic.currentCount;
                    final maxC = int.tryParse(maxCountController.text.trim()) ?? topic.maxCount;
                    final urlInput = urlController.text.trim();
                    if (maxC > 0) {
                      final updated = existingData.copyWith(url: urlInput);
                      ref.read(syllabusControllerProvider.notifier).updateCounterCard(
                            topic.id,
                            topic.name,
                            cur.clamp(0, maxC),
                            maxC,
                            updated.encode(),
                          );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: context.appColors.onAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('SAVE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ),
              ],
            ),

            // Dynamic Centered Revert to Task Checklist Button (Only if subtasks exist!)
            FutureBuilder<bool>(
              future: ref.read(syllabusControllerProvider.notifier).hasTopicSubtasks(topic.id),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == true) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Center(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ref
                              .read(syllabusControllerProvider.notifier)
                              .revertToTaskCard(topic.id, topic.name);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Converted "${topic.name}" back to task checklist'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.sync_alt_rounded, size: 16, color: Colors.orangeAccent),
                        label: Text(
                          'Revert to Task Checklist',
                          style: GoogleFonts.outfit(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orangeAccent, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    ),
  );
}
