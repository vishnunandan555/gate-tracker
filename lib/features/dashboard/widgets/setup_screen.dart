import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme_context_ext.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../database/app_database.dart';
import '../../../database/syllabus_preset.dart';
import 'package:gateletics/providers/providers.dart';
import 'setup/setup_step_accent_color.dart';
import 'setup/setup_step_branch_selection.dart';
import 'setup/setup_step_daily_goal.dart';
import 'setup/setup_step_exam_date.dart';
import 'setup/setup_step_profile.dart';
import 'setup/setup_step_review.dart';
import 'setup/setup_step_rollover.dart';
import 'setup/setup_step_tracking.dart';
import 'shell_common.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  int _currentStep = 1;
  bool _isLoading = false;

  String _displayName = "";
  int _dailyGoalMins = 180;
  late DateTime _targetDate;
  String _selectedBranch = "CS";
  bool _usePreset = true;
  StudyDayRollover _studyDayRollover = StudyDayRollover.overnight;

  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();

    final now = DateTime.now();
    _targetDate = now.month >= 2 ? DateTime(now.year + 1, 2, 1) : DateTime(now.year, 2, 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForCloudBackup();
      final initialName = ref.read(displayNameProvider);
      if (initialName != null) {
        setState(() {
          _nameController.text = initialName;
          _displayName = initialName;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _checkForCloudBackup() async {
    final authState = ref.read(authProvider).value;
    if (authState?.user == null) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final forceOnboarding = prefs.getBool('force_onboarding') ?? false;

    setState(() => _isLoading = true);
    try {
      final needsAction = await ref.read(syncProvider.notifier).initializeSync();
      if (needsAction) {
        if (mounted) {
          showSyncConflictDialog(context, ref, ref.read(overallProgressColorProvider));
        }
      } else {
        final hasSetup = ref.read(setupCompletedProvider).value ?? false;
        if (hasSetup && !forceOnboarding && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Cloud data loaded successfully!', style: TextStyle(color: context.appColors.onAccent)),
              backgroundColor: context.appColors.primaryAccent,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error checking for cloud backup: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleFinishSetup() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final forceOnboarding = prefs.getBool('force_onboarding') ?? false;

    if (forceOnboarding && mounted) {
      final preserveHistory = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: context.appColors.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Preserve User Stats & History?',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.appColors.textPrimary, fontSize: 18),
          ),
          content: Text(
            'All previous user stats, study velocity logs, and completion history will be cleared unless preserved. Do you want to preserve your previous stats and history?',
            style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'No (Clear History)',
                style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontWeight: FontWeight.bold),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: ref.read(overallProgressColorProvider),
                foregroundColor: context.appColors.onAccent,
              ),
              child: Text(
                'Yes (Preserve)',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

      if (preserveHistory == false) {
        final db = ref.read(appDatabaseProvider);
        await db.delete(db.syllabusProgressLogs).go();
        await db.delete(db.dailyHistory).go();
        await db.delete(db.focusSessions).go();

        await ref.read(focusProvider.notifier).resetState();
        ref.invalidate(progressLogsProvider);
        ref.invalidate(dailyHistoryProvider);
        ref.invalidate(todayFocusSessionsProvider);
        ref.invalidate(todayFocusDurationProvider);
      }
    }

    setState(() => _isLoading = true);
    try {
      if (_displayName.trim().isNotEmpty) {
        await ref.read(profileProvider.notifier).setCustomDisplayName(_displayName.trim());
      }
      await ref.read(dailyFocusGoalProvider.notifier).setGoalMinutes(_dailyGoalMins);
      await ref.read(targetDateProvider.notifier).setDate(_targetDate);
      await ref.read(selectedBranchProvider.notifier).setSelectedBranch(_selectedBranch);
      await ref.read(studyDayRolloverProvider.notifier).setRollover(_studyDayRollover);

      if (_usePreset) {
        final presetList = branchPresets[_selectedBranch.toUpperCase()];
        await ref.read(syllabusControllerProvider.notifier).applyPreset(presetList);
      } else {
        await ref.read(syllabusControllerProvider.notifier).resetEverything();
      }

      final authState = ref.read(authProvider).value;
      if (authState?.user != null) {
        try {
          await ref.read(syncProvider.notifier).uploadLocalToCloud();
        } catch (_) {}
      }
      await ref.read(setupCompletedProvider.notifier).completeSetup();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing setup: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showTargetDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: context.appColors.primaryAccent,
              surface: context.appColors.surfaceColor,
              onSurface: context.appColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressColor = context.appColors.primaryAccent;

    return Scaffold(
      backgroundColor: context.appColors.scaffoldBackground,
      body: SafeArea(
        child: _isLoading
            ? Center(child: AppLoadingIndicator(color: progressColor))
            : Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildCurrentStepWidget(progressColor),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCurrentStepWidget(Color accentColor) {
    switch (_currentStep) {
      case 1:
        return SetupStepProfile(
          accentColor: accentColor,
          nameController: _nameController,
          displayName: _displayName,
          onNameChanged: (val) => setState(() => _displayName = val),
          onNext: () => setState(() => _currentStep = 2),
        );
      case 2:
        return SetupStepDailyGoal(
          accentColor: accentColor,
          dailyGoalMins: _dailyGoalMins,
          onGoalChanged: (val) => setState(() => _dailyGoalMins = val),
          onBack: () => setState(() => _currentStep = 1),
          onNext: () => setState(() => _currentStep = 3),
        );
      case 3:
        return SetupStepExamDate(
          accentColor: accentColor,
          targetDate: _targetDate,
          onPickDate: _showTargetDatePicker,
          onBack: () => setState(() => _currentStep = 2),
          onNext: () => setState(() => _currentStep = 4),
        );
      case 4:
        return SetupStepBranchSelection(
          accentColor: accentColor,
          selectedBranch: _selectedBranch,
          onBranchSelected: (branch, usePreset) {
            setState(() {
              _selectedBranch = branch;
              _usePreset = usePreset;
            });
          },
          onBack: () => setState(() => _currentStep = 3),
          onNext: () => setState(() => _currentStep = 5),
        );
      case 5:
        return SetupStepRollover(
          accentColor: accentColor,
          studyDayRollover: _studyDayRollover,
          onRolloverChanged: (val) => setState(() => _studyDayRollover = val),
          onBack: () => setState(() => _currentStep = 4),
          onNext: () => setState(() => _currentStep = _selectedBranch == "CUSTOM" ? 7 : 6),
        );
      case 6:
        return SetupStepTracking(
          accentColor: accentColor,
          selectedBranch: _selectedBranch,
          usePreset: _usePreset,
          onPresetChanged: (val) => setState(() => _usePreset = val),
          onBack: () => setState(() => _currentStep = 5),
          onNext: () => setState(() => _currentStep = 7),
        );
      case 7:
        return SetupStepAccentColor(
          accentColor: accentColor,
          selectedBranch: _selectedBranch,
          onBack: () => setState(() => _currentStep = _selectedBranch == "CUSTOM" ? 5 : 6),
          onNext: () => setState(() => _currentStep = 8),
        );
      case 8:
        return SetupStepReview(
          accentColor: accentColor,
          displayName: _displayName,
          selectedBranch: _selectedBranch,
          dailyGoalMins: _dailyGoalMins,
          targetDate: _targetDate,
          studyDayRollover: _studyDayRollover,
          usePreset: _usePreset,
          onFinish: _handleFinishSetup,
          onBack: () => setState(() => _currentStep = 7),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
