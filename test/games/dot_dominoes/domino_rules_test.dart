import 'dart:math';

import 'package:allways_games/games/dot_dominoes/domain/domino_board.dart';
import 'package:allways_games/games/dot_dominoes/domain/domino_game_state.dart';
import 'package:allways_games/games/dot_dominoes/domain/domino_generator.dart';
import 'package:allways_games/games/dot_dominoes/domain/domino_puzzle.dart';
import 'package:allways_games/games/dot_dominoes/domain/domino_solver.dart';
import 'package:flutter_test/flutter_test.dart';

List<int?> _pips(Map<int, int> values) {
  final out = List<int?>.filled(dominoCellCount, null);
  values.forEach((cell, value) => out[cell] = value);
  return out;
}

void main() {
  group('geometry', () {
    test('a domino only spans orthogonal neighbours', () {
      final centre = dominoIndexAt(2, 2);
      expect(dominoAdjacency[centre], hasLength(4));
      // Diagonals are not neighbours: a domino is a straight tile.
      expect(dominoAdjacency[centre], isNot(contains(dominoIndexAt(1, 1))));
    });

    test('a corner has two neighbours', () {
      expect(dominoAdjacency[dominoIndexAt(0, 0)], hasLength(2));
    });
  });

  group('region rules', () {
    test('sum rejects an overshoot immediately', () {
      const region = DominoRegion(cells: [0, 1], rule: DominoRule.sum, value: 5);
      expect(region.isSatisfiable(_pips({0: 6})), isFalse);
      expect(region.isSatisfiable(_pips({0: 2})), isTrue);
      expect(region.isSatisfiable(_pips({0: 2, 1: 3})), isTrue);
      expect(region.isSatisfiable(_pips({0: 2, 1: 2})), isFalse);
    });

    test('sum rejects a total that can no longer be reached', () {
      // Two cells, target 12, and the first is a 0: even a six leaves it
      // short, so the branch is dead now rather than two moves later.
      const region =
          DominoRegion(cells: [0, 1], rule: DominoRule.sum, value: 12);
      expect(region.isSatisfiable(_pips({0: 0})), isFalse);
      expect(region.isSatisfiable(_pips({0: 6})), isTrue);
    });

    test('same demands equal pips', () {
      const region = DominoRegion(cells: [0, 1], rule: DominoRule.same, value: 0);
      expect(region.isSatisfiable(_pips({0: 3, 1: 3})), isTrue);
      expect(region.isSatisfiable(_pips({0: 3, 1: 4})), isFalse);
      // A single pip cannot yet contradict it.
      expect(region.isSatisfiable(_pips({0: 3})), isTrue);
    });

    test('allDifferent rejects a repeat', () {
      const region =
          DominoRegion(cells: [0, 1, 2], rule: DominoRule.allDifferent, value: 0);
      expect(region.isSatisfiable(_pips({0: 1, 1: 2})), isTrue);
      expect(region.isSatisfiable(_pips({0: 1, 1: 1})), isFalse);
    });

    test('lessThan and greaterThan bound every pip', () {
      const under =
          DominoRegion(cells: [0, 1], rule: DominoRule.lessThan, value: 3);
      expect(under.isSatisfiable(_pips({0: 2})), isTrue);
      expect(under.isSatisfiable(_pips({0: 3})), isFalse);

      const over =
          DominoRegion(cells: [0, 1], rule: DominoRule.greaterThan, value: 3);
      expect(over.isSatisfiable(_pips({0: 4})), isTrue);
      expect(over.isSatisfiable(_pips({0: 3})), isFalse);
    });
  });

  group('domino set', () {
    test('the double-six set is 28 distinct tiles', () {
      final set = fullDominoSet();
      expect(set, hasLength(28));
      expect(set.toSet(), hasLength(28));
    });

    test('a domino is written low pip first however it is built', () {
      expect(Domino.of(5, 2), Domino(2, 5));
      expect(Domino.of(2, 5).low, 2);
    });
  });

  group('generator', () {
    test('every generated puzzle has exactly one solution', () {
      final rng = Random(9);
      var built = 0;
      for (var seed = 0; seed < 120 && built < 12; seed++) {
        final puzzle = DominoGenerator.generate(
          dominoCount: 3 + (seed % 3),
          random: Random(rng.nextInt(1 << 30)),
        );
        if (puzzle == null) continue;
        built++;

        expect(DominoSolver.countSolutions(puzzle), 1);
        expect(DominoSolver.isValidSolution(puzzle, puzzle.solution), isTrue);

        // The tray must match the arrangement exactly.
        expect(puzzle.tray.length, puzzle.solution.length);
        expect(puzzle.tray.toSet().length, puzzle.tray.length);

        // Regions must partition the board, or a cell would be
        // unconstrained or double-constrained.
        final counted = <int, int>{};
        for (final region in puzzle.regions) {
          for (final cell in region.cells) {
            counted[cell] = (counted[cell] ?? 0) + 1;
          }
        }
        for (final cell in puzzle.cells) {
          expect(counted[cell], 1, reason: 'cell $cell');
        }
      }
      expect(built, greaterThan(0), reason: 'generator produced nothing');
    });
  });

  group('game state', () {
    DominoPuzzle build() {
      for (var seed = 0; seed < 200; seed++) {
        final puzzle = DominoGenerator.generate(
          dominoCount: 3,
          random: Random(seed),
        );
        if (puzzle != null) return puzzle;
      }
      throw StateError('no puzzle generated for the test');
    }

    test('a fresh board is empty and unsolved', () {
      final state = DominoGameState.initial(build());
      expect(state.placed, isEmpty);
      expect(state.status, DominoStatus.playing);
      expect(state.boardFull, isFalse);
    });

    test('placing the real solution solves it', () {
      final puzzle = build();
      var state = DominoGameState.initial(puzzle);
      for (var i = 0; i < puzzle.solution.length; i++) {
        final placement = puzzle.solution[i];
        // Hold the matching tray tile, oriented as the answer has it.
        final trayIndex = [
          for (var t = 0; t < puzzle.tray.length; t++)
            if (puzzle.tray[t] == placement.domino) t,
        ].firstWhere((t) => !state.usedTrayIndices.contains(t));

        state = state.selectTray(trayIndex);
        if (state.puzzle.tray[trayIndex].low != placement.pipsA &&
            !state.puzzle.tray[trayIndex].isDouble) {
          state = state.selectTray(trayIndex); // flip
        }
        final result = state.place(placement.cellA, placement.cellB);
        expect(result.outcome, DominoPlaceOutcome.placed);
        state = result.state;
      }
      expect(state.boardFull, isTrue);
      expect(state.status, DominoStatus.solved);
      expect(state.brokenRegions, isEmpty);
    });

    test('a domino will not go on an occupied or non-adjacent pair', () {
      final puzzle = build();
      final first = puzzle.solution.first;
      var state = DominoGameState.initial(puzzle).selectTray(0);

      // Non-adjacent cells are refused.
      final far = puzzle.cells.firstWhere(
        (c) => !dominoAdjacency[first.cellA].contains(c) && c != first.cellA,
        orElse: () => -1,
      );
      if (far != -1) {
        expect(
          state.place(first.cellA, far).outcome,
          DominoPlaceOutcome.blocked,
        );
      }

      // Once a cell is covered, nothing else may sit on it.
      state = state.place(first.cellA, first.cellB).state;
      state = state.selectTray(1);
      expect(
        state.place(first.cellA, first.cellB).outcome,
        DominoPlaceOutcome.blocked,
      );
    });

    test('tapping a placed domino lifts it back off', () {
      final puzzle = build();
      final first = puzzle.solution.first;
      var state = DominoGameState.initial(puzzle).selectTray(0);
      state = state.place(first.cellA, first.cellB).state;
      expect(state.placed, hasLength(1));

      state = state.removeAt(first.cellA);
      expect(state.placed, isEmpty);
      expect(state.usedTrayIndices, isEmpty);
    });

    test('selecting the held domino again turns it round', () {
      final puzzle = build();
      // Find a tray tile that is not a double, since a double reads the
      // same either way.
      final index = [
        for (var i = 0; i < puzzle.tray.length; i++)
          if (!puzzle.tray[i].isDouble) i,
      ].firstOrNull;
      if (index == null) return;

      var state = DominoGameState.initial(puzzle).selectTray(index);
      expect(state.flipped, isFalse);
      state = state.selectTray(index);
      expect(state.flipped, isTrue);
    });
  });
}
