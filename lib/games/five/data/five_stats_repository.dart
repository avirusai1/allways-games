import 'package:isar_community/isar.dart';

import '../../../core/persistence/puzzle_completion.dart';

const String fiveGameId = 'five';

class FiveGameStats {
  const FiveGameStats({
    required this.wonDayIndices,
    required this.playedDayIndices,
  });

  final Set<int> wonDayIndices;
  final Set<int> playedDayIndices;

  int get totalPlayed => playedDayIndices.length;
  int get totalWon => wonDayIndices.length;
}

/// Reads/writes Five's completion history against the shared
/// [PuzzleCompletion] collection, scoped to [fiveGameId].
class FiveStatsRepository {
  FiveStatsRepository(this._isar);

  final Isar _isar;

  Future<PuzzleCompletion?> completionForDay(int dayIndex) {
    return _isar.puzzleCompletions
        .filter()
        .gameIdEqualTo(fiveGameId)
        .dayIndexEqualTo(dayIndex)
        .findFirst();
  }

  Future<void> recordCompletion({
    required int dayIndex,
    required bool won,
    required int guessesUsed,
  }) async {
    final existing = await completionForDay(dayIndex);
    final record = PuzzleCompletion()
      ..id = existing?.id ?? Isar.autoIncrement
      ..gameId = fiveGameId
      ..dayIndex = dayIndex
      ..won = won
      ..guessesUsed = guessesUsed
      ..completedAt = DateTime.now();
    await _isar.writeTxn(() => _isar.puzzleCompletions.put(record));
  }

  Future<FiveGameStats> loadStats() async {
    final all = await _isar.puzzleCompletions
        .filter()
        .gameIdEqualTo(fiveGameId)
        .findAll();
    final won = <int>{};
    final played = <int>{};
    for (final c in all) {
      played.add(c.dayIndex);
      if (c.won) won.add(c.dayIndex);
    }
    return FiveGameStats(wonDayIndices: won, playedDayIndices: played);
  }
}
