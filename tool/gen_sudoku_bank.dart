// Offline content generator for Sudoku.
//
// Produces assets/content/sudoku/bank.json. Every generated puzzle is
// verified to have exactly one solution before it is written, so an invalid
// puzzle can never reach the app. Run with:
//   dart run tool/gen_sudoku_bank.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:allways_games/games/sudoku/domain/sudoku_board.dart';
import 'package:allways_games/games/sudoku/domain/sudoku_generator.dart';
import 'package:allways_games/games/sudoku/domain/sudoku_solver.dart';

/// Days of puzzles to generate. Override with --days=N.
const int defaultDayCount = 1825; // five years
const int baseSeed = 20240102;

void main(List<String> args) {
  var dayCount = defaultDayCount;
  for (final arg in args) {
    if (arg.startsWith('--days=')) {
      dayCount = int.parse(arg.substring('--days='.length));
    }
  }

  // Per-day seed, so regenerating with a larger --days never disturbs the
  // puzzles already published for earlier days. A single shared RNG would
  // reshuffle every day's puzzle the moment the count changed.
  final puzzles = <SudokuPuzzle>[];
  for (var day = 0; day < dayCount; day++) {
    // Difficulty cycles by day so consecutive days vary.
    final difficulty =
        SudokuDifficulty.values[day % SudokuDifficulty.values.length];
    final puzzle = SudokuGenerator.generate(difficulty, Random(baseSeed + day));
    _assertValid(puzzle);
    puzzles.add(puzzle);

    if ((day + 1) % 200 == 0) {
      stdout.writeln('${day + 1}/$dayCount generated...');
    }
  }

  final bank = {
    'schemaVersion': 1,
    'game': 'sudoku',
    'generatedAt': '2024-01-02T00:00:00Z',
    'puzzles': puzzles.map((p) => p.toJson()).toList(),
  };

  final outDir = Directory('assets/content/sudoku');
  outDir.createSync(recursive: true);
  final outFile = File('${outDir.path}/bank.json');
  outFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(bank));

  stdout.writeln(
    'Wrote ${outFile.path}: ${puzzles.length} puzzles '
    '(all verified to have exactly one solution).',
  );
}

/// Hard gate: a puzzle only ships if its givens are self-consistent, it has
/// exactly one solution, and that solution matches the recorded one.
void _assertValid(SudokuPuzzle puzzle) {
  if (findConflicts(puzzle.givens).isNotEmpty) {
    throw StateError('Generated puzzle has conflicting givens.');
  }
  if (!isComplete(puzzle.solution)) {
    throw StateError('Generated solution is not a valid complete grid.');
  }
  final solutionCount = SudokuSolver.countSolutions(puzzle.givens);
  if (solutionCount != 1) {
    throw StateError('Generated puzzle has $solutionCount solutions, expected 1.');
  }
  final solved = SudokuSolver.solve(puzzle.givens);
  if (solved == null || !_listEquals(solved, puzzle.solution)) {
    throw StateError('Solver result does not match the recorded solution.');
  }
  // Every given must agree with the solution.
  for (var i = 0; i < sudokuCellCount; i++) {
    if (puzzle.givens[i] != emptyCell &&
        puzzle.givens[i] != puzzle.solution[i]) {
      throw StateError('Given at $i contradicts the solution.');
    }
  }
}

bool _listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
