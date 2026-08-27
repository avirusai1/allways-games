import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:allways_games/games/sudoku/domain/sudoku_board.dart';
import 'package:allways_games/games/sudoku/domain/sudoku_game_state.dart';
import 'package:allways_games/games/sudoku/domain/sudoku_generator.dart';

void main() {
  final puzzle = SudokuGenerator.generate(SudokuDifficulty.easy, Random(42));

  test('initial state seeds entries from the givens', () {
    final state = SudokuGameState.initial(puzzle);
    expect(state.entries, puzzle.givens);
    expect(state.status, SudokuStatus.playing);
    expect(state.selectedIndex, isNull);
    expect(state.notesMode, isFalse);
  });

  test('isGiven marks pre-filled cells only', () {
    final state = SudokuGameState.initial(puzzle);
    for (var i = 0; i < sudokuCellCount; i++) {
      expect(state.isGiven(i), puzzle.givens[i] != emptyCell);
    }
  });

  test('remainingCells counts empties', () {
    final state = SudokuGameState.initial(puzzle);
    final expected = puzzle.givens.where((v) => v == emptyCell).length;
    expect(state.remainingCells, expected);
  });

  test('remainingPerDigit reflects placed values', () {
    final state = SudokuGameState.initial(puzzle);
    final counts = state.remainingPerDigit;
    for (var digit = 1; digit <= sudokuSize; digit++) {
      final placed = puzzle.givens.where((v) => v == digit).length;
      expect(counts[digit], sudokuSize - placed);
    }
  });

  test('a fully correct board is complete', () {
    final state = SudokuGameState.initial(puzzle)
        .copyWith(entries: List<int>.from(puzzle.solution));
    expect(isComplete(state.entries), isTrue);
    expect(state.conflicts, isEmpty);
    expect(state.remainingCells, 0);
  });

  test('copyWith can clear the selection explicitly', () {
    final state = SudokuGameState.initial(puzzle).copyWith(selectedIndex: 5);
    expect(state.selectedIndex, 5);
    expect(state.copyWith(clearSelection: true).selectedIndex, isNull);
  });
}
