// Offline content generator for "Dot Dominoes".
//
// Produces assets/content/dot_dominoes/bank.json: one puzzle per calendar
// day. Run with:
//   dart run tool/gen_dot_dominoes_bank.dart [--days=1825]
//
// No word list and nothing authored by hand: the rules are this app's own
// design and the puzzles are built and verified by program. Every puzzle
// is checked to have exactly one solution before it is written, because a
// domino puzzle with two answers is indistinguishable from a broken one.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:allways_games/games/dot_dominoes/domain/domino_generator.dart';
import 'package:allways_games/games/dot_dominoes/domain/domino_puzzle.dart';
import 'package:allways_games/games/dot_dominoes/domain/domino_solver.dart';

const int defaultDayCount = 1825;
const int baseSeed = 20240105;
const int attemptsPerDay = 4000;

void main(List<String> args) {
  var dayCount = defaultDayCount;
  for (final arg in args) {
    if (arg.startsWith('--days=')) {
      dayCount = int.parse(arg.substring('--days='.length));
    }
  }

  final puzzles = <DominoPuzzle>[];
  final sizeUse = <int, int>{};

  for (var day = 0; day < dayCount; day++) {
    // Size cycles so the week has a shape rather than every day being the
    // same board.
    final dominoCount = 3 + (day % 3);

    DominoPuzzle? built;
    for (var attempt = 0; attempt < attemptsPerDay && built == null; attempt++) {
      // Per-day seed: regenerating with a larger --days never disturbs the
      // puzzles already published for earlier days.
      final rng = Random(baseSeed + day * attemptsPerDay + attempt);
      built = DominoGenerator.generate(dominoCount: dominoCount, random: rng);
    }

    if (built == null) {
      stderr.writeln('Day $day produced no puzzle.');
      continue;
    }
    _assertValid(built);
    puzzles.add(built);
    sizeUse[dominoCount] = (sizeUse[dominoCount] ?? 0) + 1;

    if ((day + 1) % 200 == 0) stdout.writeln('${day + 1}/$dayCount ...');
  }

  final bank = {
    'schemaVersion': 1,
    'game': 'dot_dominoes',
    'generatedAt': '2024-01-05T00:00:00Z',
    'puzzles': puzzles.map((p) => p.toJson()).toList(),
  };

  final outDir = Directory('assets/content/dot_dominoes');
  outDir.createSync(recursive: true);
  final outFile = File('${outDir.path}/bank.json');
  outFile.writeAsStringSync(jsonEncode(bank));

  stdout.writeln('Wrote ${outFile.path}: ${puzzles.length} verified puzzles.');
  for (final entry in (sizeUse.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key)))) {
    stdout.writeln('  ${entry.key} dominoes: ${entry.value} puzzles');
  }
  stdout.writeln(
    '  file size: ${(outFile.lengthSync() / 1024).toStringAsFixed(0)} KiB',
  );
}

/// Hard gate: a puzzle only ships if it is solvable, uniquely, and its
/// recorded answer is genuinely an answer.
void _assertValid(DominoPuzzle puzzle) {
  final cells = puzzle.cells;
  if (cells.length != puzzle.solution.length * 2) {
    throw StateError('board is ${cells.length} cells for '
        '${puzzle.solution.length} dominoes');
  }
  if (puzzle.tray.length != puzzle.solution.length) {
    throw StateError('tray and solution disagree in size');
  }
  if (puzzle.tray.toSet().length != puzzle.tray.length) {
    throw StateError('tray repeats a domino');
  }

  // Every present cell belongs to exactly one region.
  final counted = <int, int>{};
  for (final region in puzzle.regions) {
    if (region.cells.isEmpty) throw StateError('empty region');
    for (final cell in region.cells) {
      if (!puzzle.present[cell]) throw StateError('region covers a gap');
      counted[cell] = (counted[cell] ?? 0) + 1;
    }
  }
  for (final cell in cells) {
    if (counted[cell] != 1) {
      throw StateError('cell $cell is in ${counted[cell] ?? 0} regions');
    }
  }

  if (!DominoSolver.isValidSolution(puzzle, puzzle.solution)) {
    throw StateError('recorded solution is not valid');
  }
  final count = DominoSolver.countSolutions(puzzle);
  if (count != 1) throw StateError('puzzle has $count solutions');
}
