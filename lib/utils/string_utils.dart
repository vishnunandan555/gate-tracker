import 'dart:math';
import '../database/app_database.dart';

extension DateFormattingX on DateTime {
  String toDateKey() {
    return "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
  }
}

String formatDurationSeconds(int seconds, {bool isCountUp = false}) {
  if (isCountUp) {
    final h = (seconds / 3600).floor();
    final m = ((seconds % 3600) / 60).floor();
    final s = seconds % 60;
    if (h > 0) {
      return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}";
    }
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  } else {
    final m = (seconds / 60).floor();
    final s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }
}

double calculateSyllabusMatchScore(SyllabusTopicWithTasks topicWithTasks, String query, String categoryName) {
  final topic = topicWithTasks.topic;
  final name = topic.name.toLowerCase();
  final catName = categoryName.toLowerCase();
  
  final rawUrl = topic.resourceUrl ?? '';
  String note = '';
  if (rawUrl.trim().isNotEmpty) {
    final parts = rawUrl.trim().split('|');
    if (parts.length > 2) {
      note = parts[2].trim().toLowerCase();
    }
  }

  double score = 0;
  
  if (catName == query) {
    score += 150;
  } else if (catName.contains(query)) {
    score += 80 + (1.0 / (catName.indexOf(query) + 1));
  }
  
  if (name == query) {
    score += 100;
  } else if (name.contains(query)) {
    score += 50 + (1.0 / (name.indexOf(query) + 1));
  }
  
  if (note.isNotEmpty) {
    if (note == query) {
      score += 40;
    } else if (note.contains(query)) {
      score += 20;
    }
  }
  
  for (final task in topicWithTasks.tasks) {
    final taskName = task.name.toLowerCase();
    if (taskName == query) {
      score += 30;
    } else if (taskName.contains(query)) {
      score += 15;
    }
  }
  return score;
}

class SyllabusSearchResult {
  final List<SyllabusCategoryWithTopics> filteredSyllabus;
  final SyllabusTopicWithTasks? bestMatchTopic;
  final SyllabusCategory? bestMatchCategory;

  const SyllabusSearchResult({
    required this.filteredSyllabus,
    this.bestMatchTopic,
    this.bestMatchCategory,
  });
}

SyllabusSearchResult filterSyllabusWithScores(List<SyllabusCategoryWithTopics> syllabusData, String query) {
  final trimmedQuery = query.trim().toLowerCase();
  if (trimmedQuery.isEmpty) {
    return SyllabusSearchResult(filteredSyllabus: syllabusData);
  }

  List<SyllabusCategoryWithTopics> filteredSyllabus = [];
  SyllabusTopicWithTasks? bestMatchTopic;
  SyllabusCategory? bestMatchCategory;
  double maxScore = 0;

  for (final catWithTopics in syllabusData) {
    List<SyllabusTopicWithTasks> matchedTopics = [];
    for (final topicWithTasks in catWithTopics.topics) {
      double score = calculateSyllabusMatchScore(topicWithTasks, trimmedQuery, catWithTopics.category.name);
      if (score > 0) {
        matchedTopics.add(topicWithTasks);
        if (score > maxScore) {
          maxScore = score;
          bestMatchTopic = topicWithTasks;
          bestMatchCategory = catWithTopics.category;
        }
      }
    }
    
    if (matchedTopics.isNotEmpty) {
      filteredSyllabus.add(SyllabusCategoryWithTopics(
        category: catWithTopics.category,
        topics: matchedTopics,
      ));
    }
  }
  
  if (bestMatchTopic != null && bestMatchCategory != null) {
    filteredSyllabus = filteredSyllabus.map((catWithTopics) {
      if (catWithTopics.category.id == bestMatchCategory!.id) {
        return SyllabusCategoryWithTopics(
          category: catWithTopics.category,
          topics: catWithTopics.topics.where((t) => t.topic.id != bestMatchTopic!.topic.id).toList(),
        );
      }
      return catWithTopics;
    }).where((catWithTopics) => catWithTopics.topics.isNotEmpty).toList();
  }

  return SyllabusSearchResult(
    filteredSyllabus: filteredSyllabus,
    bestMatchTopic: bestMatchTopic,
    bestMatchCategory: bestMatchCategory,
  );
}

String getCategoryShortName(String name) {
  if (name.isEmpty) return "";
  final parts = name.trim().split(RegExp(r'[^a-zA-Z0-9]+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return "";
  if (parts.length == 1) {
    final word = parts.first;
    if (word.length <= 3) return word.toUpperCase();
    return word.substring(0, min(3, word.length)).toUpperCase();
  }
  return parts.map((p) => p[0].toUpperCase()).join("");
}

String formatTimeOfDay(DateTime dateTime) {
  final hour = dateTime.hour;
  final minute = dateTime.minute;
  final ampm = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  final displayMinute = minute.toString().padLeft(2, '0');
  return "$displayHour:$displayMinute $ampm";
}

String getMonthName(int month, {bool short = false}) {
  if (month < 1 || month > 12) return "";
  const fullMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  const shortMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return short ? shortMonths[month - 1] : fullMonths[month - 1];
}

String formatSyncTime(DateTime time) {
  final now = DateTime.now();
  final isToday = time.year == now.year && time.month == now.month && time.day == now.day;
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  if (isToday) {
    return "$hour:$minute";
  } else {
    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    return "$day/$month $hour:$minute";
  }
}

