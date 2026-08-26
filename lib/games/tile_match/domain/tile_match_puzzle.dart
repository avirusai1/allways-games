import 'tile_face.dart';
import 'tile_layout.dart';

/// One published Tile Match board: a layout plus the face on every tile.
class TileMatchPuzzle {
  TileMatchPuzzle({required this.layout, required Map<TileSlot, TileFace> faces})
      : faces = Map<TileSlot, TileFace>.unmodifiable(faces);

  /// Faces are stored in the bank as one integer per slot, in the layout's
  /// own slot order, so a board costs a short list of small numbers rather
  /// than a repeat of the geometry the layout already describes.
  factory TileMatchPuzzle.fromJson(Map<String, dynamic> json) {
    final layout = tileLayoutByName(json['layout'] as String);
    final faceIds = (json['faces'] as List).cast<int>();
    if (faceIds.length != layout.slots.length) {
      throw FormatException(
        'Layout "${layout.name}" has ${layout.slots.length} slots but the '
        'board lists ${faceIds.length} faces.',
      );
    }
    return TileMatchPuzzle(
      layout: layout,
      faces: {
        for (var i = 0; i < faceIds.length; i++)
          layout.slots[i]: TileFace.fromId(faceIds[i]),
      },
    );
  }

  final TileLayout layout;
  final Map<TileSlot, TileFace> faces;

  int get tileCount => layout.slots.length;

  Set<TileSlot> get allSlots => layout.slots.toSet();

  /// Distinct faces used on this board.
  Set<TileFace> get facesUsed => faces.values.toSet();

  Map<String, dynamic> toJson() => {
        'layout': layout.name,
        'faces': [for (final slot in layout.slots) faces[slot]!.id],
      };
}
