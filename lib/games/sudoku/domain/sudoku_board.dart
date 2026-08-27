/// Pure-Dart Sudoku board model. No Flutter imports so the rules are
/// independently unit-testable and reusable from the offline generator in
/// tool/gen_sudoku_bank.dart.
library;

const int sudokuSize = 9;
const int sudokuCellCount = sudokuSize * sudokuSize;
const int sudokuBoxSize = 3;

/// 0 represents an empty cell.
const int emptyCell = 0;

enum SudokuDifficulty { easy, medium, hard }

extension SudokuDifficultyLabel on SudokuDifficulty {
  String get label => switch (this) {
        SudokuDifficulty.easy => 'Easy',
        SudokuDifficulty.medium => 'Medium',
        SudokuDifficulty.hard => 'Hard',
      };
}

/// One generated puzzle: the starting grid plus its unique solution.
class SudokuPuzzle {
  const SudokuPuzzle({
    required this.givens,
    required this.solution,
    required this.difficulty,
  });

  /// 81 values, 0 for cells the player must fill.
  final List<int> givens;

  /// 81 values, the single valid completion of [givens].
  final List<int> solution;

  final SudokuDifficulty difficulty;

  factory SudokuPuzzle.fromJson(Map<String, dynamic> json) => SudokuPuzzle(
        givens: _parseGrid(json['givens'] as String),
        solution: _parseGrid(json['solution'] as String),
        difficulty: SudokuDifficulty.values.byName(json['difficulty'] as String),
      );

  Map<String, dynamic> toJson() => {
        'givens': _encodeGrid(givens),
        'solution': _encodeGrid(solution),
        'difficulty': difficulty.name,
      };

  static List<int> _parseGrid(String encoded) {
    assert(encoded.length == sudokuCellCount);
    return encoded.split('').map((c) => int.parse(c)).toList();
  }

  static String _encodeGrid(List<int> grid) => grid.join();
}

int rowOf(int index) => index ~/ sudokuSize;
int colOf(int index) => index % sudokuSize;
int boxOf(int index) =>
    (rowOf(index) ~/ sudokuBoxSize) * sudokuBoxSize + (colOf(index) ~/ sudokuBoxSize);

/// Whether placing [value] at [index] violates row/column/box constraints.
/// Ignores the current contents of [index] itself.
bool isPlacementValid(List<int> grid, int index, int value) {
  final row = rowOf(index);
  final col = colOf(index);
  final boxRowStart = (row ~/ sudokuBoxSize) * sudokuBoxSize;
  final boxColStart = (col ~/ sudokuBoxSize) * sudokuBoxSize;

  for (var i = 0; i < sudokuSize; i++) {
    final rowIndex = row * sudokuSize + i;
    if (rowIndex != index && grid[rowIndex] == value) return false;

    final colIndex = i * sudokuSize + col;
    if (colIndex != index && grid[colIndex] == value) return false;
  }

  for (var r = 0; r < sudokuBoxSize; r++) {
    for (var c = 0; c < sudokuBoxSize; c++) {
      final boxIndex = (boxRowStart + r) * sudokuSize + (boxColStart + c);
      if (boxIndex != index && grid[boxIndex] == value) return false;
    }
  }

  return true;
}

/// Indices whose value conflicts with another filled cell. Used to surface
/// mistakes in the UI without revealing the solution.
Set<int> findConflicts(List<int> grid) {
  final conflicts = <int>{};
  for (var i = 0; i < sudokuCellCount; i++) {
    final value = grid[i];
    if (value == emptyCell) continue;
    if (!isPlacementValid(grid, i, value)) conflicts.add(i);
  }
  return conflicts;
}

bool isComplete(List<int> grid) =>
    !grid.contains(emptyCell) && findConflicts(grid).isEmpty;
