import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../games/honeycomb/data/honeycomb_progress.dart';
import 'puzzle_completion.dart';

/// Opens (once) the shared Isar database used for stats/streaks/history
/// across every game module. Individual games should depend on this
/// provider rather than opening their own Isar instance.
///
/// Most games need nothing beyond the shared [PuzzleCompletion] record.
/// A game that has to remember mid-puzzle state adds its own collection
/// here — [HoneycombProgress] is the first, because Honeycomb is played in
/// several visits across a day rather than in one sitting.
final isarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    [PuzzleCompletionSchema, HoneycombProgressSchema],
    directory: dir.path,
  );
});
