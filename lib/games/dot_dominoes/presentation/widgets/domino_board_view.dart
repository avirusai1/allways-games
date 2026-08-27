import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../domain/domino_board.dart';
import '../../domain/domino_game_state.dart';
import 'pip_face.dart';

/// The board: cells grouped into regions, each region wearing its rule.
class DominoBoardView extends StatelessWidget {
  const DominoBoardView({
    super.key,
    required this.state,
    required this.pendingCell,
    required this.onCellTap,
  });

  final DominoGameState state;

  /// The first cell of a placement in progress.
  final int? pendingCell;

  final ValueChanged<int> onCellTap;

  @override
  Widget build(BuildContext context) {
    final pips = state.pipsByCell;
    final regionOf = state.puzzle.regionOfCell;
    final broken = state.brokenRegions;

    // The rule is written in the region's top-left cell, so it sits where
    // the eye starts rather than floating over the middle.
    final badgeCell = <int, int>{};
    for (var r = 0; r < state.puzzle.regions.length; r++) {
      final cells = List<int>.of(state.puzzle.regions[r].cells)..sort();
      badgeCell[cells.first] = r;
    }

    return AspectRatio(
      aspectRatio: dominoBoardCols / dominoBoardRows,
      child: Column(
        children: List.generate(dominoBoardRows, (row) {
          return Expanded(
            child: Row(
              children: List.generate(dominoBoardCols, (col) {
                final index = dominoIndexAt(row, col);
                if (!state.puzzle.present[index]) {
                  return const Expanded(child: SizedBox.shrink());
                }
                final region = regionOf[index];
                return Expanded(
                  child: _Cell(
                    pips: pips[index],
                    rule: badgeCell.containsKey(index)
                        ? state.puzzle.regions[badgeCell[index]!]
                        : null,
                    pending: pendingCell == index,
                    broken: region != null && broken.contains(region),
                    // A thicker edge wherever the neighbour is in another
                    // region (or off the board): that outline is the only
                    // thing showing where one rule stops applying.
                    borders: _bordersFor(index, regionOf),
                    onTap: () => onCellTap(index),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  _CellBorders _bordersFor(int index, Map<int, int> regionOf) {
    final row = dominoRowOf(index);
    final col = dominoColOf(index);
    final mine = regionOf[index];

    bool edge(int r, int c) {
      if (r < 0 || r >= dominoBoardRows || c < 0 || c >= dominoBoardCols) {
        return true;
      }
      final other = dominoIndexAt(r, c);
      if (!state.puzzle.present[other]) return true;
      return regionOf[other] != mine;
    }

    return _CellBorders(
      top: edge(row - 1, col),
      bottom: edge(row + 1, col),
      left: edge(row, col - 1),
      right: edge(row, col + 1),
    );
  }
}

class _CellBorders {
  const _CellBorders({
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
  });

  final bool top;
  final bool bottom;
  final bool left;
  final bool right;
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.pips,
    required this.rule,
    required this.pending,
    required this.broken,
    required this.borders,
    required this.onTap,
  });

  final int? pips;
  final DominoRegion? rule;
  final bool pending;
  final bool broken;
  final _CellBorders borders;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const thick = BorderSide(color: AppColors.gridLineStrong, width: 2);
    const thin = BorderSide(color: AppColors.gridLine);

    final Color background;
    if (broken) {
      background = AppColors.cellError;
    } else if (pending) {
      background = AppColors.cellSelected;
    } else if (pips != null) {
      background = AppColors.surface;
    } else {
      background = AppColors.surfaceAlt.withValues(alpha: 0.45);
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: background,
          border: Border(
            top: borders.top ? thick : thin,
            bottom: borders.bottom ? thick : thin,
            left: borders.left ? thick : thin,
            right: borders.right ? thick : thin,
          ),
        ),
        child: Stack(
          children: [
            if (pips != null)
              Positioned.fill(
                child: PipFace(
                  value: pips!,
                  colour: broken ? AppColors.textError : AppColors.primary,
                ),
              ),
            if (rule != null)
              Positioned(
                left: 3,
                top: 1,
                child: Text(
                  rule!.rule.badge(rule!.value),
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: broken
                        ? AppColors.textError
                        : AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
