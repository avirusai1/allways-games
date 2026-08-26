import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'puzzle_completion.dart';

/// Opens (once) the shared Isar database used for stats/streaks/history
/// across every game module. Individual games should depend on this
/// provider rather than opening their own Isar instance.
final isarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    [PuzzleCompletionSchema],
    directory: dir.path,
  );
});
