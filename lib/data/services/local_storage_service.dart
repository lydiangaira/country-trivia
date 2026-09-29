import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting game state locally using SharedPreferences.
///
/// Stores:
/// - `user_score` (`int`) — cumulative points across all rounds
/// - `solved_flags` (`List<String>`) — ISO codes of correctly identified countries
class LocalStorageService {
  static const String _scoreKey = 'user_score';
  static const String _solvedKey = 'solved_flags';

  /// Retrieves the persisted user score.
  ///
  /// Returns 0 if no score has been saved yet.
  Future<int> getScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_scoreKey) ?? 0;
  }

  /// Persists the user score.
  Future<void> setScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_scoreKey, score);
  }

  /// Retrieves the set of solved flag ISO codes.
  ///
  /// Returns an empty set if no flags have been solved yet.
  Future<Set<String>> getSolvedFlags() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_solvedKey) ?? [];
    return list.toSet();
  }

  /// Adds a solved flag ISO code to the persisted set.
  Future<void> addSolvedFlag(String cca2) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getSolvedFlags();
    current.add(cca2);
    await prefs.setStringList(_solvedKey, current.toList());
  }

  /// Clears all solved flags (used on game reset).
  ///
  /// Note: This does NOT reset the user score.
  Future<void> resetSolvedFlags() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_solvedKey);
  }
}
