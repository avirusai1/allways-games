import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../games/five/domain/letter_state.dart';

const List<String> _row1 = ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'];
const List<String> _row2 = ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'];
const List<String> _row3 = ['Z', 'X', 'C', 'V', 'B', 'N', 'M'];

/// Generic QWERTY on-screen keyboard shared by every letter-entry game
/// (Five now; Honeycomb and Word Loop reuse it later). Key coloring is
/// driven by [letterStates], keyed by uppercase letter.
class OnScreenKeyboard extends StatelessWidget {
  const OnScreenKeyboard({
    super.key,
    required this.letterStates,
    required this.onLetter,
    required this.onBackspace,
    required this.onSubmit,
  });

  final Map<String, LetterState> letterStates;
  final ValueChanged<String> onLetter;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    // Every game screen wraps this in a SafeArea, so the system gesture
    // inset is already gone by the time we get here. This is the extra
    // breathing room on top of it: flush against the gesture bar the
    // ENTER row is awkward to hit and easy to turn into a back-swipe by
    // accident, which costs more than the space does.
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _keyRow(context, _row1),
          const SizedBox(height: 8),
          _keyRow(context, _row2),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionKey(label: 'ENTER', flex: 3, onTap: onSubmit),
              const SizedBox(width: 6),
              ..._row3.map((l) => _LetterKey(
                    letter: l,
                    state: letterStates[l],
                    onTap: () => onLetter(l),
                  )),
              const SizedBox(width: 6),
              _ActionKey(
                flex: 3,
                onTap: onBackspace,
                child: const Icon(Icons.backspace_outlined, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _keyRow(BuildContext context, List<String> letters) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: letters
          .map((l) => _LetterKey(
                letter: l,
                state: letterStates[l],
                onTap: () => onLetter(l),
              ))
          .toList(),
    );
  }
}

class _LetterKey extends StatelessWidget {
  const _LetterKey({required this.letter, required this.state, required this.onTap});

  final String letter;
  final LetterState? state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: _colorFor(state),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            width: 34,
            height: 48,
            alignment: Alignment.center,
            child: Text(
              letter,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: state == null ? AppColors.textPrimary : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Color _colorFor(LetterState? state) {
    switch (state) {
      case LetterState.correct:
        return AppColors.feedbackCorrect;
      case LetterState.present:
        return AppColors.feedbackPresent;
      case LetterState.absent:
        return AppColors.feedbackAbsent;
      case LetterState.empty:
      case null:
        return AppColors.surfaceAlt;
    }
  }
}

class _ActionKey extends StatelessWidget {
  const _ActionKey({required this.onTap, this.child, this.label, this.flex = 1});

  final VoidCallback onTap;
  final Widget? child;
  final String? label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              child: child ??
                  Text(
                    label ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
