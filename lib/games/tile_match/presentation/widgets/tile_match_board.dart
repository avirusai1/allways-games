import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../domain/tile_layout.dart';
import '../../domain/tile_match_game_state.dart';
import 'tile_glyph.dart';

/// Renders the tile stack.
///
/// Layers are drawn bottom-up and each one is nudged up and left by a few
/// pixels, which is what makes the pile read as three-dimensional and lets
/// a player see at a glance which tiles are buried.
class TileMatchBoardView extends StatelessWidget {
  const TileMatchBoardView({
    super.key,
    required this.state,
    required this.onTileTap,
  });

  final TileMatchGameState state;
  final void Function(TileSlot slot) onTileTap;

  @override
  Widget build(BuildContext context) {
    final layout = state.puzzle.layout;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Layer offsets eat into the available box, so the cell size has to
        // account for them or the top layer clips.
        const layerShift = 4.0;
        final shiftAllowance = layerShift * layout.layerCount;
        final cellWidth =
            (constraints.maxWidth - shiftAllowance) / layout.columns;
        final cellHeight = constraints.hasBoundedHeight
            ? (constraints.maxHeight - shiftAllowance) / layout.rows
            : cellWidth * 1.25;
        // Tiles are taller than they are wide, the way a physical tile is.
        final tileWidth = cellWidth.clamp(18.0, 64.0);
        final tileHeight = cellHeight.clamp(22.0, 78.0);

        return SizedBox(
          width: tileWidth * layout.columns + shiftAllowance,
          height: tileHeight * layout.rows + shiftAllowance,
          child: Stack(
            children: [
              for (var layer = 0; layer < layout.layerCount; layer++)
                for (final slot in layout.slots.where((s) => s.layer == layer))
                  if (state.remaining.contains(slot))
                    Positioned(
                      left: slot.col * tileWidth + layer * layerShift,
                      top: slot.row * tileHeight - layer * layerShift +
                          shiftAllowance,
                      width: tileWidth,
                      height: tileHeight,
                      child: _Tile(
                        state: state,
                        slot: slot,
                        onTap: () => onTileTap(slot),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.state, required this.slot, required this.onTap});

  final TileMatchGameState state;
  final TileSlot slot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final face = state.faceAt(slot)!;
    final isFree = state.isFree(slot);
    final isSelected = state.selected == slot;

    return Padding(
      padding: const EdgeInsets.all(1),
      child: Material(
        // A buried tile is dimmed rather than hidden: the player needs to
        // see what is under the pile to plan, but must not mistake it for
        // something they can take.
        color: isSelected ? AppColors.cellSelected : AppColors.surface,
        elevation: isFree ? 2 : 0,
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          borderRadius: BorderRadius.circular(5),
          onTap: onTap,
          child: Opacity(
            opacity: isFree ? 1 : 0.45,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.gridLine,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Center(
                child: TileGlyph(face: face, size: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
