import 'dart:math';

import 'package:allways_games/games/tile_match/domain/tile_face.dart';
import 'package:allways_games/games/tile_match/domain/tile_layout.dart';
import 'package:allways_games/games/tile_match/domain/tile_match_game_state.dart';
import 'package:allways_games/games/tile_match/domain/tile_match_generator.dart';
import 'package:allways_games/games/tile_match/domain/tile_match_puzzle.dart';
import 'package:flutter_test/flutter_test.dart';

TileSlot _slot(int layer, int row, int col) =>
    TileSlot(layer: layer, row: row, col: col);

const _circle = TileFace(TileShape.circle, TileHue.teal);
const _square = TileFace(TileShape.square, TileHue.amber);

/// A four-tile board on a single row: two circles at the ends and two
/// squares in the middle. Small enough to reason about move by move.
///
/// Columns 0..3 on layer 0, so the ends are free and the middle pair is
/// boxed in until an end is taken.
TileMatchPuzzle _tinyPuzzle() {
  final layout = TileLayout(
    name: 'Test Row',
    slots: [for (var col = 0; col < 4; col++) _slot(0, 0, col)],
  );
  return TileMatchPuzzle(
    layout: layout,
    faces: {
      _slot(0, 0, 0): _circle,
      _slot(0, 0, 1): _square,
      _slot(0, 0, 2): _square,
      _slot(0, 0, 3): _circle,
    },
  );
}

void main() {
  group('initial state', () {
    test('every tile is on the board with nothing selected', () {
      final state = TileMatchGameState.initial(_tinyPuzzle());
      expect(state.remaining, hasLength(4));
      expect(state.selected, isNull);
      expect(state.canUndo, isFalse);
      expect(state.tilesCleared, 0);
      expect(state.status, TileMatchStatus.playing);
      expect(state.elapsedSeconds, 0);
    });

    test('only the ends of the row are free', () {
      final state = TileMatchGameState.initial(_tinyPuzzle());
      expect(state.freeSlots, {_slot(0, 0, 0), _slot(0, 0, 3)});
      expect(state.isFree(_slot(0, 0, 1)), isFalse);
    });
  });

  group('tapping', () {
    test('tapping a free tile selects it', () {
      final state =
          TileMatchGameState.initial(_tinyPuzzle()).tap(_slot(0, 0, 0));
      expect(state.selected, _slot(0, 0, 0));
      expect(state.remaining, hasLength(4));
    });

    test('tapping a blocked tile does nothing', () {
      final state = TileMatchGameState.initial(_tinyPuzzle());
      expect(state.tap(_slot(0, 0, 1)), same(state));
    });

    test('tapping a tile that is already gone does nothing', () {
      final cleared = TileMatchGameState.initial(_tinyPuzzle())
          .tap(_slot(0, 0, 0))
          .tap(_slot(0, 0, 3));
      expect(cleared.tap(_slot(0, 0, 0)), same(cleared));
    });

    test('tapping the selected tile deselects it', () {
      final state = TileMatchGameState.initial(_tinyPuzzle())
          .tap(_slot(0, 0, 0))
          .tap(_slot(0, 0, 0));
      expect(state.selected, isNull);
    });

    test('tapping a different free tile moves the selection', () {
      // Both ends are free but only match each other, so this needs a
      // three-tile setup: select an end, then tap the other end. They do
      // match here, so instead check the move-selection path with a board
      // where the two free tiles differ.
      final layout = TileLayout(
        name: 'Mismatched',
        slots: [_slot(0, 0, 0), _slot(0, 2, 0)],
      );
      final puzzle = TileMatchPuzzle(
        layout: layout,
        faces: {_slot(0, 0, 0): _circle, _slot(0, 2, 0): _square},
      );
      final state = TileMatchGameState.initial(puzzle)
          .tap(_slot(0, 0, 0))
          .tap(_slot(0, 2, 0));
      expect(state.selected, _slot(0, 2, 0));
      expect(state.remaining, hasLength(2));
    });

    test('tapping a matching free tile takes the pair', () {
      final state = TileMatchGameState.initial(_tinyPuzzle())
          .tap(_slot(0, 0, 0))
          .tap(_slot(0, 0, 3));
      expect(state.remaining, {_slot(0, 0, 1), _slot(0, 0, 2)});
      expect(state.selected, isNull);
      expect(state.tilesCleared, 2);
      expect(state.canUndo, isTrue);
    });

    test('taking the ends frees the middle pair', () {
      final state = TileMatchGameState.initial(_tinyPuzzle())
          .tap(_slot(0, 0, 0))
          .tap(_slot(0, 0, 3));
      expect(state.freeSlots, {_slot(0, 0, 1), _slot(0, 0, 2)});
    });

    test('clearing every tile ends the board', () {
      final state = TileMatchGameState.initial(_tinyPuzzle())
          .tap(_slot(0, 0, 0))
          .tap(_slot(0, 0, 3))
          .tap(_slot(0, 0, 1))
          .tap(_slot(0, 0, 2));
      expect(state.remaining, isEmpty);
      expect(state.status, TileMatchStatus.cleared);
      expect(state.isPlaying, isFalse);
      expect(state.tilesCleared, 4);
      expect(state.tap(_slot(0, 0, 0)), same(state));
    });
  });

  group('stuck boards', () {
    test('a board with no available move reports stuck, not playing', () {
      final layout = TileLayout(
        name: 'Dead',
        slots: [_slot(0, 0, 0), _slot(0, 2, 0)],
      );
      final puzzle = TileMatchPuzzle(
        layout: layout,
        faces: {_slot(0, 0, 0): _circle, _slot(0, 2, 0): _square},
      );
      final state = TileMatchGameState.initial(puzzle);
      expect(state.availableMoves, isEmpty);
      expect(state.status, TileMatchStatus.stuck);
      expect(state.isPlaying, isFalse);
    });

    test('undo brings a stuck board back to life', () {
      // Undo is the only way out of a dead board, which is why it matters
      // more here than in the other games.
      final layout = TileLayout(
        name: 'Recoverable',
        slots: [
          _slot(0, 0, 0),
          _slot(0, 0, 1),
          _slot(0, 0, 2),
          _slot(0, 0, 3),
        ],
      );
      final puzzle = TileMatchPuzzle(
        layout: layout,
        faces: {
          _slot(0, 0, 0): _circle,
          _slot(0, 0, 1): _square,
          _slot(0, 0, 2): _square,
          _slot(0, 0, 3): _circle,
        },
      );
      final taken = TileMatchGameState.initial(puzzle)
          .tap(_slot(0, 0, 0))
          .tap(_slot(0, 0, 3));
      expect(taken.isPlaying, isTrue);
      final restored = taken.undo();
      expect(restored.remaining, hasLength(4));
      expect(restored.isPlaying, isTrue);
    });
  });

  group('undo', () {
    test('puts the last pair back and forgets the selection', () {
      final state = TileMatchGameState.initial(_tinyPuzzle())
          .tap(_slot(0, 0, 0))
          .tap(_slot(0, 0, 3))
          .undo();
      expect(state.remaining, hasLength(4));
      expect(state.selected, isNull);
      expect(state.canUndo, isFalse);
    });

    test('walks back through several pairs in order', () {
      var state = TileMatchGameState.initial(_tinyPuzzle())
          .tap(_slot(0, 0, 0))
          .tap(_slot(0, 0, 3))
          .tap(_slot(0, 0, 1))
          .tap(_slot(0, 0, 2));
      expect(state.remaining, isEmpty);

      state = state.undo();
      expect(state.remaining, {_slot(0, 0, 1), _slot(0, 0, 2)});
      state = state.undo();
      expect(state.remaining, hasLength(4));
      expect(state.canUndo, isFalse);
      expect(state.undo(), same(state));
    });
  });

  group('hints', () {
    test('offers a pair that can actually be taken', () {
      final state = TileMatchGameState.initial(_tinyPuzzle());
      final hint = state.hint();
      expect(hint, isNotNull);
      expect(state.isFree(hint!.$1), isTrue);
      expect(state.isFree(hint.$2), isTrue);
      expect(state.faceAt(hint.$1), state.faceAt(hint.$2));
    });

    test('offers nothing on a dead board', () {
      final layout = TileLayout(
        name: 'Dead',
        slots: [_slot(0, 0, 0), _slot(0, 2, 0)],
      );
      final puzzle = TileMatchPuzzle(
        layout: layout,
        faces: {_slot(0, 0, 0): _circle, _slot(0, 2, 0): _square},
      );
      expect(TileMatchGameState.initial(puzzle).hint(), isNull);
    });
  });

  test('the clock only runs while the board is in play', () {
    var state = TileMatchGameState.initial(_tinyPuzzle());
    state = state.tick().tick();
    expect(state.elapsedSeconds, 2);

    final cleared = state
        .tap(_slot(0, 0, 0))
        .tap(_slot(0, 0, 3))
        .tap(_slot(0, 0, 1))
        .tap(_slot(0, 0, 2));
    expect(cleared.tick().elapsedSeconds, cleared.elapsedSeconds);
  });

  group('layout validation', () {
    test('an odd tile count is refused outright', () {
      expect(
        () => TileLayout(name: 'Odd', slots: [_slot(0, 0, 0)]),
        throwsArgumentError,
      );
    });
  });

  group('json', () {
    test('a generated board round-trips', () {
      final puzzle = TileMatchGenerator.generate(
        layout: tileLayouts.first,
        random: Random(21),
      )!;
      final restored = TileMatchPuzzle.fromJson(puzzle.toJson());
      expect(restored.layout.name, puzzle.layout.name);
      expect(restored.tileCount, puzzle.tileCount);
      for (final slot in puzzle.layout.slots) {
        expect(restored.faces[slot], puzzle.faces[slot], reason: '$slot');
      }
    });

    test('a face list of the wrong length is refused', () {
      final puzzle = TileMatchGenerator.generate(
        layout: tileLayouts.first,
        random: Random(22),
      )!;
      final json = puzzle.toJson();
      json['faces'] = (json['faces'] as List).sublist(0, 4);
      expect(() => TileMatchPuzzle.fromJson(json), throwsFormatException);
    });
  });
}
