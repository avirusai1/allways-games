import 'package:isar_community/isar.dart';

import '../../../core/persistence/puzzle_completion.dart';
import '../domain/honeycomb_scoring.dart';

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

/// Mirrors a Honeycomb session's outcome into the shared completion
/// history, for streaks and cross-day stats.
///
/// Free play draws a fresh random board every time the player starts one,
/// so unlike the old daily-lock version there is no single "today's board"
/// to persist and resume — a board in progress lives only in memory for
/// that session, same as every other free-play game in the app.
class HoneycombRepository {
  HoneycombRepository(this._isar);

  final Isar _isar;

  /// Records the day's outcome so far. Called after every accepted word:
  /// if this session's score reaches the daily goal rank, that is recorded
  /// immediately rather than waiting for the player to stop.
  Future<void> recordSession({
    required int dayIndex,
    required int score,
    required int maxScore,
  }) async {
    final reachedGoal =
        score >= honeycombScoreForRank(honeycombDailyGoalRank, maxScore);
    // A day already marked as having reached the goal stays marked, even
    // if this particular session's score is lower — the player earned that
    // once today already.
    final existing = await _isar.puzzleCompletions
        .filter()
        .gameIdEqualTo(honeycombGameId)
        .dayIndexEqualTo(dayIndex)
        .findFirst();
    final bestScoreToday = existing?.guessesUsed;
    final won = reachedGoal || (existing?.won ?? false);
    final scoreToStore = bestScoreToday == null
        ? score
        : (score > bestScoreToday ? score : bestScoreToday);

    final completion = PuzzleCompletion()
      ..id = existing?.id ?? Isar.autoIncrement
      ..gameId = honeycombGameId
      ..dayIndex = dayIndex
      // "Won" here means the day's goal rank was reached at some point
      // today, not that every word was found — on most boards nobody
      // finds every word.
      ..won = won
      ..guessesUsed = scoreToStore
      ..completedAt = DateTime.now();

    await _isar.writeTxn(() => _isar.puzzleCompletions.put(completion));
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
