import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../domain/word_loop_box.dart';

/// The square board: three letters along each side, with the word being
/// typed drawn as a path across the middle.
///
/// Letters are laid out clockwise from the top-left so that reading round
/// the board matches the order they are listed in, which makes the board
/// easy to describe and to share.
class WordLoopBoardView extends StatelessWidget {
  const WordLoopBoardView({
    super.key,
    required this.box,
    required this.currentInput,
    required this.usedLetters,
    required this.onLetterTap,
    this.maxSize = 340,
  });

  final WordLoopBox box;
  final String currentInput;

  /// Letters already covered by played words, shown as spent.
  final Set<String> usedLetters;

  final void Function(String letter) onLetterTap;
  final double maxSize;

  /// Where each letter sits, in unit coordinates on the square.
  ///
  /// Exposed for testing: the layout is the one piece of this widget with
  /// real logic in it.
  static Map<String, Offset> letterPositions(WordLoopBox box) {
    const stops = [1 / 6, 3 / 6, 5 / 6];
    final positions = <String, Offset>{};
    for (var i = 0; i < stops.length; i++) {
      positions[box.sides[WordLoopSide.top.index][i]] = Offset(stops[i], 0);
      positions[box.sides[WordLoopSide.right.index][i]] = Offset(1, stops[i]);
      // Bottom and left run back the other way, so the sequence travels
      // clockwise round the square instead of jumping across it.
      positions[box.sides[WordLoopSide.bottom.index][i]] =
          Offset(stops[stops.length - 1 - i], 1);
      positions[box.sides[WordLoopSide.left.index][i]] =
          Offset(0, stops[stops.length - 1 - i]);
    }
    return positions;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final candidates = <double>[
          maxSize,
          if (constraints.hasBoundedWidth) constraints.maxWidth,
          if (constraints.hasBoundedHeight) constraints.maxHeight,
        ];
        // Tiles straddle the square's edge, so the square itself has to sit
        // inside the available box by half a tile on every side.
        const tile = 40.0;
        final side = candidates.reduce((a, b) => a < b ? a : b) - tile;
        final positions = letterPositions(box);

        return Center(
          child: SizedBox(
            width: side + tile,
            height: side + tile,
            child: Stack(
              children: [
                Positioned(
                  left: tile / 2,
                  top: tile / 2,
                  width: side,
                  height: side,
                  child: CustomPaint(
                    painter: _BoardPainter(
                      positions: positions,
                      path: currentInput.split(''),
                    ),
                  ),
                ),
                for (final entry in positions.entries)
                  Positioned(
                    left: entry.value.dx * side,
                    top: entry.value.dy * side,
                    width: tile,
                    height: tile,
                    child: _LetterTile(
                      letter: entry.key,
                      used: usedLetters.contains(entry.key),
                      inCurrentWord: currentInput.contains(entry.key),
                      onTap: () => onLetterTap(entry.key),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LetterTile extends StatelessWidget {
  const _LetterTile({
    required this.letter,
    required this.used,
    required this.inCurrentWord,
    required this.onTap,
  });

  final String letter;
  final bool used;
  final bool inCurrentWord;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = inCurrentWord
        ? AppColors.primary
        : (used ? AppColors.primaryContainer : AppColors.surface);
    final foreground = inCurrentWord
        ? Colors.white
        : (used ? AppColors.primary : AppColors.textPrimary);

    return Semantics(
      button: true,
      label: letter,
      child: Material(
        color: background,
        shape: CircleBorder(
          side: BorderSide(
            color: used ? AppColors.primary : AppColors.gridLineStrong,
            width: 2,
          ),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  const _BoardPainter({required this.positions, required this.path});

  final Map<String, Offset> positions;
  final List<String> path;

  @override
  void paint(Canvas canvas, Size size) {
    final square = Paint()
      ..color = AppColors.gridLine
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Offset.zero & size, square);

    if (path.length < 2) return;
    final trace = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    Offset? previous;
    for (final letter in path) {
      final unit = positions[letter];
      if (unit == null) continue;
      final point = Offset(unit.dx * size.width, unit.dy * size.height);
      if (previous != null) canvas.drawLine(previous, point, trace);
      previous = point;
    }
  }

  @override
  bool shouldRepaint(_BoardPainter old) =>
      old.path.join() != path.join() || old.positions != positions;
}
