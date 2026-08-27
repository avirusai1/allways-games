import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A small drawing of what each game actually looks like.
///
/// Material icons were doing this job badly: a generic grid or hexagon
/// says nothing about the difference between Sudoku and Crossword, and
/// nine tiles all wearing the same mint square read as one undifferentiated
/// list. These are miniatures of the real boards instead, which is what
/// lets a player pick a game out at a glance.
class GameGlyph extends StatelessWidget {
  const GameGlyph({
    super.key,
    required this.gameId,
    required this.colour,
    this.size = 30,
  });

  final String gameId;
  final Color colour;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GlyphPainter(gameId, colour)),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.gameId, this.colour);

  final String gameId;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final strong = Paint()..color = colour;
    final soft = Paint()..color = colour.withValues(alpha: 0.28);
    final line = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (gameId) {
      case 'five':
        _five(canvas, size, strong, soft);
      case 'sudoku':
        _sudoku(canvas, size, strong, soft);
      case 'word_loop':
        _wordLoop(canvas, size, strong, soft, line);
      case 'honeycomb':
        _honeycomb(canvas, size, strong, soft);
      case 'tile_match':
        _tileMatch(canvas, size, strong, soft);
      case 'groups':
        _groups(canvas, size, strong, soft);
      case 'weave':
        _weave(canvas, size, strong, soft, line);
      case 'crossword':
        _crossword(canvas, size, strong, soft);
      case 'dot_dominoes':
        _dominoes(canvas, size, strong, soft, line);
    }
  }

  /// A row of guess tiles, two of them resolved.
  void _five(Canvas canvas, Size size, Paint strong, Paint soft) {
    const columns = 3;
    final gap = size.width * 0.09;
    final cell = (size.width - gap * (columns - 1)) / columns;
    final top = (size.height - cell * 2 - gap) / 2;

    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < columns; col++) {
        final filled = (row == 0 && col == 1) || (row == 1 && col == 2);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              col * (cell + gap),
              top + row * (cell + gap),
              cell,
              cell,
            ),
            Radius.circular(cell * 0.24),
          ),
          filled ? strong : soft,
        );
      }
    }
  }

  /// A 3x3 box with a few givens placed.
  void _sudoku(Canvas canvas, Size size, Paint strong, Paint soft) {
    const n = 3;
    final gap = size.width * 0.08;
    final cell = (size.width - gap * (n - 1)) / n;
    const filled = {0, 4, 5, 7};

    for (var i = 0; i < n * n; i++) {
      final row = i ~/ n;
      final col = i % n;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(col * (cell + gap), row * (cell + gap), cell, cell),
          Radius.circular(cell * 0.2),
        ),
        filled.contains(i) ? strong : soft,
      );
    }
  }

  /// Letters around a square with a chain looping between two sides.
  void _wordLoop(
    Canvas canvas,
    Size size,
    Paint strong,
    Paint soft,
    Paint line,
  ) {
    final inset = size.width * 0.14;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );

    // The box itself, drawn as an outline: the game is letters arranged
    // around a square, so the square has to be the readable part.
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.1)),
      Paint()
        ..color = colour.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.06,
    );

    // Two letters per side, as on the real board.
    final dot = size.width * 0.075;
    final top = [0.35, 0.65].map((t) =>
        Offset(rect.left + rect.width * t, rect.top));
    final bottom = [0.35, 0.65].map((t) =>
        Offset(rect.left + rect.width * t, rect.bottom));
    final left = [0.35, 0.65].map((t) =>
        Offset(rect.left, rect.top + rect.height * t));
    final right = [0.35, 0.65].map((t) =>
        Offset(rect.right, rect.top + rect.height * t));

    for (final p in [...top, ...bottom, ...left, ...right]) {
      canvas.drawCircle(p, dot, soft);
    }

    // A chain hopping between sides, which is the whole rule of the game:
    // consecutive letters can never share a side.
    final a = top.first;
    final b = right.last;
    final c = left.last;
    canvas.drawPath(
      Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(c.dx, c.dy),
      line,
    );
    for (final p in [a, b, c]) {
      canvas.drawCircle(p, dot, strong);
    }
  }

  /// The seven-cell rosette, centre picked out.
  void _honeycomb(Canvas canvas, Size size, Paint strong, Paint soft) {
    final centre = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.155;
    // Flat-top hexagons: neighbours sit directly above and below.
    final dx = r * 1.5;
    final dy = r * math.sqrt(3) / 2 * 2;

    final offsets = <Offset>[
      Offset.zero,
      Offset(0, -dy),
      Offset(dx, -dy / 2),
      Offset(dx, dy / 2),
      Offset(0, dy),
      Offset(-dx, dy / 2),
      Offset(-dx, -dy / 2),
    ];

    for (var i = 0; i < offsets.length; i++) {
      final c = centre + offsets[i];
      final path = Path();
      for (var v = 0; v < 6; v++) {
        final angle = math.pi / 3 * v;
        final point = Offset(
          c.dx + r * 0.92 * math.cos(angle),
          c.dy + r * 0.92 * math.sin(angle),
        );
        v == 0
            ? path.moveTo(point.dx, point.dy)
            : path.lineTo(point.dx, point.dy);
      }
      path.close();
      canvas.drawPath(path, i == 0 ? strong : soft);
    }
  }

  /// Two tiles stacked, the top one lifted clear.
  void _tileMatch(Canvas canvas, Size size, Paint strong, Paint soft) {
    final w = size.width * 0.52;
    final h = size.height * 0.62;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height - h, w, h),
        Radius.circular(w * 0.2),
      ),
      soft,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - w, 0, w, h),
        Radius.circular(w * 0.2),
      ),
      strong,
    );
  }

  /// Sixteen words, one group of four already resolved.
  void _groups(Canvas canvas, Size size, Paint strong, Paint soft) {
    const n = 4;
    final gap = size.width * 0.07;
    final cell = (size.width - gap * (n - 1)) / n;
    for (var row = 0; row < n; row++) {
      for (var col = 0; col < n; col++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(col * (cell + gap), row * (cell + gap), cell, cell),
            Radius.circular(cell * 0.3),
          ),
          row == 0 ? strong : soft,
        );
      }
    }
  }

  /// A path threaded through a field of letters.
  void _weave(
    Canvas canvas,
    Size size,
    Paint strong,
    Paint soft,
    Paint line,
  ) {
    const cols = 3;
    const rows = 3;
    final dot = size.width * 0.1;
    final stepX = size.width / cols;
    final stepY = size.height / rows;

    Offset at(int col, int row) => Offset(
          stepX * (col + 0.5),
          stepY * (row + 0.5),
        );

    const onPath = {(0, 0), (1, 1), (1, 2), (2, 2)};
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        canvas.drawCircle(
          at(col, row),
          dot,
          onPath.contains((col, row)) ? strong : soft,
        );
      }
    }

    final path = Path()..moveTo(at(0, 0).dx, at(0, 0).dy);
    for (final cell in [(1, 1), (1, 2), (2, 2)]) {
      final p = at(cell.$1, cell.$2);
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, line);
  }

  /// A mini grid with its black squares.
  void _crossword(Canvas canvas, Size size, Paint strong, Paint soft) {
    const n = 4;
    final gap = size.width * 0.06;
    final cell = (size.width - gap * (n - 1)) / n;
    const blocked = {0, 5, 10, 15};

    for (var i = 0; i < n * n; i++) {
      final row = i ~/ n;
      final col = i % n;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(col * (cell + gap), row * (cell + gap), cell, cell),
          Radius.circular(cell * 0.16),
        ),
        blocked.contains(i) ? strong : soft,
      );
    }
  }

  /// A domino on its side, pips showing.
  void _dominoes(
    Canvas canvas,
    Size size,
    Paint strong,
    Paint soft,
    Paint line,
  ) {
    final rect = Rect.fromLTWH(
      size.width * 0.08,
      size.height * 0.2,
      size.width * 0.84,
      size.height * 0.6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.12)),
      soft,
    );
    canvas.drawLine(
      Offset(rect.center.dx, rect.top + rect.height * 0.18),
      Offset(rect.center.dx, rect.bottom - rect.height * 0.18),
      line..strokeWidth = size.width * 0.05,
    );

    final pip = size.width * 0.062;
    // Two pips left, three right — a real domino face, not decoration.
    for (final p in [
      Offset(rect.left + rect.width * 0.16, rect.center.dy - rect.height * 0.2),
      Offset(rect.left + rect.width * 0.32, rect.center.dy + rect.height * 0.2),
      Offset(rect.left + rect.width * 0.66, rect.center.dy - rect.height * 0.22),
      Offset(rect.left + rect.width * 0.82, rect.center.dy),
      Offset(rect.left + rect.width * 0.66, rect.center.dy + rect.height * 0.22),
    ]) {
      canvas.drawCircle(p, pip, strong);
    }
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter old) =>
      old.gameId != gameId || old.colour != colour;
}
