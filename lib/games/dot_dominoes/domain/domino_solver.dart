import 'domino_board.dart';
import 'domino_puzzle.dart';

/// Backtracking solver over domino placements.
///
/// Kept separate from the generator because uniqueness checking is the
/// expensive part of generation and the thing most worth testing on its
/// own: a puzzle with two answers is not a hard puzzle, it is a broken
/// one.
class DominoSolver {
  DominoSolver._();

  /// Counts solutions, stopping at [limit].
  ///
  /// Generation only ever asks "exactly one, or more than one?", so the
  /// default of 2 avoids enumerating a large solution space in full.
  static int countSolutions(DominoPuzzle puzzle, {int limit = 2}) {
    final found = <List<DominoPlacement>>[];
    _search(puzzle, limit, found);
    return found.length;
  }

  /// Returns the first solution found, or null if there is none.
  static List<DominoPlacement>? solve(DominoPuzzle puzzle) {
    final found = <List<DominoPlacement>>[];
    _search(puzzle, 1, found);
    return found.isEmpty ? null : found.first;
  }

  static void _search(
    DominoPuzzle puzzle,
    int limit,
    List<List<DominoPlacement>> found,
  ) {
    final pips = List<int?>.filled(dominoCellCount, null);
    final placements = <DominoPlacement>[];

    // Tray counts rather than a flat list: two identical dominoes are
    // interchangeable, and treating them as distinct would multiply every
    // solution by their permutations and make uniqueness meaningless.
    final remaining = <Domino, int>{};
    for (final domino in puzzle.tray) {
      remaining[domino] = (remaining[domino] ?? 0) + 1;
    }

    final regionOf = puzzle.regionOfCell;

    bool regionsOk(int cellA, int cellB) {
      for (final cell in {cellA, cellB}) {
        final index = regionOf[cell];
        if (index == null) continue;
        if (!puzzle.regions[index].isSatisfiable(pips)) return false;
      }
      return true;
    }

    void descend() {
      if (found.length >= limit) return;

      // First unfilled cell in reading order. Fixing the order this way
      // means each tiling is reached once, not once per ordering of the
      // dominoes that make it up.
      var target = -1;
      for (final cell in puzzle.cells) {
        if (pips[cell] == null) {
          target = cell;
          break;
        }
      }
      if (target == -1) {
        found.add(List<DominoPlacement>.of(placements));
        return;
      }

      for (final neighbour in dominoAdjacency[target]) {
        if (!puzzle.present[neighbour] || pips[neighbour] != null) continue;

        for (final entry in remaining.entries.toList()) {
          if (entry.value == 0) continue;
          final domino = entry.key;

          // A non-double can go either way round.
          final orientations = domino.isDouble
              ? [(domino.low, domino.high)]
              : [(domino.low, domino.high), (domino.high, domino.low)];

          for (final (a, b) in orientations) {
            pips[target] = a;
            pips[neighbour] = b;
            remaining[domino] = entry.value - 1;
            placements.add(DominoPlacement(
              cellA: target,
              cellB: neighbour,
              pipsA: a,
              pipsB: b,
            ));

            if (regionsOk(target, neighbour)) descend();

            placements.removeLast();
            remaining[domino] = entry.value;
            pips[target] = null;
            pips[neighbour] = null;

            if (found.length >= limit) return;
          }
        }
      }
    }

    descend();
  }

  /// Whether [placements] is a legal, complete answer to [puzzle].
  static bool isValidSolution(
    DominoPuzzle puzzle,
    List<DominoPlacement> placements,
  ) {
    final pips = List<int?>.filled(dominoCellCount, null);
    final used = <Domino, int>{};

    for (final placement in placements) {
      if (!puzzle.present[placement.cellA] ||
          !puzzle.present[placement.cellB]) {
        return false;
      }
      if (!dominoAdjacency[placement.cellA].contains(placement.cellB)) {
        return false;
      }
      if (pips[placement.cellA] != null || pips[placement.cellB] != null) {
        return false;
      }
      pips[placement.cellA] = placement.pipsA;
      pips[placement.cellB] = placement.pipsB;
      used[placement.domino] = (used[placement.domino] ?? 0) + 1;
    }

    for (final cell in puzzle.cells) {
      if (pips[cell] == null) return false;
    }

    final tray = <Domino, int>{};
    for (final domino in puzzle.tray) {
      tray[domino] = (tray[domino] ?? 0) + 1;
    }
    if (used.length != tray.length) return false;
    for (final entry in used.entries) {
      if (tray[entry.key] != entry.value) return false;
    }

    for (final region in puzzle.regions) {
      if (!region.isSatisfiable(pips)) return false;
    }
    return true;
  }
}
