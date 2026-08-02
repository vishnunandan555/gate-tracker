import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../database/app_database.dart';
import '../../../../core/theme/theme_context_ext.dart';
import 'package:gateletics/providers/providers.dart';
import '../../../../utils/ui_scaling.dart';

class WaveAreaChartPainter extends CustomPainter {
  final List<double> data;
  final List<double>? secondaryData;
  final double goalValue;
  final Color accentColor;
  final int? selectedIndex;
  final List<String> tooltipLabels;
  final double animValue;
  final bool showGoalLine;
  final bool sharpLines;
  final bool disableGlow;
  final List<String> xAxisLabels;
  final String timeframe;
  final DateTime selectedWeekStart;
  final bool isLight;

  WaveAreaChartPainter({
    required this.data,
    this.secondaryData,
    required this.goalValue,
    required this.accentColor,
    this.selectedIndex,
    required this.tooltipLabels,
    this.animValue = 1.0,
    this.showGoalLine = true,
    this.sharpLines = false,
    this.disableGlow = false,
    required this.xAxisLabels,
    required this.timeframe,
    required this.selectedWeekStart,
    this.isLight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final width = size.width;
    final height = size.height;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, width * animValue.clamp(0.0, 1.0), height));

    final colWidth = width / data.length;

    final maxData = data.reduce(max);
    final maxY = maxData > goalValue ? (maxData * 1.15) : (goalValue > 0.0 ? goalValue : 1.0);

    final usableHeight = height - 35;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = (i + 0.5) * colWidth;
      final y = height - (data[i] / (maxY > 0 ? maxY : 1.0)) * usableHeight - 25;
      points.add(Offset(x, y));
    }

    void drawDashedPath(Canvas canvas, Path path, Paint paint, double dashWidth, double dashSpace) {
      for (final PathMetric metric in path.computeMetrics()) {
        double distance = 0.0;
        while (distance < metric.length) {
          final double length = min(dashWidth, metric.length - distance);
          final Path extract = metric.extractPath(distance, distance + length);
          canvas.drawPath(extract, paint);
          distance += dashWidth + dashSpace;
        }
      }
    }

    if (showGoalLine) {
      final yGoal = height - (goalValue / (maxY > 0 ? maxY : 1.0)) * usableHeight - 25;

      final goalPaint = Paint()
        ..color = isLight ? Colors.black.withAlpha(40) : Colors.white.withAlpha(40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;

      double dashWidth = 6.0;
      double dashSpace = 4.0;
      double startX = 0.0;
      while (startX < width) {
        final endX = min(startX + dashWidth, width);
        canvas.drawLine(Offset(startX, yGoal), Offset(endX, yGoal), goalPaint);
        startX += dashWidth + dashSpace;
      }

      final goalLabelPainter = TextPainter(
        text: TextSpan(
          text: 'GOAL',
          style: GoogleFonts.outfit(
            color: isLight ? Colors.black.withAlpha(100) : Colors.white.withAlpha(100),
            fontSize: 8.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      goalLabelPainter.paint(
        canvas,
        Offset(width - goalLabelPainter.width - 2, yGoal - goalLabelPainter.height - 1),
      );
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    if (sharpLines) {
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    } else {
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final controlX1 = p0.dx + colWidth / 3.2;
        final controlX2 = p1.dx - colWidth / 3.2;
        path.cubicTo(controlX1, p0.dy, controlX2, p1.dy, p1.dx, p1.dy);
      }
    }

    final fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, height - 25);
    fillPath.lineTo(points.first.dx, height - 25);
    fillPath.close();

    final fillGradient = LinearGradient(
      colors: [accentColor.withAlpha(45), accentColor.withAlpha(0)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    if (!disableGlow) {
      final shadowPaint2 = Paint()
        ..color = accentColor.withAlpha(60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawPath(path, shadowPaint2);
    }

    final strokePaintAccent = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaintAccent);

    final strokePaintCore = Paint()
      ..color = Colors.white.withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaintCore);

    if (secondaryData != null && secondaryData!.isNotEmpty) {
      final maxSecData = secondaryData!.reduce(max);
      final maxSecY = maxSecData > 0.0 ? maxSecData * 1.15 : 1.0;
      final colWidthSec = width / secondaryData!.length;

      final secondaryPoints = <Offset>[];
      for (int i = 0; i < secondaryData!.length; i++) {
        final x = (i + 0.5) * colWidthSec;
        final y = height - (secondaryData![i] / maxSecY) * usableHeight - 25;
        secondaryPoints.add(Offset(x, y));
      }

      final secondaryPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      final secondaryPath = Path();
      secondaryPath.moveTo(secondaryPoints[0].dx, secondaryPoints[0].dy);

      if (sharpLines) {
        for (int i = 1; i < secondaryPoints.length; i++) {
          secondaryPath.lineTo(secondaryPoints[i].dx, secondaryPoints[i].dy);
        }
      } else {
        for (int i = 0; i < secondaryPoints.length - 1; i++) {
          final p0 = secondaryPoints[i];
          final p1 = secondaryPoints[i + 1];
          final controlX1 = p0.dx + colWidthSec / 3.2;
          final controlX2 = p1.dx - colWidthSec / 3.2;
          secondaryPath.cubicTo(controlX1, p0.dy, controlX2, p1.dy, p1.dx, p1.dy);
        }
      }

      drawDashedPath(canvas, secondaryPath, secondaryPaint, 4.0, 3.0);

      if (secondaryData!.length <= 7) {
        final secDotPaint = Paint()
          ..color = accentColor.withValues(alpha: 0.35)
          ..style = PaintingStyle.fill;
        for (final p in secondaryPoints) {
          canvas.drawCircle(p, 2.0, secDotPaint);
        }
      }
    }

    if (data.length <= 7) {
      final dotPaint = Paint()..color = Colors.white;
      final outerDotPaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.fill;

      for (final p in points) {
        canvas.drawCircle(p, 3.5, outerDotPaint);
        canvas.drawCircle(p, 1.8, dotPaint);
      }
    }

    if (selectedIndex != null && selectedIndex! < points.length) {
      final selectedPoint = points[selectedIndex!];

      final indicatorPaint = Paint()
        ..color = accentColor.withAlpha(80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      double currentY = 0.0;
      double dashHt = 4.0;
      double spaceHt = 3.0;
      while (currentY < height - 25) {
        canvas.drawLine(
          Offset(selectedPoint.dx, currentY),
          Offset(selectedPoint.dx, min(currentY + dashHt, height - 25)),
          indicatorPaint,
        );
        currentY += dashHt + spaceHt;
      }

      final highlightOuterPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final highlightInnerPaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(selectedPoint, 5.5, highlightOuterPaint);
      canvas.drawCircle(selectedPoint, 3.5, highlightInnerPaint);

      if (selectedIndex! < tooltipLabels.length) {
        final tooltipText = tooltipLabels[selectedIndex!];
        final textPainter = TextPainter(
          text: TextSpan(
            text: tooltipText,
            style: GoogleFonts.outfit(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 10.0,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        final bubblePaddingH = 8.0;
        final bubblePaddingV = 4.0;
        final bubbleW = textPainter.width + bubblePaddingH * 2;
        final bubbleH = textPainter.height + bubblePaddingV * 2;

        double bubbleX = selectedPoint.dx - bubbleW / 2;
        bubbleX = bubbleX.clamp(4.0, width - bubbleW - 4.0);

        double bubbleY = selectedPoint.dy - bubbleH - 12.0;
        if (bubbleY < 4.0) {
          bubbleY = selectedPoint.dy + 12.0;
        }

        final bubbleRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(bubbleX, bubbleY, bubbleW, bubbleH),
          const Radius.circular(6.0),
        );

        final bubblePaint = Paint()
          ..color = accentColor
          ..style = PaintingStyle.fill;

        canvas.drawRRect(bubbleRect, bubblePaint);

        textPainter.paint(
          canvas,
          Offset(bubbleX + bubblePaddingH, bubbleY + bubblePaddingV),
        );
      }
    }
    canvas.restore();

    // Draw X-axis labels aligned with data points (outside clipped region)
    final labelPaintColorDefault = isLight ? Colors.black.withAlpha(140) : Colors.white.withAlpha(80);
    for (int i = 0; i < data.length; i++) {
      if (i >= xAxisLabels.length) continue;
      final label = xAxisLabels[i];
      final dayNum = i + 1;
      final showLabel = timeframe != 'Monthly' || (dayNum == 1 || dayNum % 5 == 0 || dayNum == xAxisLabels.length);
      if (!showLabel) continue;

      bool isToday = false;
      if (timeframe == 'Weekly') {
        final date = selectedWeekStart.add(Duration(days: i));
        final now = DateTime.now();
        isToday = now.year == date.year && now.month == date.month && now.day == date.day;
      }

      final labelColor = isToday ? accentColor : labelPaintColorDefault;
      final labelWeight = isToday ? FontWeight.bold : FontWeight.normal;

      final labelPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: GoogleFonts.outfit(
            color: labelColor,
            fontWeight: labelWeight,
            fontSize: 9.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final xOffset = points[i].dx - labelPainter.width / 2;
      final yOffset = height - 14;

      labelPainter.paint(canvas, Offset(xOffset, yOffset));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class HistoryGraph extends ConsumerStatefulWidget {
  final String timeframe;
  final DateTime selectedWeekStart;
  final DateTime selectedMonth;
  final int selectedYear;
  final List<DailyHistoryData> history;
  final int dailyGoalMinutes;
  final Color accentColor;
  final DateTime accountCreationDate;
  
  final ValueChanged<String> onTimeframeChanged;
  final ValueChanged<DateTime> onSelectedWeekStartChanged;
  final ValueChanged<DateTime> onSelectedMonthChanged;
  final ValueChanged<int> onSelectedYearChanged;

  const HistoryGraph({
    super.key,
    required this.timeframe,
    required this.selectedWeekStart,
    required this.selectedMonth,
    required this.selectedYear,
    required this.history,
    required this.dailyGoalMinutes,
    required this.accentColor,
    required this.accountCreationDate,
    required this.onTimeframeChanged,
    required this.onSelectedWeekStartChanged,
    required this.onSelectedMonthChanged,
    required this.onSelectedYearChanged,
  });

  @override
  ConsumerState<HistoryGraph> createState() => _HistoryGraphState();
}

class _HistoryGraphState extends ConsumerState<HistoryGraph> with TickerProviderStateMixin {
  int? _selectedChartIndex;
  late AnimationController _chartDataAnimController;

  @override
  void initState() {
    super.initState();
    _chartDataAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _chartDataAnimController.forward();
  }

  @override
  void dispose() {
    _chartDataAnimController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HistoryGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeframe != widget.timeframe ||
        oldWidget.selectedWeekStart != widget.selectedWeekStart ||
        oldWidget.selectedMonth != widget.selectedMonth ||
        oldWidget.selectedYear != widget.selectedYear) {
      setState(() {
        _selectedChartIndex = null;
      });
      _chartDataAnimController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disableGlow = ref.watch(disableGraphGlowProvider);
    final swapChartLines = ref.watch(swapChartLinesProvider);

    final logsAsync = ref.watch(progressLogsProvider);
    final statsAsync = ref.watch(completionStatsProvider);

    final logs = logsAsync.value ?? [];
    final totalItems = statsAsync.value?.total ?? 100;

    double totalHours = 0.0;
    double totalProgressInc = 0.0;
    List<double> dataPointsHours = [];
    List<double> dataPointsProgress = [];
    List<String> labels = [];

    double getSyllabusProgressDeltaFromLogs(DateTime date, List<SyllabusProgressLog> logs, int totalItems) {
      if (totalItems <= 0) return 0.0;
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));

      int deltaSum = 0;
      for (final l in logs) {
        if (!l.timestamp.isBefore(start) && l.timestamp.isBefore(end)) {
          deltaSum += l.delta;
        }
      }
      return (deltaSum / totalItems) * 100.0;
    }

    double pctChange = 0.0;
    bool isUp = true;
    double currentSum = 0.0;
    double previousSum = 0.0;

    if (widget.timeframe == 'Weekly') {
      double currentHoursSum = 0.0;
      double previousHoursSum = 0.0;
      double currentProgressSum = 0.0;
      double previousProgressSum = 0.0;

      final startOfWeek = widget.selectedWeekStart;
      final prevStartOfWeek = startOfWeek.subtract(const Duration(days: 7));

      for (int i = 0; i < 7; i++) {
        final dCurr = startOfWeek.add(Duration(days: i));
        final dateStrCurr = "${dCurr.year}-${dCurr.month.toString().padLeft(2, '0')}-${dCurr.day.toString().padLeft(2, '0')}";
        final recordCurr = widget.history.firstWhere((h) => h.dateStr == dateStrCurr, orElse: () => DailyHistoryData(dateStr: dateStrCurr, totalFocusSeconds: 0, targetGoalSeconds: widget.dailyGoalMinutes * 60, isGoalCompleted: false, syllabusProgressPct: 0, tasksCompletedTotal: 0));
        currentHoursSum += recordCurr.totalFocusSeconds;
        currentProgressSum += getSyllabusProgressDeltaFromLogs(dCurr, logs, totalItems);

        final dPrev = prevStartOfWeek.add(Duration(days: i));
        final dateStrPrev = "${dPrev.year}-${dPrev.month.toString().padLeft(2, '0')}-${dPrev.day.toString().padLeft(2, '0')}";
        final recordPrev = widget.history.firstWhere((h) => h.dateStr == dateStrPrev, orElse: () => DailyHistoryData(dateStr: dateStrPrev, totalFocusSeconds: 0, targetGoalSeconds: widget.dailyGoalMinutes * 60, isGoalCompleted: false, syllabusProgressPct: 0, tasksCompletedTotal: 0));
        previousHoursSum += recordPrev.totalFocusSeconds;
        previousProgressSum += getSyllabusProgressDeltaFromLogs(dPrev, logs, totalItems);
      }

      currentSum = swapChartLines ? currentProgressSum : currentHoursSum;
      previousSum = swapChartLines ? previousProgressSum : previousHoursSum;

      if (previousSum > 0) {
        pctChange = ((currentSum - previousSum) / previousSum) * 100;
      } else {
        pctChange = currentSum > 0 ? 100.0 : 0.0;
      }
      isUp = pctChange >= 0;

      labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
      for (int i = 0; i < 7; i++) {
        final d = startOfWeek.add(Duration(days: i));
        final dateStr = "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
        final record = widget.history.firstWhere((h) => h.dateStr == dateStr, orElse: () => DailyHistoryData(dateStr: dateStr, totalFocusSeconds: 0, targetGoalSeconds: widget.dailyGoalMinutes * 60, isGoalCompleted: false, syllabusProgressPct: 0, tasksCompletedTotal: 0));
        final hrs = record.totalFocusSeconds / 3600.0;
        dataPointsHours.add(hrs);
        totalHours += hrs;

        final delta = getSyllabusProgressDeltaFromLogs(d, logs, totalItems);
        dataPointsProgress.add(delta);
        totalProgressInc += delta;
      }
    } else if (widget.timeframe == 'Monthly') {
      double currentHoursSum = 0.0;
      double previousHoursSum = 0.0;
      double currentProgressSum = 0.0;
      double previousProgressSum = 0.0;

      for (final h in widget.history) {
        final d = DateTime.tryParse(h.dateStr);
        if (d != null) {
          if (d.year == widget.selectedMonth.year && d.month == widget.selectedMonth.month) {
            currentHoursSum += h.totalFocusSeconds;
          } else {
            final prevMonth = widget.selectedMonth.month == 1
                ? DateTime(widget.selectedMonth.year - 1, 12)
                : DateTime(widget.selectedMonth.year, widget.selectedMonth.month - 1);
            if (d.year == prevMonth.year && d.month == prevMonth.month) {
              previousHoursSum += h.totalFocusSeconds;
            }
          }
        }
      }

      final daysInMonth = DateTime(widget.selectedMonth.year, widget.selectedMonth.month + 1, 0).day;
      for (int d = 1; d <= daysInMonth; d++) {
        final cellDate = DateTime(widget.selectedMonth.year, widget.selectedMonth.month, d);
        currentProgressSum += getSyllabusProgressDeltaFromLogs(cellDate, logs, totalItems);
      }

      final prevMonth = widget.selectedMonth.month == 1
          ? DateTime(widget.selectedMonth.year - 1, 12)
          : DateTime(widget.selectedMonth.year, widget.selectedMonth.month - 1);
      final daysInPrevMonth = DateTime(prevMonth.year, prevMonth.month + 1, 0).day;
      for (int d = 1; d <= daysInPrevMonth; d++) {
        final cellDate = DateTime(prevMonth.year, prevMonth.month, d);
        previousProgressSum += getSyllabusProgressDeltaFromLogs(cellDate, logs, totalItems);
      }

      currentSum = swapChartLines ? currentProgressSum : currentHoursSum;
      previousSum = swapChartLines ? previousProgressSum : previousHoursSum;

      if (previousSum > 0) {
        pctChange = ((currentSum - previousSum) / previousSum) * 100;
      } else {
        pctChange = currentSum > 0 ? 100.0 : 0.0;
      }
      isUp = pctChange >= 0;

      labels = List.generate(daysInMonth, (i) => "${i + 1}");
      for (int d = 1; d <= daysInMonth; d++) {
        final cellDate = DateTime(widget.selectedMonth.year, widget.selectedMonth.month, d);
        final dateStr = "${widget.selectedMonth.year}-${widget.selectedMonth.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}";
        final record = widget.history.firstWhere((h) => h.dateStr == dateStr, orElse: () => DailyHistoryData(dateStr: dateStr, totalFocusSeconds: 0, targetGoalSeconds: widget.dailyGoalMinutes * 60, isGoalCompleted: false, syllabusProgressPct: 0, tasksCompletedTotal: 0));
        final hrs = record.totalFocusSeconds / 3600.0;
        dataPointsHours.add(hrs);
        totalHours += hrs;

        final delta = getSyllabusProgressDeltaFromLogs(cellDate, logs, totalItems);
        dataPointsProgress.add(delta);
        totalProgressInc += delta;
      }
    } else {
      double currentHoursSum = 0.0;
      double previousHoursSum = 0.0;
      double currentProgressSum = 0.0;
      double previousProgressSum = 0.0;

      for (final h in widget.history) {
        final d = DateTime.tryParse(h.dateStr);
        if (d != null) {
          if (d.year == widget.selectedYear) {
            currentHoursSum += h.totalFocusSeconds;
          } else if (d.year == widget.selectedYear - 1) {
            previousHoursSum += h.totalFocusSeconds;
          }
        }
      }

      for (int m = 1; m <= 12; m++) {
        final monthStart = DateTime(widget.selectedYear, m, 1);
        final monthEnd = m == 12 ? DateTime(widget.selectedYear + 1, 1, 1) : DateTime(widget.selectedYear, m + 1, 1);
        int monthDeltaSum = 0;
        for (final l in logs) {
          if (!l.timestamp.isBefore(monthStart) && l.timestamp.isBefore(monthEnd)) {
            monthDeltaSum += l.delta;
          }
        }
        currentProgressSum += totalItems > 0 ? (monthDeltaSum / totalItems) * 100.0 : 0.0;

        final prevYearMonthStart = DateTime(widget.selectedYear - 1, m, 1);
        final prevYearMonthEnd = m == 12 ? DateTime(widget.selectedYear, 1, 1) : DateTime(widget.selectedYear - 1, m + 1, 1);
        int prevYearMonthDeltaSum = 0;
        for (final l in logs) {
          if (!l.timestamp.isBefore(prevYearMonthStart) && l.timestamp.isBefore(prevYearMonthEnd)) {
            prevYearMonthDeltaSum += l.delta;
          }
        }
        previousProgressSum += totalItems > 0 ? (prevYearMonthDeltaSum / totalItems) * 100.0 : 0.0;
      }

      currentSum = swapChartLines ? currentProgressSum : currentHoursSum;
      previousSum = swapChartLines ? previousProgressSum : previousHoursSum;

      if (previousSum > 0) {
        pctChange = ((currentSum - previousSum) / previousSum) * 100;
      } else {
        pctChange = currentSum > 0 ? 100.0 : 0.0;
      }
      isUp = pctChange >= 0;

      labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      for (int m = 1; m <= 12; m++) {
        final monthPrefix = "${widget.selectedYear}-${m.toString().padLeft(2, '0')}";
        final monthSumSeconds = widget.history
            .where((h) => h.dateStr.startsWith(monthPrefix))
            .fold(0, (sum, h) => sum + h.totalFocusSeconds);
        final hrs = monthSumSeconds / 3600.0;
        dataPointsHours.add(hrs);
        totalHours += hrs;

        final monthStart = DateTime(widget.selectedYear, m, 1);
        final monthEnd = m == 12 ? DateTime(widget.selectedYear + 1, 1, 1) : DateTime(widget.selectedYear, m + 1, 1);
        int monthDeltaSum = 0;
        for (final l in logs) {
          if (!l.timestamp.isBefore(monthStart) && l.timestamp.isBefore(monthEnd)) {
            monthDeltaSum += l.delta;
          }
        }
        final delta = totalItems > 0 ? (monthDeltaSum / totalItems) * 100.0 : 0.0;
        dataPointsProgress.add(delta);
        totalProgressInc += delta;
      }
    }

    final List<double> dataPointsPrimary = swapChartLines ? dataPointsProgress : dataPointsHours;
    final List<double> dataPointsSecondary = dataPointsProgress.isEmpty ? [] : (swapChartLines ? dataPointsHours : dataPointsProgress);

    final List<String> tooltipLabels = [];
    if (widget.timeframe == 'Weekly') {
      for (int i = 0; i < 7; i++) {
        final d = widget.selectedWeekStart.add(Duration(days: i));
        final dd = d.day.toString().padLeft(2, '0');
        final mm = d.month.toString().padLeft(2, '0');
        final yy = (d.year % 100).toString().padLeft(2, '0');
        final hrsStr = dataPointsHours[i].toStringAsFixed(1);
        final progressStr = dataPointsProgress[i].toStringAsFixed(1);
        tooltipLabels.add("$dd/$mm/$yy\n$hrsStr hrs | +$progressStr%");
      }
    } else if (widget.timeframe == 'Monthly') {
      for (int i = 0; i < dataPointsHours.length; i++) {
        final d = i + 1;
        final dd = d.toString().padLeft(2, '0');
        final mm = widget.selectedMonth.month.toString().padLeft(2, '0');
        final yy = (widget.selectedMonth.year % 100).toString().padLeft(2, '0');
        final hrsStr = dataPointsHours[i].toStringAsFixed(1);
        final progressStr = dataPointsProgress[i].toStringAsFixed(1);
        tooltipLabels.add("$dd/$mm/$yy\n$hrsStr hrs | +$progressStr%");
      }
    } else {
      for (int i = 0; i < 12; i++) {
        final mm = (i + 1).toString().padLeft(2, '0');
        final yy = (widget.selectedYear % 100).toString().padLeft(2, '0');
        final hrsStr = dataPointsHours[i].toStringAsFixed(1);
        final progressStr = dataPointsProgress[i].toStringAsFixed(1);
        tooltipLabels.add("$mm/$yy\n$hrsStr hrs | +$progressStr%");
      }
    }

    final dailyGoalHours = widget.dailyGoalMinutes / 60.0;
    final referenceGoal = widget.timeframe == 'Yearly' ? (dailyGoalHours * 30.4) : dailyGoalHours;
    final hasData = dataPointsPrimary.any((v) => v > 0) || dataPointsSecondary.any((v) => v > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTimeframeSelector(widget.accentColor),
        SizedBox(height: context.s(12)),
        Container(
          padding: EdgeInsets.all(context.s(12)),
          decoration: BoxDecoration(
            color: context.appColors.cardBackground,
            borderRadius: BorderRadius.circular(context.s(16)),
            border: Border.all(color: Colors.white.withAlpha(8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedBuilder(
                animation: _chartDataAnimController,
                builder: (context, _) {
                  final val = _chartDataAnimController.value;
                  final animatedHours = totalHours * val;
                  final animatedProgressInc = totalProgressInc * val;
                  final animatedPctChange = pctChange * val;
                  final timeframeNoun = widget.timeframe.toLowerCase() == 'weekly'
                      ? 'week'
                      : (widget.timeframe.toLowerCase() == 'monthly' ? 'month' : 'year');

                  final showOnlyUpArrow = previousSum == 0 && currentSum > 0;
                  final showNeutralZero = previousSum == 0 && currentSum == 0;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${animatedHours.toStringAsFixed(1).replaceAll('.0', '')} hrs | +${animatedProgressInc.toStringAsFixed(1)}%',
                            style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: context.s(14),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: context.s(2)),
                          Text(
                            'total this $timeframeNoun',
                            style: GoogleFonts.outfit(
                              color: Colors.white38,
                              fontSize: context.s(11),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (showNeutralZero)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: context.s(8), vertical: context.s(4)),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(12),
                                borderRadius: BorderRadius.circular(context.s(6)),
                              ),
                              child: Text(
                                "0%",
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: context.s(11),
                                ),
                              ),
                            )
                          else if (showOnlyUpArrow)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: context.s(8), vertical: context.s(4)),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withAlpha(20),
                                borderRadius: BorderRadius.circular(context.s(6)),
                              ),
                              child: Icon(
                                Icons.arrow_upward_rounded,
                                color: Colors.greenAccent,
                                size: context.s(12),
                              ),
                            )
                          else
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: context.s(8), vertical: context.s(4)),
                              decoration: BoxDecoration(
                                color: isUp ? Colors.greenAccent.withAlpha(20) : Colors.redAccent.withAlpha(20),
                                borderRadius: BorderRadius.circular(context.s(6)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                    color: isUp ? Colors.greenAccent : Colors.redAccent,
                                    size: context.s(12),
                                  ),
                                  SizedBox(width: context.s(4)),
                                  Text(
                                    "${animatedPctChange.abs().toStringAsFixed(0)}%",
                                    style: GoogleFonts.outfit(
                                      color: isUp ? Colors.greenAccent : Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: context.s(11),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(height: context.s(4)),
                          Text(
                            "vs last $timeframeNoun",
                            style: GoogleFonts.outfit(
                              color: Colors.white38,
                              fontSize: context.s(10),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: context.s(16)),
              LayoutBuilder(
                builder: (context, constraints) {
                  final chartWidth = constraints.maxWidth;
                  return GestureDetector(
                    onTapDown: (details) {
                      final colWidth = chartWidth / dataPointsPrimary.length;
                      final index = (details.localPosition.dx / colWidth).floor().clamp(0, dataPointsPrimary.length - 1);
                      setState(() {
                        if (_selectedChartIndex == index) {
                          _selectedChartIndex = null;
                        } else {
                          _selectedChartIndex = index;
                        }
                      });
                    },
                    child: AnimatedBuilder(
                      animation: _chartDataAnimController,
                      builder: (context, _) {
                        return SizedBox(
                          height: context.s(120),
                          child: hasData
                              ? CustomPaint(
                                  painter: WaveAreaChartPainter(
                                    data: dataPointsPrimary,
                                    secondaryData: dataPointsSecondary,
                                    goalValue: referenceGoal,
                                    accentColor: widget.accentColor,
                                    selectedIndex: _selectedChartIndex,
                                    tooltipLabels: tooltipLabels,
                                    animValue: _chartDataAnimController.value,
                                    showGoalLine: widget.timeframe != 'Yearly' && !swapChartLines,
                                    sharpLines: false,
                                    disableGlow: disableGlow,
                                    xAxisLabels: labels,
                                    timeframe: widget.timeframe,
                                    selectedWeekStart: widget.selectedWeekStart,
                                    isLight: context.appColors.scaffoldBackground.computeLuminance() > 0.5,
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    'No data found',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white30,
                                      fontSize: context.s(13),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                        );
                      },
                    ),
                  );
                },
              ),
              SizedBox(height: context.s(8)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: context.s(14),
                        height: context.s(3),
                        decoration: BoxDecoration(
                          color: widget.accentColor,
                          borderRadius: BorderRadius.circular(context.s(1.5)),
                        ),
                      ),
                      SizedBox(width: context.s(6)),
                      Text(
                        swapChartLines ? "Syllabus Progress (+%)" : "Focused Hours",
                        style: GoogleFonts.outfit(
                          color: Colors.white60,
                          fontSize: context.s(9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: context.s(20)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (index) {
                          return Container(
                            width: context.s(4),
                            height: context.s(2),
                            margin: EdgeInsets.symmetric(horizontal: context.s(1)),
                            decoration: BoxDecoration(
                              color: widget.accentColor.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(context.s(1)),
                            ),
                          );
                        }),
                      ),
                      SizedBox(width: context.s(6)),
                      Text(
                        swapChartLines ? "Focused Hours" : "Syllabus Progress (+%)",
                        style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: context.s(9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: context.s(12)),
        _buildGraphPaginationRow(widget.accentColor, widget.accountCreationDate, widget.history),
      ],
    );
  }

  Widget _buildTimeframeSelector(Color accentColor) {
    Alignment alignment = Alignment.center;
    if (widget.timeframe == 'Weekly') {
      alignment = Alignment.centerLeft;
    } else if (widget.timeframe == 'Yearly') {
      alignment = Alignment.centerRight;
    }

    return Container(
      height: context.s(32),
      decoration: BoxDecoration(
        color: context.appColors.cardBackground,
        borderRadius: BorderRadius.circular(context.s(8)),
        border: Border.all(color: Colors.white.withAlpha(6)),
      ),
      padding: EdgeInsets.all(context.s(2)),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: alignment,
            child: FractionallySizedBox(
              widthFactor: 0.33,
              child: Container(
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(context.s(6)),
                ),
              ),
            ),
          ),
          Row(
            children: ['Weekly', 'Monthly', 'Yearly'].map((time) {
              final isSel = widget.timeframe == time;
              return Expanded(
                child: GestureDetector(
                  onTap: () => widget.onTimeframeChanged(time),
                  behavior: HitTestBehavior.translucent,
                  child: Center(
                    child: Text(
                      time,
                      style: GoogleFonts.outfit(
                        color: isSel ? Colors.black : Colors.white60,
                        fontWeight: FontWeight.bold,
                        fontSize: context.s(11),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphPaginationRow(Color accentColor, DateTime accountCreationDate, List<DailyHistoryData> history) {
    final now = DateTime.now();
    String infoText = '';
    bool isNotCurrent = false;
    bool canGoPrev = false;
    bool canGoNext = false;

    if (widget.timeframe == 'Weekly') {
      infoText = _getWeekInfoString(widget.selectedWeekStart);
      final currentWeekStart = now.subtract(Duration(days: now.weekday % 7));
      final currentWeekClean = DateTime(currentWeekStart.year, currentWeekStart.month, currentWeekStart.day);
      final selectedWeekClean = DateTime(widget.selectedWeekStart.year, widget.selectedWeekStart.month, widget.selectedWeekStart.day);
      isNotCurrent = !selectedWeekClean.isAtSameMomentAs(currentWeekClean);
      canGoPrev = _canGoToPreviousWeek(accountCreationDate);
      canGoNext = _canGoToNextWeek();
    } else if (widget.timeframe == 'Monthly') {
      final monthNamesLong = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      infoText = "${monthNamesLong[widget.selectedMonth.month - 1]} | ${widget.selectedMonth.year}";
      isNotCurrent = widget.selectedMonth.year != now.year || widget.selectedMonth.month != now.month;
      canGoPrev = _canGoToPreviousMonth(accountCreationDate);
      canGoNext = _canGoToNextMonth();
    } else {
      infoText = "${widget.selectedYear}";
      isNotCurrent = widget.selectedYear != now.year;
      canGoPrev = _canGoToPreviousYear(accountCreationDate);
      canGoNext = _canGoToNextYear();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: canGoPrev ? () => _goToPrevSet(accountCreationDate) : null,
          child: Container(
            width: context.s(32),
            height: context.s(32),
            decoration: BoxDecoration(
              color: canGoPrev ? Colors.white.withAlpha(12) : Colors.white.withAlpha(4),
              shape: BoxShape.circle,
              border: Border.all(
                color: canGoPrev ? Colors.white.withAlpha(8) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Icon(
              Icons.chevron_left_rounded,
              size: context.s(20),
              color: canGoPrev ? accentColor : Colors.white24,
            ),
          ),
        ),
        SizedBox(width: context.s(12)),
        GestureDetector(
          onLongPress: () => _showPeriodSelectionDialog(context, history),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: context.s(16), vertical: context.s(6)),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(8),
              borderRadius: BorderRadius.circular(context.s(8)),
              border: Border.all(color: Colors.white.withAlpha(8)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  infoText,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: context.s(11),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isNotCurrent) ...[
                  SizedBox(width: context.s(8)),
                  GestureDetector(
                    onTap: _resetToCurrentPeriod,
                    child: Icon(
                      Icons.restore_rounded,
                      color: accentColor,
                      size: context.s(14),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(width: context.s(12)),
        GestureDetector(
          onTap: canGoNext ? _goToNextSet : null,
          child: Container(
            width: context.s(32),
            height: context.s(32),
            decoration: BoxDecoration(
              color: canGoNext ? Colors.white.withAlpha(12) : Colors.white.withAlpha(4),
              shape: BoxShape.circle,
              border: Border.all(
                color: canGoNext ? Colors.white.withAlpha(8) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              size: context.s(20),
              color: canGoNext ? accentColor : Colors.white24,
            ),
          ),
        ),
      ],
    );
  }

  String _getWeekInfoString(DateTime weekStart) {
    int sundayCount = 0;
    DateTime temp = DateTime(weekStart.year, weekStart.month, 1);
    while (temp.isBefore(weekStart) || temp.isAtSameMomentAs(weekStart)) {
      if (temp.weekday == DateTime.sunday) {
        sundayCount++;
      }
      temp = temp.add(const Duration(days: 1));
    }
    final monthNamesShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthName = monthNamesShort[weekStart.month - 1];
    return "Week $sundayCount | $monthName | ${weekStart.year}";
  }

  bool _canGoToNextWeek() {
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday % 7));
    final currentWeekClean = DateTime(currentWeekStart.year, currentWeekStart.month, currentWeekStart.day);
    final selectedWeekClean = DateTime(widget.selectedWeekStart.year, widget.selectedWeekStart.month, widget.selectedWeekStart.day);
    return selectedWeekClean.isBefore(currentWeekClean);
  }

  bool _canGoToNextMonth() {
    final now = DateTime.now();
    return widget.selectedMonth.year < now.year || (widget.selectedMonth.year == now.year && widget.selectedMonth.month < now.month);
  }

  bool _canGoToNextYear() {
    final now = DateTime.now();
    return widget.selectedYear < now.year;
  }

  bool _canGoToPreviousWeek(DateTime accountCreationDate) {
    final prevWeekStart = widget.selectedWeekStart.subtract(const Duration(days: 7));
    final creationWeekStart = accountCreationDate.subtract(Duration(days: accountCreationDate.weekday % 7));
    final prevWeekClean = DateTime(prevWeekStart.year, prevWeekStart.month, prevWeekStart.day);
    final creationWeekClean = DateTime(creationWeekStart.year, creationWeekStart.month, creationWeekStart.day);
    return prevWeekClean.isAtSameMomentAs(creationWeekClean) || prevWeekClean.isAfter(creationWeekClean);
  }

  bool _canGoToPreviousMonth(DateTime accountCreationDate) {
    final prevMonth = widget.selectedMonth.month == 1
        ? DateTime(widget.selectedMonth.year - 1, 12)
        : DateTime(widget.selectedMonth.year, widget.selectedMonth.month - 1);
    return prevMonth.year > accountCreationDate.year ||
        (prevMonth.year == accountCreationDate.year && prevMonth.month >= accountCreationDate.month);
  }

  bool _canGoToPreviousYear(DateTime accountCreationDate) {
    final prevYear = widget.selectedYear - 1;
    return prevYear >= accountCreationDate.year;
  }

  void _goToPrevSet(DateTime accountCreationDate) {
    if (widget.timeframe == 'Weekly') {
      if (_canGoToPreviousWeek(accountCreationDate)) {
        widget.onSelectedWeekStartChanged(widget.selectedWeekStart.subtract(const Duration(days: 7)));
      }
    } else if (widget.timeframe == 'Monthly') {
      if (_canGoToPreviousMonth(accountCreationDate)) {
        widget.onSelectedMonthChanged(widget.selectedMonth.month == 1
            ? DateTime(widget.selectedMonth.year - 1, 12)
            : DateTime(widget.selectedMonth.year, widget.selectedMonth.month - 1));
      }
    } else {
      if (_canGoToPreviousYear(accountCreationDate)) {
        widget.onSelectedYearChanged(widget.selectedYear - 1);
      }
    }
  }

  void _goToNextSet() {
    if (widget.timeframe == 'Weekly') {
      if (_canGoToNextWeek()) {
        widget.onSelectedWeekStartChanged(widget.selectedWeekStart.add(const Duration(days: 7)));
      }
    } else if (widget.timeframe == 'Monthly') {
      if (_canGoToNextMonth()) {
        widget.onSelectedMonthChanged(widget.selectedMonth.month == 12
            ? DateTime(widget.selectedMonth.year + 1, 1)
            : DateTime(widget.selectedMonth.year, widget.selectedMonth.month + 1));
      }
    } else {
      if (_canGoToNextYear()) {
        widget.onSelectedYearChanged(widget.selectedYear + 1);
      }
    }
  }

  void _showPeriodSelectionDialog(BuildContext context, List<DailyHistoryData> history) {
    final now = DateTime.now();
    final years = <int>{now.year};
    for (final h in history) {
      if (h.totalFocusSeconds > 0) {
        final d = DateTime.tryParse(h.dateStr);
        if (d != null) {
          years.add(d.year);
        }
      }
    }
    final sortedYears = years.toList()..sort((a, b) => b.compareTo(a));

    int selectedY = widget.timeframe == 'Yearly' ? widget.selectedYear : (widget.timeframe == 'Monthly' ? widget.selectedMonth.year : widget.selectedWeekStart.year);
    int selectedM = widget.timeframe == 'Yearly' ? 1 : (widget.timeframe == 'Monthly' ? widget.selectedMonth.month : widget.selectedWeekStart.month);

    int selectedW = 1;
    if (widget.timeframe == 'Weekly') {
      final info = _getWeekInfoString(widget.selectedWeekStart);
      final match = RegExp(r'Week (\d+)').firstMatch(info);
      if (match != null) {
        selectedW = int.parse(match.group(1)!);
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF131316),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.s(16)),
                side: BorderSide(color: Colors.white.withAlpha(8)),
              ),
              title: Text(
                'Jump to Period',
                style: GoogleFonts.orbitron(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: context.s(14),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Year:', style: TextStyle(color: context.appColors.textSecondary, fontSize: context.s(12))),
                      DropdownButton<int>(
                        value: selectedY,
                        dropdownColor: context.appColors.surfaceColor,
                        style: TextStyle(color: context.appColors.textPrimary, fontSize: context.s(12)),
                        onChanged: (y) {
                          if (y != null) {
                            setDialogState(() {
                              selectedY = y;
                            });
                          }
                        },
                        items: sortedYears.map((y) {
                          return DropdownMenuItem<int>(
                            value: y,
                            child: Text('$y'),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  if (widget.timeframe != 'Yearly') ...[
                    SizedBox(height: context.s(8)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Month:', style: TextStyle(color: Colors.white70, fontSize: context.s(12))),
                        DropdownButton<int>(
                          value: selectedM,
                          dropdownColor: const Color(0xFF1E1E22),
                          style: TextStyle(color: Colors.white, fontSize: context.s(12)),
                          onChanged: (m) {
                            if (m != null) {
                              setDialogState(() {
                                selectedM = m;
                              });
                            }
                          },
                          items: List.generate(12, (i) => i + 1).map((m) {
                            final monthNames = [
                              'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                            ];
                            return DropdownMenuItem<int>(
                              value: m,
                              child: Text(monthNames[m - 1]),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                  if (widget.timeframe == 'Weekly') ...[
                    SizedBox(height: context.s(8)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Week:', style: TextStyle(color: Colors.white70, fontSize: context.s(12))),
                        DropdownButton<int>(
                          value: selectedW,
                          dropdownColor: const Color(0xFF1E1E22),
                          style: TextStyle(color: Colors.white, fontSize: context.s(12)),
                          onChanged: (w) {
                            if (w != null) {
                              setDialogState(() {
                                selectedW = w;
                              });
                            }
                          },
                          items: List.generate(5, (i) => i + 1).map((w) {
                            return DropdownMenuItem<int>(
                              value: w,
                              child: Text('Week $w'),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Cancel', style: TextStyle(color: Colors.white30, fontSize: context.s(12))),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
                TextButton(
                  child: Text('Go', style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.bold, fontSize: context.s(12))),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _applySelectedPeriod(selectedY, selectedM, selectedW);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _applySelectedPeriod(int year, int month, int week) {
    if (widget.timeframe == 'Weekly') {
      final sun = _getSundayForWeek(year, month, week);
      widget.onSelectedWeekStartChanged(sun);
    } else if (widget.timeframe == 'Monthly') {
      widget.onSelectedMonthChanged(DateTime(year, month));
    } else {
      widget.onSelectedYearChanged(year);
    }
  }

  void _resetToCurrentPeriod() {
    final now = DateTime.now();
    widget.onSelectedWeekStartChanged(now.subtract(Duration(days: now.weekday % 7)));
    widget.onSelectedMonthChanged(DateTime(now.year, now.month));
    widget.onSelectedYearChanged(now.year);
  }

  DateTime _getSundayForWeek(int year, int month, int weekNum) {
    DateTime temp = DateTime(year, month, 1);
    while (temp.weekday != DateTime.sunday) {
      temp = temp.add(const Duration(days: 1));
    }
    final targetSunday = temp.add(Duration(days: (weekNum - 1) * 7));
    if (targetSunday.month != month) {
      DateTime lastDay = DateTime(year, month + 1, 0);
      while (lastDay.weekday != DateTime.sunday) {
        lastDay = lastDay.subtract(const Duration(days: 1));
      }
      return lastDay;
    }
    return targetSunday;
  }
}
