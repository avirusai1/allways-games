import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';

/// A regular hexagon, flat-top, sized to fill its box.
///
/// Drawn rather than pulled from an icon set so the shape is the app's own
/// and scales cleanly to any cell size.
class HexagonBorder extends ShapeBorder {
  const HexagonBorder();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final centre = rect.center;
    final radius = rect.shortestSide / 2;
    final path = Path();
    for (var i = 0; i < 6; i++) {
      // Flat-top hexagon: vertices at 0deg, 60deg, ... put the points left
      // and right and the flat edges top and bottom. That is the
      // orientation the ring layout below assumes — it places one cell
      // directly above the centre and one directly below, which only
      // packs tightly for flat-top cells.
      final angle = pi / 3 * i;
      final point = Offset(
        centre.dx + radius * cos(angle),
        centre.dy + radius * sin(angle),
      );
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => const HexagonBorder();
}

/// One tappable letter cell.
class HoneycombCell extends StatelessWidget {
  const HoneycombCell({
    super.key,
    required this.letter,
    required this.isRequired,
    required this.onTap,
    this.size = 62,
  });

  final String letter;

  /// The centre letter, which every answer must use. Given the accent
  /// colour so it reads as a constraint rather than just another letter.
  final bool isRequired;

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: letter,
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color: isRequired ? AppColors.secondary : AppColors.surfaceAlt,
          shape: const HexagonBorder(),
          child: InkWell(
            customBorder: const HexagonBorder(),
            onTap: onTap,
            child: Center(
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w800,
                  color: isRequired ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The seven cells: one in the middle, six packed around it.
class HoneycombCluster extends StatelessWidget {
  const HoneycombCluster({
    super.key,
    required this.requiredLetter,
    required this.outerLetters,
    required this.onLetterTap,
    this.cellSize = 62,
  });

  final String requiredLetter;

  /// The six outer letters, in display order clockwise from the top.
  final List<String> outerLetters;

  final void Function(String letter) onLetterTap;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    // A flat-top hexagon drawn inside a [cellSize] square spans cellSize
    // point-to-point across and sqrt(3)/2 of that flat-to-flat down. Cells
    // touch exactly when neighbours sit 3/4 of the width apart
    // horizontally and a full flat-to-flat height apart vertically;
    // anything less and the cells overlap.
    // Nudged just past exact tangency so a hairline of background shows
    // between cells: touching cells of the same colour merge into one
    // blob and stop reading as six separate tap targets.
    const gap = 1.05;
    final dx = cellSize * 0.75 * gap;
    final dy = cellSize * sqrt(3) / 2 * gap;
    const offsets = [
      Offset(0, -1),
      Offset(1, -0.5),
      Offset(1, 0.5),
      Offset(0, 1),
      Offset(-1, 0.5),
      Offset(-1, -0.5),
    ];

    // Widest across the middle row (centre cell plus a full cell either
    // side); tallest through the vertical column of three stacked cells.
    final width = cellSize + 2 * dx;
    final height = 3 * dy;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < outerLetters.length && i < offsets.length; i++)
            Transform.translate(
              offset: Offset(offsets[i].dx * dx, offsets[i].dy * dy),
              child: HoneycombCell(
                letter: outerLetters[i],
                isRequired: false,
                size: cellSize,
                onTap: () => onLetterTap(outerLetters[i]),
              ),
            ),
          HoneycombCell(
            letter: requiredLetter,
            isRequired: true,
            size: cellSize,
            onTap: () => onLetterTap(requiredLetter),
          ),
        ],
      ),
    );
  }
}
