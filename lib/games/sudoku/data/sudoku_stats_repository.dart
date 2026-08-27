import 'package:isar_community/isar.dart';

import '../../../core/persistence/puzzle_completion.dart';

const String sudokuGameId = 'sudoku';

class SudokuGameStats {
  const SudokuGameStats({
    required this.wonDayIndices,
    required this.playedDayIndices,
    required this.bestSeconds,
  });

  final Set<int> wonDayIndices;
  final Set<int> playedDayIndices;
  final int? bestSeconds;

  int get totalPlayed => playedDayIndices.length;
  int get totalWon => wonDayIndices.length;
}

/// Reads/writes Sudoku history against the shared [PuzzleCompletion]
/// collection, scoped to [sudokuGameId].
class SudokuStatsRepository {
  SudokuStatsRepository(this._isar);

  final Isar _isar;

  Future<PuzzleCompletion?> completionForDay(int dayIndex) {
    return _isar.puzzleCompletions
        .filter()
        .gameIdEqualTo(sudokuGameId)
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
      ..gameId = sudokuGameId
      ..dayIndex = dayIndex
      ..won = won
      ..elapsedSeconds = elapsedSeconds
      ..completedAt = DateTime.now();
    await _isar.writeTxn(() => _isar.puzzleCompletions.put(record));
  }

  Future<SudokuGameStats> loadStats() async {
    final all = await _isar.puzzleCompletions
        .filter()
        .gameIdEqualTo(sudokuGameId)
        .findAll();
    final won = <int>{};
    final played = <int>{};
    int? best;
    for (final c in all) {
      played.add(c.dayIndex);
      if (c.won) {
        won.add(c.dayIndex);
        final seconds = c.elapsedSeconds;
        if (seconds != null && (best == null || seconds < best)) {
          best = seconds;
        }
      }
    }
    return SudokuGameStats(
      wonDayIndices: won,
      playedDayIndices: played,
      bestSeconds: best,
    );
  }
}
