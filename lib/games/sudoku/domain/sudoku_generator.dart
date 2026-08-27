import 'dart:math';

import 'sudoku_board.dart';
import 'sudoku_solver.dart';

/// Generates puzzles with a guaranteed-unique solution.
///
/// Run offline via tool/gen_sudoku_bank.dart, never on-device: uniqueness
/// checking is expensive and puzzle quality should be reviewable before it
/// ships.
class SudokuGenerator {
  SudokuGenerator._();

  /// Target number of filled cells per difficulty. Fewer givens means a
  /// harder puzzle; these ranges are the conventional ones for backtracking
  /// generators and are validated by the solver, not assumed.
  static int _targetGivens(SudokuDifficulty difficulty, Random rng) =>
      switch (difficulty) {
        SudokuDifficulty.easy => 40 + rng.nextInt(6), // 40-45
        SudokuDifficulty.medium => 32 + rng.nextInt(5), // 32-36
        SudokuDifficulty.hard => 26 + rng.nextInt(5), // 26-30
      };

  static SudokuPuzzle generate(SudokuDifficulty difficulty, Random rng) {
    final solution = _generateSolvedGrid(rng);
    final givens = _carvePuzzle(solution, difficulty, rng);
    return SudokuPuzzle(
      givens: givens,
      solution: solution,
      difficulty: difficulty,
    );
  }

  /// Randomized backtracking fill produces a uniformly arbitrary complete
  /// grid rather than permutations of one fixed base grid.
  static List<int> _generateSolvedGrid(Random rng) {
    final grid = List<int>.filled(sudokuCellCount, emptyCell);
    _fillRandom(grid, rng);
    return grid;
  }

  static bool _fillRandom(List<int> grid, Random rng) {
    final index = grid.indexOf(emptyCell);
    if (index == -1) return true;

    final values = List<int>.generate(sudokuSize, (i) => i + 1)..shuffle(rng);
    for (final value in values) {
      if (!isPlacementValid(grid, index, value)) continue;
      grid[index] = value;
      if (_fillRandom(grid, rng)) return true;
      grid[index] = emptyCell;
    }
    return false;
  }

  /// Removes cells one at a time, reverting any removal that would allow a
  /// second solution. Guarantees the returned puzzle has exactly one.
  static List<int> _carvePuzzle(
    List<int> solution,
    SudokuDifficulty difficulty,
    Random rng,
  ) {
    final puzzle = List<int>.from(solution);
    final target = _targetGivens(difficulty, rng);
    final order = List<int>.generate(sudokuCellCount, (i) => i)..shuffle(rng);

    var filled = sudokuCellCount;
    for (final index in order) {
      if (filled <= target) break;
      final removed = puzzle[index];
      puzzle[index] = emptyCell;

      if (SudokuSolver.countSolutions(puzzle) != 1) {
        puzzle[index] = removed; // removal made it ambiguous; keep the given
      } else {
        filled--;
      }
    }
    return puzzle;
  }
}
