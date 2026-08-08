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
import 'package:share_plus/share_plus.dart';

import '../../../../core/config/brand_config.dart';
import '../../../../core/theme/theme_context_ext.dart';
import '../../../../database/app_database.dart';
import 'package:gateletics/providers/providers.dart';
import '../../../../utils/string_utils.dart';
import '../../../../utils/ui_scaling.dart';
import 'share/share_card_actions.dart';
import 'share/share_card_options_panel.dart';
import 'share/square_progress_painter.dart';

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
      final dateStr = now.toDateKey();
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
            text: 'My GATE preparation progress on GATEletics!',
          ),
        );
      } else {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$defaultFileName');
        await tempFile.writeAsBytes(pngBytes);

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(tempFile.path)],
            text: 'My GATE preparation progress on GATEletics!',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _captureAndSave() async {
    final targetPixelRatio = View.of(context).devicePixelRatio.clamp(2.0, 3.5);
    setState(() => _isSaving = true);
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
      final dateStr = now.toDateKey();
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
            text: 'My GATE preparation progress on GATEletics!',
          ),
        );
        return;
      }

      if (Platform.isAndroid) {
        final params = SaveFileDialogParams(
          data: pngBytes,
          fileName: defaultFileName,
        );
        final filePath = await FlutterFileDialog.saveFile(params: params);
        if (filePath != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✓ Image saved to gallery/downloads!'), backgroundColor: Colors.green),
          );
        }
      } else {
        final outputFile = await FilePicker.saveFile(
          dialogTitle: 'Save Progress Card Image',
          fileName: defaultFileName,
          bytes: pngBytes,
          type: FileType.custom,
          allowedExtensions: ['png'],
        );
        if (outputFile != null) {
          final file = File(outputFile);
          await file.writeAsBytes(pngBytes);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✓ Progress card saved successfully!'), backgroundColor: Colors.green),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  List<String> _getTodayAccomplishments(List<FocusSession> sessions) {
    final Map<String, int> taskCounts = {};
    for (final s in sessions) {
      if (s.accomplishments != null && s.accomplishments!.isNotEmpty) {
        taskCounts[s.accomplishments!] = (taskCounts[s.accomplishments!] ?? 0) + 1;
      }
    }
    return taskCounts.keys.toList();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final targetDate = _isYesterday ? now.subtract(const Duration(days: 1)) : now;
    final dateStr = "${targetDate.day} ${getMonthName(targetDate.month, short: true)} ${targetDate.year}";

    final profileImage = ref.watch(displayProfileImageProvider);
    final displayName = ref.watch(displayNameProvider);
    final stats = ref.watch(completionStatsProvider).value;
    final branch = ref.watch(selectedBranchProvider);

    final durationAsync = ref.watch(_isYesterday ? yesterdayFocusDurationProvider : todayFocusDurationProvider);
    final totalSecs = durationAsync.value ?? 0;
    final hrs = totalSecs ~/ 3600;
    final mins = (totalSecs % 3600) ~/ 60;
    final timeStudiedStr = hrs > 0 ? "${hrs}h ${mins}m" : "${mins}m";

    final goalMins = ref.watch(dailyFocusGoalProvider);
    final goalHrs = goalMins / 60.0;
    final goalStr = "${goalHrs.toStringAsFixed(goalHrs % 1 == 0 ? 0 : 1)}h";

    final streak = ref.watch(currentStreakProvider);

    final hasCustomName = _showName && displayName != null && displayName.isNotEmpty;
    final headerTitle = hasCustomName ? displayName : "GATE Aspirant";
    final showHeaderPhoto = (_showProfilePhoto && profileImage != null) || hasCustomName;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: context.s(16), vertical: context.s(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShareCardOptionsPanel(
            accentColor: widget.accentColor,
            isYesterday: _isYesterday,
            showAccomplishments: _showAccomplishments,
            showProfilePhoto: _showProfilePhoto,
            showName: _showName,
            onDayChanged: (val) => setState(() => _isYesterday = val),
            onToggleAccomplishments: () => setState(() => _showAccomplishments = !_showAccomplishments),
            onTogglePhoto: () => setState(() => _showProfilePhoto = !_showProfilePhoto),
            onToggleName: () => setState(() => _showName = !_showName),
          ),
          const SizedBox(height: 16),
          RepaintBoundary(
            key: _repaintKey,
            child: Container(
              width: 360,
              height: _showAccomplishments ? 640.0 : null,
              decoration: BoxDecoration(
                color: context.appColors.cardBackground,
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
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset('assets/logo_trans_cropped.png', width: 22, height: 22),
                            const SizedBox(width: 10),
                            Text(
                              BrandConfig.appName.toUpperCase(),
                              style: GoogleFonts.orbitron(
                                color: context.appColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              dateStr,
                              style: GoogleFonts.outfit(
                                color: context.appColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            if (showHeaderPhoto) ...[
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: widget.accentColor.withAlpha(40),
                                backgroundImage: (_showProfilePhoto && profileImage != null) ? profileImage : null,
                                onBackgroundImageError: (_showProfilePhoto && profileImage != null) ? (e, s) {} : null,
                                child: (_showProfilePhoto && profileImage != null)
                                    ? null
                                    : (_showName && displayName != null && displayName.isNotEmpty)
                                        ? Text(
                                            displayName[0].toUpperCase(),
                                            style: GoogleFonts.outfit(color: widget.accentColor, fontWeight: FontWeight.bold, fontSize: 16),
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
                                    style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  Text("GATE $branch", style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 12)),
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
                                      backgroundColor: context.appColors.surfaceColor,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                ),
                                Text(
                                  "${(stats?.percentage ?? 0.0).toStringAsFixed(0)}%",
                                  style: GoogleFonts.orbitron(color: context.appColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                                decoration: BoxDecoration(
                                  color: context.appColors.surfaceColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: context.appColors.borderColor),
                                ),
                                child: Column(
                                  children: [
                                    FittedBox(fit: BoxFit.scaleDown, child: Text("STUDY TIME", style: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8))),
                                    const SizedBox(height: 6),
                                    FittedBox(fit: BoxFit.scaleDown, child: Text(timeStudiedStr, style: GoogleFonts.orbitron(color: widget.accentColor, fontSize: 13, fontWeight: FontWeight.bold))),
                                    const SizedBox(height: 4),
                                    FittedBox(fit: BoxFit.scaleDown, child: Text("Goal: $goalStr", style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 9))),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                                decoration: BoxDecoration(
                                  color: context.appColors.surfaceColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: context.appColors.borderColor),
                                ),
                                child: Column(
                                  children: [
                                    FittedBox(fit: BoxFit.scaleDown, child: Text("STREAK", style: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8))),
                                    const SizedBox(height: 6),
                                    FittedBox(fit: BoxFit.scaleDown, child: Text("$streak DAYS", style: GoogleFonts.orbitron(color: widget.accentColor, fontSize: 13, fontWeight: FontWeight.bold))),
                                    const SizedBox(height: 4),
                                    FittedBox(fit: BoxFit.scaleDown, child: Text("Current Active", style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 9))),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_showAccomplishments) ...[
                          const SizedBox(height: 28),
                          Text(
                            _isYesterday ? "YESTERDAY'S ACCOMPLISHMENTS" : "TODAY'S ACCOMPLISHMENTS",
                            style: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
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
                                        child: Text("No checklist tasks completed yet.", style: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 12)),
                                      );
                                    }
                                    return ListView.builder(
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: accomplishmentsList.length,
                                      itemBuilder: (context, index) {
                                        final item = accomplishmentsList[index];
                                        final parts = item.split(' > ');
                                        final displayName = parts.length > 2 ? "${parts[1]} > ${parts[2]}" : item;
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Row(
                                            children: [
                                              Icon(Icons.check_circle_outline_rounded, color: widget.accentColor, size: 14),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text(displayName, style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  loading: () => const Center(child: CircularProgressIndicator()),
                                  error: (e, _) => Text("Error loading accomplishments", style: TextStyle(color: context.appColors.textMuted, fontSize: 12)),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ShareCardActions(
            accentColor: widget.accentColor,
            isSaving: _isSaving,
            isSharing: _isSharing,
            onSave: _captureAndSave,
            onShare: _captureAndShare,
            onClose: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
