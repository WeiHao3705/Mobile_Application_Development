import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const String _searchHistoryKey = 'meal_search_history';
  static const int _maxHistoryItems = 10;

  /// Save a search query to history
  Future<void> addSearchQuery(String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_searchHistoryKey) ?? [];

    // Remove the query if it already exists (to move it to the top)
    history.removeWhere((item) => item.toLowerCase() == query.toLowerCase());

    // Add the query to the beginning
    history.insert(0, query.trim());

    // Keep only the most recent items
    if (history.length > _maxHistoryItems) {
      history = history.sublist(0, _maxHistoryItems);
    }

    await prefs.setStringList(_searchHistoryKey, history);
  }

  /// Get all search history
  Future<List<String>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_searchHistoryKey) ?? [];
  }

  /// Clear all search history
  Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_searchHistoryKey);
  }

  /// Remove a specific search query from history
  Future<void> removeSearchQuery(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_searchHistoryKey) ?? [];

    history.removeWhere((item) => item.toLowerCase() == query.toLowerCase());

    if (history.isEmpty) {
      await prefs.remove(_searchHistoryKey);
    } else {
      await prefs.setStringList(_searchHistoryKey, history);
    }
  }
}

