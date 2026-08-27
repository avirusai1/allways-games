import 'package:isar_community/isar.dart';

import '../../../core/persistence/puzzle_completion.dart';

const String crosswordGameId = 'crossword';

class CrosswordGameStats {
  const CrosswordGameStats({
    required this.wonDayIndices,
    required this.playedDayIndices,
    required this.bestSeconds,
  });

  final Set<int> wonDayIndices;
  final Set<int> playedDayIndices;
  final int? bestSeconds;

  int get totalPlayed => playedDayIndices.length;
}

class CrosswordStatsRepository {
  CrosswordStatsRepository(this._isar);

  final Isar _isar;

  Future<PuzzleCompletion?> completionForDay(int dayIndex) {
    return _isar.puzzleCompletions
        .filter()
        .gameIdEqualTo(crosswordGameId)
        .dayIndexEqualTo(dayIndex)
        .findFirst();
  }

  Future<void> recordCompletion({
    required int dayIndex,
    required bool won,
    required int elapsedSeconds,
  }) async {
    final existing = await completionForDay(dayIndex);
    final record = PuzzleCompletion()
      ..id = existing?.id ?? Isar.autoIncrement
      ..gameId = crosswordGameId
      ..dayIndex = dayIndex
      ..won = won
      ..elapsedSeconds = elapsedSeconds
      ..completedAt = DateTime.now();
    await _isar.writeTxn(() => _isar.puzzleCompletions.put(record));
  }

  Future<CrosswordGameStats> loadStats() async {
    final all = await _isar.puzzleCompletions
        .filter()
        .gameIdEqualTo(crosswordGameId)
        .findAll();
    final won = <int>{};
    final played = <int>{};
    int? best;
    for (final c in all) {
      played.add(c.dayIndex);
      if (c.won) {
        won.add(c.dayIndex);
        final s = c.elapsedSeconds;
        if (s != null && (best == null || s < best)) best = s;
      }
    }
    return CrosswordGameStats(
      wonDayIndices: won,
      playedDayIndices: played,
      bestSeconds: best,
    );
  }
}
