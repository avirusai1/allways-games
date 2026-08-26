import 'package:isar_community/isar.dart';

import '../../../core/persistence/puzzle_completion.dart';

const String tileMatchGameId = 'tile_match';

class TileMatchGameStats {
  const TileMatchGameStats({
    required this.clearedDayIndices,
    required this.playedDayIndices,
    required this.bestSeconds,
  });

  final Set<int> clearedDayIndices;
  final Set<int> playedDayIndices;

  /// Fastest clear, or null if no board has been cleared.
  final int? bestSeconds;

  int get totalPlayed => playedDayIndices.length;
  int get totalCleared => clearedDayIndices.length;
}

/// Reads/writes Tile Match's history against the shared [PuzzleCompletion]
/// collection.
class TileMatchStatsRepository {
  TileMatchStatsRepository(this._isar);

  final Isar _isar;

  Future<PuzzleCompletion?> completionForDay(int dayIndex) {
    return _isar.puzzleCompletions
        .filter()
        .gameIdEqualTo(tileMatchGameId)
        .dayIndexEqualTo(dayIndex)
        .findFirst();
  }

  Future<void> recordCompletion({
    required int dayIndex,
    required bool cleared,
    required int elapsedSeconds,
  }) async {
    final existing = await completionForDay(dayIndex);
    final record = PuzzleCompletion()
      ..id = existing?.id ?? Isar.autoIncrement
      ..gameId = tileMatchGameId
      ..dayIndex = dayIndex
      ..won = cleared
      ..elapsedSeconds = elapsedSeconds
      ..completedAt = DateTime.now();
    await _isar.writeTxn(() => _isar.puzzleCompletions.put(record));
  }

  Future<TileMatchGameStats> loadStats() async {
    final all = await _isar.puzzleCompletions
        .filter()
        .gameIdEqualTo(tileMatchGameId)
        .findAll();
    final cleared = <int>{};
    final played = <int>{};
    int? best;
    for (final completion in all) {
      played.add(completion.dayIndex);
      if (!completion.won) continue;
      cleared.add(completion.dayIndex);
      final seconds = completion.elapsedSeconds;
      if (seconds != null && (best == null || seconds < best)) best = seconds;
    }
    return TileMatchGameStats(
      clearedDayIndices: cleared,
      playedDayIndices: played,
      bestSeconds: best,
    );
  }
}
