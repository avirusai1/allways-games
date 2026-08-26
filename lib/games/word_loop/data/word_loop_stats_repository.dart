import 'package:isar_community/isar.dart';

import '../../../core/persistence/puzzle_completion.dart';

const String wordLoopGameId = 'word_loop';

class WordLoopGameStats {
  const WordLoopGameStats({
    required this.solvedDayIndices,
    required this.playedDayIndices,
    required this.bestWordCount,
  });

  final Set<int> solvedDayIndices;
  final Set<int> playedDayIndices;

  /// Fewest words the player has ever finished a board in, or null if they
  /// have not finished one.
  final int? bestWordCount;

  int get totalPlayed => playedDayIndices.length;
  int get totalSolved => solvedDayIndices.length;
}

/// Reads/writes Word Loop's history against the shared [PuzzleCompletion]
/// collection.
///
/// Word Loop cannot be lost — a player either covers the board or leaves
/// it unfinished — so a stored record always means "solved", and the
/// interesting number is how many words it took.
class WordLoopStatsRepository {
  WordLoopStatsRepository(this._isar);

  final Isar _isar;

  Future<PuzzleCompletion?> completionForDay(int dayIndex) {
    return _isar.puzzleCompletions
        .filter()
        .gameIdEqualTo(wordLoopGameId)
        .dayIndexEqualTo(dayIndex)
        .findFirst();
  }

  Future<void> recordCompletion({
    required int dayIndex,
    required int wordsUsed,
  }) async {
    final existing = await completionForDay(dayIndex);
    final record = PuzzleCompletion()
      ..id = existing?.id ?? Isar.autoIncrement
      ..gameId = wordLoopGameId
      ..dayIndex = dayIndex
      ..won = true
      ..guessesUsed = wordsUsed
      ..completedAt = DateTime.now();
    await _isar.writeTxn(() => _isar.puzzleCompletions.put(record));
  }

  Future<WordLoopGameStats> loadStats() async {
    final all = await _isar.puzzleCompletions
        .filter()
        .gameIdEqualTo(wordLoopGameId)
        .findAll();
    final solved = <int>{};
    final played = <int>{};
    int? best;
    for (final completion in all) {
      played.add(completion.dayIndex);
      if (!completion.won) continue;
      solved.add(completion.dayIndex);
      final words = completion.guessesUsed;
      if (words != null && (best == null || words < best)) best = words;
    }
    return WordLoopGameStats(
      solvedDayIndices: solved,
      playedDayIndices: played,
      bestWordCount: best,
    );
  }
}
