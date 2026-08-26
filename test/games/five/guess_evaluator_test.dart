import 'package:flutter_test/flutter_test.dart';
import 'package:allways_games/games/five/domain/guess_evaluator.dart';
import 'package:allways_games/games/five/domain/letter_state.dart';

void main() {
  group('evaluateGuess', () {
    test('all correct', () {
      final result = evaluateGuess(guess: 'crane', answer: 'crane');
      expect(result, List.filled(5, LetterState.correct));
    });

    test('all absent', () {
      final result = evaluateGuess(guess: 'goofy', answer: 'stern');
      expect(result, List.filled(5, LetterState.absent));
    });

    test('mixed correct/present/absent', () {
      // answer: crane, guess: cabin -> c correct, a present, b absent,
      // i absent, n present
      final result = evaluateGuess(guess: 'cabin', answer: 'crane');
      expect(result, [
        LetterState.correct,
        LetterState.present,
        LetterState.absent,
        LetterState.absent,
        LetterState.present,
      ]);
    });

    test('duplicate guessed letter, single occurrence in answer: only one marked present', () {
      // answer: sissy has two s's already used by position;
      // simpler case: answer "abide", guess "eerie" style duplicate check
      // answer has one 'e' at the end; guess "eerie" has three e's.
      final result = evaluateGuess(guess: 'eerie', answer: 'abide');
      // positions: e(0) e(1) r(2) i(3) e(4)
      // answer: a b i d e
      // pass1 exact matches: guess[3]='i' vs answer[3]='d' no; guess[4]='e' vs answer[4]='e' yes -> correct
      // remaining pool after pass1: a b i d (e consumed)
      // pass2: guess[0]='e' -> no e left -> absent
      // guess[1]='e' -> no e left -> absent
      // guess[2]='r' -> not in answer -> absent
      // guess[3]='i' -> 'i' present in pool -> present
      expect(result, [
        LetterState.absent,
        LetterState.absent,
        LetterState.absent,
        LetterState.present,
        LetterState.correct,
      ]);
    });

    test('duplicate letter in both guess and answer at different positions', () {
      // answer "level": l e v e l
      // guess  "extra": e x t r a — no shared duplicates, use a clearer case:
      // answer "erase", guess "eerie"
      final result = evaluateGuess(guess: 'eerie', answer: 'erase');
      // answer: e r a s e (two e's)
      // pass1: guess[0]='e' vs answer[0]='e' -> correct; consume one e (pool e:1)
      //        guess[4]='e' vs answer[4]='e' -> correct; consume other e (pool e:0)
      // pass2: guess[1]='e' -> pool e=0 -> absent
      //        guess[2]='r' -> pool has r -> present
      //        guess[3]='i' -> not in answer -> absent
      expect(result, [
        LetterState.correct,
        LetterState.absent,
        LetterState.present,
        LetterState.absent,
        LetterState.correct,
      ]);
    });
  });
}
