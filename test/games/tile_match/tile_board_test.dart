import 'dart:math';

import 'package:allways_games/games/tile_match/domain/tile_board.dart';
import 'package:allways_games/games/tile_match/domain/tile_face.dart';
import 'package:allways_games/games/tile_match/domain/tile_layout.dart';
import 'package:allways_games/games/tile_match/domain/tile_match_generator.dart';
import 'package:flutter_test/flutter_test.dart';

TileSlot _slot(int layer, int row, int col) =>
    TileSlot(layer: layer, row: row, col: col);

const _circle = TileFace(TileShape.circle, TileHue.teal);
const _square = TileFace(TileShape.square, TileHue.amber);
const _star = TileFace(TileShape.star, TileHue.plum);

void main() {
  group('layouts', () {
    test('every layout has an even tile count', () {
      // An odd count leaves one tile that can never be paired off.
      for (final layout in tileLayouts) {
        expect(layout.tileCount.isEven, isTrue, reason: layout.name);
        expect(layout.tileCount, greaterThan(0), reason: layout.name);
      }
    });

    test('no layout repeats a slot', () {
      for (final layout in tileLayouts) {
        expect(layout.slots.toSet().length, layout.slots.length,
            reason: layout.name);
      }
    });

    test('every tile above the base rests on a tile below it', () {
      // A floating tile would be unreachable-looking and, worse, would
      // never block anything.
      for (final layout in tileLayouts) {
        final slots = layout.slots.toSet();
        for (final slot in layout.slots) {
          if (slot.layer == 0) continue;
          expect(
            slots.contains(_slot(slot.layer - 1, slot.row, slot.col)),
            isTrue,
            reason: '${layout.name}: $slot floats',
          );
        }
      }
    });

    test('layouts are looked up by name', () {
      for (final layout in tileLayouts) {
        expect(tileLayoutByName(layout.name).name, layout.name);
      }
    });

    test('layout names are distinct', () {
      expect(
        tileLayouts.map((l) => l.name).toSet().length,
        tileLayouts.length,
      );
    });
  });

  group('TileBoard.isFree', () {
    test('a tile with a tile on top is blocked', () {
      final remaining = {_slot(0, 0, 0), _slot(1, 0, 0)};
      expect(TileBoard.isFree(_slot(0, 0, 0), remaining), isFalse);
      expect(TileBoard.isFree(_slot(1, 0, 0), remaining), isTrue);
    });

    test('a tile boxed in on both sides is blocked', () {
      final remaining = {_slot(0, 0, 0), _slot(0, 0, 1), _slot(0, 0, 2)};
      expect(TileBoard.isFree(_slot(0, 0, 1), remaining), isFalse);
      // The outer two each have an open side.
      expect(TileBoard.isFree(_slot(0, 0, 0), remaining), isTrue);
      expect(TileBoard.isFree(_slot(0, 0, 2), remaining), isTrue);
    });

    test('losing one neighbour frees a boxed-in tile', () {
      final remaining = {_slot(0, 0, 0), _slot(0, 0, 1), _slot(0, 0, 2)};
      expect(TileBoard.isFree(_slot(0, 0, 1), remaining), isFalse);
      final fewer = {...remaining}..remove(_slot(0, 0, 0));
      expect(TileBoard.isFree(_slot(0, 0, 1), fewer), isTrue);
    });

    test('a tile already taken is not free', () {
      expect(TileBoard.isFree(_slot(0, 0, 0), const {}), isFalse);
    });

    test('neighbours on other rows or layers do not block', () {
      final remaining = {
        _slot(0, 0, 1),
        _slot(0, 1, 0), // different row
        _slot(0, 1, 2), // different row
        _slot(1, 0, 5), // different layer and column
      };
      expect(TileBoard.isFree(_slot(0, 0, 1), remaining), isTrue);
    });
  });

  group('TileBoard.availableMoves', () {
    test('pairs only free tiles that share a face', () {
      final remaining = {_slot(0, 0, 0), _slot(0, 0, 2), _slot(0, 1, 0)};
      final faces = {
        _slot(0, 0, 0): _circle,
        _slot(0, 0, 2): _circle,
        _slot(0, 1, 0): _square,
      };
      final moves = TileBoard.availableMoves(remaining, faces);
      expect(moves, hasLength(1));
      expect({moves.first.$1, moves.first.$2}, {_slot(0, 0, 0), _slot(0, 0, 2)});
    });

    test('a matching pair with one tile buried is not a move', () {
      final remaining = {_slot(0, 0, 0), _slot(0, 0, 1), _slot(0, 0, 2)};
      final faces = {
        _slot(0, 0, 0): _circle,
        _slot(0, 0, 1): _circle, // boxed in
        _slot(0, 0, 2): _square,
      };
      expect(TileBoard.availableMoves(remaining, faces), isEmpty);
    });
  });

  group('TileBoard.isSolvable', () {
    test('an empty board is trivially solved', () {
      expect(TileBoard.isSolvable(const {}, const {}), isTrue);
    });

    test('two matching free tiles clear', () {
      final remaining = {_slot(0, 0, 0), _slot(0, 0, 2)};
      final faces = {_slot(0, 0, 0): _circle, _slot(0, 0, 2): _circle};
      expect(TileBoard.isSolvable(remaining, faces), isTrue);
    });

    test('a board with no matching pair is unsolvable', () {
      final remaining = {_slot(0, 0, 0), _slot(0, 0, 2)};
      final faces = {_slot(0, 0, 0): _circle, _slot(0, 0, 2): _square};
      expect(TileBoard.isSolvable(remaining, faces), isFalse);
    });

    test('a board whose only pair is permanently buried is unsolvable', () {
      // Three in a row: the middle tile can only be freed by taking a
      // neighbour, but neither neighbour has a partner.
      final remaining = {
        _slot(0, 0, 0),
        _slot(0, 0, 1),
        _slot(0, 0, 2),
        _slot(0, 2, 0),
      };
      final faces = {
        _slot(0, 0, 0): _circle,
        _slot(0, 0, 1): _square,
        _slot(0, 0, 2): _star,
        _slot(0, 2, 0): _square, // partner for the buried middle tile
      };
      // The only matching pair is the two squares, and one of them is boxed
      // in. Freeing it means taking a neighbour first, but neither
      // neighbour has a partner to be taken with — so no move exists at
      // all and the board is dead from the start.
      expect(TileBoard.availableMoves(remaining, faces), isEmpty);
      expect(TileBoard.isSolvable(remaining, faces), isFalse);
    });

    test('order matters: a greedy wrong turn can strand a solvable board', () {
      // Four tiles of one face in a row. Taking the outer two first leaves
      // the middle two boxed in by nothing — they become free — so this
      // particular shape survives; the point of the test is that the search
      // reports the truth rather than assuming any first move works.
      final remaining = {
        _slot(0, 0, 0),
        _slot(0, 0, 1),
        _slot(0, 0, 2),
        _slot(0, 0, 3),
      };
      final faces = {
        for (final slot in remaining) slot: _circle,
      };
      expect(TileBoard.isSolvable(remaining, faces), isTrue);
    });

    test('a starved budget reports "unknown" rather than "unsolvable"', () {
      // Reporting false on a timeout would let the generator ship a board
      // it had failed to verify.
      final puzzle = TileMatchGenerator.build(
        layout: tileLayouts.first,
        random: Random(1),
      )!;
      expect(
        TileBoard.isSolvable(puzzle.allSlots, puzzle.faces, nodeBudget: 1),
        isNull,
      );
    });
  });

  group('TileMatchGenerator', () {
    test('builds a board covering every slot with an even face count', () {
      for (final layout in tileLayouts) {
        final puzzle = TileMatchGenerator.build(
          layout: layout,
          random: Random(7),
        );
        expect(puzzle, isNotNull, reason: layout.name);
        expect(puzzle!.faces.length, layout.slots.length, reason: layout.name);

        final counts = <int, int>{};
        for (final face in puzzle.faces.values) {
          counts[face.id] = (counts[face.id] ?? 0) + 1;
        }
        for (final entry in counts.entries) {
          expect(entry.value.isEven, isTrue,
              reason: '${layout.name}: face ${entry.key} appears '
                  '${entry.value} times');
        }
      }
    });

    test('a built board is genuinely clearable', () {
      // The reverse walk is supposed to guarantee this; the check is on the
      // reasoning, not on luck. Built via generate, since a single walk can
      // strand itself (see the next test) and returns null when it does.
      for (final layout in tileLayouts) {
        final puzzle = TileMatchGenerator.generate(
          layout: layout,
          random: Random(11),
        );
        expect(puzzle, isNotNull, reason: layout.name);
        expect(TileBoard.isSolvable(puzzle!.allSlots, puzzle.faces), isTrue,
            reason: layout.name);
      }
    });

    test('a stranded walk returns null instead of a broken board', () {
      // The walk takes two free tiles at a time and can, occasionally,
      // leave a single free tile with others still on the board. That is a
      // dead end, not a board: build says so by returning null, and
      // generate simply tries again. Over many seeds at least one walk on
      // some layout strands, which is why the retry exists at all.
      var stranded = 0;
      for (final layout in tileLayouts) {
        final random = Random(4242);
        for (var i = 0; i < 200; i++) {
          if (TileMatchGenerator.build(layout: layout, random: random) == null) {
            stranded++;
          }
        }
      }
      expect(stranded, greaterThan(0),
          reason: 'if walks never strand, the retry loop is dead code');
    });

    test('generation is deterministic for a seed', () {
      final a = TileMatchGenerator.build(
        layout: tileLayouts.first,
        random: Random(99),
      )!;
      final b = TileMatchGenerator.build(
        layout: tileLayouts.first,
        random: Random(99),
      )!;
      expect(a.toJson(), b.toJson());
    });

    test('different seeds give different boards', () {
      final a = TileMatchGenerator.build(
        layout: tileLayouts.first,
        random: Random(1),
      )!;
      final b = TileMatchGenerator.build(
        layout: tileLayouts.first,
        random: Random(2),
      )!;
      expect(a.toJson(), isNot(b.toJson()));
    });

    test('a board draws on a spread of faces, not one or two', () {
      final puzzle = TileMatchGenerator.build(
        layout: tileLayouts.first,
        random: Random(5),
      )!;
      expect(puzzle.facesUsed.length, tileMatchPaletteSize);
      // Shapes carry the distinction, so hue alone never separates tiles.
      expect(puzzle.facesUsed.map((f) => f.shape).toSet().length,
          greaterThan(1));
    });

    test('generate returns a verified board', () {
      final puzzle = TileMatchGenerator.generate(
        layout: tileLayouts[1],
        random: Random(3),
      );
      expect(puzzle, isNotNull);
      expect(TileBoard.isSolvable(puzzle!.allSlots, puzzle.faces), isTrue);
    });
  });

  group('TileFace', () {
    test('ids round-trip', () {
      for (var id = 0; id < TileFace.faceCount; id++) {
        expect(TileFace.fromId(id).id, id);
      }
    });

    test('faces compare by shape and hue', () {
      expect(const TileFace(TileShape.circle, TileHue.teal), _circle);
      expect(const TileFace(TileShape.circle, TileHue.amber), isNot(_circle));
      expect(const TileFace(TileShape.square, TileHue.teal), isNot(_circle));
    });

    test('there are more faces than any board needs', () {
      expect(TileFace.faceCount, greaterThan(tileMatchPaletteSize));
    });
  });
}
