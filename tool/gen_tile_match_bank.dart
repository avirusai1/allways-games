// Offline content generator for the "Tile Match" game.
//
// Produces assets/content/tile_match/bank.json: one board per calendar
// day, each a tile layout plus the face on every tile. Run with:
//   dart run tool/gen_tile_match_bank.dart [--days=730]
//
// There is no external content source here and there cannot be one. The
// layouts are described in code (lib/games/tile_match/domain/
// tile_layout.dart) and the tile faces are plain shape-and-colour pairs
// the app draws itself, so nothing is copied from any existing tile set.
//
// Boards are built by playing a solve backwards: walk a legal removal
// order, painting each pair taken with a shared face. The order walked is
// by construction a way to clear the finished board.
//
// Every board is then re-checked with an independent clearing search
// before the file is written. A failure aborts the run rather than
// shipping a board nobody can finish.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:allways_games/games/tile_match/domain/tile_board.dart';
import 'package:allways_games/games/tile_match/domain/tile_layout.dart';
import 'package:allways_games/games/tile_match/domain/tile_match_generator.dart';
import 'package:allways_games/games/tile_match/domain/tile_match_puzzle.dart';

const int defaultDayCount = 730;
const int baseSeed = 20240101;

void main(List<String> args) {
  var dayCount = defaultDayCount;
  for (final arg in args) {
    if (arg.startsWith('--days=')) {
      dayCount = int.parse(arg.substring('--days='.length));
    }
  }

  final stopwatch = Stopwatch()..start();
  final boards = <TileMatchPuzzle>[];

  for (var day = 0; day < dayCount; day++) {
    // Per-day seed, so regenerating with a larger --days never disturbs
    // the boards already published for earlier days.
    final random = Random(baseSeed + day);
    // Rotate the layouts rather than picking at random: a player gets a
    // visibly different silhouette each day instead of the same shape
    // three times running by chance.
    final layout = tileLayouts[day % tileLayouts.length];

    final puzzle = TileMatchGenerator.generate(
      layout: layout,
      random: random,
    );
    if (puzzle == null) {
      stderr.writeln('Day $day: gave up building a ${layout.name} board.');
      exit(1);
    }
    _verify(day, puzzle);
    boards.add(puzzle);

    if ((day + 1) % 100 == 0) {
      stdout.writeln(
        'Built ${day + 1}/$dayCount boards '
        '(${stopwatch.elapsed.inSeconds}s elapsed)',
      );
    }
  }

  final bank = {
    'schemaVersion': 1,
    'game': 'tile_match',
    'generatedAt': '2024-01-01T00:00:00Z',
    'puzzles': boards.map((p) => p.toJson()).toList(),
  };

  final outDir = Directory('assets/content/tile_match');
  outDir.createSync(recursive: true);
  final outFile = File('${outDir.path}/bank.json');
  outFile.writeAsStringSync(jsonEncode(bank));

  stdout.writeln(
    'Wrote ${outFile.path}: ${boards.length} verified boards '
    'in ${stopwatch.elapsed.inSeconds}s.',
  );
  for (final layout in tileLayouts) {
    final count = boards.where((b) => b.layout.name == layout.name).length;
    stdout.writeln(
      '  ${layout.name.padRight(10)} ${layout.tileCount} tiles, '
      '$count boards',
    );
  }
  stdout.writeln(
    '  file size: ${(outFile.lengthSync() / 1024).toStringAsFixed(0)} KiB',
  );
}

/// Aborts the run unless [puzzle] is sound.
void _verify(int day, TileMatchPuzzle puzzle) {
  void fail(String reason) {
    stderr.writeln('Day $day (${puzzle.layout.name}): $reason');
    exit(1);
  }

  if (puzzle.faces.length != puzzle.layout.slots.length) {
    fail('has ${puzzle.faces.length} faces for '
        '${puzzle.layout.slots.length} slots');
  }

  // Every face must appear an even number of times, or some tile can never
  // be paired off however well the board is played.
  final counts = <int, int>{};
  for (final face in puzzle.faces.values) {
    counts[face.id] = (counts[face.id] ?? 0) + 1;
  }
  for (final entry in counts.entries) {
    if (entry.value.isOdd) {
      fail('face ${entry.key} appears ${entry.value} times, which is odd');
    }
  }

  final solvable = TileBoard.isSolvable(puzzle.allSlots, puzzle.faces);
  if (solvable == null) {
    fail('could not be proven clearable inside the search budget');
  }
  if (solvable == false) fail('cannot be cleared');

  // A board that round-trips wrong would ship fine and load broken.
  final restored = TileMatchPuzzle.fromJson(puzzle.toJson());
  for (final slot in puzzle.layout.slots) {
    if (restored.faces[slot] != puzzle.faces[slot]) {
      fail('does not survive a json round-trip at $slot');
    }
  }
}
