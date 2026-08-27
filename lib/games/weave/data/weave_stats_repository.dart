import 'package:isar_community/isar.dart';

import '../../../core/persistence/puzzle_completion.dart';

const String weaveGameId = 'weave';

class WeaveGameStats {
  const WeaveGameStats({
    required this.wonDayIndices,
    required this.playedDayIndices,
  });

  final Set<int> wonDayIndices;
  final Set<int> playedDayIndices;

  int get totalPlayed => playedDayIndices.length;
  int get totalWon => wonDayIndices.length;
}

/// Reads/writes Weave history against the shared [PuzzleCompletion]
/// collection, scoped to [weaveGameId].
class WeaveStatsRepository {
  WeaveStatsRepository(this._isar);

  final Isar _isar;

  Future<PuzzleCompletion?> completionForDay(int dayIndex) {
    return _isar.puzzleCompletions
        .filter()
        .gameIdEqualTo(weaveGameId)
        .dayIndexEqualTo(dayIndex)
        .findFirst();
  }

  Future<void> recordCompletion({
    required int dayIndex,
    required bool won,
  }) async {
    final existing = await completionForDay(dayIndex);
    final record = PuzzleCompletion()
      ..id = existing?.id ?? Isar.autoIncrement
      ..gameId = weaveGameId
      ..dayIndex = dayIndex
      ..won = won
      ..completedAt = DateTime.now();
    await _isar.writeTxn(() => _isar.puzzleCompletions.put(record));
  }

  Future<WeaveGameStats> loadStats() async {
    final all = await _isar.puzzleCompletions
        .filter()
        .gameIdEqualTo(weaveGameId)
        .findAll();
    final won = <int>{};
    final played = <int>{};
    for (final c in all) {
      played.add(c.dayIndex);
      if (c.won) won.add(c.dayIndex);
    }
    return WeaveGameStats(wonDayIndices: won, playedDayIndices: played);
  }
}
