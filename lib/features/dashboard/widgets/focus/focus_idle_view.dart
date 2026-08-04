import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_context_ext.dart';
import 'package:gateletics/providers/providers.dart';
import '../../../../utils/demo_keys.dart';
import '../../../../utils/string_utils.dart';

import 'focus_dialogs.dart';
import 'timer_painters.dart';
import '../../../../utils/ui_scaling.dart';
import 'focus_accomplishments_widget.dart';
import '../share_progress_card.dart';

class FocusIdleView extends ConsumerStatefulWidget {
  final Color accentColor;

  const FocusIdleView({
    super.key,
    required this.accentColor,
  });

  @override
  ConsumerState<FocusIdleView> createState() => _FocusIdleViewState();
}

class _FocusIdleViewState extends ConsumerState<FocusIdleView> {
  int _displayMode = 0;
  bool _isYesterdayExpanded = false;

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.accentColor;
    final sessionState = ref.watch(focusProvider);
    final todaySessionsAsync = ref.watch(todayFocusSessionsProvider);
    final yesterdaySessionsAsync = ref.watch(yesterdayFocusSessionsProvider);
    final todayDurationAsync = ref.watch(todayFocusDurationProvider);
    final dailyGoalMinutes = ref.watch(dailyFocusGoalProvider);

    final isDemoActive = ref.watch(demoGuideProvider) != DemoStep.none;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(left: context.s(24), right: context.s(24), top: context.s(16), bottom: context.s(40)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              SizedBox(height: context.s(12)),
              Center(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(
                      fontSize: context.s(32),
                      fontWeight: FontWeight.bold,
                      color: context.appColors.textPrimary,
                      letterSpacing: context.s(0.5),
                    ),
                    children: [
                      const TextSpan(text: 'Ready to '),
                      TextSpan(
                        text: 'Begin',
                        style: TextStyle(color: accentColor),
                      ),
                      const TextSpan(text: '?'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: context.s(24)),

              // Timer Start Box
              _buildTimerStartBox(context, ref, sessionState, accentColor, isDemoActive),
              SizedBox(height: context.s(16)),

              // Method Selector Chip
              Center(
                child: GestureDetector(
                  key: isDemoActive ? DemoKeys.focusTimerSelectors : null,
                  onTap: () => showMethodSelectionMenu(context, sessionState, accentColor, ref),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: context.s(20), vertical: context.s(10)),
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(35),
                      borderRadius: BorderRadius.circular(context.s(12)),
                      border: Border.all(color: accentColor.withAlpha(100), width: context.s(1.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        buildMethodIcon(sessionState.details, accentColor, size: context.s(24)),
                        SizedBox(width: context.s(12)),
                        Text(
                          sessionState.details.name,
                          style: GoogleFonts.outfit(
                            color: context.appColors.textPrimary,
                            fontSize: context.s(14),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: context.s(32)),

              // Daily Goal Progress
              () {
                final effectiveGoalMinutes = (dailyGoalMinutes == 0 && isDemoActive) ? 120 : dailyGoalMinutes;
                if (effectiveGoalMinutes == 0) return const SizedBox();
                return todayDurationAsync.when(
                  data: (elapsedSeconds) {
                    final elapsedMinutes = (elapsedSeconds / 60).floor();
                    final progressPercent = min(1.0, elapsedMinutes / effectiveGoalMinutes);
                    final elapsedHoursStr = (elapsedMinutes / 60).toStringAsFixed(1).replaceAll('.0', '');
                    final goalHoursStr = (effectiveGoalMinutes / 60).toStringAsFixed(1).replaceAll('.0', '');

                    final minutesLeft = max(0, effectiveGoalMinutes - elapsedMinutes);
                    final hoursLeftStr = (minutesLeft / 60).toStringAsFixed(1).replaceAll('.0', '');

                    final pctCompleted = (progressPercent * 100);
                    final pctLeft = max(0.0, 100.0 - pctCompleted);

                  String progressInfo = "";
                  switch (_displayMode) {
                    case 0:
                      progressInfo = "${elapsedHoursStr}hr / ${goalHoursStr}hr";
                      break;
                    case 1:
                      progressInfo = "${hoursLeftStr}hr left / ${goalHoursStr}hr";
                      break;
                    case 2:
                      progressInfo = "${pctCompleted.toStringAsFixed(1).replaceAll('.0', '')}% completed";
                      break;
                    case 3:
                      progressInfo = "${pctLeft.toStringAsFixed(1).replaceAll('.0', '')}% left";
                      break;
                    default:
                      progressInfo = "${elapsedHoursStr}hr / ${goalHoursStr}hr";
                  }

                  return GestureDetector(
                    key: isDemoActive ? DemoKeys.focusDailyGoalBar : null,
                    onTap: () {
                      setState(() {
                        _displayMode = (_displayMode + 1) % 4;
                      });
                    },
                    onLongPress: () => showDailyGoalDialog(context, dailyGoalMinutes, accentColor, ref),
                    child: Container(
                      padding: EdgeInsets.all(context.s(16)),
                      decoration: BoxDecoration(
                        color: context.appColors.cardBackground,
                        borderRadius: BorderRadius.circular(context.s(16)),
                        border: Border.all(color: context.appColors.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Daily Goal:",
                                style: GoogleFonts.outfit(
                                  color: context.appColors.textPrimary,
                                  fontSize: context.s(15),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                progressInfo,
                                style: GoogleFonts.outfit(
                                  color: context.appColors.textPrimary,
                                  fontSize: context.s(15),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.s(10)),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(context.s(8)),
                            child: Stack(
                              children: [
                                Container(
                                  height: context.s(32),
                                  color: context.appColors.surfaceColor,
                                ),
                                FractionallySizedBox(
                                  widthFactor: progressPercent,
                                  child: Container(
                                    height: context.s(32),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [accentColor.withAlpha(200), accentColor],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text("Goal error: $e"),
              );
            }(),
              SizedBox(height: context.s(32)),

              // Today's History Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Today’s History:",
                    style: GoogleFonts.outfit(
                      fontSize: context.s(24),
                      fontWeight: FontWeight.bold,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  if (ref.watch(enableShareProgressCardProvider))
                    IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(context.s(6)),
                        decoration: BoxDecoration(
                          color: accentColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(context.s(8)),
                          border: Border.all(color: accentColor.withAlpha(80), width: 1),
                        ),
                        child: Icon(
                          Icons.share_rounded,
                          color: accentColor,
                          size: context.s(16),
                        ),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierColor: Colors.black.withAlpha(200),
                          builder: (context) => ShareProgressCard(accentColor: accentColor),
                        );
                      },
                      tooltip: 'Share Progress Card',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                    ),
                ],
              ),
              SizedBox(height: context.s(16)),

              // History List Timeline
              todaySessionsAsync.when(
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: context.s(24.0)),
                      child: Center(
                        child: Text(
                          "No focus sessions completed today yet.",
                          style: GoogleFonts.outfit(
                            color: context.appColors.textMuted,
                            fontSize: context.s(14),
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final s = sessions[index];
                      final durationMin = (s.durationSeconds / 60).floor();
                      final durationStr = durationMin >= 60
                          ? "${(durationMin / 60).toStringAsFixed(1).replaceAll('.0', '')} hr"
                          : "$durationMin min";

                      final formattedTime = formatTimeOfDay(s.startTime);

                      return _buildHistoryTimelineEntry(
                        context,
                        time: formattedTime,
                        method: s.method,
                        duration: durationStr,
                        accomplishments: s.accomplishments,
                        progressDelta: s.progressDelta,
                        isFirst: index == 0,
                        isLast: index == sessions.length - 1,
                        accentColor: accentColor,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text("History error: $e"),
              ),
              // Yesterday's History (Only shown if yesterday has completed sessions)
              yesterdaySessionsAsync.when(
                data: (yesterdaySessions) {
                  if (yesterdaySessions.isEmpty) return const SizedBox();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: context.s(28)),

                      // Yesterday's History Header Row (Expandable)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isYesterdayExpanded = !_isYesterdayExpanded;
                          });
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Yesterday’s History:",
                              style: GoogleFonts.outfit(
                                fontSize: context.s(20),
                                fontWeight: FontWeight.bold,
                                color: context.appColors.textSecondary,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _isYesterdayExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: context.appColors.textSecondary,
                                size: context.s(24),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isYesterdayExpanded = !_isYesterdayExpanded;
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),

                      if (_isYesterdayExpanded) ...[
                        SizedBox(height: context.s(16)),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: yesterdaySessions.length,
                          itemBuilder: (context, index) {
                            final s = yesterdaySessions[index];
                            final durationMin = (s.durationSeconds / 60).floor();
                            final durationStr = durationMin >= 60
                                ? "${(durationMin / 60).toStringAsFixed(1).replaceAll('.0', '')} hr"
                                : "$durationMin min";

                            final formattedTime = formatTimeOfDay(s.startTime);

                            return _buildHistoryTimelineEntry(
                              context,
                              time: formattedTime,
                              method: s.method,
                              duration: durationStr,
                              accomplishments: s.accomplishments,
                              progressDelta: s.progressDelta,
                              isFirst: index == 0,
                              isLast: index == yesterdaySessions.length - 1,
                              accentColor: accentColor.withValues(alpha: 0.7),
                            );
                          },
                        ),
                      ],
                    ],
                  );
                },
                loading: () => const SizedBox(),
                error: (e, _) => const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildTimerStartBox(BuildContext context, WidgetRef ref, FocusSessionState sessionState, Color accentColor, bool isDemoActive) {
    if (sessionState.details.isCountUp) {
      // Freestyle big play button
      return SizedBox(
        height: context.s(252),
        child: Center(
          child: GestureDetector(
            key: isDemoActive ? DemoKeys.focusStartButton : null,
            onTap: () => ref.read(focusProvider.notifier).startSession(),
            child: Container(
              width: context.s(140),
              height: context.s(140),
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withAlpha(38),
                    blurRadius: context.s(16),
                    spreadRadius: context.s(1),
                  ),
                ],
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: context.appColors.onAccent,
                size: context.s(72),
              ),
            ),
          ),
        ),
      );
    }

    // Standard timer start box
    final focusStr = sessionState.details.isCustom
        ? "${sessionState.customTimerMinutes.toString().padLeft(2, '0')}:00"
        : "${sessionState.details.focusMinutes.toString().padLeft(2, '0')}:00";
    final breakStr = sessionState.details.isCustom
        ? "--:--"
        : "${sessionState.details.breakMinutes.toString().padLeft(2, '0')}:00";

    return SizedBox(
      height: context.s(252),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: context.s(20), vertical: context.s(24)),
          decoration: BoxDecoration(
            color: context.appColors.cardBackground,
            borderRadius: BorderRadius.circular(context.s(20)),
            border: Border.all(color: context.appColors.borderColor, width: context.s(1.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          "FOCUS",
                          style: GoogleFonts.outfit(
                            color: context.appColors.textSecondary,
                            fontSize: context.s(10),
                            fontWeight: FontWeight.bold,
                            letterSpacing: context.s(1.5),
                          ),
                        ),
                        SizedBox(height: context.s(6)),
                        GestureDetector(
                          onTap: () {
                            if (sessionState.details.isCustom) {
                              showCustomDurationPicker(context, sessionState.customTimerMinutes, accentColor, ref);
                            }
                          },
                          child: Text(
                            focusStr,
                            style: GoogleFonts.orbitron(
                              color: context.appColors.textPrimary,
                              fontSize: context.s(32),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.s(24.0)),
                      child: Container(
                        width: context.s(1),
                        height: context.s(40),
                        color: context.appColors.dividerColor,
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          "BREAK",
                          style: GoogleFonts.outfit(
                            color: context.appColors.textSecondary,
                            fontSize: context.s(10),
                            fontWeight: FontWeight.bold,
                            letterSpacing: context.s(1.5),
                          ),
                        ),
                        SizedBox(height: context.s(6)),
                        Text(
                          breakStr,
                          style: GoogleFonts.orbitron(
                            color: context.appColors.textPrimary,
                            fontSize: context.s(32),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.s(24)),
              SizedBox(
                width: double.infinity,
                height: context.s(48),
                child: FilledButton.icon(
                  key: isDemoActive ? DemoKeys.focusStartButton : null,
                  onPressed: () => ref.read(focusProvider.notifier).startSession(),
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: context.appColors.onAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.s(14)),
                    ),
                  ),
                  icon: Icon(Icons.play_arrow_rounded, color: context.appColors.onAccent),
                  label: Text(
                    "Lets Do This!",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      letterSpacing: context.s(0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // History timeline entry
  Widget _buildHistoryTimelineEntry(
    BuildContext context, {
    required String time,
    required String method,
    required String duration,
    required String? accomplishments,
    required double progressDelta,
    required bool isFirst,
    required bool isLast,
    required Color accentColor,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left timestamp
          SizedBox(
            width: context.s(72),
            child: Padding(
              padding: EdgeInsets.only(top: context.s(14.0)),
              child: Text(
                time,
                style: GoogleFonts.outfit(
                  color: context.appColors.textMuted,
                  fontSize: context.s(12),
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ),
          SizedBox(width: context.s(16)),

          // Timeline node
          SizedBox(
            width: context.s(16),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: isFirst ? context.s(16) : 0,
                  bottom: isLast ? null : 0,
                  height: isLast ? context.s(16) : null,
                  child: Container(
                    width: context.s(2),
                    color: accentColor.withAlpha(50),
                  ),
                ),
                Positioned(
                  top: context.s(16),
                  child: Container(
                    width: context.s(10),
                    height: context.s(10),
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: context.s(16)),

          // Entry Card
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: context.s(16)),
              padding: EdgeInsets.symmetric(horizontal: context.s(16), vertical: context.s(12)),
              decoration: BoxDecoration(
                color: context.appColors.cardBackground,
                borderRadius: BorderRadius.circular(context.s(14)),
                border: Border.all(color: accentColor.withAlpha(50)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, color: accentColor, size: context.s(16)),
                          SizedBox(width: context.s(6)),
                          Text(
                            duration,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: context.s(14),
                            ),
                          ),
                        ],
                      ),
                      // Overall % increase in the middle
                      Text(
                        "+${progressDelta.toStringAsFixed(progressDelta == progressDelta.toInt() ? 0 : 1)}%",
                        style: GoogleFonts.outfit(
                          color: progressDelta > 0 ? accentColor : context.appColors.textMuted,
                          fontWeight: FontWeight.bold,
                          fontSize: context.s(13),
                        ),
                      ),
                      Text(
                        method,
                        style: GoogleFonts.outfit(
                          color: context.appColors.textSecondary,
                          fontSize: context.s(12),
                        ),
                      ),
                    ],
                  ),
                  if (accomplishments != null && accomplishments.isNotEmpty) ...[
                    SizedBox(height: context.s(6)),
                    Divider(color: context.appColors.dividerColor),
                    SizedBox(height: context.s(4)),
                    FocusAccomplishmentsWidget(
                      accomplishments: accomplishments,
                      accentColor: accentColor,
                      maxWidgetHeight: 240,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
