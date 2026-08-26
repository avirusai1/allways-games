import 'package:isar_community/isar.dart';

part 'puzzle_completion.g.dart';

/// One record per (gameId, dayIndex) a player has completed or attempted.
/// Shared across all 9 games so stats/streaks/archive logic lives in one
/// place instead of being reimplemented per game.
@collection
class PuzzleCompletion {
  Id id = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('dayIndex')], unique: true)
  late String gameId;

  late int dayIndex;

  late bool won;

  /// Guesses used, seconds elapsed, score, etc. Kept generic since each
  /// game's scoring shape differs; game-specific detail lives in a
  /// per-game data model that references this record's dayIndex/gameId.
  int? guessesUsed;
  int? elapsedSeconds;

  late DateTime completedAt;
}
