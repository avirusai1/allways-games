import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) => SharedPreferences.getInstance());

class FreePlayDifficultyStats {
  const FreePlayDifficultyStats({required this.solved, required this.bestSeconds});

  final int solved;
  final int? bestSeconds;
}

/// Cumulative stats per difficulty tier, for a game that lets the player
/// choose a difficulty up front and solve as many puzzles as they want
/// rather than one puzzle per calendar day.
///
/// Backed by SharedPreferences rather than Isar: a handful of counters per
/// difficulty doesn't need a database, and it keeps this separate from the
/// existing daily-streak record (PuzzleCompletion) rather than overloading
/// one row-per-day model with "how many did you solve today".
class FreePlayStats {
  FreePlayStats(this._gameId, this._prefs);

  final String _gameId;
  final SharedPreferences _prefs;

  String _solvedKey(String difficulty) => '${_gameId}_solved_$difficulty';
  String _bestKey(String difficulty) => '${_gameId}_best_$difficulty';

  FreePlayDifficultyStats forDifficulty(String difficulty) {
    return FreePlayDifficultyStats(
      solved: _prefs.getInt(_solvedKey(difficulty)) ?? 0,
      bestSeconds: _prefs.getInt(_bestKey(difficulty)),
    );
  }

  /// Records a solve and updates the tracked "best" value for [difficulty].
  ///
  /// By default lower is better (elapsed seconds, fewest words) — the shape
  /// every game but Honeycomb's score uses. Pass [higherIsBetter] for a
  /// metric like a word-finding score, where more is the improvement.
  Future<void> recordSolve(
    String difficulty,
    int value, {
    bool higherIsBetter = false,
  }) async {
    final solvedKey = _solvedKey(difficulty);
    await _prefs.setInt(solvedKey, (_prefs.getInt(solvedKey) ?? 0) + 1);

    final bestKey = _bestKey(difficulty);
    final currentBest = _prefs.getInt(bestKey);
    final improved = currentBest == null ||
        (higherIsBetter ? value > currentBest : value < currentBest);
    if (improved) {
      await _prefs.setInt(bestKey, value);
    }
  }
}
