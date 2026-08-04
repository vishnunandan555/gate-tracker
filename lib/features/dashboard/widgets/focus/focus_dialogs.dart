import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gateletics/providers/providers.dart';
import '../../../../core/theme/theme_context_ext.dart';
import 'timer_painters.dart';

// Dialog to configure daily target focus goal
void showDailyGoalDialog(BuildContext context, int currentGoalMins, Color progressColor, WidgetRef ref) {
  int localMins = currentGoalMins;
  final appColors = context.appColors;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final hrStr = (localMins / 60).toStringAsFixed(1).replaceAll('.0', '');

          return AlertDialog(
            backgroundColor: appColors.dialogBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: appColors.borderColor),
            ),
            title: Text(
              "Set Daily Goal",
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: appColors.textPrimary,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$hrStr hours ($localMins minutes)",
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
                const SizedBox(height: 16),
                Slider(
                  value: (localMins / 60).roundToDouble(), // hourly steps
                  min: 1.0,
                  max: 16.0,
                  divisions: 15,
                  activeColor: progressColor,
                  inactiveColor: appColors.borderColor,
                  label: '${(localMins / 60).round()}h',
                  onChanged: (val) {
                    setDialogState(() {
                      localMins = (val.round() * 60);
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.outfit(color: appColors.textSecondary),
                ),
              ),
              FilledButton(
                onPressed: () {
                  ref.read(dailyFocusGoalProvider.notifier).setGoalMinutes(localMins);
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: progressColor,
                  foregroundColor: appColors.onAccent,
                ),
                child: Text(
                  "Save",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

// Dialog to configure custom timer duration
void showCustomDurationPicker(BuildContext context, int currentMins, Color progressColor, WidgetRef ref) {
  int localMins = currentMins;
  final appColors = context.appColors;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: appColors.dialogBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: appColors.borderColor),
            ),
            title: Text(
              "Focus Duration",
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: appColors.textPrimary,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$localMins minutes",
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
                const SizedBox(height: 16),
                Slider(
                  value: localMins.toDouble(),
                  min: 1.0,
                  max: 180.0,
                  divisions: 179,
                  activeColor: progressColor,
                  inactiveColor: appColors.borderColor,
                  onChanged: (val) {
                    setDialogState(() {
                      localMins = val.round();
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.outfit(color: appColors.textSecondary),
                ),
              ),
              FilledButton(
                onPressed: () {
                  ref.read(focusProvider.notifier).setCustomTimerMinutes(localMins);
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: progressColor,
                  foregroundColor: appColors.onAccent,
                ),
                child: Text(
                  "Apply",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

// Method selection modal overlay
void showMethodSelectionMenu(BuildContext context, FocusSessionState sessionState, Color accentColor, WidgetRef ref) {
  final appColors = context.appColors;

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: appColors.dialogBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: accentColor.withValues(alpha: 0.4), width: 1.5),
        ),
        child: SizedBox(
          width: 272,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Choose Focus Method",
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: appColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: FocusMethod.values.map((method) {
                        final details = focusMethodsData[method]!;
                        final isSelected = sessionState.selectedMethod == method;
                        return InkWell(
                          onTap: () {
                            ref.read(focusProvider.notifier).selectMethod(method);
                            Navigator.pop(context);
                            // Advance demo guide when user selects a method during guided flow
                            if (ref.read(demoGuideProvider) == DemoStep.focusMethodInteract) {
                              Future.delayed(const Duration(milliseconds: 300), () {
                                ref.read(demoGuideProvider.notifier).setStep(DemoStep.focusStartInfo);
                              });
                            }
                            if (method == FocusMethod.timer) {
                              showCustomDurationPicker(context, 30, accentColor, ref);
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 110,
                            height: 110,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? accentColor.withValues(alpha: 0.15) : appColors.surfaceColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? accentColor : appColors.borderColor,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                buildMethodIcon(details, isSelected ? accentColor : appColors.textSecondary, size: 28),
                                const SizedBox(height: 6),
                                Text(
                                  details.name,
                                  style: GoogleFonts.outfit(
                                    color: isSelected ? accentColor : appColors.textPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Center(
                  child: SizedBox(
                    width: 232,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        showTechniqueGuideModal(context, sessionState, accentColor, ref);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: accentColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        "Learn More ?",
                        style: GoogleFonts.outfit(color: accentColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// Technique details guide sheet
void showTechniqueGuideModal(BuildContext context, FocusSessionState sessionState, Color accentColor, WidgetRef ref) {
  final appColors = context.appColors;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: appColors.dialogBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: appColors.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Technique Guide:",
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: appColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: appColors.surfaceColor,
                        foregroundColor: appColors.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text("Exit", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  itemCount: FocusMethod.values.length,
                  itemBuilder: (context, index) {
                    final method = FocusMethod.values[index];
                    final details = focusMethodsData[method]!;
                    final isSelected = sessionState.selectedMethod == method;

                    final targetStr = details.isCountUp
                        ? "Count Up | No Breaks"
                        : (details.isCustom
                            ? "Custom Timer | No Breaks"
                            : "${details.focusMinutes}m Focus | ${details.breakMinutes}m Break");

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: appColors.cardBackground,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? accentColor : appColors.borderColor,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? accentColor.withValues(alpha: 0.15) : appColors.surfaceColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: buildMethodIcon(details, isSelected ? accentColor : appColors.textSecondary, size: 30),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    details.name,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: appColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              isSelected
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: accentColor.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        "Selected",
                                        style: GoogleFonts.outfit(
                                          color: accentColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : OutlinedButton(
                                      onPressed: () {
                                        ref.read(focusProvider.notifier).selectMethod(method);
                                        Navigator.pop(context);
                                        if (method == FocusMethod.timer) {
                                          showCustomDurationPicker(context, 30, accentColor, ref);
                                        }
                                      },
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                        side: BorderSide(color: appColors.borderColor),
                                      ),
                                      child: Text(
                                        "Select",
                                        style: GoogleFonts.outfit(color: appColors.textSecondary, fontSize: 11),
                                      ),
                                    ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            targetStr,
                            style: GoogleFonts.outfit(
                              color: isSelected ? accentColor : appColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            details.description,
                            style: GoogleFonts.outfit(
                              color: appColors.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
