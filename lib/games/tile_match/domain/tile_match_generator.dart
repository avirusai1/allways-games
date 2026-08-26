import 'dart:math';

import 'tile_board.dart';
import 'tile_face.dart';
import 'tile_layout.dart';
import 'tile_match_puzzle.dart';

/// How many distinct faces a board draws on.
///
/// Fewer faces means more copies of each, which means more moves available
/// at any moment and an easier board; more faces means tighter, more
/// forced play. This sits where a board has real choices without being
/// a maze.
const int tileMatchPaletteSize = 14;

/// Builds clearable Tile Match boards offline.
class TileMatchGenerator {
  TileMatchGenerator._();

  /// Builds a board by playing a solve backwards.
  ///
  /// Assigning faces at random and hoping the result is clearable fails far
  /// more often than it succeeds. Instead this walks a legal *removal*
  /// order — repeatedly taking two tiles that are genuinely free right now
  /// — and paints each pair it takes with a shared face. The order it
  /// walked is by construction a way to clear the finished board, so a
  /// solution is guaranteed rather than hoped for.
  ///
  /// Returns null if the walk ever reaches a point with fewer than two free
  /// tiles, which the caller should treat as "try another seed".
  static TileMatchPuzzle? build({
    required TileLayout layout,
    required Random random,
  }) {
    final remaining = layout.slots.toSet();
    final faces = <TileSlot, TileFace>{};

    // A palette of distinct faces, spread across the full shape/hue space
    // rather than clustered, so a board never shows four near-identical
    // tiles that only differ by hue.
    final palette = _palette(random);
    var pairIndex = 0;

    while (remaining.isNotEmpty) {
      final free = TileBoard.freeSlots(remaining);
      if (free.length < 2) return null;

      free.shuffle(random);
      // Look one step ahead. Taking any two free tiles is legal, but some
      // choices leave a single free tile and strand the walk with tiles
      // still on the board. Trying a handful of pairs and keeping one that
      // leaves a playable position turns most of those dead ends into
      // finished boards instead of wasted attempts.
      var first = free[0];
      var second = free[1];
      for (var attempt = 0; attempt + 1 < free.length && attempt < 8; attempt++) {
        final a = free[attempt];
        final b = free[attempt + 1];
        final after = {...remaining}
          ..remove(a)
          ..remove(b);
        if (after.isEmpty || TileBoard.freeSlots(after).length >= 2) {
          first = a;
          second = b;
          break;
        }
      }

      // Round-robin over the palette, so each face ends up on four or six
      // tiles rather than one face dominating the board.
      final face = palette[pairIndex % palette.length];
      pairIndex++;

      faces[first] = face;
      faces[second] = face;
      remaining.remove(first);
      remaining.remove(second);
    }

    return TileMatchPuzzle(layout: layout, faces: faces);
  }

  /// Builds a board and proves it clearable with an independent search.
  ///
  /// The reverse walk already guarantees a solution exists, so this is a
  /// check on the reasoning rather than on luck — but it is cheap, it is
  /// the property players actually depend on, and it catches the case
  /// where the walk and the rules have drifted apart.
  ///
  /// Returns null after [maxAttempts] failures rather than looping forever.
  static TileMatchPuzzle? generate({
    required TileLayout layout,
    required Random random,
    int maxAttempts = 40,
    int nodeBudget = 300000,
  }) {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final puzzle = build(layout: layout, random: random);
      if (puzzle == null) continue;
      if (TileBoard.isSolvable(
            puzzle.allSlots,
            puzzle.faces,
            nodeBudget: nodeBudget,
          ) ==
          true) {
        return puzzle;
      }
    }
    return null;
  }

  /// [tileMatchPaletteSize] faces chosen to be easy to tell apart.
  ///
  /// Shapes are taken first and hues cycle underneath them, so the palette
  /// only doubles up on a shape once every shape has been used.
  static List<TileFace> _palette(Random random) {
    final shapes = List<TileShape>.of(TileShape.values)..shuffle(random);
    final hues = List<TileHue>.of(TileHue.values)..shuffle(random);
    return [
      for (var i = 0; i < tileMatchPaletteSize; i++)
        TileFace(shapes[i % shapes.length], hues[(i ~/ shapes.length) % hues.length]),
    ];
  }
}
