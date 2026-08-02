import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_context_ext.dart';
import '../../../../utils/ui_scaling.dart';

class HistoryProjection extends StatefulWidget {
  final Map<String, dynamic>? projection;
  final Color accentColor;

  const HistoryProjection({
    super.key,
    required this.projection,
    required this.accentColor,
  });

  @override
  State<HistoryProjection> createState() => _HistoryProjectionState();
}

class _HistoryProjectionState extends State<HistoryProjection> with SingleTickerProviderStateMixin {
  late AnimationController _projectedCompletionAnimController;
  late Animation<double> _projectedCompletionAnim;

  @override
  void initState() {
    super.initState();
    _projectedCompletionAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _projectedCompletionAnim = CurvedAnimation(
      parent: _projectedCompletionAnimController,
      curve: Curves.easeOut,
    );
    _projectedCompletionAnimController.forward();
  }

  @override
  void dispose() {
    _projectedCompletionAnimController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HistoryProjection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projection != widget.projection) {
      _projectedCompletionAnimController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return Container(
      padding: EdgeInsets.all(context.s(14)),
      decoration: BoxDecoration(
        color: context.appColors.cardBackground,
        borderRadius: BorderRadius.circular(context.s(16)),
        border: Border.all(color: widget.accentColor.withAlpha(40)),
      ),
      child: widget.projection == null
          ? Row(
              children: [
                Icon(Icons.auto_graph_rounded, color: context.appColors.textMuted, size: context.s(22)),
                SizedBox(width: context.s(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Projected Completion',
                        style: GoogleFonts.outfit(
                          color: context.appColors.textSecondary,
                          fontSize: context.s(12),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: context.s(2)),
                      Text(
                        'Study for a few more days to unlock your completion forecast',
                        style: GoogleFonts.outfit(
                          color: context.appColors.textMuted,
                          fontSize: context.s(10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : widget.projection!['completed'] == true
              ? Row(
                  children: [
                    Text('🎉', style: TextStyle(fontSize: context.s(24))),
                    SizedBox(width: context.s(10)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Syllabus Complete!',
                          style: GoogleFonts.orbitron(
                            color: widget.accentColor,
                            fontSize: context.s(15),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '100% done — incredible work!',
                          style: GoogleFonts.outfit(
                            color: context.appColors.textSecondary,
                            fontSize: context.s(11),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : _buildProjectionDetails(context, widget.projection!, widget.accentColor, monthNames),
    );
  }

  Widget _buildProjectionDetails(
    BuildContext context,
    Map<String, dynamic> projection,
    Color accentColor,
    List<String> monthNames,
  ) {
    final projectedDate = projection['projectedDate'] as DateTime;
    final daysRemaining = projection['daysRemaining'] as int;
    final currentProgress = projection['currentProgress'] as double;
    final avgDailyGain = projection['avgDailyGain'] as double;
    final confidence = projection['confidence'] as String;

    final confidenceColor = confidence == 'high'
        ? Colors.greenAccent
        : confidence == 'medium'
            ? Colors.amberAccent
            : Colors.orangeAccent;
    final confidenceLabel = confidence == 'high'
        ? 'High confidence'
        : confidence == 'medium'
            ? 'Medium confidence'
            : 'Early estimate';
    final dateStr = '${projectedDate.day} ${monthNames[projectedDate.month - 1]} ${projectedDate.year}';

    return AnimatedBuilder(
      animation: _projectedCompletionAnim,
      builder: (context, _) {
        final val = _projectedCompletionAnim.value;
        final animatedDays = (daysRemaining * val).round();
        final animatedProgress = currentProgress * val;
        final animatedAvgDailyGain = avgDailyGain * val;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Projected Completion',
                  style: GoogleFonts.outfit(
                    color: context.appColors.textSecondary,
                    fontSize: context.s(11),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: context.s(6), vertical: context.s(2)),
                  decoration: BoxDecoration(
                    color: confidenceColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(context.s(4)),
                  ),
                  child: Text(
                    confidenceLabel,
                    style: GoogleFonts.outfit(
                      color: confidenceColor,
                      fontSize: context.s(9),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.s(8)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.flag_rounded, color: accentColor, size: context.s(18)),
                SizedBox(width: context.s(6)),
                Opacity(
                  opacity: val,
                  child: Text(
                    dateStr,
                    style: GoogleFonts.orbitron(
                      color: context.appColors.textPrimary,
                      fontSize: context.s(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.s(10)),
            Row(
              children: [
                _projStat(context, '$animatedDays', 'days left', accentColor),
                SizedBox(width: context.s(20)),
                _projStat(context, '${animatedProgress.toStringAsFixed(1)}%', 'done now', context.appColors.textSecondary),
                SizedBox(width: context.s(20)),
                _projStat(context, '+${animatedAvgDailyGain.toStringAsFixed(1)}', 'tasks/day avg', context.appColors.textSecondary),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _projStat(BuildContext context, String value, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.orbitron(
            color: color,
            fontSize: context.s(12),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: context.appColors.textMuted,
            fontSize: context.s(9),
          ),
        ),
      ],
    );
  }
}
