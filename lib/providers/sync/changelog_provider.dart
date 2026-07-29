import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class ChangelogItem {
  final String version;
  final String date;
  final String title;
  final List<String> changes;
  final String githubUrl;

  const ChangelogItem({
    required this.version,
    required this.date,
    required this.title,
    required this.changes,
    required this.githubUrl,
  });

  factory ChangelogItem.fromGitHubRelease(Map<String, dynamic> json) {
    final rawTag = json['tag_name'] as String? ?? 'v1.3.0';
    final version = rawTag.replaceFirst(RegExp(r'^v'), '');
    final name = json['name'] as String? ?? 'v$version';
    final publishedAt = json['published_at'] as String? ?? '';
    final body = json['body'] as String? ?? '';
    final htmlUrl = json['html_url'] as String? ?? 'https://github.com/vishnunandan555/gateletics/releases';

    String dateStr = '';
    if (publishedAt.isNotEmpty) {
      final dt = DateTime.tryParse(publishedAt);
      if (dt != null) {
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        dateStr = '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
      }
    }

    final changes = <String>[];
    final lines = body.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      if (line.startsWith('- ') || line.startsWith('* ') || line.startsWith('+ ')) {
        changes.add(line.substring(2).trim());
      } else if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        changes.add(line.replaceFirst(RegExp(r'^\d+\.\s'), '').trim());
      } else if (changes.isNotEmpty && !line.startsWith('http')) {
        changes[changes.length - 1] = '${changes.last} $line';
      } else if (line.isNotEmpty && !line.startsWith('http')) {
        changes.add(line);
      }
    }

    return ChangelogItem(
      version: version,
      date: dateStr,
      title: name.isNotEmpty ? name : 'GATEletics v$version',
      changes: changes.isEmpty ? [body] : changes,
      githubUrl: htmlUrl,
    );
  }
}

final changelogFamilyProvider = FutureProvider.family<ChangelogItem, String?>((ref, requestedVersion) async {
  final cleanRequested = requestedVersion?.replaceFirst(RegExp(r'^v'), '').split('+').first.trim();

  final response = await http.get(
    Uri.parse('https://api.github.com/repos/vishnunandan555/gateletics/releases'),
  ).timeout(const Duration(seconds: 5));

  if (response.statusCode == 200) {
    final List<dynamic> releases = jsonDecode(response.body);
    if (releases.isNotEmpty) {
      Map<String, dynamic>? targetRelease;
      if (cleanRequested != null && cleanRequested.isNotEmpty) {
        for (final rel in releases) {
          final tag = (rel['tag_name'] as String? ?? '').replaceFirst(RegExp(r'^v'), '').split('+').first.trim();
          if (tag == cleanRequested) {
            targetRelease = rel as Map<String, dynamic>;
            break;
          }
        }
      }
      targetRelease ??= releases.first as Map<String, dynamic>;
      return ChangelogItem.fromGitHubRelease(targetRelease);
    }
  }

  throw Exception('Unable to fetch release notes from GitHub.');
});
