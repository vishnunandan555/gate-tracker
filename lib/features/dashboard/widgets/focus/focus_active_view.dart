import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../database/app_database.dart';
import '../../../../core/theme/theme_context_ext.dart';
import 'package:gateletics/providers/providers.dart';
import 'timer_painters.dart';
import '../../../../utils/ui_scaling.dart';
import 'focus_accomplishments_widget.dart';
import '../../../../utils/demo_keys.dart';



class FocusActiveView extends ConsumerStatefulWidget {
  final Color accentColor;

  const FocusActiveView({
    super.key,
    required this.accentColor,
  });

  @override
  ConsumerState<FocusActiveView> createState() => _FocusActiveViewState();
}

class _FocusActiveViewState extends ConsumerState<FocusActiveView> {
  double _swipeDelta = 0.0;

  @override
  Widget build(BuildContext context) {
    ref.listen<DemoStep>(demoGuideProvider, (prev, next) async {
      if (next == DemoStep.focusSavePrompt) {
        final finalSession = await ref.read(focusProvider.notifier).stopSession();
        if (context.mounted) {
          _showSessionSummary(context, finalSession, widget.accentColor);
        }
      }
    });

    final sessionState = ref.watch(focusProvider);
    final accentColor = widget.accentColor;

    final isBreak = sessionState.isBreakActive;
    final isPaused = sessionState.status == FocusStatus.paused;
    final isCountUp = sessionState.details.isCountUp;

    final quoteText = ref.watch(formattedQuoteProvider(null));

    final displaySeconds = isCountUp
        ? sessionState.totalSecondsFocused
        : max(0, sessionState.currentTargetSeconds - sessionState.elapsedSeconds);

    final hours = (displaySeconds / 3600).floor();
    final minutes = ((displaySeconds % 3600) / 60).floor();
    final seconds = displaySeconds % 60;
    final totalMinutes = (displaySeconds / 60).floor();

    final progress = sessionState.currentTargetSeconds == 0
        ? 0.0
        : min(1.0, sessionState.elapsedSeconds / sessionState.currentTargetSeconds);

    final ringColor = isBreak ? context.appColors.textPrimary : accentColor;

    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final timeStr = "$displayHour:$minute $period";

    return Stack(
      children: [
        Positioned.fill(
          child: FocusAmbientGlow(color: ringColor),
        ),
        // 1. Top Section (Mode Tag) - Pinned to Top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: context.s(16)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: context.s(16), vertical: context.s(6)),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(context.s(20)),
                    border: Border.all(color: ringColor, width: context.s(1.5)),
                  ),
                  child: Text(
                    isBreak ? "Break Period" : sessionState.details.name,
                    style: GoogleFonts.outfit(
                      color: ringColor,
                      fontSize: context.s(12),
                      fontWeight: FontWeight.bold,
                      letterSpacing: context.s(0.5),
                    ),
                  ),
                ),
                SizedBox(height: context.s(6)),
                Text(
                  timeStr,
                  style: GoogleFonts.outfit(
                    color: context.appColors.textMuted,
                    fontSize: context.s(10),
                    fontWeight: FontWeight.bold,
                    letterSpacing: context.s(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Middle Section (Timer Display) - Centered Vertically
        Center(
          key: DemoKeys.activeTimerCircle,
          child: isCountUp
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    _buildTimerUnit(hours.toString().padLeft(2, '0'), 'hr'),
                    SizedBox(width: context.s(8)),
                    _buildTimerUnit(minutes.toString().padLeft(2, '0'), 'min'),
                    SizedBox(width: context.s(8)),
                    _buildTimerUnit(seconds.toString().padLeft(2, '0'), 's', highlightColor: accentColor),
                  ],
                )
              : Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.s(24.0)),
                  child: SizedBox(
                    width: double.infinity,
                    height: context.s(140),
                    child: CustomPaint(
                      painter: SquircleTimerPainter(
                        progress: progress,
                        color: ringColor,
                        trackColor: context.appColors.borderColor,
                        strokeWidth: context.s(10),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${totalMinutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}",
                              style: GoogleFonts.orbitron(
                                fontSize: context.s(52),
                                fontWeight: FontWeight.w900,
                                color: ringColor,
                                shadows: [
                                  Shadow(color: ringColor.withValues(alpha: 0.5), blurRadius: context.s(18)),
                                ],
                                letterSpacing: context.s(2),
                              ),
                            ),
                            SizedBox(height: context.s(2)),
                            Text(
                              isBreak ? "Break Time" : (isPaused ? "Paused" : "Focusing"),
                              style: GoogleFonts.outfit(
                                color: context.appColors.textSecondary,
                                fontSize: context.s(11),
                                fontWeight: FontWeight.bold,
                                letterSpacing: context.s(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),

        // 3. Bottom Section - Pinned to Bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quotes or status label
                if (!isCountUp && !isBreak && ref.watch(focusQuotesEnabledProvider))
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.s(32.0)),
                    child: Center(
                      child: Text(
                        "“$quoteText”",
                        style: GoogleFonts.caveat(
                          fontSize: context.s(18),
                          fontWeight: FontWeight.bold,
                          color: context.appColors.textPrimary,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  Center(
                    child: Text(
                      isCountUp
                          ? (isPaused ? "Paused" : "Focusing...")
                          : (isBreak ? "Break Time" : (isPaused ? "Paused" : "Focusing")),
                      style: GoogleFonts.outfit(
                        fontSize: context.s(18),
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),

                SizedBox(height: context.s(28)), // Spacing above Pause button / indicators

                if (!isCountUp) ...[
                  _buildSessionIndicators(sessionState, accentColor),
                  SizedBox(height: context.s(8)),
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: context.s(14), vertical: context.s(6)),
                      decoration: BoxDecoration(
                        color: context.appColors.surfaceColor,
                        borderRadius: BorderRadius.circular(context.s(16)),
                        border: Border.all(color: context.appColors.borderColor),
                      ),
                      child: Text(
                        _formatTotalDuration(sessionState.totalSecondsFocused),
                        style: GoogleFonts.outfit(
                          color: context.appColors.textSecondary,
                          fontSize: context.s(12),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: context.s(20)),
                ],

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.s(24.0)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isBreak) ...[
                        // Accomplishments box during break
                        if (sessionState.sessionAccomplishments.isNotEmpty) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "This session:",
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: context.s(13),
                                color: context.appColors.textMuted,
                              ),
                            ),
                          ),
                          SizedBox(height: context.s(6)),
                          FocusAccomplishmentsWidget(
                            accomplishments: sessionState.sessionAccomplishments.join('\n'),
                            accentColor: accentColor,
                            maxWidgetHeight: 90,
                          ),
                          SizedBox(height: context.s(12)),
                        ],
                        SizedBox(
                          width: double.infinity,
                          height: context.s(48),
                          child: FilledButton.icon(
                            onPressed: () => _handleStopSessionConfirm(context, sessionState),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF221111),
                              foregroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(context.s(12)),
                                side: const BorderSide(color: Colors.redAccent, width: 1.5),
                              ),
                            ),
                            icon: const Icon(Icons.stop_rounded),
                            label: Text(
                              "Stop Session",
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ] else ...[
                        if (isCountUp) ...[
                          // Pause/Resume button (Freestyle only, fitter and more squarish corner: 12)
                          Center(
                            child: SizedBox(
                              width: context.s(110),
                              height: context.s(38),
                              child: FilledButton.icon(
                                onPressed: () {
                                  if (isPaused) {
                                    ref.read(focusProvider.notifier).resumeSession();
                                  } else {
                                    ref.read(focusProvider.notifier).pauseSession();
                                  }
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: context.appColors.cardBackground,
                                  foregroundColor: context.appColors.textPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(context.s(12)), // More squarish corner
                                    side: BorderSide(color: ringColor.withValues(alpha: 0.3)),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: context.s(8)),
                                ),
                                icon: Icon(
                                  isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                                  color: ringColor,
                                  size: context.s(16),
                                ),
                                label: Text(
                                  isPaused ? "Resume" : "Pause",
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: context.s(11),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: context.s(16)),
                        ],
                        _buildSlideToStop(sessionState),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: context.s(12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimerUnit(String val, String label, {Color? highlightColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          val,
          style: GoogleFonts.orbitron(
            fontSize: context.s(32),
            fontWeight: FontWeight.bold,
            color: highlightColor ?? context.appColors.textPrimary,
          ),
        ),
        SizedBox(width: context.s(2)),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: context.s(10),
            color: context.appColors.textMuted,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionIndicators(FocusSessionState sessionState, Color accentColor) {
    final completed = sessionState.completedFocusIntervals;
    final isBreakActive = sessionState.isBreakActive;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.s(24.0), vertical: context.s(12.0)),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(completed + 1, (index) {
              final isCompletedCircle = index < completed;

              return Row(
                children: [
                  if (isCompletedCircle)
                    Container(
                      width: context.s(24),
                      height: context.s(24),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: accentColor, width: context.s(2)),
                      ),
                      child: Icon(Icons.check_rounded, color: accentColor, size: context.s(14)),
                    )
                  else
                    PulsingIndicatorNode(
                      accentColor: isBreakActive ? context.appColors.textPrimary : accentColor,
                      isPulsing: sessionState.status != FocusStatus.paused,
                    ),

                  if (isBreakActive && index == completed - 1)
                    DottedLineConnection(
                      accentColor: context.appColors.textPrimary,
                      isFlashing: sessionState.status != FocusStatus.paused,
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildSlideToStop(FocusSessionState sessionState) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _swipeDelta -= details.delta.dy;
          if (_swipeDelta < 0.0) _swipeDelta = 0.0;
          if (_swipeDelta > context.s(80.0)) {
            _swipeDelta = 0.0;
            _handleStopSessionConfirm(context, sessionState);
          }
        });
      },
      onVerticalDragEnd: (_) {
        setState(() {
          _swipeDelta = 0.0;
        });
      },
      child: Container(
        height: context.s(60),
        alignment: Alignment.bottomCenter,
        padding: EdgeInsets.only(bottom: context.s(12)),
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: (1.0 - (_swipeDelta / context.s(80.0))).clamp(0.2, 1.0),
              child: Icon(
                Icons.keyboard_double_arrow_up_rounded,
                color: widget.accentColor,
                size: context.s(18),
              ),
            ),
            SizedBox(height: context.s(2)),
            Text(
              "Slide up to Stop",
              style: GoogleFonts.outfit(
                color: context.appColors.textPrimary,
                fontSize: context.s(10),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleStopSessionConfirm(BuildContext context, FocusSessionState sessionState) async {
    ref.read(focusProvider.notifier).pauseSession();

    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: context.appColors.dialogBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.appColors.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Are you sure you want to stop?",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.appColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "All your accrued focus progress and accomplishments will be saved.",
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: context.appColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: context.appColors.borderColor),
                      ),
                      child: Text(
                        "No, Continue",
                        style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: widget.accentColor,
                        foregroundColor: context.appColors.onAccent,
                      ),
                      child: Text(
                        "Yes, Stop",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (result == true) {
      final finalSession = await ref.read(focusProvider.notifier).stopSession();
      if (context.mounted) {
        _showSessionSummary(context, finalSession, widget.accentColor);
      }
    } else {
      ref.read(focusProvider.notifier).resumeSession();
    }
  }

  void _showSessionSummary(BuildContext context, FocusSession session, Color accentColor) {
    final durationMin = (session.durationSeconds / 60).floor();
    final durationStr = durationMin >= 60
        ? "${(durationMin / 60).toStringAsFixed(1).replaceAll('.0', '')} hr"
        : "$durationMin min";

    // Capture demo state and notifier BEFORE showDialog.
    // After the session ends, FocusActiveView may be replaced by FocusIdleView,
    // unmounting this widget. Using ref inside the dialog builder or its callbacks
    // would then throw "ref used after unmount". The Notifier instance itself is
    // stable and safe to hold across widget lifecycle boundaries.
    final isDemoSaveStep = ref.read(demoGuideProvider) == DemoStep.focusSavePrompt;
    final demoNotifier = ref.read(demoGuideProvider.notifier);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: context.appColors.dialogBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: accentColor.withAlpha(60), width: 1.5),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Session Summary",
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: context.appColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Duration:", style: GoogleFonts.outfit(color: context.appColors.textMuted)),
                        Text(durationStr, style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Method:", style: GoogleFonts.outfit(color: context.appColors.textMuted)),
                        Text(session.method, style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Progress:", style: GoogleFonts.outfit(color: context.appColors.textMuted)),
                        Text(
                          "+${session.progressDelta.toStringAsFixed(session.progressDelta == session.progressDelta.toInt() ? 0 : 1)}%",
                          style: GoogleFonts.outfit(
                            color: session.progressDelta > 0 ? accentColor : context.appColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    if (session.accomplishments != null && session.accomplishments!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        "Accomplishments:",
                        style: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      FocusAccomplishmentsWidget(
                        accomplishments: session.accomplishments,
                        accentColor: accentColor,
                        maxWidgetHeight: (MediaQuery.sizeOf(context).height * 0.40).clamp(180.0, 320.0),
                      ),
                    ],

                    const SizedBox(height: 24),
                    if (isDemoSaveStep) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          "Tap Awesome to save this session and continue the walkthrough.",
                          style: GoogleFonts.outfit(
                            color: context.appColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    FilledButton(
                      key: DemoKeys.accomplishmentsSaveButton,
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        if (isDemoSaveStep) {
                          Future.delayed(const Duration(milliseconds: 400), () {
                            demoNotifier.setStep(DemoStep.focusDailyGoalBar);
                          });
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: context.appColors.onAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text("Awesome", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTotalDuration(int totalSeconds) {
    final hours = (totalSeconds / 3600).floor();
    final minutes = ((totalSeconds % 3600) / 60).floor();
    if (hours > 0) {
      final hoursStr = hours.toString();
      final minsStr = minutes.toString();
      return "Total: ${hoursStr}h ${minsStr}m";
    }
    return "Total: ${minutes}min";
  }
}

class FocusAmbientGlow extends ConsumerStatefulWidget {
  final Color color;

  const FocusAmbientGlow({super.key, required this.color});

  @override
  ConsumerState<FocusAmbientGlow> createState() => _FocusAmbientGlowState();
}

class _FocusAmbientGlowState extends ConsumerState<FocusAmbientGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Random _random = Random();
  int _currentIndex = 0;
  double _currentSize = 400.0;

  @override
  void initState() {
    super.initState();
    // 5 places: 0 = Top Center, 1 = Top Left, 2 = Top Right, 3 = Bottom Left, 4 = Bottom Right
    _currentIndex = _random.nextInt(5);
    _currentSize = 360.0 + _random.nextDouble() * 140.0; // Randomize diameter between 360 and 500 logical pixels
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500), // 4.5 seconds out + 4.5 seconds back = 9 seconds total cycle
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        if (mounted) {
          setState(() {
            _currentIndex = _random.nextInt(5);
            _currentSize = 360.0 + _random.nextDouble() * 140.0;
          });
          _controller.forward();
        }
      } else if (status == AnimationStatus.completed) {
        if (mounted) {
          _controller.reverse();
        }
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glowStrength = ref.watch(focusGlowStrengthProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final glowSize = context.s(_currentSize);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final val = CurveTween(curve: Curves.easeInOutCubic).evaluate(_controller);
        
        // Starts completely off-screen at -glowSize, slides out by up to 45% of its diameter onto screen
        final offset = -glowSize + (val * glowSize * 0.45);

        // Making the gradient extremely faint, soft, and screensaver-like
        final glowWidget = Container(
          width: glowSize,
          height: glowSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.color.withValues(alpha: 0.16 * glowStrength),
                widget.color.withValues(alpha: 0.08 * glowStrength),
                widget.color.withValues(alpha: 0.02 * glowStrength),
                Colors.transparent,
              ],
              stops: const [0.0, 0.4, 0.7, 1.0],
            ),
          ),
        );

        Widget positionedGlow;
        switch (_currentIndex) {
          case 0: // Top Center
            positionedGlow = Positioned(
              top: offset,
              left: (screenWidth - glowSize) / 2,
              child: glowWidget,
            );
            break;
          case 1: // Top Left Corner
            positionedGlow = Positioned(
              top: offset,
              left: offset,
              child: glowWidget,
            );
            break;
          case 2: // Top Right Corner
            positionedGlow = Positioned(
              top: offset,
              right: offset,
              child: glowWidget,
            );
            break;
          case 3: // Bottom Left Corner
            positionedGlow = Positioned(
              bottom: offset,
              left: offset,
              child: glowWidget,
            );
            break;
          case 4: // Bottom Right Corner
          default:
            positionedGlow = Positioned(
              bottom: offset,
              right: offset,
              child: glowWidget,
            );
            break;
        }

        return Stack(
          children: [
            positionedGlow,
          ],
        );
      },
    );
  }
}
