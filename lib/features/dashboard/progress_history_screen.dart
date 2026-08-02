import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gateletics/providers/providers.dart';
import '../../utils/ui_scaling.dart';
import '../../database/app_database.dart';

import 'widgets/history/history_calendar.dart';
import 'widgets/history/history_heatmap.dart';
import 'widgets/history/history_graph.dart';
import 'widgets/history/history_streaks.dart';
import 'widgets/history/history_pie_chart.dart';
import 'widgets/history/history_projection.dart';
import '../../utils/demo_keys.dart';

class ProgressHistoryScreen extends ConsumerStatefulWidget {
  const ProgressHistoryScreen({super.key});

  @override
  ConsumerState<ProgressHistoryScreen> createState() => _ProgressHistoryScreenState();
}

class _ProgressHistoryScreenState extends ConsumerState<ProgressHistoryScreen>
    with TickerProviderStateMixin {
  bool _isHeatmapMode = false;
  DateTime _selectedMonth = DateTime.now();
  String _timeframe = 'Weekly'; // 'Weekly' | 'Monthly' | 'Yearly'
  int _heatmapYear = DateTime.now().year;
  late DateTime _selectedWeekStart;
  late int _selectedYear;

  late AnimationController _chartAnimController;
  late AnimationController _calendarDataAnimController;
  late Animation<double> _streakHeaderAnim;
  late Animation<double> _calendarHeatmapAnim;
  late Animation<double> _projectedCompletionAnim;
  late Animation<double> _chartCardAnim;
  late Animation<double> _donutChartAnim;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedWeekStart = now.subtract(Duration(days: now.weekday % 7));
    _selectedYear = now.year;
    _loadPersistedSettings();
    _chartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _calendarDataAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    
    _streakHeaderAnim = CurvedAnimation(
      parent: _chartAnimController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    );
    _calendarHeatmapAnim = CurvedAnimation(
      parent: _chartAnimController,
      curve: const Interval(0.15, 0.6, curve: Curves.easeOutCubic),
    );
    _projectedCompletionAnim = CurvedAnimation(
      parent: _chartAnimController,
      curve: const Interval(0.3, 0.75, curve: Curves.easeOutCubic),
    );
    _chartCardAnim = CurvedAnimation(
      parent: _chartAnimController,
      curve: const Interval(0.45, 0.9, curve: Curves.easeOutCubic),
    );
    _donutChartAnim = CurvedAnimation(
      parent: _chartAnimController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
    );
    _chartAnimController.forward();
    _calendarDataAnimController.forward();
  }

  void _loadPersistedSettings() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      setState(() {
        _isHeatmapMode = prefs.getBool('stats_is_heatmap_mode') ?? false;
      });
    } catch (_) {}
  }

  Future<void> _persistHeatmapMode(bool mode) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool('stats_is_heatmap_mode', mode);
    } catch (_) {}
  }

  @override
  void dispose() {
    _chartAnimController.dispose();
    _calendarDataAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = ref.watch(overallProgressColorProvider);
    final history = ref.watch(dailyHistoryProvider).value ?? [];
    final currentStreak = ref.watch(currentStreakProvider);
    final checkInStreak = ref.watch(checkInStreakProvider);
    final todayFocusSeconds = ref.watch(todayFocusDurationProvider).value ?? 0;
    final dailyGoalMinutes = ref.watch(dailyFocusGoalProvider);
    final categoriesAsync = ref.watch(syllabusCategoriesProvider);
    final projection = ref.watch(projectedCompletionProvider);
    final showProjComp = ref.watch(showProjectedCompletionProvider);
    final accountCreationDateAsync = ref.watch(earliestDataDateProvider);
    final accountCreationDate = accountCreationDateAsync.value ?? DateTime.now();

    final todayGoalSeconds = dailyGoalMinutes * 60;
    final todayProgressPct = todayGoalSeconds == 0 ? 0.0 : (todayFocusSeconds.toDouble() / todayGoalSeconds);

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Statistics',
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: context.s(18),
            letterSpacing: context.s(1.5),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: context.s(12), vertical: context.s(6)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (history.isEmpty) ...[
                _buildEmptyStateCard(context, accentColor),
                SizedBox(height: context.s(16)),
              ],
              _buildAnimatedEntrance(
                animation: _streakHeaderAnim,
                child: SizedBox(
                  key: DemoKeys.statsStreakCard,
                  child: HistoryStreaks(
                    dailyGoalStreak: currentStreak,
                    checkInStreak: checkInStreak,
                    progressPct: todayProgressPct,
                    accentColor: accentColor,
                  ),
                ),
              ),
              SizedBox(height: context.s(16)),

              Center(
                child: FractionallySizedBox(
                  widthFactor: 0.9,
                  child: SizedBox(
                    key: DemoKeys.statsTopButtons,
                    child: _buildSlidingToggle(accentColor),
                  ),
                ),
              ),
              SizedBox(height: context.s(14)),

              _buildAnimatedEntrance(
                animation: _calendarHeatmapAnim,
                child: SizedBox(
                  key: DemoKeys.statsHeatmapCard,
                  child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _isHeatmapMode
                      ? KeyedSubtree(
                          key: ValueKey('heatmap_$_heatmapYear'),
                          child: HistoryHeatmap(
                            heatmapYear: _heatmapYear,
                            animation: _calendarDataAnimController,
                            history: history,
                            dailyGoalMinutes: dailyGoalMinutes,
                            accentColor: accentColor,
                            accountCreationDate: accountCreationDate,
                            onYearChanged: (year) {
                              setState(() {
                                _heatmapYear = year;
                              });
                              _calendarDataAnimController.forward(from: 0.0);
                            },
                            tooltipMessageBuilder: (dateStr, record) => _getTooltipMessage(dateStr, record, dailyGoalMinutes),
                          ),
                        )
                      : KeyedSubtree(
                          key: ValueKey('calendar_${_selectedMonth.year}_${_selectedMonth.month}'),
                          child: HistoryCalendar(
                            selectedMonth: _selectedMonth,
                            animation: _calendarDataAnimController,
                            history: history,
                            dailyGoalMinutes: dailyGoalMinutes,
                            accentColor: accentColor,
                            accountCreationDate: accountCreationDate,
                            onMonthChanged: (month) {
                              setState(() {
                                _selectedMonth = month;
                              });
                              _calendarDataAnimController.forward(from: 0.0);
                            },
                            tooltipMessageBuilder: (dateStr, record) => _getTooltipMessage(dateStr, record, dailyGoalMinutes),
                          ),
                        ),
                ),
                ),
              ),

              if (showProjComp) ...[
                SizedBox(height: context.s(16)),
                _buildAnimatedEntrance(
                  animation: _projectedCompletionAnim,
                  child: SizedBox(
                    key: DemoKeys.statsProjectionCard,
                    child: HistoryProjection(
                      projection: projection,
                      accentColor: accentColor,
                    ),
                  ),
                ),
              ],

              SizedBox(height: context.s(16)),

              _buildAnimatedEntrance(
                animation: _chartCardAnim,
                child: SizedBox(
                  key: DemoKeys.statsChartCard,
                  child: HistoryGraph(
                    timeframe: _timeframe,
                    selectedWeekStart: _selectedWeekStart,
                    selectedMonth: _selectedMonth,
                    selectedYear: _selectedYear,
                    history: history,
                    dailyGoalMinutes: dailyGoalMinutes,
                    accentColor: accentColor,
                    accountCreationDate: accountCreationDate,
                    onTimeframeChanged: (time) {
                      setState(() {
                        _timeframe = time;
                      });
                    },
                    onSelectedWeekStartChanged: (start) {
                      setState(() {
                        _selectedWeekStart = start;
                      });
                    },
                    onSelectedMonthChanged: (month) {
                      setState(() {
                        _selectedMonth = month;
                      });
                    },
                    onSelectedYearChanged: (year) {
                      setState(() {
                        _selectedYear = year;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: context.s(16)),

              Builder(
                builder: (context) {
                  final logsAsync = ref.watch(progressLogsProvider);
                  if (logsAsync.hasError || categoriesAsync.hasError) return const SizedBox();
                  if (!logsAsync.hasValue || !categoriesAsync.hasValue) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final filteredList = getFilteredCategoriesStudy(
                    logsAsync.value!,
                    categoriesAsync.value!,
                  );
                  return _buildAnimatedEntrance(
                    animation: _donutChartAnim,
                    child: HistoryPieChart(
                      categoriesStudy: filteredList,
                      accentColor: accentColor,
                    ),
                  );
                },
              ),

              SizedBox(height: context.s(20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedEntrance({required Widget child, required Animation<double> animation}) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * 15),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildSlidingToggle(Color accentColor) {
    return Container(
      height: context.s(36),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(context.s(18)),
      ),
      padding: EdgeInsets.all(context.s(4)),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: _isHeatmapMode ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(context.s(14)),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_isHeatmapMode) {
                      setState(() => _isHeatmapMode = false);
                      _persistHeatmapMode(false);
                      _calendarDataAnimController.forward(from: 0.0);
                    }
                  },
                  behavior: HitTestBehavior.translucent,
                  child: Center(
                    child: Text(
                      'Calendar',
                      style: GoogleFonts.outfit(
                        color: !_isHeatmapMode ? Colors.black : Colors.white60,
                        fontWeight: FontWeight.bold,
                        fontSize: context.s(12),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!_isHeatmapMode) {
                      setState(() => _isHeatmapMode = true);
                      _persistHeatmapMode(true);
                      _calendarDataAnimController.forward(from: 0.0);
                    }
                  },
                  behavior: HitTestBehavior.translucent,
                  child: Center(
                    child: Text(
                      'Heatmap',
                      style: GoogleFonts.outfit(
                        color: _isHeatmapMode ? Colors.black : Colors.white60,
                        fontWeight: FontWeight.bold,
                        fontSize: context.s(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<CategoryStudyTime> getFilteredCategoriesStudy(
    List<SyllabusProgressLog> logs,
    List<SyllabusCategory> categories,
  ) {
    final Map<int, int> categoryProgressSums = {};
    int totalProgress = 0;

    DateTime startDate;
    DateTime endDate;

    if (_timeframe == 'Weekly') {
      startDate = _selectedWeekStart;
      endDate = _selectedWeekStart.add(const Duration(days: 7));
    } else if (_timeframe == 'Monthly') {
      startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    } else {
      startDate = DateTime(_selectedYear, 1, 1);
      endDate = DateTime(_selectedYear + 1, 1, 1);
    }

    for (final log in logs) {
      if (log.timestamp.compareTo(startDate) >= 0 && log.timestamp.isBefore(endDate)) {
        categoryProgressSums[log.categoryId] = (categoryProgressSums[log.categoryId] ?? 0) + log.delta;
        totalProgress += log.delta;
      }
    }

    final List<CategoryStudyTime> list = [];
    final Map<int, SyllabusCategory> catMap = {for (final c in categories) c.id: c};

    for (final entry in categoryProgressSums.entries) {
      final catId = entry.key;
      final progress = entry.value;
      final pct = totalProgress > 0 ? (progress / totalProgress) * 100 : 0.0;

      final cat = catMap[catId];
      if (cat != null) {
        list.add(CategoryStudyTime(
          id: catId,
          name: cat.name,
          colorValue: cat.color,
          hours: progress.toDouble(),
          percentage: pct,
        ));
      }
    }

    list.sort((a, b) => b.hours.compareTo(a.hours));
    return list;
  }

  String _getTooltipMessage(String dateStr, DailyHistoryData? record, int dailyGoalMinutes) {
    String dateLabel = dateStr;
    try {
      final parsed = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      dateLabel = "${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}";
    } catch (_) {}

    double delta = 0.0;
    int progressOnDay = 0;
    final Map<String, int> catContributions = {};
    try {
      final parsed = DateTime.parse(dateStr);
      final dayStart = DateTime(parsed.year, parsed.month, parsed.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final logs = ref.read(progressLogsProvider).value ?? [];
      final categories = ref.read(syllabusCategoriesProvider).value ?? [];
      final catMap = {for (final c in categories) c.id: c.name};

      for (final log in logs) {
        if (!log.timestamp.isBefore(dayStart) && log.timestamp.isBefore(dayEnd)) {
          progressOnDay += log.delta;
          final catName = catMap[log.categoryId] ?? 'Unknown';
          catContributions[catName] = (catContributions[catName] ?? 0) + log.delta;
        }
      }

      final totalItems = ref.read(completionStatsProvider).value?.total ?? 100;
      delta = totalItems > 0 ? (progressOnDay / totalItems) * 100.0 : 0.0;
    } catch (_) {}

    final deltaPctStr = delta > 0.0 ? "+${delta.toStringAsFixed(1)}% syllabus" : "no progress change";
    final String deltaStr;
    if (progressOnDay > 0) {
      final items = catContributions.entries.map((e) => "${e.key} (+${e.value})").join(', ');
      deltaStr = "$deltaPctStr\nStudied: $items";
    } else {
      deltaStr = deltaPctStr;
    }

    if (record == null || record.totalFocusSeconds == 0) {
      return "$dateLabel\nNo focus sessions recorded\n($deltaStr)";
    }

    final mins = (record.totalFocusSeconds / 60).floor();
    final hrs = mins / 60.0;
    final hrsStr = hrs.toStringAsFixed(1).replaceAll('.0', '');

    final goalMins = (record.targetGoalSeconds / 60).floor();
    final pct = goalMins == 0 ? 0 : ((mins / goalMins) * 100).round();

    if (mins >= goalMins) {
      return "$dateLabel\nFocused for $hrsStr hrs ($pct%)\nGoal Reached | $deltaStr";
    } else {
      return "$dateLabel\nFocused for $hrsStr hrs ($pct%)\nGoal Not Reached | $deltaStr";
    }
  }

  Widget _buildEmptyStateCard(BuildContext context, Color accentColor) {
    return Container(
      padding: EdgeInsets.all(context.s(16)),
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        borderRadius: BorderRadius.circular(context.s(16)),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.track_changes_rounded, size: context.s(32), color: accentColor),
          SizedBox(height: context.s(8)),
          Text(
            'Your Study Journey Starts Here',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: context.s(14),
            ),
          ),
          SizedBox(height: context.s(4)),
          Text(
            'Complete your first focus session or check off a syllabus topic to unlock daily heatmaps, study streaks, and completion analytics!',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: Colors.white60,
              fontSize: context.s(11),
              height: 1.4,
            ),
          ),
          SizedBox(height: context.s(12)),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(shellTabProvider.notifier).state = 2; // Switch to Focus tab
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.s(10))),
              padding: EdgeInsets.symmetric(horizontal: context.s(16), vertical: context.s(8)),
            ),
            icon: Icon(Icons.play_arrow_rounded, size: context.s(16)),
            label: Text(
              'Start Focus Session',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: context.s(12)),
            ),
          ),
        ],
      ),
    );
  }
}
