import 'letter_state.dart';

/// Evaluates a 5-letter [guess] against the [answer], returning one
/// [LetterState] per position.
///
/// Uses the standard two-pass approach so duplicate letters are scored
/// correctly: a repeated guessed letter is only marked "present" as many
/// times as it actually remains unaccounted-for in the answer (matching
/// the well-established convention this genre of game uses).
List<LetterState> evaluateGuess({required String guess, required String answer}) {
  assert(guess.length == answer.length);
  final length = answer.length;
  final result = List<LetterState>.filled(length, LetterState.absent);

  final answerLetterCounts = <String, int>{};
  for (final letter in answer.split('')) {
    answerLetterCounts[letter] = (answerLetterCounts[letter] ?? 0) + 1;
  }

  // Pass 1: exact position matches consume from the letter pool first.
  for (var i = 0; i < length; i++) {
    if (guess[i] == answer[i]) {
      result[i] = LetterState.correct;
      answerLetterCounts[guess[i]] = answerLetterCounts[guess[i]]! - 1;
    }
  }

  // Pass 2: remaining guessed letters are "present" only while the pool
  // for that letter isn't already exhausted.
  for (var i = 0; i < length; i++) {
    if (result[i] == LetterState.correct) continue;
    final letter = guess[i];
    final remaining = answerLetterCounts[letter] ?? 0;
    if (remaining > 0) {
      result[i] = LetterState.present;
      answerLetterCounts[letter] = remaining - 1;
    }
  }

  return result;
}
