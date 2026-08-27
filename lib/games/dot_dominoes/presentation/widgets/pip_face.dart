import 'package:flutter/material.dart';

/// The pips for one half of a domino, in the usual dice arrangement.
///
/// Drawn rather than written as a numeral: the whole game is about
/// reading values at a glance and comparing them across a region, and
/// counted dots are quicker to take in than digits.
class PipFace extends StatelessWidget {
  const PipFace({super.key, required this.value, required this.colour});

  final int value;
  final Color colour;

  /// Which of the nine positions in a 3x3 are inked for each value.
  static const Map<int, List<int>> _layout = {
    0: [],
    1: [4],
    2: [0, 8],
    3: [0, 4, 8],
    4: [0, 2, 6, 8],
    5: [0, 2, 4, 6, 8],
    6: [0, 2, 3, 5, 6, 8],
  };

  @override
  Widget build(BuildContext context) {
    final inked = _layout[value] ?? const <int>[];
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        final pip = side * 0.15;
        return Padding(
          padding: EdgeInsets.all(side * 0.16),
          child: Column(
            children: List.generate(3, (row) {
              return Expanded(
                child: Row(
                  children: List.generate(3, (col) {
                    final index = row * 3 + col;
                    return Expanded(
                      child: Center(
                        child: inked.contains(index)
                            ? Container(
                                width: pip,
                                height: pip,
                                decoration: BoxDecoration(
                                  color: colour,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
