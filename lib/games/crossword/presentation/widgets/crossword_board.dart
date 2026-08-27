import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../domain/crossword_game_state.dart';
import '../../domain/crossword_grid.dart';

/// The 5x5 grid: black squares, entry numbers, and the letters entered.
class CrosswordBoard extends StatelessWidget {
  const CrosswordBoard({
    super.key,
    required this.state,
    required this.onCellTap,
    this.showMistakes = false,
  });

  final CrosswordGameState state;
  final ValueChanged<int> onCellTap;
  final bool showMistakes;

  @override
  Widget build(BuildContext context) {
    final highlighted = state.highlightedCells;
    final numbers = state.puzzle.numbers;
    final wrong = showMistakes ? state.wrongCells() : const <int>{};

    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gridLineStrong, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: List.generate(crosswordSize, (row) {
            return Expanded(
              child: Row(
                children: List.generate(crosswordSize, (col) {
                  final index = crosswordIndexAt(row, col);
                  return Expanded(
                    child: _Cell(
                      blocked: state.puzzle.blocked[index],
                      letter: state.entered[index],
                      number: numbers[index],
                      selected: state.selectedCell == index,
                      highlighted: highlighted.contains(index),
                      revealed: state.revealedCells.contains(index),
                      wrong: wrong.contains(index),
                      onTap: () => onCellTap(index),
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.blocked,
    required this.letter,
    required this.number,
    required this.selected,
    required this.highlighted,
    required this.revealed,
    required this.wrong,
    required this.onTap,
  });

  final bool blocked;
  final String letter;
  final int? number;
  final bool selected;
  final bool highlighted;
  final bool revealed;
  final bool wrong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (blocked) {
      return const DecoratedBox(
        decoration: BoxDecoration(color: AppColors.gridLineStrong),
        child: SizedBox.expand(),
      );
    }

    final Color background;
    if (wrong) {
      background = AppColors.cellError;
    } else if (selected) {
      background = AppColors.cellSelected;
    } else if (highlighted) {
      background = AppColors.cellPeer;
    } else {
      background = AppColors.surface;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: AppColors.gridLine),
        ),
        child: Stack(
          children: [
            if (number != null)
              Positioned(
                left: 2,
                top: 1,
                child: Text(
                  '$number',
                  style: const TextStyle(
                    fontSize: 9,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            Center(
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  // A revealed letter is drawn differently so the player
                  // can tell what they were given from what they solved.
                  color: wrong
                      ? AppColors.textError
                      : (revealed ? AppColors.secondary : AppColors.textPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
