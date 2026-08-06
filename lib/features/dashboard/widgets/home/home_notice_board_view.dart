import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_context_ext.dart';
import 'package:gateletics/providers/providers.dart';
import '../../../../utils/ui_scaling.dart';
import '../../../../utils/demo_keys.dart';
import '../../../../database/app_database.dart';
import 'home_task_dialogs.dart';

class HomeNoticeBoardView extends ConsumerWidget {
  final Color accentColor;
  final TextEditingController controller;

  const HomeNoticeBoardView({
    super.key,
    required this.accentColor,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksStream = ref.watch(customTasksProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Notice Board",
              style: GoogleFonts.outfit(
                color: context.appColors.textPrimary,
                fontSize: context.s(18),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Icon(
              Icons.push_pin_rounded,
              color: accentColor.withAlpha(200),
              size: context.s(18),
            ),
          ],
        ),
        SizedBox(height: context.s(14)),

        Container(
          decoration: BoxDecoration(
            color: context.appColors.cardBackground,
            border: Border.all(color: accentColor.withAlpha(50), width: 1.0),
            borderRadius: BorderRadius.circular(context.s(14)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withAlpha(15),
                blurRadius: context.s(8),
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: GoogleFonts.outfit(
                    color: context.appColors.textPrimary,
                    fontSize: context.s(14),
                  ),
                  decoration: InputDecoration(
                    hintText: "Add a quick task...",
                    hintStyle: GoogleFonts.outfit(
                      color: context.appColors.textMuted,
                      fontSize: context.s(14),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: context.s(16),
                      vertical: context.s(12),
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      ref.read(customTasksNotifierProvider.notifier).addTask(value.trim());
                      controller.clear();
                      if (ref.read(demoGuideProvider) == DemoStep.homeAddTask) {
                        ref.read(demoGuideProvider.notifier).setStep(DemoStep.homeCloseNotice);
                      }
                    }
                  },
                ),
              ),
              IconButton(
                key: DemoKeys.homeAddTaskButton,
                icon: Icon(Icons.add_rounded, color: accentColor),
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    ref.read(customTasksNotifierProvider.notifier).addTask(controller.text.trim());
                    controller.clear();
                    if (ref.read(demoGuideProvider) == DemoStep.homeAddTask) {
                      ref.read(demoGuideProvider.notifier).setStep(DemoStep.homeCloseNotice);
                    }
                  }
                },
              ),
            ],
          ),
        ),
        SizedBox(height: context.s(20)),

        tasksStream.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, stack) => Center(
            child: Text(
              "Failed to load tasks: $err",
              style: GoogleFonts.outfit(color: Colors.redAccent),
            ),
          ),
          data: (tasks) {
            if (tasks.isEmpty) {
              return Container(
                padding: EdgeInsets.all(context.s(24)),
                decoration: BoxDecoration(
                  color: context.appColors.cardBackground,
                  borderRadius: BorderRadius.circular(context.s(16)),
                  border: Border.all(color: context.appColors.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: context.s(10),
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.push_pin_outlined,
                      color: accentColor.withAlpha(120),
                      size: context.s(40),
                    ),
                    SizedBox(height: context.s(12)),
                    Text(
                      "Your Notice Board is Empty",
                      style: GoogleFonts.outfit(
                        color: context.appColors.textPrimary,
                        fontSize: context.s(14),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: context.s(6)),
                    Text(
                      "Use this space for quick reminders, test series deadlines, or equations to revise.",
                      style: GoogleFonts.outfit(
                        color: context.appColors.textSecondary,
                        fontSize: context.s(11),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final activeTasks = tasks.where((t) => !t.isCompleted).toList()
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
            final completedTasks = tasks.where((t) => t.isCompleted).toList()
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
            final sortedTasks = [...activeTasks, ...completedTasks];

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedTasks.length,
              separatorBuilder: (context, index) => SizedBox(height: context.s(8)),
              itemBuilder: (context, index) {
                final task = sortedTasks[index];
                return _buildTaskItem(context, ref, task, accentColor);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildTaskItem(BuildContext context, WidgetRef ref, CustomTask task, Color accentColor) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: task.isCompleted
              ? context.appColors.surfaceColor
              : context.appColors.cardBackground,
          borderRadius: BorderRadius.circular(context.s(12)),
          border: Border.all(
            color: task.isCompleted
                ? context.appColors.borderColor
                : accentColor.withAlpha(50),
            width: 1.0,
          ),
          boxShadow: [
            if (!task.isCompleted)
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.s(12)),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  ref.read(customTasksNotifierProvider.notifier).toggleTask(task.id, !task.isCompleted);
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(context.s(12), context.s(10), context.s(6), context.s(10)),
                  child: Container(
                    width: context.s(20),
                    height: context.s(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.isCompleted ? accentColor : context.appColors.borderColor,
                        width: 1.5,
                      ),
                      color: task.isCompleted ? accentColor.withAlpha(40) : Colors.transparent,
                    ),
                    child: task.isCompleted
                        ? Icon(
                            Icons.check,
                            color: accentColor,
                            size: context.s(12),
                          )
                        : null,
                  ),
                ),
              ),
              SizedBox(width: context.s(6)),
              Expanded(
                child: GestureDetector(
                  onTap: () => showTaskOptionsDialog(context, ref, task),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.s(6),
                      vertical: context.s(10),
                    ),
                    child: Text(
                      task.content,
                      style: GoogleFonts.outfit(
                        color: task.isCompleted ? context.appColors.textMuted : context.appColors.textPrimary,
                        fontSize: context.s(13),
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                color: context.appColors.textMuted,
                hoverColor: Colors.redAccent.withAlpha(20),
                highlightColor: Colors.redAccent.withAlpha(30),
                onPressed: () {
                  ref.read(customTasksNotifierProvider.notifier).deleteTask(task.id);
                },
                padding: EdgeInsets.symmetric(horizontal: context.s(12)),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
