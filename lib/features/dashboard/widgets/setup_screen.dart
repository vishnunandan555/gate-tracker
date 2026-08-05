import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'shell_common.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/theme/models/accent_pool_model.dart';
import 'package:gateletics/providers/providers.dart';
import '../../../utils/ui_scaling.dart';
import '../../../database/syllabus_preset.dart';
import '../../../database/app_database.dart';
import 'settings/customization_settings.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  int _currentStep = 1;
  bool _isLoading = false;

  // Onboarding configuration state
  String _displayName = "";
  int _dailyGoalMins = 180; // Default 3 hours
  late DateTime _targetDate;
  String _selectedBranch = "CS";
  bool _usePreset = true;
  StudyDayRollover _studyDayRollover = StudyDayRollover.overnight;

  late TextEditingController _nameController;
  late TextEditingController _setupHexController;
  late FocusNode _setupHexFocusNode;
  bool? _isViewingDarkPool;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _setupHexController = TextEditingController();
    _setupHexFocusNode = FocusNode();

    // Default target date to next February 1st dynamically
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
    _setupHexController.dispose();
    _setupHexFocusNode.dispose();
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
          _showSyncConflictDialog();
        }
      } else {
        final hasSetup = ref.read(setupCompletedProvider).value ?? false;
        if (hasSetup && !forceOnboarding) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Cloud data loaded successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
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

  void _showSyncConflictDialog() {
    final accentColor = ref.read(overallProgressColorProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.dialogBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Sync Conflict Detected",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.appColors.textPrimary, fontSize: 18),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Both your local device and cloud backup contain study tracking progress. How would you like to resolve this conflict?",
                style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final localData = await ref.read(syncProvider.notifier).exportLocalData();
                  final cloudData = ref.read(syncProvider).pendingCloudData;
                  if (cloudData != null && ctx.mounted) {
                    showConflictDetailsDialog(ctx, localData, cloudData, accentColor);
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: accentColor.withValues(alpha: 0.4)),
                  foregroundColor: accentColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.compare_arrows_rounded, size: 16),
                label: Text(
                  "Compare Data (View Conflicts)",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              const SizedBox(height: 16),
              _buildDialogOption(
                title: "Merge Progress (Recommended)",
                subtitle: "Combine local and cloud progress (no data lost)",
                icon: Icons.merge_type_rounded,
                color: context.appColors.primaryAccent,
                onTap: () async {
                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);
                  try {
                    await ref.read(syncProvider.notifier).mergeCloudAndLocal();
                    await ref.read(setupCompletedProvider.notifier).completeSetup();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Cloud data merged successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Merge failed: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildDialogOption(
                title: "Use Cloud Backup",
                subtitle: "Overwrite local data with your cloud backup",
                icon: Icons.cloud_download_rounded,
                color: context.appColors.primaryAccent,
                onTap: () async {
                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);
                  try {
                    await ref.read(syncProvider.notifier).downloadCloudToLocal();
                    await ref.read(setupCompletedProvider.notifier).completeSetup();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Cloud data loaded successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Restore failed: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildDialogOption(
                title: "Keep Local Progress",
                subtitle: "Overwrite cloud data with your local progress",
                icon: Icons.cloud_upload_rounded,
                color: context.appColors.primaryAccent,
                onTap: () async {
                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);
                  try {
                    await ref.read(syncProvider.notifier).uploadLocalToCloud();
                    await ref.read(setupCompletedProvider.notifier).completeSetup();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Local progress kept and uploaded successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Upload failed: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: context.appColors.borderColor),
          borderRadius: BorderRadius.circular(16),
          color: context.appColors.surfaceColor,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
      // 1. Save Profile Display Name
      if (_displayName.trim().isNotEmpty) {
        await ref.read(profileProvider.notifier).setCustomDisplayName(_displayName.trim());
      }

      // 2. Save Daily Focus Goal
      await ref.read(dailyFocusGoalProvider.notifier).setGoalMinutes(_dailyGoalMins);

      // 3. Save Target Exam Date
      await ref.read(targetDateProvider.notifier).setDate(_targetDate);

      // 4. Save Selected Branch
      await ref.read(selectedBranchProvider.notifier).setSelectedBranch(_selectedBranch);

      // Save Day Rollover
      await ref.read(studyDayRolloverProvider.notifier).setRollover(_studyDayRollover);

      // 5. Seed Syllabus or Reset
      if (_usePreset) {
        final presetList = branchPresets[_selectedBranch.toUpperCase()];
        await ref.read(syllabusControllerProvider.notifier).applyPreset(presetList);
      } else {
        await ref.read(syllabusControllerProvider.notifier).resetEverything();
      }

      // 6. Push initial local backup to cloud if logged in
      final authState = ref.read(authProvider).value;
      if (authState?.user != null) {
        try {
          await ref.read(syncProvider.notifier).uploadLocalToCloud();
        } catch (e) {
          debugPrint("Failed to upload initial data to cloud: $e");
        }
      }

      // 7. Complete Setup flag
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

  @override
  Widget build(BuildContext context) {
    final progressColor = context.appColors.primaryAccent;

    return Scaffold(
      backgroundColor: context.appColors.scaffoldBackground,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: progressColor),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final screenHeight = MediaQuery.sizeOf(context).height;
                  final heightScale = (screenHeight / 800.0).clamp(0.65, 1.25);

                  return Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.05, 0.0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: _buildCurrentStepWidget(progressColor, heightScale),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildCurrentStepWidget(Color accentColor, double heightScale) {
    switch (_currentStep) {
      case 1:
        return _buildStepProfile(accentColor);
      case 2:
        return _buildStepDailyGoal(accentColor);
      case 3:
        return _buildStepExamDate(accentColor);
      case 4:
        return _buildStepBranchSelection(accentColor);
      case 5:
        return _buildStepRollover(accentColor);
      case 6:
        return _buildStepTrackingOption(accentColor);
      case 7:
        return _buildStepAccentColor(accentColor);
      case 8:
        return _buildStepReview(accentColor);
      default:
        return _buildStepProfile(accentColor);
    }
  }

  // --- Step 1: Profile Customization ---
  Widget _buildStepProfile(Color accentColor) {
    final profileImage = ref.watch(displayProfileImageProvider);

    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "WELCOME TO GATELETICS",
          style: GoogleFonts.jersey15(
            fontSize: context.s(24),
            fontWeight: FontWeight.bold,
            color: context.appColors.textPrimary,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "Let's personalize your exam preparation dashboard.",
          style: GoogleFonts.outfit(
            fontSize: context.s(13),
            color: context.appColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Center(
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accentColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ],
              image: profileImage != null
                  ? DecorationImage(image: profileImage, fit: BoxFit.cover)
                  : null,
            ),
            child: profileImage == null
                ? Icon(Icons.person_rounded, size: 48, color: context.appColors.textSecondary)
                : null,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          "YOUR DISPLAY NAME",
          style: GoogleFonts.orbitron(
            fontSize: context.s(10),
            fontWeight: FontWeight.bold,
            color: context.appColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          onChanged: (val) => setState(() => _displayName = val),
          style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: "Enter your name",
            hintStyle: GoogleFonts.outfit(color: context.appColors.textMuted),
            filled: true,
            fillColor: context.appColors.cardBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.appColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.appColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 48),
        _buildNavigationRow(
          accentColor: accentColor,
          onNext: _displayName.trim().isNotEmpty
              ? () => setState(() => _currentStep = 2)
              : null,
          nextLabel: "CONTINUE",
        ),
      ],
    );
  }

  // --- Step 2: Daily Study Goal ---
  Widget _buildStepDailyGoal(Color accentColor) {
    final hourOptions = [120, 180, 240];

    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "DAILY STUDY TARGET",
          style: GoogleFonts.jersey15(
            fontSize: context.s(24),
            fontWeight: FontWeight.bold,
            color: context.appColors.textPrimary,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "How many hours do you plan to dedicate to focus studying each day?",
          style: GoogleFonts.outfit(
            fontSize: context.s(13),
            color: context.appColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Center(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "${(_dailyGoalMins / 60).toStringAsFixed(_dailyGoalMins % 60 == 0 ? 0 : 1)} ",
                  style: GoogleFonts.jersey15(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                TextSpan(
                  text: _dailyGoalMins == 60 ? "HOUR" : "HOURS",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: context.appColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: hourOptions.map((mins) {
            final isSelected = _dailyGoalMins == mins;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _dailyGoalMins = mins),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor.withValues(alpha: 0.1) : context.appColors.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? accentColor : context.appColors.borderColor,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Text(
                    "${mins ~/ 60} Hrs",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: isSelected ? context.appColors.textPrimary : context.appColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        Text(
          "CUSTOM DURATION",
          style: GoogleFonts.orbitron(
            fontSize: context.s(10),
            fontWeight: FontWeight.bold,
            color: context.appColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accentColor,
            inactiveTrackColor: context.appColors.borderColor,
            thumbColor: context.appColors.textPrimary,
            overlayColor: accentColor.withValues(alpha: 0.2),
            valueIndicatorColor: accentColor,
            valueIndicatorTextStyle: TextStyle(color: context.appColors.onAccent, fontWeight: FontWeight.bold),
          ),
          child: Slider(
            value: _dailyGoalMins.toDouble(),
            min: 30.0,
            max: 720.0,
            divisions: 46, // 15 mins steps
            label: "${(_dailyGoalMins / 60).toStringAsFixed(_dailyGoalMins % 60 == 0 ? 0 : 1)} Hrs",
            onChanged: (val) {
              setState(() {
                _dailyGoalMins = val.round();
              });
            },
          ),
        ),
        const SizedBox(height: 48),
        _buildNavigationRow(
          accentColor: accentColor,
          onBack: () => setState(() => _currentStep = 1),
          onNext: () => setState(() => _currentStep = 3),
        ),
      ],
    );
  }

  // --- Step 3: Exam Target Date ---
  Widget _buildStepExamDate(Color accentColor) {
    final remainingDays = _targetDate.difference(DateTime.now()).inDays;
    final displayDays = remainingDays > 0 ? remainingDays : 0;

    final formattedDate = "${_getMonthName(_targetDate.month)} ${_targetDate.day}, ${_targetDate.year}";

    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "TARGET EXAM DATE",
          style: GoogleFonts.jersey15(
            fontSize: context.s(24),
            fontWeight: FontWeight.bold,
            color: context.appColors.textPrimary,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "Configure when you will sit for the GATE exam. A live countdown will show on your home screen.",
          style: GoogleFonts.outfit(
            fontSize: context.s(13),
            color: context.appColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Center(
          child: Column(
            children: [
              Text(
                formattedDate,
                style: GoogleFonts.orbitron(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: context.appColors.textPrimary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  "$displayDays DAYS REMAINING",
                  style: GoogleFonts.jersey15(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        ElevatedButton.icon(
          onPressed: _showTargetDatePicker,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.appColors.cardBackground,
            foregroundColor: context.appColors.textPrimary,
            side: BorderSide(color: context.appColors.borderColor),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: Icon(Icons.calendar_month_rounded, color: accentColor),
          label: Text(
            "CHANGE TARGET DATE",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        const SizedBox(height: 48),
        _buildNavigationRow(
          accentColor: accentColor,
          onBack: () => setState(() => _currentStep = 2),
          onNext: () => setState(() => _currentStep = 4),
        ),
      ],
    );
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
      setState(() {
        _targetDate = picked;
      });
    }
  }

  String _getMonthName(int month) {
    const months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return months[month - 1];
  }

  // --- Step 4: Branch Selection ---
  Widget _buildStepBranchSelection(Color accentColor) {
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
        Text(
          "CHOOSE YOUR BRANCH",
          style: GoogleFonts.jersey15(
            fontSize: context.s(24),
            fontWeight: FontWeight.bold,
            color: context.appColors.textPrimary,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "Select the engineering branch you are preparing for to configure your syllabus presets.",
          style: GoogleFonts.outfit(
            fontSize: context.s(13),
            color: context.appColors.textSecondary,
          ),
          textAlign: TextAlign.center,
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
            final isSelected = _selectedBranch == id;

            return GestureDetector(
              onTap: () {
                ref.read(hapticSettingsProvider.notifier).selectionClick();
                setState(() {
                  _selectedBranch = id;
                  _usePreset = id != "CUSTOM";
                });
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
        const SizedBox(height: 32),
        _buildNavigationRow(
          accentColor: accentColor,
          onBack: () => setState(() => _currentStep = 3),
          onNext: () {
            setState(() {
              _currentStep = 5;
            });
          },
        ),
      ],
    );
  }

  // --- Step 5: Day Rollover Hour ---
  Widget _buildStepRollover(Color accentColor) {
    return Column(
      key: const ValueKey(5),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "STUDY DAY ROLLOVER",
          style: GoogleFonts.jersey15(
            fontSize: context.s(24),
            fontWeight: FontWeight.bold,
            color: context.appColors.textPrimary,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "Select when your daily study tracking transitions to the next day to match your biological clock.",
          style: GoogleFonts.outfit(
            fontSize: context.s(13),
            color: context.appColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _buildRolloverOptionCard(
          title: "Late Night (04:00 AM) - Default",
          description: "Ideal for night owls. If you study past midnight (up to 4 AM), your progress continues to count towards the current day's streak.",
          icon: Icons.nights_stay_rounded,
          accentColor: accentColor,
          isSelected: _studyDayRollover == StudyDayRollover.overnight,
          onTap: () => setState(() => _studyDayRollover = StudyDayRollover.overnight),
        ),
        const SizedBox(height: 16),
        _buildRolloverOptionCard(
          title: "Midnight (12:00 AM)",
          description: "Ideal for early birds. Your study day resets strictly at midnight. Early morning study counts immediately towards the new day.",
          icon: Icons.wb_sunny_rounded,
          accentColor: accentColor,
          isSelected: _studyDayRollover == StudyDayRollover.midnight,
          onTap: () => setState(() => _studyDayRollover = StudyDayRollover.midnight),
        ),
        const SizedBox(height: 48),
        _buildNavigationRow(
          accentColor: accentColor,
          onBack: () => setState(() => _currentStep = 4),
          onNext: () {
            if (_selectedBranch == "CUSTOM") {
              setState(() => _currentStep = 7);
            } else {
              setState(() => _currentStep = 6);
            }
          },
        ),
      ],
    );
  }

  Widget _buildRolloverOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.08) : context.appColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : context.appColors.borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? accentColor.withValues(alpha: 0.15) : context.appColors.surfaceColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isSelected ? accentColor : context.appColors.textSecondary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: context.appColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.outfit(
                      color: context.appColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 6: Tracking Slate Preset vs Scratch ---
  Widget _buildStepTrackingOption(Color accentColor) {
    return Column(
      key: const ValueKey(6),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "INITIAL CHECKLIST STATE",
          style: GoogleFonts.jersey15(
            fontSize: context.s(24),
            fontWeight: FontWeight.bold,
            color: context.appColors.textPrimary,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "Do you want to initialize with a preloaded syllabus preset or start with a clean slate?",
          style: GoogleFonts.outfit(
            fontSize: context.s(13),
            color: context.appColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () => setState(() => _usePreset = true),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _usePreset ? accentColor.withValues(alpha: 0.08) : context.appColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _usePreset ? accentColor : context.appColors.borderColor,
                width: _usePreset ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _usePreset ? accentColor.withValues(alpha: 0.15) : context.appColors.surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.auto_awesome_rounded, color: _usePreset ? accentColor : context.appColors.textSecondary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Load Curated Presets",
                        style: GoogleFonts.outfit(
                          color: context.appColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Autofills categories, topics, and tasks derived from the official syllabus for branch $_selectedBranch.",
                        style: GoogleFonts.outfit(
                          color: context.appColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => setState(() => _usePreset = false),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: !_usePreset ? context.appColors.primaryAccent.withValues(alpha: 0.08) : context.appColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: !_usePreset ? context.appColors.primaryAccent : context.appColors.borderColor,
                width: !_usePreset ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: !_usePreset ? context.appColors.primaryAccent.withValues(alpha: 0.15) : context.appColors.surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.dashboard_customize_rounded, color: !_usePreset ? context.appColors.primaryAccent : context.appColors.textSecondary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Start Empty (Custom)",
                        style: GoogleFonts.outfit(
                          color: context.appColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Starts with zero categories. You must add categories, subjects, and trackers manually.",
                        style: GoogleFonts.outfit(
                          color: context.appColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildNavigationRow(
          accentColor: accentColor,
          onBack: () => setState(() => _currentStep = 5),
          onNext: () => setState(() => _currentStep = 7),
        ),
      ],
    );
  }

  // --- Step 7: Accent Color & UI Customization ---
  Widget _buildStepAccentColor(Color accentColor) {
    final colorNotifier = ref.watch(overallProgressColorProvider.notifier);
    final isAuto = colorNotifier.mode == 'auto';
    final isDevice = colorNotifier.mode == 'device';

    _isViewingDarkPool ??= !context.appColors.isLight;
    final activePool = _isViewingDarkPool! ? colorNotifier.darkPool : colorNotifier.lightPool;

    int r = (accentColor.r * 255).round().clamp(0, 255);
    int g = (accentColor.g * 255).round().clamp(0, 255);
    int b = (accentColor.b * 255).round().clamp(0, 255);

    final currentHex = AppAccentPools.toHexString(accentColor);
    if (_setupHexController.text != currentHex && !_setupHexFocusNode.hasFocus) {
      _setupHexController.text = currentHex;
    }

    return Column(
      key: const ValueKey(7),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "CHOOSE ACCENT THEME",
          style: GoogleFonts.jersey15(
            fontSize: context.s(24),
            fontWeight: FontWeight.bold,
            color: context.appColors.textPrimary,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "Personalize your app's accent color. Select auto-changing dynamic themes, pick a preset, or enter custom Hex code.",
          style: GoogleFonts.outfit(
            fontSize: context.s(13),
            color: context.appColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Live Preview Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.appColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.12),
                blurRadius: 16,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "LIVE UI PREVIEW",
                    style: GoogleFonts.orbitron(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isAuto ? "AUTO DYNAMIC" : "#${currentHex.toUpperCase()}",
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Sample Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: 0.68,
                  minHeight: 8,
                  backgroundColor: context.appColors.borderColor,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department_rounded, color: accentColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "STREAK: 14 DAYS",
                          style: GoogleFonts.jersey15(color: accentColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "Sample Action",
                        style: GoogleFonts.outfit(
                          color: context.appColors.onAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Auto-change option
        GestureDetector(
          onTap: () => colorNotifier.setAutoMode(),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isAuto ? accentColor.withValues(alpha: 0.08) : context.appColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isAuto ? accentColor : context.appColors.borderColor,
                width: isAuto ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.brightness_auto_rounded, color: isAuto ? accentColor : context.appColors.textSecondary, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Auto-Change Color",
                            style: GoogleFonts.outfit(
                              color: context.appColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "RECOMMENDED",
                              style: GoogleFonts.orbitron(color: accentColor, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Automatically shifts accent colors every session for a fresh visual look.",
                        style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (isAuto) Icon(Icons.check_circle_rounded, color: accentColor, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── Accent Presets Section with Light / Dark Pool Switcher ──────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "PRESET ACCENT POOL",
              style: GoogleFonts.orbitron(
                fontSize: context.s(10),
                fontWeight: FontWeight.bold,
                color: context.appColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text('Dark', style: GoogleFonts.outfit(fontSize: 10, color: context.appColors.textPrimary))),
                ButtonSegment(value: false, label: Text('Light', style: GoogleFonts.outfit(fontSize: 10, color: context.appColors.textPrimary))),
              ],
              selected: {_isViewingDarkPool!},
              onSelectionChanged: (val) {
                setState(() {
                  _isViewingDarkPool = val.first;
                });
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return context.appColors.surfaceColor;
                  }
                  return Colors.transparent;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "Pick a curated accent color from the theme pool.",
          style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: activePool.map((presetColor) {
            final isSelected = !isAuto && !isDevice && colorNotifier.frozenColor?.toARGB32() == presetColor.toARGB32();
            return GestureDetector(
              onTap: () => colorNotifier.setFrozenColor(presetColor),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: presetColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? context.appColors.textPrimary : context.appColors.borderColor,
                    width: isSelected ? 2.5 : 1.2,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: presetColor.withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: isSelected
                    ? Icon(Icons.check_rounded, color: context.appColors.onAccent, size: 18)
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // ── Custom Hex & RGB Color Picker ──────────────────────────────
        Text(
          "CUSTOM ACCENT PICKER",
          style: GoogleFonts.orbitron(
            fontSize: context.s(10),
            fontWeight: FontWeight.bold,
            color: context.appColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Fine-tune exact Hex (#) code or Red, Green, Blue sliders.",
          style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 12),

        // Hex Code TextField Row with Live Color Preview Circle
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
                border: Border.all(color: context.appColors.borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                controller: _setupHexController,
                focusNode: _setupHexFocusNode,
                style: GoogleFonts.orbitron(
                  color: context.appColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: context.appColors.cardBackground,
                  labelText: 'Hex Code',
                  labelStyle: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 12),
                  prefixText: '# ',
                  prefixStyle: GoogleFonts.orbitron(color: context.appColors.textSecondary, fontSize: 13),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.appColors.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accentColor, width: 1.5),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (val) {
                  final parsed = AppAccentPools.parseHexColor(val);
                  if (parsed != null) {
                    colorNotifier.setFrozenColor(parsed);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Custom RGB Sliders
        _buildRgbSlider("R", r, Colors.redAccent, (val) {
          final newColor = Color.fromARGB(255, val.round(), g, b);
          colorNotifier.setFrozenColor(newColor);
        }),
        _buildRgbSlider("G", g, Colors.greenAccent, (val) {
          final newColor = Color.fromARGB(255, r, val.round(), b);
          colorNotifier.setFrozenColor(newColor);
        }),
        _buildRgbSlider("B", b, Colors.blueAccent, (val) {
          final newColor = Color.fromARGB(255, r, g, val.round());
          colorNotifier.setFrozenColor(newColor);
        }),
        const SizedBox(height: 12),

        // Button to open Full Color Picker Dialog popup
        OutlinedButton.icon(
          onPressed: () => showAccentColorDialog(context, ref),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: context.appColors.borderColor),
            foregroundColor: context.appColors.textPrimary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: Icon(Icons.color_lens_rounded, size: 18, color: accentColor),
          label: Text(
            "OPEN COLOR PICKER DIALOG",
            style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
        ),

        const SizedBox(height: 32),
        _buildNavigationRow(
          accentColor: accentColor,
          onBack: () => setState(() => _currentStep = _selectedBranch == "CUSTOM" ? 5 : 6),
          onNext: () => setState(() => _currentStep = 8),
        ),
      ],
    );
  }

  Widget _buildRgbSlider(String label, int value, Color activeColor, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          child: Text(
            label,
            style: GoogleFonts.orbitron(color: activeColor, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: activeColor,
              inactiveTrackColor: context.appColors.borderColor,
              thumbColor: context.appColors.textPrimary,
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 255,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            "$value",
            textAlign: TextAlign.end,
            style: GoogleFonts.orbitron(color: context.appColors.textSecondary, fontSize: 11),
          ),
        ),
      ],
    );
  }

  // --- Step 8: Review & Finalize Summary ---
  Widget _buildStepReview(Color accentColor) {
    final remainingDays = _targetDate.difference(DateTime.now()).inDays;
    final displayDays = remainingDays > 0 ? remainingDays : 0;
    final formattedDate = "${_getMonthName(_targetDate.month)} ${_targetDate.day}, ${_targetDate.year}";
    final colorNotifier = ref.watch(overallProgressColorProvider.notifier);

    return Column(
      key: const ValueKey(8),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "YOU'RE READY!",
          style: GoogleFonts.jersey15(
            fontSize: context.s(26),
            fontWeight: FontWeight.bold,
            color: context.appColors.textPrimary,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "Confirm your settings below before launching the exam tracker.",
          style: GoogleFonts.outfit(
            fontSize: context.s(13),
            color: context.appColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.appColors.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.appColors.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSummaryItem("Profile Name", _displayName, Icons.person_rounded, accentColor),
              Divider(color: context.appColors.dividerColor, height: 24),
              _buildSummaryItem("GATE Branch", _selectedBranch == "CUSTOM" ? "Custom / None" : _selectedBranch, Icons.school_rounded, accentColor),
              Divider(color: context.appColors.dividerColor, height: 24),
              _buildSummaryItem("Daily Goal", "${(_dailyGoalMins / 60).toStringAsFixed(_dailyGoalMins % 60 == 0 ? 0 : 1)} Hours", Icons.timer_rounded, accentColor),
              Divider(color: context.appColors.dividerColor, height: 24),
              _buildSummaryItem("Exam Date", "$formattedDate ($displayDays days left)", Icons.calendar_month_rounded, accentColor),
              Divider(color: context.appColors.dividerColor, height: 24),
              _buildSummaryItem("Day Rollover", _studyDayRollover == StudyDayRollover.overnight ? "Late Night (04:00 AM)" : "Midnight (12:00 AM)", Icons.alarm_rounded, accentColor),
              Divider(color: context.appColors.dividerColor, height: 24),
              _buildSummaryItem("Syllabus Setup", _usePreset ? "$_selectedBranch Preset Loaded" : "Empty (Custom)", Icons.auto_awesome_rounded, accentColor),
              Divider(color: context.appColors.dividerColor, height: 24),
              _buildSummaryItem("Accent Theme", colorNotifier.mode == 'auto' ? "Dynamic Auto-change" : "Custom Accent (#${accentColor.toARGB32().toRadixString(16).substring(2).toUpperCase()})", Icons.palette_rounded, accentColor),
            ],
          ),
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: _handleFinishSetup,
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: context.appColors.onAccent,
            shadowColor: accentColor.withValues(alpha: 0.4),
            elevation: 12,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            "FINALIZE AND LOAD",
            style: GoogleFonts.orbitron(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _currentStep = 7),
          child: Text(
            "GO BACK",
            style: GoogleFonts.outfit(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color accentColor) {
    return Row(
      children: [
        Icon(icon, color: accentColor.withValues(alpha: 0.7), size: 20),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: GoogleFonts.orbitron(color: context.appColors.textMuted, fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  // Navigation rows helpers
  Widget _buildNavigationRow({
    required Color accentColor,
    VoidCallback? onBack,
    VoidCallback? onNext,
    String nextLabel = "NEXT",
  }) {
    final prefs = ref.read(sharedPreferencesProvider);
    final isReOnboarding = prefs.getBool('force_onboarding') ?? false;

    if (onBack == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: context.appColors.onAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                nextLabel,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          if (isReOnboarding) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () async {
                // Strict Safety Check: Verify force_onboarding is true before allowing exit
                final currentForce = prefs.getBool('force_onboarding') ?? false;
                if (!currentForce) return;

                ref.read(hapticSettingsProvider.notifier).selectionClick();

                // Restore setup state and clear force_onboarding flag
                await prefs.setBool('has_completed_setup', true);
                await prefs.setBool('force_onboarding', false);
                await ref.read(setupCompletedProvider.notifier).completeSetup();
              },
              icon: Icon(
                Icons.arrow_back_rounded,
                size: 14,
                color: context.appColors.textMuted,
              ),
              label: Text(
                "CANCEL & RETURN TO DASHBOARD",
                style: GoogleFonts.outfit(
                  color: context.appColors.textMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: accentColor.withValues(alpha: 0.4), width: 1.5),
              foregroundColor: accentColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              "BACK",
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: context.appColors.onAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              nextLabel,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
