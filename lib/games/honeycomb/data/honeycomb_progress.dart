import 'package:isar_community/isar.dart';

part 'honeycomb_progress.g.dart';

/// Words a player has found on one day's Honeycomb board.
///
/// Honeycomb is the one game in the roster a player dips into repeatedly
/// through the day rather than finishing in a sitting, so the shared
/// [PuzzleCompletion] record — which only says whether a day was finished —
/// is not enough. Closing the app must not cost a player their words.
@collection
class HoneycombProgress {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late int dayIndex;

  late List<String> foundWords;

  late DateTime updatedAt;
}
