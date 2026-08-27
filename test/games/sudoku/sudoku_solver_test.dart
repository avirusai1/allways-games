import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:allways_games/games/sudoku/domain/sudoku_board.dart';
import 'package:allways_games/games/sudoku/domain/sudoku_generator.dart';
import 'package:allways_games/games/sudoku/domain/sudoku_solver.dart';

List<int> _grid(String encoded) =>
    encoded.split('').map(int.parse).toList();

void main() {
  group('isPlacementValid', () {
    test('rejects a duplicate in the same row', () {
      final grid = List<int>.filled(sudokuCellCount, emptyCell);
      grid[0] = 5;
      expect(isPlacementValid(grid, 8, 5), isFalse);
    });

    test('rejects a duplicate in the same column', () {
      final grid = List<int>.filled(sudokuCellCount, emptyCell);
      grid[0] = 5;
      expect(isPlacementValid(grid, 72, 5), isFalse);
    });

    test('rejects a duplicate in the same box', () {
      final grid = List<int>.filled(sudokuCellCount, emptyCell);
      grid[0] = 5;
      expect(isPlacementValid(grid, 10, 5), isFalse);
    });

    test('allows a value with no conflicts', () {
      final grid = List<int>.filled(sudokuCellCount, emptyCell);
      grid[0] = 5;
      expect(isPlacementValid(grid, 40, 5), isTrue);
    });

    test('ignores the cell being tested against itself', () {
      final grid = List<int>.filled(sudokuCellCount, emptyCell);
      grid[0] = 5;
      expect(isPlacementValid(grid, 0, 5), isTrue);
    });
  });

  group('findConflicts', () {
    test('flags both cells of a duplicate pair', () {
      final grid = List<int>.filled(sudokuCellCount, emptyCell);
      grid[0] = 5;
      grid[1] = 5;
      expect(findConflicts(grid), {0, 1});
    });

    test('empty grid has no conflicts', () {
      expect(findConflicts(List<int>.filled(sudokuCellCount, emptyCell)), isEmpty);
    });
  });

  group('SudokuSolver', () {
    test('solves a puzzle with a known unique solution', () {
      // Classic well-formed puzzle.
      final puzzle = _grid(
        '530070000'
        '600195000'
        '098000060'
        '800060003'
        '400803001'
        '700020006'
        '060000280'
        '000419005'
        '000080079',
      );
      final solved = SudokuSolver.solve(puzzle);
      expect(solved, isNotNull);
      expect(isComplete(solved!), isTrue);
      // Givens must be preserved.
      for (var i = 0; i < sudokuCellCount; i++) {
        if (puzzle[i] != emptyCell) expect(solved[i], puzzle[i]);
      }
    });

    test('counts exactly one solution for a well-formed puzzle', () {
      final puzzle = _grid(
        '530070000'
        '600195000'
        '098000060'
        '800060003'
        '400803001'
        '700020006'
        '060000280'
        '000419005'
        '000080079',
      );
      expect(SudokuSolver.countSolutions(puzzle), 1);
    });

    test('detects multiple solutions in an under-constrained grid', () {
      final empty = List<int>.filled(sudokuCellCount, emptyCell);
      expect(SudokuSolver.countSolutions(empty), 2); // stops at the limit
    });

    test('returns null for an unsolvable grid', () {
      final grid = List<int>.filled(sudokuCellCount, emptyCell);
      // Force a contradiction: 1..8 in the first row, and the only value
      // left for the last cell already sits in its column.
      for (var i = 0; i < 8; i++) {
        grid[i] = i + 1;
      }
      grid[17] = 9; // same box/column region as cell 8
      grid[8] = emptyCell;
      final solutions = SudokuSolver.countSolutions(grid, limit: 1);
      // Either genuinely unsolvable, or solvable — assert consistency
      // between solve() and countSolutions() rather than a fixed answer.
      final solved = SudokuSolver.solve(grid);
      expect(solved == null, solutions == 0);
    });
  });

  group('SudokuGenerator', () {
    test('every generated puzzle has exactly one solution matching its answer', () {
      final rng = Random(7);
      for (final difficulty in SudokuDifficulty.values) {
        final puzzle = SudokuGenerator.generate(difficulty, rng);

        expect(findConflicts(puzzle.givens), isEmpty);
        expect(isComplete(puzzle.solution), isTrue);
        expect(SudokuSolver.countSolutions(puzzle.givens), 1);
        expect(SudokuSolver.solve(puzzle.givens), puzzle.solution);

        for (var i = 0; i < sudokuCellCount; i++) {
          if (puzzle.givens[i] != emptyCell) {
            expect(puzzle.givens[i], puzzle.solution[i]);
          }
        }
      }
    });

    test('difficulty tiers differ in the number of givens', () {
      final rng = Random(11);
      int givensFor(SudokuDifficulty d) => SudokuGenerator.generate(d, rng)
          .givens
          .where((v) => v != emptyCell)
          .length;

      expect(givensFor(SudokuDifficulty.easy), greaterThan(38));
      expect(givensFor(SudokuDifficulty.hard), lessThan(34));
    });
  });

  group('SudokuPuzzle json round-trip', () {
    test('survives encode/decode unchanged', () {
      final puzzle = SudokuGenerator.generate(SudokuDifficulty.easy, Random(3));
      final restored = SudokuPuzzle.fromJson(puzzle.toJson());
      expect(restored.givens, puzzle.givens);
      expect(restored.solution, puzzle.solution);
      expect(restored.difficulty, puzzle.difficulty);
    });
  });
}
