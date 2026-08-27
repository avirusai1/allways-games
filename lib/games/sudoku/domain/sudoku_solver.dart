import 'sudoku_board.dart';

/// Backtracking solver. Kept separate from the generator so uniqueness
/// checking (the expensive part of generation) is independently testable.
class SudokuSolver {
  SudokuSolver._();

  /// Returns a solved copy of [grid], or null if unsolvable.
  static List<int>? solve(List<int> grid) {
    final working = List<int>.from(grid);
    return _fill(working) ? working : null;
  }

  /// Counts solutions, stopping early once [limit] is reached. Generation
  /// only ever needs to know "exactly one" vs "more than one", so the
  /// default limit of 2 avoids exhaustively enumerating huge solution
  /// spaces for sparse grids.
  static int countSolutions(List<int> grid, {int limit = 2}) {
    final working = List<int>.from(grid);
    var found = 0;
    _count(working, limit, () => found++, () => found);
    return found;
  }

  static bool _fill(List<int> grid) {
    final index = _firstEmpty(grid);
    if (index == null) return true;

    for (var value = 1; value <= sudokuSize; value++) {
      if (!isPlacementValid(grid, index, value)) continue;
      grid[index] = value;
      if (_fill(grid)) return true;
      grid[index] = emptyCell;
    }
    return false;
  }

  static void _count(
    List<int> grid,
    int limit,
    void Function() onFound,
    int Function() currentCount,
  ) {
    if (currentCount() >= limit) return;

    final index = _firstEmpty(grid);
    if (index == null) {
      onFound();
      return;
    }

    for (var value = 1; value <= sudokuSize; value++) {
      if (currentCount() >= limit) return;
      if (!isPlacementValid(grid, index, value)) continue;
      grid[index] = value;
      _count(grid, limit, onFound, currentCount);
      grid[index] = emptyCell;
    }
  }

  /// Picks the empty cell with the fewest legal candidates, which prunes
  /// the search tree far more aggressively than scanning in order.
  static int? _firstEmpty(List<int> grid) {
    int? best;
    var bestCandidates = sudokuSize + 1;

    for (var i = 0; i < sudokuCellCount; i++) {
      if (grid[i] != emptyCell) continue;
      var candidates = 0;
      for (var value = 1; value <= sudokuSize; value++) {
        if (isPlacementValid(grid, i, value)) candidates++;
      }
      if (candidates < bestCandidates) {
        bestCandidates = candidates;
        best = i;
        if (candidates <= 1) break;
      }
    }
    return best;
  }
}
