import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_context_ext.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../utils/ui_scaling.dart';

class HistoryStreaks extends StatefulWidget {
  final int dailyGoalStreak;
  final int checkInStreak;
  final double progressPct;
  final Color accentColor;

  const HistoryStreaks({
    super.key,
    required this.dailyGoalStreak,
    required this.checkInStreak,
    required this.progressPct,
    required this.accentColor,
  });

  @override
  State<HistoryStreaks> createState() => _HistoryStreaksState();
}

class _HistoryStreaksState extends State<HistoryStreaks> with SingleTickerProviderStateMixin {
  late AnimationController _streakHeaderAnimController;
  late Animation<double> _streakHeaderAnim;

  @override
  void initState() {
    super.initState();
    _streakHeaderAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _streakHeaderAnim = CurvedAnimation(
      parent: _streakHeaderAnimController,
      curve: Curves.easeOut,
    );
    _streakHeaderAnimController.forward();
  }

  @override
  void dispose() {
    _streakHeaderAnimController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HistoryStreaks oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dailyGoalStreak != widget.dailyGoalStreak ||
        oldWidget.checkInStreak != widget.checkInStreak ||
        oldWidget.progressPct != widget.progressPct) {
      _streakHeaderAnimController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _streakHeaderAnim,
      builder: (context, _) {
        final animVal = _streakHeaderAnim.value;
        final animatedGoalStreak = (widget.dailyGoalStreak * animVal).round();
        final animatedCheckInStreak = (widget.checkInStreak * animVal).round();
        final animatedProgressPct = widget.progressPct * animVal;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: context.s(4)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildStreakHeaderCard(
                  context,
                  'Daily Goal Streak',
                  animatedGoalStreak,
                  SvgPicture.asset(
                    'assets/fire.svg',
                    width: context.s(22),
                    height: context.s(22),
                  ),
                  widget.accentColor,
                ),
              ),
              SizedBox(width: context.s(8)),
              Expanded(
                child: _buildStreakHeaderCard(
                  context,
                  'Daily Check-in Streak',
                  animatedCheckInStreak,
                  Icon(
                    Icons.check_circle_rounded,
                    color: widget.accentColor,
                    size: context.s(22),
                  ),
                  widget.accentColor,
                ),
              ),
              SizedBox(width: context.s(8)),
              Expanded(
                child: _buildProgressHeaderCard(
                  context,
                  'Daily Goal Completion',
                  animatedProgressPct,
                  widget.accentColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStreakHeaderCard(
    BuildContext context,
    String label,
    int count,
    Widget iconWidget,
    Color accentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            color: context.appColors.textSecondary,
            fontSize: context.s(11),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: context.s(6)),
        Container(
          height: context.s(54),
          decoration: BoxDecoration(
            color: context.appColors.cardBackground,
            borderRadius: BorderRadius.circular(context.s(12)),
            border: Border.all(color: context.appColors.isLight ? context.appColors.borderColor : accentColor.withAlpha(50), width: 1.2),
          ),
          padding: EdgeInsets.symmetric(horizontal: context.s(6)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconWidget,
              SizedBox(width: context.s(6)),
              Text(
                '$count ',
                style: GoogleFonts.orbitron(
                  color: accentColor,
                  fontWeight: FontWeight.w900,
                  fontSize: context.s(16),
                ),
              ),
              Text(
                'DAYS',
                style: GoogleFonts.orbitron(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: context.s(10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressHeaderCard(
    BuildContext context,
    String label,
    double progressPct,
    Color accentColor,
  ) {
    final pctString = '${(progressPct * 100).toStringAsFixed(0)}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            color: context.appColors.textSecondary,
            fontSize: context.s(11),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: context.s(6)),
        Container(
          height: context.s(54),
          decoration: BoxDecoration(
            color: context.appColors.cardBackground,
            borderRadius: BorderRadius.circular(context.s(12)),
            border: Border.all(color: context.appColors.isLight ? context.appColors.borderColor : accentColor.withAlpha(50), width: 1.2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(context.s(11)),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: progressPct.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(200),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    pctString,
                    style: GoogleFonts.orbitron(
                      color: progressPct > 0.5 ? context.appColors.onAccent : context.appColors.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: context.s(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
