import 'dart:math';

import 'domino_board.dart';
import 'domino_puzzle.dart';
import 'domino_solver.dart';

/// Builds Dot Dominoes puzzles that have exactly one answer.
///
/// Works backwards, which is the only tractable direction: lay a real
/// arrangement down first, then describe it with regions, then check that
/// the description admits nothing else. Generating constraints first and
/// hoping something satisfies them would almost always produce a puzzle
/// with no solution or thousands.
class DominoGenerator {
  DominoGenerator._();

  /// Builds one puzzle, or null if this seed did not work out. Callers
  /// retry; failure is a normal outcome, not an error.
  static DominoPuzzle? generate({
    required int dominoCount,
    required Random random,
    int regionAttempts = 24,
  }) {
    final present = _carveBoard(dominoCount * 2, random);
    if (present == null) return null;

    final tiling = _tile(present, random);
    if (tiling == null) return null;

    // Give each half a pip count, never repeating a domino: a tray with
    // the same tile twice makes "which one goes where" meaningless.
    final available = fullDominoSet()..shuffle(random);
    final placements = <DominoPlacement>[];
    final used = <Domino>{};

    for (final (cellA, cellB) in tiling) {
      Domino? pick;
      for (final candidate in available) {
        if (used.add(candidate)) {
          pick = candidate;
          break;
        }
      }
      if (pick == null) return null;
      final flip = random.nextBool() && !pick.isDouble;
      placements.add(DominoPlacement(
        cellA: cellA,
        cellB: cellB,
        pipsA: flip ? pick.high : pick.low,
        pipsB: flip ? pick.low : pick.high,
      ));
    }

    final pips = List<int>.filled(dominoCellCount, 0);
    for (final placement in placements) {
      pips[placement.cellA] = placement.pipsA;
      pips[placement.cellB] = placement.pipsB;
    }

    // Try several region carvings over the same arrangement before giving
    // up on it: the arrangement is the expensive part, the description is
    // cheap to redo.
    for (var attempt = 0; attempt < regionAttempts; attempt++) {
      final regions = _describe(present, pips, random);
      if (regions == null) continue;

      final puzzle = DominoPuzzle(
        present: present,
        regions: regions,
        tray: placements.map((p) => p.domino).toList(),
        solution: placements,
      );

      if (DominoSolver.countSolutions(puzzle) == 1) return puzzle;
    }
    return null;
  }

  /// Carves a contiguous board of [cellCount] cells out of the grid.
  static List<bool>? _carveBoard(int cellCount, Random random) {
    if (cellCount > dominoCellCount) return null;
    final present = List<bool>.filled(dominoCellCount, false);
    final frontier = <int>{random.nextInt(dominoCellCount)};
    var placed = 0;

    while (placed < cellCount) {
      if (frontier.isEmpty) return null;
      final options = frontier.toList()..shuffle(random);
      final cell = options.first;
      frontier.remove(cell);
      if (present[cell]) continue;
      present[cell] = true;
      placed++;
      for (final next in dominoAdjacency[cell]) {
        if (!present[next]) frontier.add(next);
      }
    }
    return present;
  }

  /// Perfect matching of the board into dominoes.
  static List<(int, int)>? _tile(List<bool> present, Random random) {
    final filled = List<bool>.of(present.map((p) => !p));
    final pairs = <(int, int)>[];

    bool descend() {
      var target = -1;
      for (var i = 0; i < dominoCellCount; i++) {
        if (!filled[i]) {
          target = i;
          break;
        }
      }
      if (target == -1) return true;

      final neighbours = List<int>.of(dominoAdjacency[target])..shuffle(random);
      for (final neighbour in neighbours) {
        if (filled[neighbour]) continue;
        filled[target] = true;
        filled[neighbour] = true;
        pairs.add((target, neighbour));
        if (descend()) return true;
        pairs.removeLast();
        filled[target] = false;
        filled[neighbour] = false;
      }
      return false;
    }

    return descend() ? pairs : null;
  }

  /// Splits the board into regions and gives each one a rule its own pips
  /// already satisfy.
  static List<DominoRegion>? _describe(
    List<bool> present,
    List<int> pips,
    Random random,
  ) {
    final cells = [
      for (var i = 0; i < dominoCellCount; i++)
        if (present[i]) i,
    ]..shuffle(random);

    final assigned = <int, int>{};
    final groups = <List<int>>[];

    for (final cell in cells) {
      if (assigned.containsKey(cell)) continue;
      // Small regions state more; a region covering half the board says
      // almost nothing about any individual pip.
      final target = 2 + random.nextInt(3);
      final group = <int>[cell];
      assigned[cell] = groups.length;

      while (group.length < target) {
        final candidates = <int>[
          for (final member in group)
            for (final next in dominoAdjacency[member])
              if (present[next] && !assigned.containsKey(next)) next,
        ];
        if (candidates.isEmpty) break;
        final next = candidates[random.nextInt(candidates.length)];
        assigned[next] = groups.length;
        group.add(next);
      }
      groups.add(group);
    }

    final regions = <DominoRegion>[];
    for (final group in groups) {
      final values = group.map((c) => pips[c]).toList();
      final rule = _ruleFor(values, random);
      if (rule == null) return null;
      regions.add(DominoRegion(
        cells: group,
        rule: rule.$1,
        value: rule.$2,
      ));
    }
    return regions;
  }

  /// Picks a rule that [values] satisfies, preferring the ones that say
  /// most about the pips.
  static (DominoRule, int)? _ruleFor(List<int> values, Random random) {
    final options = <(DominoRule, int)>[];

    if (values.every((v) => v == values.first) && values.length > 1) {
      options.add((DominoRule.same, 0));
    }
    if (values.toSet().length == values.length && values.length > 1) {
      options.add((DominoRule.allDifferent, 0));
    }
    final maximum = values.reduce(max);
    final minimum = values.reduce(min);
    if (maximum < dominoMaxPips) {
      // "under n" only bites when n is just above the largest pip.
      options.add((DominoRule.lessThan, maximum + 1));
    }
    if (minimum > 0) {
      options.add((DominoRule.greaterThan, minimum - 1));
    }
    // A sum always applies and is the workhorse, so it goes in twice to
    // keep boards from being wall-to-wall symbols.
    final total = values.fold<int>(0, (a, b) => a + b);
    options.add((DominoRule.sum, total));
    options.add((DominoRule.sum, total));

    if (options.isEmpty) return null;
    return options[random.nextInt(options.length)];
  }
}
