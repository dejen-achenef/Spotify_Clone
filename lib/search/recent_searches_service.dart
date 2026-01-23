import 'package:shared_preferences/shared_preferences.dart';

class RecentSearchesService {
  static const _key = 'recent-searches';
  static const int maxItems = 10;

  Future<List<String>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? <String>[];
  }

  Future<void> addSearchTerm(String term) async {
    if (term.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? <String>[];
    // Move term to front, unique
    final updated = [term, ...current.where((t) => t != term)].take(maxItems).toList();
    await prefs.setStringList(_key, updated);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
