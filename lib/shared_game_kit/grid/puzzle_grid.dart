import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

/// Generic square puzzle grid, shared by every grid-based game (Sudoku now;
/// Crossword, Weave and Tile Match reuse it later).
///
/// The caller supplies the cell content via [cellBuilder]; this widget owns
/// only layout, tap routing, and the heavier box/section borders drawn every
/// [majorEvery] cells.
class PuzzleGrid extends StatelessWidget {
  const PuzzleGrid({
    super.key,
    required this.size,
    required this.cellBuilder,
    this.onCellTap,
    this.majorEvery,
    this.borderColor = AppColors.surfaceAlt,
    this.majorBorderColor = AppColors.textSecondary,
  });

  /// Number of cells per side.
  final int size;

  final Widget Function(BuildContext context, int index) cellBuilder;
  final ValueChanged<int>? onCellTap;

  /// Draw a heavier divider every N cells (3 for Sudoku's boxes). Null
  /// disables major lines entirely.
  final int? majorEvery;

  final Color borderColor;
  final Color majorBorderColor;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellSize = constraints.maxWidth / size;
          return DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: majorBorderColor, width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: List.generate(size, (row) {
                return SizedBox(
                  height: cellSize,
                  child: Row(
                    children: List.generate(size, (col) {
                      final index = row * size + col;
                      return SizedBox(
                        width: cellSize,
                        child: _Cell(
                          index: index,
                          row: row,
                          col: col,
                          size: size,
                          majorEvery: majorEvery,
                          borderColor: borderColor,
                          majorBorderColor: majorBorderColor,
                          onTap: onCellTap == null
                              ? null
                              : () => onCellTap!(index),
                          child: cellBuilder(context, index),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.index,
    required this.row,
    required this.col,
    required this.size,
    required this.majorEvery,
    required this.borderColor,
    required this.majorBorderColor,
    required this.onTap,
    required this.child,
  });

  final int index;
  final int row;
  final int col;
  final int size;
  final int? majorEvery;
  final Color borderColor;
  final Color majorBorderColor;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Interior dividers only: the outer frame is drawn by the parent, so
    // skip the trailing edge of the last row/column to avoid doubling up.
    final isMajorRight =
        majorEvery != null && (col + 1) % majorEvery! == 0 && col != size - 1;
    final isMajorBottom =
        majorEvery != null && (row + 1) % majorEvery! == 0 && row != size - 1;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            right: col == size - 1
                ? BorderSide.none
                : BorderSide(
                    color: isMajorRight ? majorBorderColor : borderColor,
                    width: isMajorRight ? 2 : 1,
                  ),
            bottom: row == size - 1
                ? BorderSide.none
                : BorderSide(
                    color: isMajorBottom ? majorBorderColor : borderColor,
                    width: isMajorBottom ? 2 : 1,
                  ),
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}
