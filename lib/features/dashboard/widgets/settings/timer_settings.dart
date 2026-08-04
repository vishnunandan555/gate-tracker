import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/theme_context_ext.dart';
import 'package:gateletics/providers/providers.dart';
import '../../../../database/app_database.dart';

class TimerSettingsSection extends ConsumerWidget {
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final Color accentColor;

  const TimerSettingsSection({
    super.key,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.accentColor,
  });

  void _showFocusGoalDialog(BuildContext context, WidgetRef ref, int currentGoalMins, Color accentColor) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: context.appColors.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Daily Study Goal',
            style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [30, 60, 90, 120, 180, 240, 300, 360, 480].map((mins) {
              final isSelected = mins == currentGoalMins;
              final hrs = mins / 60;
              final label = hrs % 1 == 0 ? '${hrs.toInt()} hours' : '$hrs hours';
              return ListTile(
                title: Text(
                  '$label${mins == 120 ? ' (default)' : ''}',
                  style: GoogleFonts.outfit(
                    color: isSelected ? accentColor : context.appColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected ? Icon(Icons.check_rounded, color: accentColor) : null,
                onTap: () {
                  ref.read(dailyFocusGoalProvider.notifier).setGoalMinutes(mins);
                  Navigator.of(ctx).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showCheckInGoalDialog(BuildContext context, WidgetRef ref, int currentMins, Color accentColor) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: context.appColors.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Daily Check-in Goal',
            style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [5, 10, 15, 20, 30, 45].map((mins) {
              final isSelected = mins == currentMins;
              return ListTile(
                title: Text(
                  '$mins minutes${mins == 15 ? ' (default)' : ''}',
                  style: GoogleFonts.outfit(
                    color: isSelected ? accentColor : context.appColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected ? Icon(Icons.check_rounded, color: accentColor) : null,
                onTap: () {
                  ref.read(checkInGoalMinutesProvider.notifier).setMinutes(mins);
                  Navigator.of(ctx).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoSort = ref.watch(categoryAutoSortProvider);
    final focusGoalMins = ref.watch(dailyFocusGoalProvider);
    final checkInMins = ref.watch(checkInGoalMinutesProvider);
    final rollover = ref.watch(studyDayRolloverProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          activeThumbColor: accentColor,
          secondary: Icon(Icons.sort_rounded, color: accentColor),
          title: Text('Auto-Sort Categories', style: titleStyle),
          subtitle: Text(
            'Move active categories to top automatically',
            style: subtitleStyle,
          ),
          value: autoSort,
          onChanged: (val) {
            ref.read(categoryAutoSortProvider.notifier).setAutoSort(val);
          },
        ),

        ListTile(
          leading: Icon(Icons.track_changes_rounded, color: accentColor),
          title: Text('Daily Study Goal', style: titleStyle),
          subtitle: Text(
            'Daily targeted countdown goal (default 2h)',
            style: subtitleStyle,
          ),
          trailing: Text(
            '${(focusGoalMins / 60).toStringAsFixed(1).replaceFirst('.0', '')} hrs',
            style: GoogleFonts.outfit(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          onTap: () => _showFocusGoalDialog(context, ref, focusGoalMins, accentColor),
        ),
        Divider(color: context.appColors.dividerColor, height: 1),
        ListTile(
          leading: Icon(Icons.task_alt_rounded, color: accentColor),
          title: Text('Daily Check-in Goal', style: titleStyle),
          subtitle: Text(
            'Minimum study duration to mark check-in streak',
            style: subtitleStyle,
          ),
          trailing: Text(
            '$checkInMins mins',
            style: GoogleFonts.outfit(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          onTap: () => _showCheckInGoalDialog(context, ref, checkInMins, accentColor),
        ),
        Divider(color: context.appColors.dividerColor, height: 1),
        ListTile(
          leading: Icon(Icons.alarm_rounded, color: accentColor),
          title: Text('Overnight Rollover Hour', style: titleStyle),
          subtitle: Text(
            'Daily cut-off hour (0-23) for post-midnight tracking',
            style: subtitleStyle,
          ),
          trailing: Text(
            rollover == StudyDayRollover.midnight ? 'Midnight (12 AM)' : '04:00 AM',
            style: GoogleFonts.outfit(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          onTap: () async {
            final result = await showDialog<StudyDayRollover>(
              context: context,
              builder: (ctx) => SimpleDialog(
                title: const Text('Set Rollover Hour'),
                backgroundColor: context.appColors.surfaceColor,
                children: [
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, StudyDayRollover.midnight),
                    child: Text('00:00 (12:00 AM)', style: TextStyle(color: rollover == StudyDayRollover.midnight ? accentColor : context.appColors.textPrimary)),
                  ),
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, StudyDayRollover.overnight),
                    child: Text('04:00 AM (default)', style: TextStyle(color: rollover == StudyDayRollover.overnight ? accentColor : context.appColors.textPrimary)),
                  ),
                ],
              ),
            );
            if (result != null) {
              await ref.read(studyDayRolloverProvider.notifier).setRollover(result);
            }
          },
        ),
        Divider(color: context.appColors.dividerColor, height: 1),
        Builder(
          builder: (context) {
            final hapticState = ref.watch(hapticSettingsProvider);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  activeThumbColor: accentColor,
                  secondary: Icon(Icons.vibration_rounded, color: accentColor),
                  title: Text('Haptic Touch Feedback', style: titleStyle),
                  subtitle: Text(
                    'Tactile vibration on task toggles, counters & timer actions',
                    style: subtitleStyle,
                  ),
                  value: hapticState.isEnabled,
                  onChanged: (val) {
                    ref.read(hapticSettingsProvider.notifier).setEnabled(val);
                    if (val) {
                      ref.read(hapticSettingsProvider.notifier).trigger();
                    }
                  },
                ),
                if (hapticState.isEnabled) ...[
                  const Divider(color: Colors.white10, height: 1),
                  ListTile(
                    leading: Icon(Icons.tune_rounded, color: accentColor),
                    title: Text('Vibration Intensity', style: titleStyle),
                    subtitle: Text(
                      'Strength of touch feedback on mobile devices',
                      style: subtitleStyle,
                    ),
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<HapticIntensity>(
                        value: hapticState.intensity,
                        dropdownColor: context.appColors.surfaceColor,
                        alignment: Alignment.centerRight,
                        icon: Icon(Icons.arrow_drop_down, color: accentColor),
                        style: TextStyle(color: accentColor),
                        items: HapticIntensity.values.map((intensity) {
                          String label;
                          switch (intensity) {
                            case HapticIntensity.light:
                              label = 'Light';
                              break;
                            case HapticIntensity.medium:
                              label = 'Medium';
                              break;
                            case HapticIntensity.heavy:
                              label = 'Heavy';
                              break;
                          }
                          return DropdownMenuItem(
                            value: intensity,
                            child: Text(
                              label,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(hapticSettingsProvider.notifier).setIntensity(val);
                            ref.read(hapticSettingsProvider.notifier).trigger(val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),

      ],
    );
  }
}
