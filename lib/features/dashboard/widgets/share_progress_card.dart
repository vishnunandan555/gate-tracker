import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

import '../../../../core/config/brand_config.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/profile_provider.dart';
import '../../../../providers/selected_branch_provider.dart';
import '../../../../providers/completion_provider.dart';
import '../../../../providers/daily_history_provider.dart';
import '../../../../providers/focus_provider.dart';
import '../../../../utils/ui_scaling.dart';
import 'package:share_plus/share_plus.dart';

class ShareProgressCard extends ConsumerStatefulWidget {
  final Color accentColor;

  const ShareProgressCard({
    super.key,
    required this.accentColor,
  });

  @override
  ConsumerState<ShareProgressCard> createState() => _ShareProgressCardState();
}

class _ShareProgressCardState extends ConsumerState<ShareProgressCard> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isSaving = false;
  bool _isSharing = false;

  bool _isYesterday = false;
  bool _showAccomplishments = true;
  bool _showProfilePhoto = true;
  bool _showName = true;

  Widget _buildDaySegmentChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final accent = widget.accentColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.black : Colors.white54,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? Colors.black : Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleChip({
    required IconData icon,
    required String label,
    required bool value,
    required VoidCallback onTap,
  }) {
    final accent = widget.accentColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: value ? accent.withAlpha(40) : Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value ? accent.withAlpha(120) : Colors.white10,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: value ? accent : Colors.white54,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: value ? Colors.white : Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureAndShare() async {
    final targetPixelRatio = View.of(context).devicePixelRatio.clamp(2.0, 3.5);
    setState(() => _isSharing = true);
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception("Failed to get render boundary");

      final image = await boundary.toImage(pixelRatio: targetPixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception("Failed to convert image to bytes");

      final pngBytes = byteData.buffer.asUint8List();
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final defaultFileName = "gateletics_progress_$dateStr.png";

      if (kIsWeb) {
        final file = XFile.fromData(
          pngBytes,
          mimeType: 'image/png',
          name: defaultFileName,
        );
        await SharePlus.instance.share(
          ShareParams(
            files: [file],
            text: _isYesterday ? 'My study progress from yesterday on GATEletics! 🚀' : 'My progress today on GATEletics! 🚀',
          ),
        );
      } else {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$defaultFileName');
        await tempFile.writeAsBytes(pngBytes);

        final xFile = XFile(tempFile.path);
        await SharePlus.instance.share(
          ShareParams(
            files: [xFile],
            text: _isYesterday ? 'My study progress from yesterday on GATEletics! 🚀' : 'My progress today on GATEletics! 🚀',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✗ Failed to share: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _captureAndSave() async {
    final targetPixelRatio = View.of(context).devicePixelRatio.clamp(2.0, 3.5);
    setState(() => _isSaving = true);
    try {
      // Allow widget to render fully
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception("Failed to get render boundary");

      final image = await boundary.toImage(pixelRatio: targetPixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception("Failed to convert image to bytes");

      final pngBytes = byteData.buffer.asUint8List();
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final defaultFileName = "gateletics_progress_$dateStr.png";

      String? savedPath;

      if (kIsWeb) {
        savedPath = await FilePicker.saveFile(
          dialogTitle: 'Save Progress Card',
          fileName: defaultFileName,
          bytes: pngBytes,
          type: FileType.image,
        );
      } else if (defaultTargetPlatform == TargetPlatform.android ||
                 defaultTargetPlatform == TargetPlatform.iOS) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$defaultFileName');
        await tempFile.writeAsBytes(pngBytes);

        final params = SaveFileDialogParams(
          sourceFilePath: tempFile.path,
          fileName: defaultFileName,
        );
        savedPath = await FlutterFileDialog.saveFile(params: params);
      } else {
        // Desktop (Windows/Linux)
        savedPath = await FilePicker.saveFile(
          dialogTitle: 'Save Progress Card',
          fileName: defaultFileName,
          bytes: pngBytes,
          type: FileType.image,
        );
        if (savedPath != null) {
          final file = File(savedPath);
          await file.writeAsBytes(pngBytes);
        }
      }

      if (savedPath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Progress Card saved successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✗ Failed to save: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  List<String> _getTodayAccomplishments(List<FocusSession> sessions) {
    final list = <String>[];
    for (final s in sessions) {
      final acc = s.accomplishments;
      if (acc == null || acc.trim().isEmpty) continue;
      if (acc.trim().startsWith('[')) {
        try {
          final decoded = jsonDecode(acc) as List<dynamic>;
          for (final cat in decoded) {
            final catName = cat['categoryName'] as String? ?? 'Category';
            final topics = cat['topics'] as List<dynamic>? ?? [];
            for (final topic in topics) {
              final topicName = topic['topicName'] as String? ?? 'Topic';
              if (topic['isCounter'] == true) {
                final current = topic['currentCount'] as int? ?? 0;
                final initial = topic['initialCount'] as int? ?? 0;
                final diff = current - initial;
                list.add('$catName > $topicName (+$diff)');
              } else {
                final tasks = topic['tasks'] as List<dynamic>? ?? [];
                for (final t in tasks) {
                  list.add('$catName > $topicName > $t');
                }
              }
            }
          }
        } catch (_) {}
      } else {
        // Fallback for legacy text accomplishments
        final lines = acc.split('\n');
        String currentCatTopic = '';
        for (final line in lines) {
          if (line.contains('>')) {
            currentCatTopic = line.replaceAll(':', '').trim();
          } else if (line.trim().startsWith('-')) {
            final taskName = line.replaceFirst('-', '').trim();
            if (currentCatTopic.isNotEmpty) {
              list.add('$currentCatTopic > $taskName');
            } else {
              list.add(taskName);
            }
          }
        }
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final displayName = ref.watch(displayNameProvider);
    final branch = ref.watch(selectedBranchProvider);
    final stats = ref.watch(completionStatsProvider).value;
    final streak = ref.watch(currentStreakProvider);
    final profileImage = ref.watch(displayProfileImageProvider);

    final activeFocusSecondsAsync = ref.watch(_isYesterday ? yesterdayFocusDurationProvider : todayFocusDurationProvider);
    final activeFocusSeconds = activeFocusSecondsAsync.value ?? 0;
    final dailyGoalMins = ref.watch(dailyFocusGoalProvider);

    final activeSessionsAsync = ref.watch(_isYesterday ? yesterdayFocusSessionsProvider : todayFocusSessionsProvider);
    final activeSessions = activeSessionsAsync.value ?? [];
    final activeProgressDelta = activeSessions.fold<double>(0.0, (sum, s) => sum + s.progressDelta);

    final now = DateTime.now();
    final cardDate = _isYesterday ? now.subtract(const Duration(days: 1)) : now;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = "${months[cardDate.month - 1]} ${cardDate.day}, ${cardDate.year}";

    final totalMin = (activeFocusSeconds / 60).floor();
    final hrStr = (totalMin / 60).floor().toString();
    final minStr = (totalMin % 60).toString();
    final timeStudiedStr = totalMin >= 60 ? "${hrStr}h ${minStr}m" : "$totalMin min";
    final goalStr = "${(dailyGoalMins / 60).toStringAsFixed(1).replaceAll('.0', '')}h";
    final targetGoalSeconds = dailyGoalMins * 60;
    final goalRatio = targetGoalSeconds > 0 ? (activeFocusSeconds / targetGoalSeconds).clamp(0.0, 1.0) : 0.0;

    // Avatar shown only when Name is ON.
    // Photo toggle controls *what* shows inside: real image (ON) or first letter (OFF).
    // Name OFF → entire avatar hidden, regardless of Photo toggle.
    final showHeaderPhoto = _showName;
    final headerTitle = _showName
        ? (displayName != null && displayName.isNotEmpty ? displayName : "GATE Aspirant")
        : (_isYesterday ? "Yesterday's Stats" : "Today's Stats");

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: context.s(16), vertical: context.s(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Day Selector Segment (Today vs Yesterday)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDaySegmentChip(
                  label: "Today",
                  icon: Icons.today_rounded,
                  isSelected: !_isYesterday,
                  onTap: () => setState(() => _isYesterday = false),
                ),
                _buildDaySegmentChip(
                  label: "Yesterday",
                  icon: Icons.history_rounded,
                  isSelected: _isYesterday,
                  onTap: () => setState(() => _isYesterday = true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Toggle Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildToggleChip(
                icon: _showAccomplishments ? Icons.task_alt_rounded : Icons.check_box_outline_blank_rounded,
                label: "Tasks",
                value: _showAccomplishments,
                onTap: () => setState(() => _showAccomplishments = !_showAccomplishments),
              ),
              _buildToggleChip(
                icon: _showProfilePhoto ? Icons.face_rounded : Icons.face_retouching_off_rounded,
                label: "Photo",
                value: _showProfilePhoto,
                onTap: () => setState(() => _showProfilePhoto = !_showProfilePhoto),
              ),
              _buildToggleChip(
                icon: _showName ? Icons.badge_rounded : Icons.no_accounts_rounded,
                label: "Name",
                value: _showName,
                onTap: () => setState(() => _showName = !_showName),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // RepaintBoundary containing the actual Story Card (360 x 640 Aspect Ratio layout)
          RepaintBoundary(
            key: _repaintKey,
            child: Container(
              width: 360,
              height: _showAccomplishments ? 640.0 : null,
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: widget.accentColor.withAlpha(80), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: widget.accentColor.withAlpha(20),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Subtle Radial Glow background
                  Positioned(
                    top: -100,
                    left: -100,
                    width: 300,
                    height: 300,
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.accentColor.withAlpha(15),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -100,
                    right: -100,
                    width: 300,
                    height: 300,
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.accentColor.withAlpha(10),
                        ),
                      ),
                    ),
                  ),

                  // Content Layout
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // App logo & Name
                        Row(
                          children: [
                            Image.asset(
                              'assets/logo_trans_cropped.png',
                              width: 22,
                              height: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              BrandConfig.appName.toUpperCase(),
                              style: GoogleFonts.orbitron(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              dateStr,
                              style: GoogleFonts.outfit(
                                color: Colors.white38,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Greeting / Profile Header
                        Row(
                          children: [
                            if (showHeaderPhoto) ...[
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: widget.accentColor.withAlpha(40),
                                // Photo toggle ON + real image available → show image
                                backgroundImage: (_showProfilePhoto && profileImage != null)
                                    ? profileImage
                                    : null,
                                child: (_showProfilePhoto && profileImage != null)
                                    // Image is shown via backgroundImage; no text child needed
                                    ? null
                                    // Photo OFF (or no image) + Name ON → first letter
                                    : (_showName && displayName != null && displayName.isNotEmpty)
                                        ? Text(
                                            displayName[0].toUpperCase(),
                                            style: GoogleFonts.outfit(
                                              color: widget.accentColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          )
                                        : null,
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    headerTitle,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "GATE $branch",
                                    style: GoogleFonts.outfit(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: CustomPaint(
                                    painter: SquareProgressPainter(
                                      progress: (stats?.percentage ?? 0.0) / 100.0,
                                      color: widget.accentColor,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                ),
                                Text(
                                  "${(stats?.percentage ?? 0.0).toStringAsFixed(0)}%",
                                  style: GoogleFonts.orbitron(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                         // Stats Row
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             // 1. Time Studied vs Goal
                             Expanded(
                               child: Container(
                                 padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                                 decoration: BoxDecoration(
                                   color: Colors.white.withAlpha(5),
                                   borderRadius: BorderRadius.circular(12),
                                   border: Border.all(color: Colors.white10),
                                 ),
                                 child: Column(
                                   children: [
                                     FittedBox(
                                       fit: BoxFit.scaleDown,
                                       child: Text(
                                         "STUDY TIME",
                                         style: GoogleFonts.outfit(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                                       ),
                                     ),
                                     const SizedBox(height: 6),
                                     FittedBox(
                                       fit: BoxFit.scaleDown,
                                       child: Text(
                                         timeStudiedStr,
                                         style: GoogleFonts.orbitron(color: widget.accentColor, fontSize: 13, fontWeight: FontWeight.bold),
                                       ),
                                     ),
                                     const SizedBox(height: 4),
                                     FittedBox(
                                       fit: BoxFit.scaleDown,
                                       child: Text(
                                         "Goal: $goalStr",
                                         style: GoogleFonts.outfit(color: Colors.white54, fontSize: 9),
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                             ),
                             const SizedBox(width: 8),
 
                             // 2. Streak
                             Expanded(
                               child: Container(
                                 padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                                 decoration: BoxDecoration(
                                   color: Colors.white.withAlpha(5),
                                   borderRadius: BorderRadius.circular(12),
                                   border: Border.all(color: Colors.white10),
                                 ),
                                 child: Column(
                                   children: [
                                     FittedBox(
                                       fit: BoxFit.scaleDown,
                                       child: Text(
                                         "STREAK",
                                         style: GoogleFonts.outfit(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                                       ),
                                     ),
                                     const SizedBox(height: 6),
                                     FittedBox(
                                       fit: BoxFit.scaleDown,
                                       child: Row(
                                         mainAxisAlignment: MainAxisAlignment.center,
                                         children: [
                                           const Text(
                                             "🔥 ",
                                             style: TextStyle(fontSize: 11),
                                           ),
                                           Text(
                                             "$streak Day${streak == 1 ? '' : 's'}",
                                             style: GoogleFonts.orbitron(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.bold),
                                           ),
                                         ],
                                       ),
                                     ),
                                     const SizedBox(height: 4),
                                     FittedBox(
                                       fit: BoxFit.scaleDown,
                                       child: Text(
                                         "Daily Active",
                                         style: GoogleFonts.outfit(color: Colors.white54, fontSize: 9),
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                             ),
                             const SizedBox(width: 8),
 
                             // 3. Today's Progress Delta
                             Expanded(
                               child: Container(
                                 padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                                 decoration: BoxDecoration(
                                   color: Colors.white.withAlpha(5),
                                   borderRadius: BorderRadius.circular(12),
                                   border: Border.all(color: Colors.white10),
                                 ),
                                 child: Column(
                                   children: [
                                     FittedBox(
                                       fit: BoxFit.scaleDown,
                                       child: Text(
                                         "PROGRESS",
                                         style: GoogleFonts.outfit(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                                       ),
                                     ),
                                     const SizedBox(height: 6),
                                     FittedBox(
                                       fit: BoxFit.scaleDown,
                                       child: Text(
                                         "+${activeProgressDelta.toStringAsFixed(activeProgressDelta == activeProgressDelta.toInt() ? 0 : 1)}%",
                                         style: GoogleFonts.orbitron(color: Colors.tealAccent, fontSize: 13, fontWeight: FontWeight.bold),
                                       ),
                                     ),
                                     const SizedBox(height: 4),
                                     FittedBox(
                                       fit: BoxFit.scaleDown,
                                       child: Text(
                                         _isYesterday ? "Yesterday's Gain" : "Today's Gain",
                                         style: GoogleFonts.outfit(color: Colors.white54, fontSize: 9),
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                             ),
                           ],
                         ),
                        const SizedBox(height: 24),

                        // Goal Progress Bar
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Daily Goal Progress",
                                  style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11, height: 1.3),
                                ),
                                Text(
                                  "${(goalRatio * 100).round()}%",
                                  style: GoogleFonts.outfit(color: widget.accentColor, fontSize: 11, fontWeight: FontWeight.bold, height: 1.3),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 6,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: goalRatio,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: widget.accentColor,
                                    borderRadius: BorderRadius.circular(3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: widget.accentColor.withAlpha(100),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Today's Accomplishments Checklist
                        if (_showAccomplishments) ...[
                          const SizedBox(height: 28),
                          Text(
                            _isYesterday ? "YESTERDAY'S ACCOMPLISHMENTS" : "TODAY'S ACCOMPLISHMENTS",
                            style: GoogleFonts.outfit(
                              color: Colors.white30,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Consumer(
                              builder: (context, ref, child) {
                                final focusHistoryAsync = ref.watch(_isYesterday ? yesterdayFocusSessionsProvider : todayFocusSessionsProvider);
                                return focusHistoryAsync.when(
                                  data: (sessions) {
                                    final accomplishmentsList = _getTodayAccomplishments(sessions);

                                    if (accomplishmentsList.isEmpty) {
                                      return Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.hourglass_empty_rounded, color: Colors.white24, size: 32),
                                            const SizedBox(height: 8),
                                            Text(
                                              "No checklist tasks completed yet.",
                                              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    return ListView.builder(
                                      physics: const BouncingScrollPhysics(),
                                      padding: EdgeInsets.zero,
                                      itemCount: accomplishmentsList.length,
                                      itemBuilder: (context, index) {
                                        final item = accomplishmentsList[index];
                                        // Clean up naming for checklist: Category > Topic > Task
                                        final parts = item.split(' > ');
                                        final displayName = parts.length > 2
                                            ? "${parts[1]} > ${parts[2]}" // Show Topic > Task
                                            : item;

                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.check_circle_outline_rounded,
                                                color: widget.accentColor,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  displayName,
                                                  style: GoogleFonts.outfit(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  loading: () => const Center(child: CircularProgressIndicator()),
                                  error: (e, _) => Text("Error loading accomplishments", style: TextStyle(color: Colors.white24, fontSize: 12)),
                                );
                              },
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                        ],

                        // Card Footer
                        const Divider(color: Colors.white10, height: 24),
                        Center(
                          child: Text(
                            "STUDIED WITH GATELETICS",
                            style: GoogleFonts.orbitron(
                              color: Colors.white24,
                              fontSize: 9,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Control Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  "Close",
                  style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: (_isSaving || _isSharing) ? null : _captureAndSave,
                icon: _isSaving
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5))
                    : const Icon(Icons.download_rounded, size: 14),
                label: Text(
                  _isSaving ? "Saving..." : "Save",
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: widget.accentColor,
                  side: BorderSide(color: widget.accentColor.withAlpha(120)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: (_isSaving || _isSharing) ? null : _captureAndShare,
                icon: _isSharing
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 1.5))
                    : const Icon(Icons.share_rounded, size: 14),
                label: Text(
                  _isSharing ? "Sharing..." : "Share",
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: widget.accentColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SquareProgressPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color color;
  final double strokeWidth;

  SquareProgressPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    // Draw background rounded square
    canvas.drawRRect(rrect, paint);

    if (progress <= 0.0) return;

    // Draw active progress outline along the path
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height;
    final r = 8.0; // corner radius

    path.moveTo(w / 2, h);
    path.lineTo(r, h);
    path.arcToPoint(Offset(0, h - r), radius: Radius.circular(r), clockwise: false);
    path.lineTo(0, r);
    path.arcToPoint(Offset(r, 0), radius: Radius.circular(r), clockwise: false);
    path.lineTo(w - r, 0);
    path.arcToPoint(Offset(w, r), radius: Radius.circular(r), clockwise: false);
    path.lineTo(w, h - r);
    path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r), clockwise: false);
    path.lineTo(w / 2, h);

    for (final metric in path.computeMetrics()) {
      final extract = metric.extractPath(0.0, metric.length * progress);
      canvas.drawPath(extract, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SquareProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
