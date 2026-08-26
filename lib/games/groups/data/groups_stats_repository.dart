import 'package:isar_community/isar.dart';

import '../../../core/persistence/puzzle_completion.dart';

const String groupsGameId = 'groups';

class GroupsGameStats {
  const GroupsGameStats({
    required this.solvedDayIndices,
    required this.playedDayIndices,
    required this.perfectCount,
  });

  final Set<int> solvedDayIndices;
  final Set<int> playedDayIndices;

  /// Puzzles solved without a single wrong guess.
  final int perfectCount;

  int get totalPlayed => playedDayIndices.length;
  int get totalSolved => solvedDayIndices.length;
}

/// Reads/writes Groups' history against the shared [PuzzleCompletion]
/// collection. The stored `guessesUsed` is the mistake count, which is what
/// separates a clean solve from a scrape.
class GroupsStatsRepository {
  GroupsStatsRepository(this._isar);

  final Isar _isar;

  Future<PuzzleCompletion?> completionForDay(int dayIndex) {
    return _isar.puzzleCompletions
        .filter()
        .gameIdEqualTo(groupsGameId)
        .dayIndexEqualTo(dayIndex)
        .findFirst();
  }

  Future<void> recordCompletion({
    required int dayIndex,
    required bool solved,
    required int mistakes,
  }) async {
    final existing = await completionForDay(dayIndex);
    final record = PuzzleCompletion()
      ..id = existing?.id ?? Isar.autoIncrement
      ..gameId = groupsGameId
      ..dayIndex = dayIndex
      ..won = solved
      ..guessesUsed = mistakes
      ..completedAt = DateTime.now();
    await _isar.writeTxn(() => _isar.puzzleCompletions.put(record));
  }

  Future<GroupsGameStats> loadStats() async {
    final all = await _isar.puzzleCompletions
        .filter()
        .gameIdEqualTo(groupsGameId)
        .findAll();
    final solved = <int>{};
    final played = <int>{};
    var perfect = 0;
    for (final completion in all) {
      played.add(completion.dayIndex);
      if (!completion.won) continue;
      solved.add(completion.dayIndex);
      if ((completion.guessesUsed ?? 0) == 0) perfect++;
    }
    return GroupsGameStats(
      solvedDayIndices: solved,
      playedDayIndices: played,
      perfectCount: perfect,
    );
  }
}
