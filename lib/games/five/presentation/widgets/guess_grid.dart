import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../domain/five_game_state.dart';
import '../../domain/letter_state.dart';

/// The 6x5 tile grid showing submitted guesses, the in-progress guess, and
/// empty rows still to come.
class GuessGrid extends StatelessWidget {
  const GuessGrid({super.key, required this.state});

  final FiveGameState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(fiveMaxGuesses, (row) => _buildRow(row)),
    );
  }

  Widget _buildRow(int row) {
    final isSubmitted = row < state.submittedGuesses.length;
    final isCurrent = row == state.submittedGuesses.length;

    late final String letters;
    late final List<LetterState> states;
    if (isSubmitted) {
      letters = state.submittedGuesses[row];
      states = state.evaluations[row];
    } else if (isCurrent) {
      letters = state.currentInput;
      states = List.filled(fiveWordLength, LetterState.empty);
    } else {
      letters = '';
      states = List.filled(fiveWordLength, LetterState.empty);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(fiveWordLength, (col) {
          final letter = col < letters.length ? letters[col] : '';
          return _Tile(letter: letter, state: states[col]);
        }),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.letter, required this.state});

  final String letter;
  final LetterState state;

  @override
  Widget build(BuildContext context) {
    final filled = letter.isNotEmpty;
    return Container(
      width: 52,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _fillColor(),
        border: Border.all(color: _borderColor(filled), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        letter.toUpperCase(),
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: state == LetterState.empty ? AppColors.textPrimary : Colors.white,
        ),
      ),
    );
  }

  Color _fillColor() {
    switch (state) {
      case LetterState.correct:
        return AppColors.feedbackCorrect;
      case LetterState.present:
        return AppColors.feedbackPresent;
      case LetterState.absent:
        return AppColors.feedbackAbsent;
      case LetterState.empty:
        return AppColors.surface;
    }
  }

  Color _borderColor(bool filled) {
    if (state != LetterState.empty) return Colors.transparent;
    return filled ? AppColors.textSecondary : AppColors.surfaceAlt;
  }
}
