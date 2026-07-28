import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

const String _kQuotesCacheKey = 'cached_quotes';
const String _kQuotesUrl =
    'https://raw.githubusercontent.com/vishnunandan555/gateletics/main/quotes.json';

/// Hardcoded fallback quotes in case there's no network and no cache.
const List<String> _kFallbackQuotes = [
  "Consistency is what transforms average into excellence.",
  "The best way to predict the future is to create it.",
  "Do not stop when you are tired. Stop when you are done.",
  "Great things are done by a series of small things brought together.",
  "Your focus determines your reality.",
  "Success is not final, failure is not fatal: it is the courage to continue that counts.",
  "It always seems impossible until it's done.",
  "An investment in knowledge pays the best interest.",
  "The only way to do great work is to love what you do.",
  "Excellence is not a skill. It is an attitude.",
  "Small daily improvements over time lead to stunning results.",
  "Believe you can and you're halfway there.",
  "Trust the process. Your hard work will pay off.",
  "Focus on progress, not perfection.",
  "Energy and persistence conquer all things.",
  "The secret of getting ahead is getting started.",
  "The expert in anything was once a beginner.",
  "Your only limit is you.",
];

class QuotesNotifier extends Notifier<List<String>> {
  final _random = Random();

  @override
  List<String> build() {
    _init();
    return _kFallbackQuotes;
  }

  Future<void> _init() async {
    // Step 1: Load from cache immediately for fast offline-first response.
    final cached = await _loadFromCache();
    if (cached.isNotEmpty) {
      state = cached;
    }

    // Step 2: Silently attempt a remote refresh in the background.
    _fetchAndCache();
  }

  Future<List<String>> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kQuotesCacheKey);
      if (raw != null) {
        final decoded = json.decode(raw);
        if (decoded is List && decoded.isNotEmpty) {
          return List<String>.from(decoded);
        }
      }
    } catch (_) {
      // Silently ignore cache errors.
    }
    return [];
  }

  Future<void> _fetchAndCache() async {
    try {
      final response = await http
          .get(Uri.parse(_kQuotesUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          final quotes = List<String>.from(decoded);
          // Update state with remote quotes.
          state = quotes;
          // Persist to cache.
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kQuotesCacheKey, json.encode(quotes));
        }
      }
    } catch (_) {
      // Silently ignore network errors — fallback or cache is already loaded.
    }
  }

  /// Returns a single randomly selected quote from the current list.
  String randomQuote() {
    final list = state.isNotEmpty ? state : _kFallbackQuotes;
    return list[_random.nextInt(list.length)];
  }
}

final quotesProvider = NotifierProvider<QuotesNotifier, List<String>>(() {
  return QuotesNotifier();
});

class FocusQuotesEnabledNotifier extends Notifier<bool> {
  static const _kKey = 'beta_focus_quotes_enabled';

  @override
  bool build() {
    _load();
    return false; // Default: disabled
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_kKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kKey, enabled);
  }
}

final focusQuotesEnabledProvider = NotifierProvider<FocusQuotesEnabledNotifier, bool>(() {
  return FocusQuotesEnabledNotifier();
});

