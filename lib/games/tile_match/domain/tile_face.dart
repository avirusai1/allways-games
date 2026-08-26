/// The glyph set painted on Tile Match tiles.
///
/// Deliberately built from plain geometry rather than any existing tile
/// artwork: each face is a shape plus a colour, both drawn by the app's own
/// painter (see presentation/widgets/tile_glyph.dart). Nothing here is
/// derived from another game's tiles.
///
/// Pure Dart with no Flutter imports, so the generator and the tests share
/// the same face vocabulary the app draws.
library;

/// Shapes a tile can carry. Each is drawable from a handful of points or a
/// single arc, which keeps them legible at small sizes.
enum TileShape {
  circle,
  square,
  triangle,
  diamond,
  hexagon,
  star,
  chevron,
  cross,
  ring,
  crescent,
}

/// Colour slots. The concrete colours live in the theme; the domain only
/// needs to know how many distinct slots exist.
enum TileHue { teal, amber, plum, sage }

/// One tile face: a shape in a colour.
///
/// [TileShape.values.length] x [TileHue.values.length] gives 40 distinct
/// faces, comfortably more than a board needs, so a day's board can use a
/// well-spread subset rather than every face every time.
class TileFace {
  const TileFace(this.shape, this.hue);

  factory TileFace.fromId(int id) {
    return TileFace(
      TileShape.values[id ~/ TileHue.values.length],
      TileHue.values[id % TileHue.values.length],
    );
  }

  final TileShape shape;
  final TileHue hue;

  /// Total number of distinct faces.
  static int get faceCount => TileShape.values.length * TileHue.values.length;

  /// Stable integer encoding, used in the content bank.
  int get id => shape.index * TileHue.values.length + hue.index;

  @override
  bool operator ==(Object other) =>
      other is TileFace && other.shape == shape && other.hue == hue;

  @override
  int get hashCode => id;

  @override
  String toString() => '${shape.name}/${hue.name}';
}
