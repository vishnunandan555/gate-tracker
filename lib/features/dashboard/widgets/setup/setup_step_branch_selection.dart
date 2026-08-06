import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/theme_context_ext.dart';
import '../../../../database/syllabus_preset.dart';
import 'package:gateletics/providers/providers.dart';
import 'setup_step_widgets.dart';

class SetupStepBranchSelection extends ConsumerWidget {
  final Color accentColor;
  final String selectedBranch;
  final Function(String branch, bool usePreset) onBranchSelected;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const SetupStepBranchSelection({
    super.key,
    required this.accentColor,
    required this.selectedBranch,
    required this.onBranchSelected,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branches = [
      {"id": "CS", "name": "Computer Science & Information Technology", "icon": Icons.computer_rounded},
      {"id": "DA", "name": "Data Science & Artificial Intelligence", "icon": Icons.analytics_rounded},
      {"id": "EC", "name": "Electronics & Communication Engineering", "icon": Icons.settings_input_antenna_rounded},
      {"id": "EE", "name": "Electrical Engineering", "icon": Icons.bolt_rounded},
      {"id": "CE", "name": "Civil Engineering", "icon": Icons.architecture_rounded},
      {"id": "ME", "name": "Mechanical Engineering", "icon": Icons.build_rounded},
      {"id": "CH", "name": "Chemical Engineering", "icon": Icons.science_rounded},
      {"id": "CUSTOM", "name": "Empty slate. Create custom subjects & trackers.", "icon": Icons.dashboard_customize_rounded},
    ];

    return Column(
      key: const ValueKey(4),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SetupStepHeader(
          title: "CHOOSE YOUR BRANCH",
          subtitle: "Select the engineering branch you are preparing for to configure your syllabus presets.",
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.50,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: branches.length,
          itemBuilder: (ctx, idx) {
            final branch = branches[idx];
            final id = branch["id"] as String;
            final name = branch["name"] as String;
            final icon = branch["icon"] as IconData;
            final isSelected = selectedBranch == id;

            return GestureDetector(
              onTap: () {
                ref.read(hapticSettingsProvider.notifier).selectionClick();
                onBranchSelected(id, id != "CUSTOM");
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? accentColor.withValues(alpha: 0.08) : context.appColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? accentColor : context.appColors.borderColor,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected ? accentColor.withValues(alpha: 0.15) : context.appColors.surfaceColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: isSelected ? accentColor : context.appColors.textSecondary, size: 24),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            id,
                            style: GoogleFonts.orbitron(
                              color: isSelected ? accentColor : context.appColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Builder(
                      builder: (_) {
                        if (id == "CUSTOM") {
                          return Text(
                            name,
                            style: GoogleFonts.outfit(
                              color: isSelected ? accentColor.withAlpha(200) : context.appColors.textSecondary,
                              fontSize: 9.5,
                              height: 1.15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          );
                        }

                        final presets = branchPresets[id.toUpperCase()];
                        int catCount = 0;
                        int topicCount = 0;
                        int taskCount = 0;
                        if (presets != null && presets.isNotEmpty) {
                          catCount = presets.length;
                          topicCount = presets.fold<int>(0, (acc, cat) => acc + cat.topics.length);
                          taskCount = presets.fold<int>(
                            0,
                            (acc, cat) => acc + cat.topics.fold<int>(0, (tAcc, t) => tAcc + t.tasks.length),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.outfit(
                                color: context.appColors.textSecondary,
                                fontSize: 9.0,
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? accentColor.withValues(alpha: 0.18)
                                    : context.appColors.surfaceColor,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: isSelected
                                      ? accentColor.withValues(alpha: 0.35)
                                      : context.appColors.borderColor,
                                ),
                              ),
                              child: Text(
                                "$catCount Subs · $topicCount Topics · $taskCount Tasks",
                                style: GoogleFonts.outfit(
                                  color: isSelected ? accentColor : context.appColors.textSecondary,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        SetupNavigationRow(
          accentColor: accentColor,
          onBack: onBack,
          onNext: onNext,
        ),
      ],
    );
  }
}
