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

/// Puzzles per difficulty. The bank cycles by day index, so this is how
/// many days of each difficulty ship before repeats.
const int puzzlesPerDifficulty = 140;

void main() {
  // Fixed seed: regenerating produces a byte-identical bank.
  final rng = Random(20240102);
  final puzzles = <SudokuPuzzle>[];

  for (final difficulty in SudokuDifficulty.values) {
    for (var i = 0; i < puzzlesPerDifficulty; i++) {
      final puzzle = SudokuGenerator.generate(difficulty, rng);
      _assertValid(puzzle);
      puzzles.add(puzzle);
    }
    stdout.writeln('Generated $puzzlesPerDifficulty ${difficulty.name} puzzles.');
  }

  // Interleave difficulties so consecutive days vary instead of serving
  // 140 easy puzzles in a row.
  final interleaved = <SudokuPuzzle>[];
  for (var i = 0; i < puzzlesPerDifficulty; i++) {
    for (var d = 0; d < SudokuDifficulty.values.length; d++) {
      interleaved.add(puzzles[d * puzzlesPerDifficulty + i]);
    }
  }

  final bank = {
    'schemaVersion': 1,
    'game': 'sudoku',
    'generatedAt': '2024-01-02T00:00:00Z',
    'puzzles': interleaved.map((p) => p.toJson()).toList(),
  };

  final outDir = Directory('assets/content/sudoku');
  outDir.createSync(recursive: true);
  final outFile = File('${outDir.path}/bank.json');
  outFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(bank));

  stdout.writeln(
    'Wrote ${outFile.path}: ${interleaved.length} puzzles '
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
