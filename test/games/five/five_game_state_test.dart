import 'package:flutter_test/flutter_test.dart';
import 'package:allways_games/games/five/domain/five_game_state.dart';
import 'package:allways_games/games/five/domain/letter_state.dart';

void main() {
  test('initial state is playing with no guesses', () {
    final state = FiveGameState.initial('crane');
    expect(state.status, FiveStatus.playing);
    expect(state.submittedGuesses, isEmpty);
    expect(state.canSubmit, isFalse);
    expect(state.remainingGuesses, fiveMaxGuesses);
  });

  test('canSubmit only true at full word length while playing', () {
    final state = FiveGameState.initial('crane').copyWith(currentInput: 'cra');
    expect(state.canSubmit, isFalse);
    final full = state.copyWith(currentInput: 'crane');
    expect(full.canSubmit, isTrue);
  });

  test('keyboardStates keeps the best-known state per letter across guesses', () {
    final state = FiveGameState.initial('crane').copyWith(
      submittedGuesses: ['cabin', 'crane'],
      evaluations: [
        [
          LetterState.correct,
          LetterState.present,
          LetterState.absent,
          LetterState.absent,
          LetterState.present,
        ],
        List.filled(5, LetterState.correct),
      ],
    );
    // 'c' was correct both times, 'a' upgraded from present (guess 1) to
    // correct (guess 2).
    expect(state.keyboardStates['c'], LetterState.correct);
    expect(state.keyboardStates['a'], LetterState.correct);
    expect(state.keyboardStates['b'], LetterState.absent);
  });
}
