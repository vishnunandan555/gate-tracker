import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/providers.dart';

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
      backgroundColor: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        "Sync Conflict Detected",
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Both your local device and cloud backup contain study tracking progress. How would you like to resolve this conflict?",
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.5),
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
              color: Colors.cyanAccent,
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
          color: Colors.white.withAlpha(5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(8)),
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
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: Colors.white30,
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
            backgroundColor: const Color(0xFF18181B),
            behavior: SnackBarBehavior.floating,
            width: useWidth ? 400 : null,
            margin: useWidth ? null : const EdgeInsets.all(16),
            duration: const Duration(seconds: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white.withAlpha(20), width: 1),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.cyanAccent,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "GATEletics updated to v${packageInfo.version}",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    final Uri url = Uri.parse('https://github.com/vishnunandan555/gateletics/releases');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    "CHANGELOG",
                    style: GoogleFonts.outfit(
                      color: Colors.cyanAccent,
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
                      color: Colors.white70,
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

  final onlyLocalSessionLabels = onlyLocalSessions.map((s) {
    final method = s['method'] as String? ?? 'Freestyle';
    final dur = ((s['durationSeconds'] ?? 0) as num).toInt() ~/ 60;
    return "$method Session (${dur}m) on ${formatSessionTime(s['startTime'] as String)}";
  }).toList();

  final onlyCloudSessionLabels = onlyCloudSessions.map((s) {
    final method = s['method'] as String? ?? 'Freestyle';
    final dur = ((s['durationSeconds'] ?? 0) as num).toInt() ~/ 60;
    return "$method Session (${dur}m) on ${formatSessionTime(s['startTime'] as String)}";
  }).toList();

  Widget buildConflictSection(String title, List<String> items, Color color) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: color, fontSize: 10),
          ),
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(5)),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: color, size: 12),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          items[index],
                          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        "Data Comparison Details",
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        "LOCAL DEVICE",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: accentColor, fontSize: 11),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Center(
                      child: Text(
                        "CLOUD BACKUP",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.cyanAccent, fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatComparisonRow("Focus Sessions", "${localSessions.length}", "${cloudSessions.length}"),
              _buildStatComparisonRow("Hours Studied", "${localHours.toStringAsFixed(1)}h", "${cloudHours.toStringAsFixed(1)}h"),
              _buildStatComparisonRow("Syllabus Tasks", "$localTasks completed", "$cloudTasks completed"),
              _buildStatComparisonRow("Videos Tracked", "$localVideos completed", "$cloudVideos completed"),
              _buildStatComparisonRow("Last Study Session", formatTime(localSessions), formatTime(cloudSessions)),
              
              buildConflictSection("COMPLETED LOCALLY ONLY (${onlyLocalCompleted.length})", onlyLocalCompleted, accentColor),
              buildConflictSection("SESSIONS RECORDED LOCALLY ONLY (${onlyLocalSessionLabels.length})", onlyLocalSessionLabels, accentColor),
              buildConflictSection("COMPLETED IN CLOUD ONLY (${onlyCloudCompleted.length})", onlyCloudCompleted, Colors.cyanAccent),
              buildConflictSection("SESSIONS RECORDED IN CLOUD ONLY (${onlyCloudSessionLabels.length})", onlyCloudSessionLabels, Colors.cyanAccent),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close', style: TextStyle(color: accentColor)),
        ),
      ],
    ),
  );
}

Widget _buildStatComparisonRow(String label, String localVal, String cloudVal) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  localVal,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  cloudVal,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
