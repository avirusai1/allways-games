import 'package:isar_community/isar.dart';

import '../../../core/persistence/puzzle_completion.dart';
import '../domain/honeycomb_scoring.dart';
import 'honeycomb_progress.dart';

const String honeycombGameId = 'honeycomb';

/// Rank that counts a day as done for streak purposes.
///
/// Honeycomb has no natural finish — finding every word is out of reach on
/// most boards — so the streak needs a bar that a good session clears and
/// a two-minute poke does not. Builder sits at a quarter of the board.
const String honeycombDailyGoalRankName = 'Builder';

HoneycombRank get honeycombDailyGoalRank =>
    honeycombRanks.firstWhere((r) => r.name == honeycombDailyGoalRankName);

class HoneycombGameStats {
  const HoneycombGameStats({
    required this.goalDayIndices,
    required this.playedDayIndices,
    required this.bestScore,
  });

  /// Days the player reached the daily goal rank on.
  final Set<int> goalDayIndices;

  final Set<int> playedDayIndices;

  /// Highest score reached on any board, or null if none has been played.
  final int? bestScore;

  int get totalPlayed => playedDayIndices.length;
  int get totalGoals => goalDayIndices.length;
}

/// Stores which words a player has found on each day's board, and mirrors
/// the day's outcome into the shared completion history for streaks.
class HoneycombRepository {
  HoneycombRepository(this._isar);

  final Isar _isar;

  Future<Set<String>> foundWordsForDay(int dayIndex) async {
    final progress = await _isar.honeycombProgress
        .filter()
        .dayIndexEqualTo(dayIndex)
        .findFirst();
    return progress?.foundWords.toSet() ?? <String>{};
  }

  /// Saves the day's found words and updates its completion record.
  ///
  /// Called after every accepted word, so a player who closes the app mid
  /// board loses nothing.
  Future<void> saveProgress({
    required int dayIndex,
    required Set<String> foundWords,
    required int score,
    required int maxScore,
  }) async {
    final progress = HoneycombProgress()
      ..dayIndex = dayIndex
      ..foundWords = foundWords.toList()
      ..updatedAt = DateTime.now();

    final reachedGoal =
        score >= honeycombScoreForRank(honeycombDailyGoalRank, maxScore);

    final existing = await _isar.puzzleCompletions
        .filter()
        .gameIdEqualTo(honeycombGameId)
        .dayIndexEqualTo(dayIndex)
        .findFirst();
    final completion = PuzzleCompletion()
      ..id = existing?.id ?? Isar.autoIncrement
      ..gameId = honeycombGameId
      ..dayIndex = dayIndex
      // "Won" here means the day's goal rank was reached, not that every
      // word was found — on most boards nobody finds every word.
      ..won = reachedGoal
      ..guessesUsed = score
      ..completedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.honeycombProgress.put(progress);
      await _isar.puzzleCompletions.put(completion);
    });
  }

  Future<HoneycombGameStats> loadStats() async {
    final all = await _isar.puzzleCompletions
        .filter()
        .gameIdEqualTo(honeycombGameId)
        .findAll();
    final goals = <int>{};
    final played = <int>{};
    int? best;
    for (final completion in all) {
      played.add(completion.dayIndex);
      if (completion.won) goals.add(completion.dayIndex);
      final score = completion.guessesUsed;
      if (score != null && (best == null || score > best)) best = score;
    }
    return HoneycombGameStats(
      goalDayIndices: goals,
      playedDayIndices: played,
      bestScore: best,
    );
  }
}
