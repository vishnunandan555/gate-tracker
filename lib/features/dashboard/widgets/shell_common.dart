import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'changelog_dialog.dart';
import '../../../core/theme/theme_context_ext.dart';
import 'package:gateletics/providers/providers.dart';

// ... (keep alive wrapper omitted in between)


class KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}

void showSyncConflictDialog(BuildContext context, WidgetRef ref, Color accentColor) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
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
                if (cloudData != null && context.mounted) {
                  showConflictDetailsDialog(context, localData, cloudData, accentColor);
                }
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: accentColor.withAlpha(100)),
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
            _SyncDialogOption(
              title: "Merge Progress (Recommended)",
              subtitle: "Combine local and cloud progress (no data lost)",
              icon: Icons.merge_type_rounded,
              color: context.appColors.primaryAccent,
              onTap: () async {
                Navigator.pop(context);
                await ref.read(syncProvider.notifier).mergeCloudAndLocal();
              },
            ),
            const SizedBox(height: 12),
            _SyncDialogOption(
              title: "Use Cloud Backup",
              subtitle: "Overwrite local data with your cloud backup",
              icon: Icons.cloud_download_rounded,
              color: Colors.greenAccent,
              onTap: () async {
                Navigator.pop(context);
                await ref.read(syncProvider.notifier).downloadCloudToLocal();
              },
            ),
            const SizedBox(height: 12),
            _SyncDialogOption(
              title: "Keep Local Progress",
              subtitle: "Overwrite cloud data with your local progress",
              icon: Icons.cloud_upload_rounded,
              color: Colors.orangeAccent,
              onTap: () async {
                Navigator.pop(context);
                await ref.read(syncProvider.notifier).uploadLocalToCloud();
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _SyncDialogOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SyncDialogOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.appColors.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appColors.borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
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
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: context.appColors.textMuted,
                      fontSize: 10,
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
}

void initializeShellServices(BuildContext context, WidgetRef ref) {
  checkAndInitSync(ref);
  checkAppVersionUpdate(context, ref);
  ref.read(desktopUpdateProvider.notifier).checkOnLaunchSilently();
}

void checkAndInitSync(WidgetRef ref) {
  final authState = ref.read(authProvider).value;
  if (authState != null && authState.user != null) {
    final syncState = ref.read(syncProvider);
    if (syncState.status == SyncStatus.idle) {
      ref.read(syncProvider.notifier).initializeSync();
    }
  }
}

Future<void> checkAppVersionUpdate(BuildContext context, WidgetRef ref) async {
  if (ref.read(hasCheckedVersionProvider)) return;
  ref.read(hasCheckedVersionProvider.notifier).setChecked(true);
  try {
    final prefs = ref.read(sharedPreferencesProvider);
    final packageInfo = ref.read(packageInfoProvider);
    final currentVer = '${packageInfo.version}+${packageInfo.buildNumber}';
    final lastKnownVer = prefs.getString('last_known_app_version');

    if (lastKnownVer != null && lastKnownVer != currentVer) {
      if (context.mounted) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final useWidth = screenWidth > 600;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: context.appColors.dialogBackground,
            behavior: SnackBarBehavior.floating,
            width: useWidth ? 400 : null,
            margin: useWidth ? null : const EdgeInsets.all(16),
            duration: const Duration(seconds: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: context.appColors.borderColor, width: 1),
            ),
            content: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: context.appColors.primaryAccent,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "GATEletics updated to v${packageInfo.version}",
                    style: GoogleFonts.outfit(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    showChangelogDialog(context, version: packageInfo.version);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    "CHANGELOG",
                    style: GoogleFonts.outfit(
                      color: context.appColors.primaryAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    "OK",
                    style: GoogleFonts.outfit(
                      color: context.appColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // Always update to current version to prevent duplicate updates or loops
    await prefs.setString('last_known_app_version', currentVer);
  } catch (e) {
    debugPrint("Error checking app version update: $e");
  }
}

void showConflictDetailsDialog(
  BuildContext context,
  Map<String, dynamic> local,
  Map<String, dynamic> cloud,
  Color accentColor,
) {
  final localSessions = local['focusSessions'] as List? ?? [];
  final cloudSessions = cloud['focusSessions'] as List? ?? [];

  final localHours = localSessions.fold<double>(0.0, (sum, s) => sum + ((s['durationSeconds'] ?? 0) as num).toDouble()) / 3600.0;
  final cloudHours = cloudSessions.fold<double>(0.0, (sum, s) => sum + ((s['durationSeconds'] ?? 0) as num).toDouble()) / 3600.0;

  final localTasks = (local['syllabusTasks'] as List? ?? []).where((t) => t['isCompleted'] == true).length;
  final cloudTasks = (cloud['syllabusTasks'] as List? ?? []).where((t) => t['isCompleted'] == true).length;

  final localVideos = (local['subjects'] as List? ?? []).fold<int>(0, (sum, s) => sum + ((s['completedVideos'] ?? 0) as int));
  final cloudVideos = (cloud['subjects'] as List? ?? []).fold<int>(0, (sum, s) => sum + ((s['completedVideos'] ?? 0) as int));

  String formatTime(List sessions) {
    if (sessions.isEmpty) return "No activity";
    try {
      DateTime? latest;
      for (final s in sessions) {
        final startStr = s['startTime'] as String?;
        if (startStr != null) {
          final dt = DateTime.parse(startStr);
          if (latest == null || dt.isAfter(latest)) {
            latest = dt;
          }
        }
      }
      if (latest != null) {
        final now = DateTime.now();
        final diff = now.difference(latest);
        if (diff.inDays == 0) return "Today";
        if (diff.inDays == 1) return "Yesterday";
        return "${diff.inDays} days ago";
      }
    } catch (_) {}
    return "Unknown";
  }

  // Compute differences
  final localCats = local['syllabusCategories'] as List? ?? [];
  final localTops = local['syllabusTopics'] as List? ?? [];
  final localTasksList = local['syllabusTasks'] as List? ?? [];
  final cloudCats = cloud['syllabusCategories'] as List? ?? [];
  final cloudTops = cloud['syllabusTopics'] as List? ?? [];
  final cloudTasksList = cloud['syllabusTasks'] as List? ?? [];

  final localCatMap = {for (var c in localCats) c['id']: c['name']};
  final cloudCatMap = {for (var c in cloudCats) c['id']: c['name']};

  final localTopicMap = <dynamic, String>{};
  for (var t in localTops) {
    final catName = localCatMap[t['categoryId']] ?? 'Unknown';
    localTopicMap[t['id']] = "$catName / ${t['name']}";
  }
  final cloudTopicMap = <dynamic, String>{};
  for (var t in cloudTops) {
    final catName = cloudCatMap[t['categoryId']] ?? 'Unknown';
    cloudTopicMap[t['id']] = "$catName / ${t['name']}";
  }

  final localTaskMap = <String, Map<String, dynamic>>{};
  for (var t in localTasksList) {
    final topicPath = localTopicMap[t['topicId']] ?? 'Unknown/Unknown';
    final key = "$topicPath / ${t['name'] ?? ''}";
    localTaskMap[key] = Map<String, dynamic>.from(t);
  }

  final cloudTaskMap = <String, Map<String, dynamic>>{};
  for (var t in cloudTasksList) {
    final topicPath = cloudTopicMap[t['topicId']] ?? 'Unknown/Unknown';
    final key = "$topicPath / ${t['name'] ?? ''}";
    cloudTaskMap[key] = Map<String, dynamic>.from(t);
  }

  final onlyLocalCompleted = <String>[];
  final onlyCloudCompleted = <String>[];

  localTaskMap.forEach((key, lt) {
    final ct = cloudTaskMap[key];
    final lComp = lt['isCompleted'] == true;
    final cComp = ct != null && ct['isCompleted'] == true;
    if (lComp && !cComp) {
      onlyLocalCompleted.add(key);
    }
  });

  cloudTaskMap.forEach((key, ct) {
    final lt = localTaskMap[key];
    final cComp = ct['isCompleted'] == true;
    final lComp = lt != null && lt['isCompleted'] == true;
    if (cComp && !lComp) {
      onlyCloudCompleted.add(key);
    }
  });

  final localSessionTimes = localSessions.map((s) => s['startTime'] as String?).whereType<String>().toSet();
  final cloudSessionTimes = cloudSessions.map((s) => s['startTime'] as String?).whereType<String>().toSet();

  final onlyLocalSessions = localSessions.where((s) => !cloudSessionTimes.contains(s['startTime'])).toList();
  final onlyCloudSessions = cloudSessions.where((s) => !localSessionTimes.contains(s['startTime'])).toList();

  String formatSessionTime(String startTimeStr) {
    try {
      final dt = DateTime.parse(startTimeStr).toLocal();
      return "${dt.day}/${dt.month} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return startTimeStr;
    }
  }

  final validOnlyLocalSessions = onlyLocalSessions.where((s) => ((s['durationSeconds'] ?? 0) as num) > 0).toList();
  final validOnlyCloudSessions = onlyCloudSessions.where((s) => ((s['durationSeconds'] ?? 0) as num) > 0).toList();

  final onlyLocalSessionLabels = validOnlyLocalSessions.map((s) {
    final method = s['method'] as String? ?? 'Freestyle';
    final durSec = ((s['durationSeconds'] ?? 0) as num).toInt();
    final durStr = durSec >= 60 ? '${durSec ~/ 60}m' : '${durSec}s';
    return "$method Session ($durStr) on ${formatSessionTime(s['startTime'] as String)}";
  }).toList();

  final onlyCloudSessionLabels = validOnlyCloudSessions.map((s) {
    final method = s['method'] as String? ?? 'Freestyle';
    final durSec = ((s['durationSeconds'] ?? 0) as num).toInt();
    final durStr = durSec >= 60 ? '${durSec ~/ 60}m' : '${durSec}s';
    return "$method Session ($durStr) on ${formatSessionTime(s['startTime'] as String)}";
  }).toList();

  final statItems = <_ComparisonStat>[
    _ComparisonStat("Focus Sessions", "${localSessions.length}", "${cloudSessions.length}", localSessions.length != cloudSessions.length, localSessions.isEmpty && cloudSessions.isEmpty),
    _ComparisonStat("Hours Studied", "${localHours.toStringAsFixed(1)}h", "${cloudHours.toStringAsFixed(1)}h", (localHours - cloudHours).abs() > 0.05, localHours == 0.0 && cloudHours == 0.0),
    _ComparisonStat("Syllabus Tasks", "$localTasks completed", "$cloudTasks completed", localTasks != cloudTasks, localTasks == 0 && cloudTasks == 0),
    _ComparisonStat("Videos Tracked", "$localVideos completed", "$cloudVideos completed", localVideos != cloudVideos, localVideos == 0 && cloudVideos == 0),
    _ComparisonStat("Last Study Session", formatTime(localSessions), formatTime(cloudSessions), formatTime(localSessions) != formatTime(cloudSessions), localSessions.isEmpty && cloudSessions.isEmpty),
  ];

  final relevantStats = statItems.where((item) => item.isDifferent || !item.isZero).toList();

  Widget buildConflictSection(String title, List<String> items, Color color) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: color, fontSize: 10.5, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            decoration: BoxDecoration(
              color: context.appColors.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.appColors.borderColor),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: color, size: 13),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: context.appColors.dialogBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        "Data Comparison Details",
        style: GoogleFonts.jersey15(fontWeight: FontWeight.bold, color: context.appColors.textPrimary, fontSize: 20, letterSpacing: 0.8),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: context.appColors.cardBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        "METRIC",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.appColors.textMuted, fontSize: 10.5),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        "LOCAL DEVICE",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: accentColor, fontSize: 10.5),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        "CLOUD BACKUP",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.appColors.primaryAccent, fontSize: 10.5),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              if (relevantStats.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      "Local device and cloud backup data match!",
                      style: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 12),
                    ),
                  ),
                )
              else
                ...relevantStats.map((s) => _buildStatComparisonRow(context, s.label, s.localVal, s.cloudVal, s.isDifferent, accentColor)),

              buildConflictSection("COMPLETED LOCALLY ONLY (${onlyLocalCompleted.length})", onlyLocalCompleted, accentColor),
              buildConflictSection("SESSIONS RECORDED LOCALLY ONLY (${onlyLocalSessionLabels.length})", onlyLocalSessionLabels, accentColor),
              buildConflictSection("COMPLETED IN CLOUD ONLY (${onlyCloudCompleted.length})", onlyCloudCompleted, context.appColors.primaryAccent),
              buildConflictSection("SESSIONS RECORDED IN CLOUD ONLY (${onlyCloudSessionLabels.length})", onlyCloudSessionLabels, context.appColors.primaryAccent),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close', style: GoogleFonts.outfit(color: accentColor, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

class _ComparisonStat {
  final String label;
  final String localVal;
  final String cloudVal;
  final bool isDifferent;
  final bool isZero;

  _ComparisonStat(this.label, this.localVal, this.cloudVal, this.isDifferent, this.isZero);
}

Widget _buildStatComparisonRow(BuildContext context, String label, String localVal, String cloudVal, bool isDifferent, Color accentColor) {
  return Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: isDifferent ? accentColor.withValues(alpha: 0.08) : context.appColors.cardBackground,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDifferent ? accentColor.withValues(alpha: 0.35) : Colors.transparent,
      ),
    ),
    child: Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              color: isDifferent ? context.appColors.textPrimary : context.appColors.textSecondary,
              fontSize: 11.5,
              fontWeight: isDifferent ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            localVal,
            style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 11.5, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            cloudVal,
            style: GoogleFonts.outfit(
              color: isDifferent ? context.appColors.primaryAccent : context.appColors.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );
}
