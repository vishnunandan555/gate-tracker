import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme_context_ext.dart';
import '../../../database/backup_service.dart';
import 'package:gateletics/providers/providers.dart';

class SyncOptimizationScreen extends ConsumerStatefulWidget {
  final Color accentColor;

  const SyncOptimizationScreen({
    super.key,
    this.accentColor = const Color(0xFF00E5FF),
  });

  @override
  ConsumerState<SyncOptimizationScreen> createState() => _SyncOptimizationScreenState();
}

class _SyncOptimizationScreenState extends ConsumerState<SyncOptimizationScreen> {
  bool _initialized = false;
  late bool _syncStatsEnabled;
  late bool _syncCompressed;
  int? _selectedPruneDays; // null, 365, or 180

  bool _isCurrentExpanded = false;
  bool _isAfterExpanded = false;

  bool _isApplying = false;
  bool _isSuccess = false;

  Map<String, dynamic>? _rawData;

  @override
  void initState() {
    super.initState();
    _loadRawData();
  }

  Future<void> _loadRawData() async {
    final notifier = ref.read(syncProvider.notifier);
    final data = await notifier.exportLocalData();
    if (mounted) {
      setState(() {
        _rawData = data;
        _syncStatsEnabled = ref.read(syncStatsEnabledProvider);
        _syncCompressed = ref.read(syncCompressedProvider);
        _initialized = true;
      });
    }
  }

  // Calculate current payload size
  double _calculateCurrentKb(Map<String, dynamic> raw) {
    final encoded = encodeSyncPayload(
      raw,
      syncStatsEnabled: ref.read(syncStatsEnabledProvider),
      forceCompression: ref.read(syncCompressedProvider),
      historyPrunedBefore: ref.read(historyPrunedBeforeProvider),
    );
    if (encoded['compressed'] == true) {
      return (encoded['data'] as String).length / 1024.0;
    } else {
      return utf8.encode(jsonEncode(encoded['data'])).length / 1024.0;
    }
  }

  // Calculate projected payload size under selected options
  double _calculateProjected(Map<String, dynamic> raw) {
    DateTime? cutoff;
    if (_syncStatsEnabled && _selectedPruneDays != null) {
      cutoff = DateTime.now().subtract(Duration(days: _selectedPruneDays!));
    }

    final encoded = encodeSyncPayload(
      raw,
      syncStatsEnabled: _syncStatsEnabled,
      forceCompression: _syncCompressed,
      historyPrunedBefore: cutoff,
    );

    if (encoded['compressed'] == true) {
      return (encoded['data'] as String).length / 1024.0;
    } else {
      return utf8.encode(jsonEncode(encoded['data'])).length / 1024.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _rawData == null) {
      return Scaffold(
        backgroundColor: context.appColors.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: context.appColors.scaffoldBackground,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: context.appColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Cloud Sync Optimization',
            style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        body: Center(child: CircularProgressIndicator(color: context.appColors.primaryAccent)),
      );
    }

    final raw = _rawData!;
    final currentKb = _calculateCurrentKb(raw);
    final currentPct = (currentKb / 1024.0) * 100.0;
    final isCurrentWarning = currentKb >= 800;

    final projectedKb = _calculateProjected(raw);
    final projectedPct = (projectedKb / 1024.0) * 100.0;
    final isProjectedWarning = projectedKb >= 800;

    final savedKb = (currentKb - projectedKb).clamp(0.0, double.infinity);
    final savedPct = currentKb > 0 ? ((savedKb / currentKb) * 100.0) : 0.0;

    final bool hasSavings = savedKb > 0.05;
    final String badgeText = hasSavings
        ? 'SAVED ${savedKb.toStringAsFixed(1)} KB (${savedPct.toStringAsFixed(0)}%)'
        : (_selectedPruneDays != null && _syncStatsEnabled)
            ? 'NO DATA TO PRUNE'
            : 'NO CHANGE';
    final Color badgeColor = hasSavings
        ? Colors.greenAccent
        : (_selectedPruneDays != null && _syncStatsEnabled)
            ? Colors.amberAccent
            : Colors.white54;

    return Scaffold(
      backgroundColor: context.appColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.appColors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.appColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Cloud Sync Optimization',
          style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. CURRENT STORAGE CARD (Expandable) ──
            _buildCardHeader('1. Current Cloud Payload Status'),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => setState(() => _isCurrentExpanded = !_isCurrentExpanded),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCurrentWarning
                      ? Colors.amber.withValues(alpha: 0.1)
                      : context.appColors.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCurrentWarning ? Colors.amber.withValues(alpha: 0.5) : context.appColors.borderColor,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCurrentWarning ? Icons.warning_amber_rounded : Icons.cloud_done_rounded,
                          color: isCurrentWarning ? Colors.amberAccent : widget.accentColor,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isCurrentWarning ? 'Optimization Required' : 'Cloud Storage Optimal',
                            style: GoogleFonts.outfit(
                              color: isCurrentWarning ? Colors.amberAccent : context.appColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: isCurrentWarning
                                ? Colors.amberAccent.withValues(alpha: 0.2)
                                : widget.accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isCurrentWarning ? 'STATUS: HIGH' : 'STATUS: OK',
                            style: GoogleFonts.outfit(
                              color: isCurrentWarning ? Colors.amberAccent : widget.accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          _isCurrentExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: context.appColors.textSecondary,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (currentKb / 1024.0).clamp(0.0, 1.0),
                        backgroundColor: context.appColors.surfaceColor,
                        color: isCurrentWarning ? Colors.amberAccent : widget.accentColor,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${currentKb.toStringAsFixed(1)} KB / 1024 KB limit',
                          style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 12),
                        ),
                        Text(
                          '${currentPct.toStringAsFixed(1)}% Used',
                          style: GoogleFonts.outfit(
                            color: isCurrentWarning ? Colors.amberAccent : widget.accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    // Expanded Section Breakdown
                    if (_isCurrentExpanded) ...[
                      Divider(color: context.appColors.dividerColor, height: 24),
                      Text(
                        'Payload Data Breakdown',
                        style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      ..._buildGranularBreakdownList(raw, isProjected: false),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildMiniTag('Stats Sync: ${ref.read(syncStatsEnabledProvider) ? "ON" : "OFF"}'),
                          const SizedBox(width: 6),
                          _buildMiniTag('Compression: ${ref.read(syncCompressedProvider) ? "ON" : "OFF"}'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── 2. OPTIMIZATION OPTIONS SECTION ──
            _buildCardHeader('2. Select Optimization Controls'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
              decoration: BoxDecoration(
                color: context.appColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.appColors.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Option 1: Sync Passive Information
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    value: _syncStatsEnabled,
                    activeThumbColor: widget.accentColor,
                    onChanged: (val) {
                      setState(() {
                        _syncStatsEnabled = val;
                        // Clear prune selection if passive stats sync is disabled
                        if (!val) {
                          _selectedPruneDays = null;
                        }
                      });
                    },
                    title: Text(
                      'Sync Passive Data',
                      style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Syncs study sessions, daily logs & timeline history',
                      style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 11),
                    ),
                  ),
                  Divider(color: context.appColors.dividerColor, height: 16),

                  // Option 2: Enable Compression
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    value: _syncCompressed,
                    activeThumbColor: widget.accentColor,
                    onChanged: (val) {
                      setState(() => _syncCompressed = val);
                    },
                    title: Text(
                      'Enable Payload GZip Compression',
                      style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Reduces cloud payload size by ~80% using GZip Base64',
                      style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 11),
                    ),
                  ),
                  Divider(color: context.appColors.dividerColor, height: 16),

                  // Option 3: Prune History Buttons
                  Text(
                    'Historical Data Pruning',
                    style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _syncStatsEnabled
                        ? 'Select a cutoff to prune older focus sessions & history logs:'
                        : 'Pruning options disabled because Passive Statistics Syncing is turned OFF.',
                    style: GoogleFonts.outfit(
                      color: _syncStatsEnabled ? context.appColors.textSecondary : context.appColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _buildPruneButton(
                          title: 'Keep Past 1 Year',
                          subtitle: 'Prune >365 days old',
                          days: 365,
                          enabled: _syncStatsEnabled,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildPruneButton(
                          title: 'Keep Past 6 Months',
                          subtitle: 'Prune >180 days old',
                          days: 180,
                          enabled: _syncStatsEnabled,
                        ),
                      ),
                    ],
                  ),
                  if (_syncStatsEnabled && _selectedPruneDays != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amberAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.amberAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Warning: all historical data before ${_formatCutoffDate(DateTime.now().subtract(Duration(days: _selectedPruneDays!)))} will be deleted',
                              style: GoogleFonts.outfit(
                                color: Colors.amberAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── 3. OPTIMIZED AFTER STORAGE CARD (Expandable) ──
            _buildCardHeader('3. Optimized Storage Payload (After Changes)'),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => setState(() => _isAfterExpanded = !_isAfterExpanded),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isProjectedWarning
                      ? Colors.amber.withValues(alpha: 0.1)
                      : widget.accentColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isProjectedWarning ? Colors.amberAccent : widget.accentColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isProjectedWarning ? Icons.warning_amber_rounded : Icons.auto_awesome_rounded,
                          color: isProjectedWarning ? Colors.amberAccent : widget.accentColor,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Optimized Payload Preview',
                            style: GoogleFonts.outfit(
                              color: isProjectedWarning ? Colors.amberAccent : context.appColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badgeText,
                            style: GoogleFonts.outfit(
                              color: badgeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          _isAfterExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: context.appColors.textSecondary,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (projectedKb / 1024.0).clamp(0.0, 1.0),
                        backgroundColor: context.appColors.surfaceColor,
                        color: widget.accentColor,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${projectedKb.toStringAsFixed(1)} KB / 1024 KB limit',
                          style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 12),
                        ),
                        Text(
                          '${projectedPct.toStringAsFixed(1)}% Used',
                          style: GoogleFonts.outfit(
                            color: widget.accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    // Expanded Section Breakdown
                    if (_isAfterExpanded) ...[
                      Divider(color: context.appColors.dividerColor, height: 24),
                      Text(
                        'Optimized Payload Breakdown',
                        style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      ..._buildGranularBreakdownList(raw, isProjected: true),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildMiniTag('Stats Sync: ${_syncStatsEnabled ? "ON" : "OFF"}'),
                          const SizedBox(width: 6),
                          _buildMiniTag('Compression: ${_syncCompressed ? "ON" : "OFF"}'),
                          if (_selectedPruneDays != null) ...[
                            const SizedBox(width: 6),
                            _buildMiniTag('Pruned: >$_selectedPruneDays days'),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── 4. CONFIRM & EXECUTE BUTTON ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: (_isApplying || _isSuccess) ? null : _executeOptimizationFlow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSuccess ? Colors.green : widget.accentColor,
                  foregroundColor: context.appColors.onAccent,
                  disabledBackgroundColor: _isSuccess ? Colors.green : Colors.grey.shade800,
                  disabledForegroundColor: _isSuccess ? Colors.white : Colors.white38,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                icon: Icon(
                  _isSuccess
                      ? Icons.check_circle_rounded
                      : _isApplying
                          ? Icons.hourglass_top_rounded
                          : Icons.rocket_launch_rounded,
                  size: 20,
                ),
                label: Text(
                  _isSuccess
                      ? '✓ Changes Successfully Implemented'
                      : _isApplying
                          ? 'Applying Changes & Syncing...'
                          : 'Apply Optimization & Sync',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
    );
  }

  Widget _buildBreakdownItem({
    required String title,
    required String subtitle,
    required String sizeText,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            sizeText,
            style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }

  double _computeSectionKb(dynamic data, {bool compress = false}) {
    if (data == null) return 0.0;
    final jsonStr = jsonEncode(data);
    final jsonBytes = utf8.encode(jsonStr);

    if (compress && jsonBytes.isNotEmpty) {
      final compressedBytes = GZipEncoder().encode(jsonBytes);
      if (compressedBytes != null) {
        final base64Str = base64Encode(compressedBytes);
        return utf8.encode(base64Str).length / 1024.0;
      }
    }
    return jsonBytes.length / 1024.0;
  }

  List<Widget> _buildGranularBreakdownList(Map<String, dynamic> raw, {bool isProjected = false}) {
    final categories = (raw['syllabusCategories'] as List?) ?? [];
    final topics = (raw['syllabusTopics'] as List?) ?? [];
    final tasks = (raw['syllabusTasks'] as List?) ?? [];
    final customTasks = (raw['customTasks'] as List?) ?? [];

    List focusSessions = (raw['focusSessions'] as List?) ?? [];
    List dailyHistory = (raw['dailyHistory'] as List?) ?? [];
    List progressLogs = (raw['syllabusProgressLogs'] as List?) ?? [];

    if (isProjected && _syncStatsEnabled && _selectedPruneDays != null) {
      final cutoff = DateTime.now().subtract(Duration(days: _selectedPruneDays!));
      focusSessions = focusSessions.where((s) {
        if (s is Map && s['startTime'] != null) {
          final dt = DateTime.tryParse(s['startTime'].toString());
          return dt != null && dt.isAfter(cutoff);
        }
        return true;
      }).toList();

      dailyHistory = dailyHistory.where((h) {
        if (h is Map && h['dateStr'] != null) {
          final dt = DateTime.tryParse(h['dateStr'].toString());
          return dt != null && dt.isAfter(cutoff);
        }
        return true;
      }).toList();

      progressLogs = progressLogs.where((p) {
        if (p is Map && p['timestamp'] != null) {
          final dt = DateTime.tryParse(p['timestamp'].toString());
          return dt != null && dt.isAfter(cutoff);
        }
        return true;
      }).toList();
    }

    final bool compress = isProjected ? _syncCompressed : ref.read(syncCompressedProvider);

    final catsTopicsKb = _computeSectionKb({
      'syllabusCategories': categories,
      'syllabusTopics': topics,
    }, compress: compress);

    final tasksKb = _computeSectionKb({
      'syllabusTasks': tasks,
      'customTasks': customTasks,
    }, compress: compress);

    int resourceCount = 0;
    List<Map<String, dynamic>> resourceItems = [];
    for (final t in topics) {
      if (t is Map) {
        final note = t['note']?.toString() ?? '';
        final url = t['url']?.toString() ?? '';
        final res = t['resourceData']?.toString() ?? '';
        if (note.isNotEmpty || url.isNotEmpty || res.isNotEmpty) {
          resourceCount++;
          resourceItems.add({'note': note, 'url': url, 'resourceData': res});
        }
      }
    }

    final resourcesKb = _computeSectionKb(resourceItems, compress: compress);

    final focusSessionsKb = (isProjected && !_syncStatsEnabled)
        ? 0.0
        : _computeSectionKb({'focusSessions': focusSessions}, compress: compress);

    final dailyHistoryKb = (isProjected && !_syncStatsEnabled)
        ? 0.0
        : _computeSectionKb({'dailyHistory': dailyHistory}, compress: compress);

    final progressLogsKb = (isProjected && !_syncStatsEnabled)
        ? 0.0
        : _computeSectionKb({'syllabusProgressLogs': progressLogs}, compress: compress);

    return [
      _buildBreakdownItem(
        title: 'Syllabus Categories & Topics',
        subtitle: '${categories.length} Categories • ${topics.length} Topics',
        sizeText: '${catsTopicsKb.toStringAsFixed(1)} KB',
        icon: Icons.category_rounded,
        color: widget.accentColor,
      ),
      _buildBreakdownItem(
        title: 'Syllabus & Custom Tasks',
        subtitle: '${tasks.length} Checklist Tasks • ${customTasks.length} Custom Tasks',
        sizeText: '${tasksKb.toStringAsFixed(1)} KB',
        icon: Icons.check_box_rounded,
        color: Colors.lightGreenAccent,
      ),
      if (resourceCount > 0)
        _buildBreakdownItem(
          title: 'Topic Resources & Notes',
          subtitle: '$resourceCount Topics with Notes/Links',
          sizeText: '${resourcesKb.toStringAsFixed(1)} KB',
          icon: Icons.note_alt_rounded,
          color: Colors.amberAccent,
        ),
      _buildBreakdownItem(
        title: 'Focus Sessions & Timer Logs',
        subtitle: (isProjected && !_syncStatsEnabled)
            ? 'Disabled from cloud sync'
            : '${focusSessions.length} Study Sessions',
        sizeText: '${focusSessionsKb.toStringAsFixed(1)} KB',
        icon: Icons.timer_rounded,
        color: (isProjected && !_syncStatsEnabled) ? context.appColors.textMuted : widget.accentColor,
      ),
      _buildBreakdownItem(
        title: 'Daily Focus History',
        subtitle: (isProjected && !_syncStatsEnabled)
            ? 'Disabled from cloud sync'
            : '${dailyHistory.length} Daily Summary Records',
        sizeText: '${dailyHistoryKb.toStringAsFixed(1)} KB',
        icon: Icons.calendar_month_rounded,
        color: (isProjected && !_syncStatsEnabled) ? Colors.white38 : Colors.deepOrangeAccent,
      ),
      _buildBreakdownItem(
        title: 'Syllabus Progress Logs',
        subtitle: (isProjected && !_syncStatsEnabled)
            ? 'Disabled from cloud sync'
            : '${progressLogs.length} Timeline Activity Logs',
        sizeText: '${progressLogsKb.toStringAsFixed(1)} KB',
        icon: Icons.show_chart_rounded,
        color: (isProjected && !_syncStatsEnabled) ? Colors.white38 : Colors.pinkAccent,
      ),
    ];
  }

  Widget _buildMiniTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.appColors.surfaceColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 10)),
    );
  }

  String _formatCutoffDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Widget _buildPruneButton({
    required String title,
    required String subtitle,
    required int days,
    required bool enabled,
  }) {
    final isSelected = _selectedPruneDays == days;

    return InkWell(
      onTap: enabled
          ? () {
              setState(() {
                if (isSelected) {
                  _selectedPruneDays = null;
                } else {
                  _selectedPruneDays = days;
                }
              });
            }
          : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: enabled
              ? (isSelected ? Colors.amberAccent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03))
              : Colors.white.withValues(alpha: 0.01),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled
                ? (isSelected ? Colors.amberAccent : Colors.white10)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.history_rounded,
                  size: 14,
                  color: enabled ? (isSelected ? Colors.amberAccent : context.appColors.textSecondary) : context.appColors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: enabled ? (isSelected ? Colors.amberAccent : context.appColors.textPrimary) : context.appColors.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                color: enabled ? context.appColors.textMuted : context.appColors.textMuted.withValues(alpha: 0.5),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── CONFIRM & STEP-BY-STEP EXECUTION FLOW ──
  Future<void> _executeOptimizationFlow() async {
    final exportBackup = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.dialogBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: Colors.tealAccent, size: 22),
            const SizedBox(width: 10),
            Text('Safety Backup Prompt', style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'Would you like to export a safety backup JSON file to your device before applying optimization changes?',
          style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Skip Backup', style: GoogleFonts.outfit(color: context.appColors.textSecondary)),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.download_rounded, size: 16),
            label: Text('Export Backup & Continue', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (exportBackup == null || !mounted) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Step-by-Step Progress Dialog State
    final List<String> steps = [
      if (exportBackup) 'Exporting safety JSON backup...',
      if (_syncStatsEnabled && _selectedPruneDays != null) 'Pruning historical focus entries older than $_selectedPruneDays days...',
      'Updating cloud compression & stats preferences...',
      'Uploading optimized payload to Firestore cloud...',
    ];

    int currentStepIndex = 0;
    StateSetter? updateDialog;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          updateDialog = setDialogState;
          return AlertDialog(
            backgroundColor: context.appColors.dialogBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: widget.accentColor),
                ),
                const SizedBox(width: 12),
                Text('Applying Optimization...', style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(steps.length, (idx) {
                final isDone = idx < currentStepIndex;
                final isCurrent = idx == currentStepIndex;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        isDone
                            ? Icons.check_circle_rounded
                            : isCurrent
                                ? Icons.arrow_right_rounded
                                : Icons.radio_button_unchecked_rounded,
                        color: isDone
                            ? Colors.greenAccent
                            : isCurrent
                                ? widget.accentColor
                                : context.appColors.textMuted,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          steps[idx],
                          style: GoogleFonts.outfit(
                            color: isDone
                                ? Colors.greenAccent
                                : isCurrent
                                    ? context.appColors.textPrimary
                                    : context.appColors.textMuted,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          );
        },
      ),
    );

    setState(() => _isApplying = true);

    try {
      // Step 1: Export safety backup if requested
      if (exportBackup) {
        final db = ref.read(appDatabaseProvider);
        await BackupService.exportBackupToFile(db);
        currentStepIndex++;
        updateDialog?.call(() {});
        await Future.delayed(const Duration(milliseconds: 400));
      }

      // Step 2: Prune history if selected
      if (_syncStatsEnabled && _selectedPruneDays != null) {
        await ref.read(syncProvider.notifier).pruneHistory(_selectedPruneDays!);
        currentStepIndex++;
        updateDialog?.call(() {});
        await Future.delayed(const Duration(milliseconds: 400));
      }

      // Step 3: Update Preferences
      await ref.read(syncStatsEnabledProvider.notifier).setSyncStatsEnabled(_syncStatsEnabled);
      await ref.read(syncCompressedProvider.notifier).setSyncCompressed(_syncCompressed);
      currentStepIndex++;
      updateDialog?.call(() {});
      await Future.delayed(const Duration(milliseconds: 400));

      // Step 4: Upload to cloud
      await ref.read(syncProvider.notifier).uploadLocalToCloud();
      currentStepIndex++;
      updateDialog?.call(() {});
      await Future.delayed(const Duration(milliseconds: 500));

      // Close loading dialog
      if (mounted && navigator.canPop()) {
        navigator.pop();
      }

      // Reload raw data for fresh state
      await _loadRawData();

      if (mounted) {
        setState(() {
          _isApplying = false;
          _isSuccess = true;
        });
      }
    } catch (e) {
      if (mounted && navigator.canPop()) {
        navigator.pop();
      }
      if (mounted) {
        setState(() => _isApplying = false);
        messenger.showSnackBar(
          SnackBar(content: Text('Optimization error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}
