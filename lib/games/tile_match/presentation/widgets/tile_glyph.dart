import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../domain/tile_face.dart';

/// Colour for each tile hue.
///
/// Drawn from the app's own palette rather than a generic rainbow, and
/// chosen so the four stay distinguishable side by side — including for
/// the most common forms of colour blindness, which is why hue alone never
/// distinguishes two tiles: the shape always differs too.
Color tileHueColor(TileHue hue) => switch (hue) {
      TileHue.teal => AppColors.primary,
      TileHue.amber => AppColors.secondary,
      TileHue.plum => const Color(0xFF7B4B6E),
      TileHue.sage => const Color(0xFF6B8F5E),
    };

/// Paints one tile face: a geometric shape in a hue.
///
/// Every shape is constructed here from points and arcs. Nothing is an
/// imported glyph or traced from existing tile artwork, so the face set is
/// wholly the app's own and scales cleanly to any tile size.
class TileGlyph extends StatelessWidget {
  const TileGlyph({super.key, required this.face, this.size = 28});

  final TileFace face;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TileGlyphPainter(face: face, color: tileHueColor(face.hue)),
      ),
    );
  }
}

class _TileGlyphPainter extends CustomPainter {
  const _TileGlyphPainter({required this.face, required this.color});

  final TileFace face;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 * 0.82;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color
      ..strokeWidth = size.shortestSide * 0.14
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (face.shape) {
      case TileShape.circle:
        canvas.drawCircle(centre, radius, fill);
      case TileShape.square:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: centre,
              width: radius * 1.7,
              height: radius * 1.7,
            ),
            Radius.circular(radius * 0.18),
          ),
          fill,
        );
      case TileShape.triangle:
        canvas.drawPath(_polygon(centre, radius, 3, -pi / 2), fill);
      case TileShape.diamond:
        canvas.drawPath(_polygon(centre, radius, 4, -pi / 2), fill);
      case TileShape.hexagon:
        canvas.drawPath(_polygon(centre, radius, 6, -pi / 2), fill);
      case TileShape.star:
        canvas.drawPath(_star(centre, radius, 5), fill);
      case TileShape.chevron:
        canvas.drawPath(
          Path()
            ..moveTo(centre.dx - radius * 0.7, centre.dy - radius * 0.55)
            ..lineTo(centre.dx + radius * 0.5, centre.dy)
            ..lineTo(centre.dx - radius * 0.7, centre.dy + radius * 0.55),
          stroke,
        );
      case TileShape.cross:
        canvas.drawLine(
          centre + Offset(-radius * 0.6, -radius * 0.6),
          centre + Offset(radius * 0.6, radius * 0.6),
          stroke,
        );
        canvas.drawLine(
          centre + Offset(radius * 0.6, -radius * 0.6),
          centre + Offset(-radius * 0.6, radius * 0.6),
          stroke,
        );
      case TileShape.ring:
        canvas.drawCircle(centre, radius * 0.72, stroke);
      case TileShape.crescent:
        // A filled disc with a second disc punched out of it, offset up and
        // to the right. saveLayer is what makes the clear blend mode cut a
        // hole rather than paint the background colour over the tile.
        canvas.saveLayer(Offset.zero & size, Paint());
        canvas.drawCircle(centre, radius, fill);
        canvas.drawCircle(
          centre + Offset(radius * 0.45, -radius * 0.3),
          radius * 0.85,
          Paint()..blendMode = BlendMode.clear,
        );
        canvas.restore();
    }
  }

  Path _polygon(Offset centre, double radius, int sides, double startAngle) {
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final angle = startAngle + 2 * pi * i / sides;
      final point = Offset(
        centre.dx + radius * cos(angle),
        centre.dy + radius * sin(angle),
      );
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  Path _star(Offset centre, double radius, int points) {
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius * 0.45;
      final angle = -pi / 2 + pi * i / points;
      final point = Offset(
        centre.dx + r * cos(angle),
        centre.dy + r * sin(angle),
      );
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_TileGlyphPainter old) =>
      old.face != face || old.color != color;
}
