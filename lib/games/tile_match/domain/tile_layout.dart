/// Board geometry for Tile Match.
///
/// Tiles sit on a stack of layers, one tile per cell. A tile can be picked
/// up when nothing rests on top of it and at least one of its side
/// neighbours on the same layer is gone — the rule that makes a stack a
/// puzzle rather than a memory test.
///
/// The layouts here are the app's own shapes, described in code rather than
/// transcribed from any published board.
library;

/// One tile position in the stack.
class TileSlot {
  const TileSlot({required this.layer, required this.row, required this.col});

  final int layer;
  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      other is TileSlot &&
      other.layer == layer &&
      other.row == row &&
      other.col == col;

  @override
  int get hashCode => Object.hash(layer, row, col);

  @override
  String toString() => 'L$layer($row,$col)';
}

/// A named board shape: which cells hold a tile on each layer.
class TileLayout {
  TileLayout({required this.name, required List<TileSlot> slots})
      : slots = List<TileSlot>.unmodifiable(slots) {
    if (this.slots.length.isOdd) {
      throw ArgumentError('Layout "$name" has an odd number of tiles.');
    }
  }

  final String name;
  final List<TileSlot> slots;

  int get tileCount => slots.length;

  int get layerCount =>
      slots.isEmpty ? 0 : slots.map((s) => s.layer).reduce((a, b) => a > b ? a : b) + 1;

  int get columns =>
      slots.isEmpty ? 0 : slots.map((s) => s.col).reduce((a, b) => a > b ? a : b) + 1;

  int get rows =>
      slots.isEmpty ? 0 : slots.map((s) => s.row).reduce((a, b) => a > b ? a : b) + 1;
}

/// Builds a centred rectangle of tiles on one layer.
List<TileSlot> _rectangle({
  required int layer,
  required int width,
  required int height,
  required int boardWidth,
  required int boardHeight,
}) {
  final left = (boardWidth - width) ~/ 2;
  final top = (boardHeight - height) ~/ 2;
  return [
    for (var r = 0; r < height; r++)
      for (var c = 0; c < width; c++)
        TileSlot(layer: layer, row: top + r, col: left + c),
  ];
}

const int tileBoardWidth = 10;
const int tileBoardHeight = 7;

/// The shapes a day's board is drawn from.
///
/// Each is a stack of centred rectangles, so every layer is fully
/// supported by the one below and the silhouette reads as a solid,
/// climbable pile. All three have an even tile count, which pairing
/// requires.
final List<TileLayout> tileLayouts = [
  TileLayout(
    name: 'Terrace',
    slots: [
      ..._rectangle(
        layer: 0,
        width: 10,
        height: 6,
        boardWidth: tileBoardWidth,
        boardHeight: tileBoardHeight,
      ),
      ..._rectangle(
        layer: 1,
        width: 6,
        height: 4,
        boardWidth: tileBoardWidth,
        boardHeight: tileBoardHeight,
      ),
      ..._rectangle(
        layer: 2,
        width: 2,
        height: 2,
        boardWidth: tileBoardWidth,
        boardHeight: tileBoardHeight,
      ),
    ],
  ),
  TileLayout(
    name: 'Spire',
    slots: [
      ..._rectangle(
        layer: 0,
        width: 8,
        height: 6,
        boardWidth: tileBoardWidth,
        boardHeight: tileBoardHeight,
      ),
      ..._rectangle(
        layer: 1,
        width: 6,
        height: 4,
        boardWidth: tileBoardWidth,
        boardHeight: tileBoardHeight,
      ),
      ..._rectangle(
        layer: 2,
        width: 4,
        height: 2,
        boardWidth: tileBoardWidth,
        boardHeight: tileBoardHeight,
      ),
      ..._rectangle(
        layer: 3,
        width: 2,
        height: 1,
        boardWidth: tileBoardWidth,
        boardHeight: tileBoardHeight,
      ),
    ],
  ),
  TileLayout(
    name: 'Long Hall',
    slots: [
      ..._rectangle(
        layer: 0,
        width: 10,
        height: 5,
        boardWidth: tileBoardWidth,
        boardHeight: tileBoardHeight,
      ),
      ..._rectangle(
        layer: 1,
        width: 8,
        height: 3,
        boardWidth: tileBoardWidth,
        boardHeight: tileBoardHeight,
      ),
      ..._rectangle(
        layer: 2,
        width: 4,
        height: 1,
        boardWidth: tileBoardWidth,
        boardHeight: tileBoardHeight,
      ),
    ],
  ),
];

TileLayout tileLayoutByName(String name) =>
    tileLayouts.firstWhere((layout) => layout.name == name);
