import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../domain/sudoku_board.dart';
import '../../domain/sudoku_game_state.dart';

/// One Sudoku cell: a given, a player entry, or pencil notes. Highlighting
/// follows the usual convention of emphasising the selected cell, its
/// row/column/box peers, and every cell holding the same digit.
class SudokuCell extends StatelessWidget {
  const SudokuCell({
    super.key,
    required this.state,
    required this.index,
    required this.conflicts,
  });

  final SudokuGameState state;
  final int index;
  final Set<int> conflicts;

  @override
  Widget build(BuildContext context) {
    final value = state.entries[index];
    final isGiven = state.isGiven(index);
    final isSelected = state.selectedIndex == index;
    final hasConflict = conflicts.contains(index);

    return ColoredBox(
      color: _backgroundColor(isSelected, hasConflict),
      child: SizedBox.expand(
        child: Center(
          child: value != emptyCell
              ? Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: isGiven ? FontWeight.w800 : FontWeight.w600,
                    color: hasConflict
                        ? AppColors.scheme.error
                        : (isGiven ? AppColors.textPrimary : AppColors.primary),
                  ),
                )
              : _Notes(notes: state.notes[index]),
        ),
      ),
    );
  }

  Color _backgroundColor(bool isSelected, bool hasConflict) {
    if (hasConflict) return AppColors.scheme.error.withValues(alpha: 0.14);
    if (isSelected) return AppColors.primaryContainer;

    final selected = state.selectedIndex;
    if (selected == null) return Colors.transparent;

    final selectedValue = state.entries[selected];
    if (selectedValue != emptyCell && state.entries[index] == selectedValue) {
      return AppColors.secondaryContainer.withValues(alpha: 0.6);
    }
    if (_isPeerOf(selected)) {
      return AppColors.surfaceAlt.withValues(alpha: 0.55);
    }
    return Colors.transparent;
  }

  bool _isPeerOf(int selected) =>
      rowOf(selected) == rowOf(index) ||
      colOf(selected) == colOf(index) ||
      boxOf(selected) == boxOf(index);
}

class _Notes extends StatelessWidget {
  const _Notes({required this.notes});

  final Set<int> notes;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(1),
      child: Column(
        children: List.generate(3, (row) {
          return Expanded(
            child: Row(
              children: List.generate(3, (col) {
                final digit = row * 3 + col + 1;
                return Expanded(
                  child: Center(
                    child: Text(
                      notes.contains(digit) ? '$digit' : '',
                      style: const TextStyle(
                        fontSize: 8,
                        height: 1,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}
