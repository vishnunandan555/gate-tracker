import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../providers.dart';

class StudyResource {
  final String id;
  final List<String> branches;
  final String subject;
  final String title;
  final String source;
  final String platform;
  final String url;
  final int lectureCount;
  final String type;
  final String description;

  const StudyResource({
    required this.id,
    required this.branches,
    required this.subject,
    required this.title,
    required this.source,
    required this.platform,
    required this.url,
    required this.lectureCount,
    required this.type,
    required this.description,
  });

  factory StudyResource.fromJson(Map<String, dynamic> json) {
    final rawBranches = json['branches'];
    List<String> parsedBranches = [];
    if (rawBranches is List) {
      parsedBranches = rawBranches.map((e) => e.toString().toUpperCase()).toList();
    } else if (rawBranches is String) {
      parsedBranches = [rawBranches.toUpperCase()];
    }

    return StudyResource(
      id: json['id'] as String? ?? '',
      branches: parsedBranches,
      subject: json['subject'] as String? ?? 'General',
      title: json['title'] as String? ?? '',
      source: json['source'] as String? ?? 'Community',
      platform: json['platform'] as String? ?? 'Website',
      url: json['url'] as String? ?? '',
      lectureCount: (json['lectureCount'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? 'Resource',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'branches': branches,
        'subject': subject,
        'title': title,
        'source': source,
        'platform': platform,
        'url': url,
        'lectureCount': lectureCount,
        'type': type,
        'description': description,
      };
}

class ResourcesNotifier extends AsyncNotifier<List<StudyResource>> {
  static const _remoteUrl =
      'https://raw.githubusercontent.com/vishnunandan555/gateletics/main/resources.json';
  static const _cacheKey = 'cached_resources_json';
  static const _lastFetchKey = 'resources_last_fetch_time';
  static const _cacheExpiryDays = 7;

  @override
  Future<List<StudyResource>> build() async {
    return _loadResources();
  }

  Future<List<StudyResource>> _loadResources({bool forceRemote = false}) async {
    final prefs = ref.read(sharedPreferencesProvider);

    final lastFetchMs = prefs.getInt(_lastFetchKey) ?? 0;
    final lastFetchDate = DateTime.fromMillisecondsSinceEpoch(lastFetchMs);
    final isExpired = DateTime.now().difference(lastFetchDate).inDays >= _cacheExpiryDays;

    // 1. Instant local load if cache is valid (< 7 days old) and not forced
    if (!forceRemote && !isExpired) {
      final localResources = await _loadFromLocalCacheOrAsset(prefs);
      if (localResources.isNotEmpty) {
        return localResources;
      }
    }

    // 2. Fetch from GitHub if expired, forced, or local cache missing
    try {
      final response = await http
          .get(Uri.parse(_remoteUrl))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final jsonString = response.body;
        final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
        final resources = list.map((e) => StudyResource.fromJson(e as Map<String, dynamic>)).toList();
        
        await prefs.setString(_cacheKey, jsonString);
        await prefs.setInt(_lastFetchKey, DateTime.now().millisecondsSinceEpoch);
        return resources;
      }
    } catch (_) {}

    // 3. Fallback to local cache/asset if network fails
    return await _loadFromLocalCacheOrAsset(prefs);
  }

  Future<List<StudyResource>> _loadFromLocalCacheOrAsset(dynamic prefs) async {
    final cached = prefs.getString(_cacheKey);
    if (cached != null && cached.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(cached) as List<dynamic>;
        return list.map((e) => StudyResource.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    try {
      final jsonString = await rootBundle.loadString('resources.json');
      final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
      return list.map((e) => StudyResource.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> forceRefresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadResources(forceRemote: true));
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadResources());
  }
}

final resourcesProvider = AsyncNotifierProvider<ResourcesNotifier, List<StudyResource>>(() {
  return ResourcesNotifier();
});
