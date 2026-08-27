import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../domain/weave_game_state.dart';
import '../../domain/weave_grid.dart';

/// The letter grid, traced by dragging a finger across it.
///
/// Hit-testing is done here against the widget's own box rather than with a
/// GestureDetector per cell: a trace is one continuous drag, so the board
/// needs to know which cell the finger is over at every move, not merely
/// which cell started the gesture.
class WeaveBoard extends StatefulWidget {
  const WeaveBoard({
    super.key,
    required this.state,
    required this.onWordTraced,
  });

  final WeaveGameState state;
  final ValueChanged<String> onWordTraced;

  @override
  State<WeaveBoard> createState() => _WeaveBoardState();
}

class _WeaveBoardState extends State<WeaveBoard> {
  final List<int> _path = [];

  int? _cellAt(Offset local, Size size) {
    final cellWidth = size.width / weaveCols;
    final cellHeight = size.height / weaveRows;
    final col = (local.dx / cellWidth).floor();
    final row = (local.dy / cellHeight).floor();
    if (!weaveInBounds(row, col)) return null;
    return weaveIndexAt(row, col);
  }

  void _extendTo(int? cell) {
    if (cell == null) return;
    if (_path.isNotEmpty) {
      // Stepping back onto the previous cell undoes the last step, which
      // is how a player corrects a wrong turn without lifting a finger.
      if (_path.length >= 2 && _path[_path.length - 2] == cell) {
        setState(() => _path.removeLast());
        return;
      }
      if (_path.contains(cell)) return;
      if (!weaveAdjacency[_path.last].contains(cell)) return;
    }
    setState(() => _path.add(cell));
  }

  void _finish() {
    if (_path.length >= 2) {
      final word = _path.map((i) => widget.state.puzzle.letters[i]).join();
      widget.onWordTraced(word);
    }
    setState(_path.clear);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final foundCells = state.foundCells;

    return AspectRatio(
      aspectRatio: weaveCols / weaveRows,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) => _extendTo(_cellAt(d.localPosition, size)),
            onPanUpdate: (d) => _extendTo(_cellAt(d.localPosition, size)),
            onPanEnd: (_) => _finish(),
            onPanCancel: () => setState(_path.clear),
            child: Column(
              children: List.generate(weaveRows, (row) {
                return Expanded(
                  child: Row(
                    children: List.generate(weaveCols, (col) {
                      final index = weaveIndexAt(row, col);
                      return Expanded(
                        child: _Cell(
                          letter: state.puzzle.letters[index],
                          found: foundCells.contains(index),
                          tracing: _path.contains(index),
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
    required this.letter,
    required this.found,
    required this.tracing,
  });

  final String letter;
  final bool found;
  final bool tracing;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    if (tracing) {
      background = AppColors.secondary;
      foreground = Colors.white;
    } else if (found) {
      background = AppColors.primary;
      foreground = Colors.white;
    } else {
      background = AppColors.surface;
      foreground = AppColors.textPrimary;
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: Border.all(
            color: tracing || found ? Colors.transparent : AppColors.surfaceAlt,
          ),
        ),
        child: Center(
          child: FittedBox(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                letter,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
