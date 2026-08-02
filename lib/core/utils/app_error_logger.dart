import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppErrorLogger {
  static const String _logKey = 'app_error_logs_json';
  static const int _maxLogs = 20;

  static final List<String> _inMemoryLogs = [];

  static Future<void> logError(String tag, dynamic error, [StackTrace? stackTrace]) async {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = "[$timestamp] [$tag] $error${stackTrace != null ? '\n$stackTrace' : ''}";
    
    if (kDebugMode) {
      debugPrint("AppErrorLogger: $logEntry");
    }

    _inMemoryLogs.add(logEntry);
    if (_inMemoryLogs.length > _maxLogs) {
      _inMemoryLogs.removeAt(0);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_logKey, List<String>.from(_inMemoryLogs));
    } catch (_) {}
  }

  static Future<List<String>> getLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_logKey) ?? [];
      return saved.isNotEmpty ? saved : List<String>.from(_inMemoryLogs);
    } catch (_) {
      return List<String>.from(_inMemoryLogs);
    }
  }

  static Future<void> clearLogs() async {
    _inMemoryLogs.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_logKey);
    } catch (_) {}
  }
}
