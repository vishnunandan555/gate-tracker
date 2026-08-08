import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/topic_resource_data.dart';
import '../../../database/app_database.dart';
import '../../../core/theme/theme_context_ext.dart';
import 'package:gateletics/providers/providers.dart';
import '../../../widgets/progress_bar.dart';
import 'syllabus_customization_sheets.dart';
import '../../../utils/ui_scaling.dart';

class SyllabusTopicCard extends ConsumerWidget {
  final SyllabusTopicWithTasks topicWithTasks;
  final Color categoryColor;
  final bool forceExpanded;

  const SyllabusTopicCard({
    super.key,
    required this.topicWithTasks,
    required this.categoryColor,
    this.forceExpanded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topic = topicWithTasks.topic;
    final tasks = topicWithTasks.tasks;

    final completedCount = topic.isCounter ? topic.currentCount : tasks.where((t) => t.isCompleted).length;
    final totalCount = topic.isCounter ? topic.maxCount : tasks.length;
    final percentage = totalCount == 0 ? 0.0 : (completedCount / totalCount) * 100;

    final expandedSet = ref.watch(expandedTopicsProvider);
    final isExpanded = forceExpanded || expandedSet.contains(topic.id);
    final isWeak = ref.watch(weakTopicsProvider).contains(topic.id);

    final resData = TopicResourceData.parse(topic.resourceUrl);
    final url = resData.url;
    final label = resData.label;
    final note = resData.note;

    final overallScale = ref.watch(overallUiScaleProvider).scaleFactor;
    final topicScaleFactor = ref.watch(topicFontSizeProvider).scaleFactor;
    final taskScaleFactor = ref.watch(taskFontSizeProvider).scaleFactor;

    // Proportional font sizes using context.s() scaling factor
    final topicFontSize = context.s(16.0) * topicScaleFactor;
    final percentFontSize = context.s(27.0) * topicScaleFactor;
    final countFontSize = context.s(11.5) * topicScaleFactor;
    final taskFontSize = context.s(14.0) * taskScaleFactor;

    late TapDownDetails topicTapDetails;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.s(16.0), vertical: context.s(2.5) * overallScale),
      decoration: BoxDecoration(
        color: context.appColors.cardBackground,
        borderRadius: BorderRadius.circular(context.s(10)),
        border: Border.all(
          color: categoryColor.withAlpha(20),
          width: context.s(1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: context.appColors.isLight
                ? Colors.black.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.25),
            blurRadius: context.s(10),
            offset: Offset(0, context.s(4)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Topic Panel (Tappable area)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              topicTapDetails = details;
            },
            onTap: () {
              ref.read(expandedTopicsProvider.notifier).toggle(topic.id);
            },
            onLongPress: () {
              _showTopicContextMenu(context, topicTapDetails, topic, tasks, ref, categoryColor);
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.s(12) * overallScale, vertical: context.s(8) * overallScale),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // LEFT: Title & Progress Bar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (topic.isCounter) ...[
                              Icon(
                                Icons.book_rounded,
                                size: topicFontSize * 0.85,
                                color: categoryColor.withAlpha(220),
                              ),
                              SizedBox(width: context.s(6) * overallScale),
                            ],
                            if (isWeak) ...[
                              Icon(
                                Icons.warning_rounded,
                                size: topicFontSize * 1.25,
                                color: Colors.amberAccent,
                              ),
                              SizedBox(width: context.s(6) * overallScale),
                            ],
                            Expanded(
                              child: Text(
                                topic.name,
                                style: GoogleFonts.outfit(
                                  fontSize: topicFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: context.appColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: context.s(6) * overallScale),
                        ProgressBar(
                          percentage: percentage,
                          height: context.s(8) * overallScale,
                          color: categoryColor,
                          showTicks: false,
                          tickCount: 10,
                        ),
                        if (note.isNotEmpty) ...[
                          SizedBox(height: context.s(6) * overallScale),
                          Text(
                            note,
                            style: GoogleFonts.outfit(
                              color: context.appColors.isLight ? context.appColors.textSecondary : categoryColor,
                              fontSize: taskFontSize,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: context.s(16) * overallScale),
                  // RIGHT: Big % & Fraction count
                  Container(
                    width: context.s(80) * overallScale,
                    alignment: Alignment.centerRight,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: GoogleFonts.orbitron(
                            fontSize: percentFontSize,
                            fontWeight: FontWeight.w900,
                            color: categoryColor,
                            letterSpacing: context.s(-0.5),
                            height: 1,
                            shadows: context.appColors.isLight
                                ? null
                                : [
                                    Shadow(
                                      color: categoryColor.withValues(alpha: 0.5),
                                      blurRadius: context.s(14),
                                    ),
                                  ],
                          ),
                        ),
                        SizedBox(height: context.s(4) * overallScale),
                        Text(
                          '$completedCount/$totalCount',
                          style: GoogleFonts.outfit(
                            color: context.appColors.textSecondary,
                            fontSize: countFontSize,
                            fontWeight: FontWeight.w500,
                            letterSpacing: context.s(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Checklist Area
          if (isExpanded && !topic.isCounter) ...[
            Divider(color: context.appColors.dividerColor, height: 1),
            if (totalCount == 0)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16 * overallScale, horizontal: 16 * overallScale),
                child: Center(
                  child: Text(
                    'No tasks in this topic. Long press topic name to add tasks!',
                    style: GoogleFonts.outfit(
                      color: context.appColors.textMuted,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ...List.generate(totalCount, (index) {
                final task = tasks[index];
                late TapDownDetails taskTapDetails;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) {
                    taskTapDetails = details;
                  },
                  onTap: () {
                    HapticFeedback.lightImpact();
                    final isBeingCompleted = !task.isCompleted;
                    ref
                        .read(syllabusControllerProvider.notifier)
                        .toggleTask(task.id, isBeingCompleted);
                    // Advance demo guide when user marks a task complete during guided flow.
                    // Done here (UI layer) so timing is deterministic — the Notifier ref
                    // can go stale after awaits inside the async toggleTask.
                    if (isBeingCompleted && ref.read(demoGuideProvider) == DemoStep.completionInteract) {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (ref.read(demoGuideProvider) == DemoStep.completionInteract) {
                          ref.read(demoGuideProvider.notifier).setStep(DemoStep.completionLongPress);
                        }
                      });
                    }
                  },
                  onLongPress: () {
                    _showTaskContextMenu(context, taskTapDetails, task, ref, categoryColor);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.s(14) * overallScale, vertical: context.s(8) * overallScale),
                    child: Row(
                      children: [
                        // Custom Checkbox
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: context.s(18) * overallScale,
                          height: context.s(18) * overallScale,
                          decoration: BoxDecoration(
                            color: task.isCompleted
                                ? categoryColor.withAlpha(38)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(context.s(5)),
                            border: Border.all(
                              color: task.isCompleted ? categoryColor : context.appColors.borderColor,
                              width: context.s(1.5),
                            ),
                          ),
                          child: task.isCompleted
                              ? Icon(
                                  Icons.check_rounded,
                                  size: context.s(14) * overallScale,
                                  color: categoryColor,
                                )
                              : null,
                        ),
                        SizedBox(width: context.s(12) * overallScale),
                        // Task Name
                        Expanded(
                          child: Text(
                            task.name,
                            style: GoogleFonts.outfit(
                              color: task.isCompleted ? context.appColors.textMuted : context.appColors.textSecondary,
                              fontSize: taskFontSize,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],

          if (topic.isCounter && isExpanded) ...[
            Divider(color: context.appColors.dividerColor, height: 1),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.s(14) * overallScale,
                vertical: context.s(10) * overallScale,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Resource Link Button
                  if (url.isNotEmpty)
                    FilledButton.icon(
                      onPressed: () async {
                        String urlToLaunch = url;
                        if (!RegExp(r'^[a-zA-Z]+:').hasMatch(urlToLaunch)) {
                          urlToLaunch = 'https://$urlToLaunch';
                        }
                        final uri = Uri.parse(urlToLaunch);
                        try {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (e) {
                          try {
                            await launchUrl(uri);
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Could not open link: $url'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        }
                      },
                      icon: Icon(
                        Icons.open_in_new_rounded,
                        size: context.s(13) * overallScale,
                      ),
                      label: Text(
                        label,
                        style: GoogleFonts.outfit(
                          fontSize: context.s(12) * overallScale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: categoryColor.withAlpha(45),
                        foregroundColor: categoryColor,
                        padding: EdgeInsets.symmetric(
                          horizontal: context.s(12) * overallScale,
                          vertical: context.s(8) * overallScale,
                        ),
                        minimumSize: Size(0, context.s(34) * overallScale),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.s(8)),
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  // Counter controls
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton.icon(
                        onPressed: topic.currentCount > 0
                            ? () {
                                ref.read(hapticSettingsProvider.notifier).trigger();
                                ref.read(syllabusControllerProvider.notifier).updateCounterValue(
                                      topic.id,
                                      topic.currentCount - 1,
                                    );
                              }
                            : null,
                        icon: Icon(
                          Icons.remove_rounded,
                          size: context.s(14) * overallScale,
                        ),
                        label: Text(
                          "DEC",
                          style: GoogleFonts.outfit(
                            fontSize: context.s(11) * overallScale,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: context.appColors.surfaceColor,
                          foregroundColor: context.appColors.textPrimary,
                          disabledBackgroundColor: context.appColors.cardBackground,
                          disabledForegroundColor: context.appColors.textMuted,
                          padding: EdgeInsets.symmetric(
                            horizontal: context.s(12) * overallScale,
                            vertical: context.s(8) * overallScale,
                          ),
                          minimumSize: Size(0, context.s(34) * overallScale),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(context.s(8)),
                          ),
                        ),
                      ),
                      SizedBox(width: context.s(8) * overallScale),
                      FilledButton.icon(
                        onPressed: topic.currentCount < topic.maxCount
                            ? () {
                                ref.read(hapticSettingsProvider.notifier).trigger();
                                ref.read(syllabusControllerProvider.notifier).updateCounterValue(
                                      topic.id,
                                      topic.currentCount + 1,
                                    );
                              }
                            : null,
                        icon: Icon(
                          Icons.add_rounded,
                          size: context.s(14) * overallScale,
                        ),
                        label: Text(
                          "INC",
                          style: GoogleFonts.outfit(
                            fontSize: context.s(11) * overallScale,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: categoryColor,
                          foregroundColor: context.appColors.onAccent,
                          disabledBackgroundColor: context.appColors.cardBackground,
                          disabledForegroundColor: context.appColors.textMuted,
                          padding: EdgeInsets.symmetric(
                            horizontal: context.s(12) * overallScale,
                            vertical: context.s(8) * overallScale,
                          ),
                          minimumSize: Size(0, context.s(34) * overallScale),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(context.s(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showTopicContextMenu(
      BuildContext context, TapDownDetails details, SyllabusTopic topic, List<SyllabusTask> tasks, WidgetRef ref, Color categoryColor) {
    final position = details.globalPosition;
    final isWeak = ref.read(weakTopicsProvider).contains(topic.id);

    final resData = TopicResourceData.parse(topic.resourceUrl);
    final note = resData.note;
    final noteLabel = note.isEmpty ? 'Add Note' : 'Edit Note';
    final noteIcon = note.isEmpty ? Icons.note_add_rounded : Icons.edit_note_rounded;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      color: context.appColors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.appColors.borderColor),
      ),
      items: topic.isCounter
          ? [
              PopupMenuItem(
                value: 'edit_counter',
                height: 36,
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, color: categoryColor, size: 18),
                    const SizedBox(width: 10),
                    Text('Edit Card', style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit_note',
                height: 36,
                child: Row(
                  children: [
                    Icon(noteIcon, color: categoryColor, size: 18),
                    const SizedBox(width: 10),
                    Text(noteLabel, style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle_weak',
                height: 36,
                child: Row(
                  children: [
                    Icon(isWeak ? Icons.warning_rounded : Icons.warning_amber_rounded, color: isWeak ? Colors.amberAccent : categoryColor, size: 18),
                    const SizedBox(width: 10),
                    Text(isWeak ? 'Unmark as Weak' : 'Mark as Weak Area', style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'complete',
                height: 36,
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, color: categoryColor, size: 18),
                    const SizedBox(width: 10),
                    Text('Mark as Complete', style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'reset',
                height: 36,
                child: Row(
                  children: [
                    Icon(Icons.replay_rounded, color: categoryColor, size: 18),
                    const SizedBox(width: 10),
                    Text('Reset Stats', style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                height: 36,
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 10),
                    Text('Delete Card', style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 13)),
                  ],
                ),
              ),
            ]
          : [
              PopupMenuItem(
                value: 'rename',
                height: 36,
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, color: categoryColor, size: 18),
                    const SizedBox(width: 10),
                    Text('Rename Topic', style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit_note',
                height: 36,
                child: Row(
                  children: [
                    Icon(noteIcon, color: categoryColor, size: 18),
                    const SizedBox(width: 10),
                    Text(noteLabel, style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'add_task',
                height: 36,
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline_rounded, color: categoryColor, size: 18),
                    const SizedBox(width: 10),
                    Text('Add Task', style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'complete',
                height: 36,
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, color: categoryColor, size: 18),
                    const SizedBox(width: 10),
                    Text('Mark as Complete', style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'reset',
                height: 36,
                child: Row(
                  children: [
                    Icon(Icons.replay_rounded, color: categoryColor, size: 18),
                    const SizedBox(width: 10),
                    Text('Reset Stats', style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'reorder',
                height: 36,
                child: Row(
                  children: [
                    Icon(Icons.swap_vert_rounded, color: categoryColor, size: 18),
                    const SizedBox(width: 10),
                    Text('Reorder Tasks', style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'convert_counter',
                height: 36,
                child: Row(
                  children: [
                    Icon(Icons.slow_motion_video_rounded, color: categoryColor, size: 18),
                    const SizedBox(width: 10),
                    Text('Convert to Counter Card', style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle_weak',
                height: 36,
                child: Row(
                  children: [
                    Icon(isWeak ? Icons.warning_rounded : Icons.warning_amber_rounded, color: isWeak ? Colors.amberAccent : categoryColor, size: 18),
                    const SizedBox(width: 10),
                    Text(isWeak ? 'Unmark as Weak' : 'Mark as Weak Area', style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                height: 36,
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 10),
                    Text('Delete Topic', style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 13)),
                  ],
                ),
              ),
            ],
    ).then((val) {
      if (!context.mounted) return;
      if (val == 'rename') {
        showRenameSyllabusTopicDialog(context, topic, categoryColor, ref);
      } else if (val == 'edit_counter') {
        showEditCounterCardDialog(context, topic, categoryColor, ref);
      } else if (val == 'edit_note') {
        showEditTopicNoteDialog(context, topic, categoryColor, ref);
      } else if (val == 'convert_counter') {
        showConvertToCounterCardDialog(context, topic, categoryColor, ref);
      } else if (val == 'add_task') {
        showAddSyllabusTaskDialog(context, topic, categoryColor, ref);
      } else if (val == 'complete') {
        ref.read(syllabusControllerProvider.notifier).markTopicCompleted(topic.id);
      } else if (val == 'reset') {
        ref.read(syllabusControllerProvider.notifier).resetTopicStats(topic.id);
      } else if (val == 'reorder') {
        showReorderSyllabusTasksDialog(context, topic, tasks, categoryColor, ref);
      } else if (val == 'toggle_weak') {
        ref.read(weakTopicsProvider.notifier).toggle(topic.id);
      } else if (val == 'delete') {
        showDeleteSyllabusTopicConfirm(context, topic, categoryColor, ref);
      }
    });
  }

  void _showTaskContextMenu(BuildContext context, TapDownDetails details, SyllabusTask task, WidgetRef ref, Color categoryColor) {
    final position = details.globalPosition;
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      color: context.appColors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.appColors.borderColor),
      ),
      items: [
        PopupMenuItem(
          value: 'rename',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.edit_rounded, color: categoryColor, size: 18),
              const SizedBox(width: 10),
              Text('Rename Task', style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          height: 36,
          child: Row(
            children: [
              const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
              const SizedBox(width: 10),
              Text('Delete Task', style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 13)),
            ],
          ),
        ),
      ],
    ).then((val) {
      if (!context.mounted) return;
      if (val == 'rename') {
        showRenameSyllabusTaskDialog(context, task, categoryColor, ref);
      } else if (val == 'delete') {
        showDeleteSyllabusTaskConfirm(context, task, categoryColor, ref);
      }
    });
  }
}
