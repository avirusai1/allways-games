import 'package:allways_games/games/honeycomb/domain/honeycomb_game_state.dart';
import 'package:allways_games/games/honeycomb/domain/honeycomb_puzzle.dart';
import 'package:allways_games/games/honeycomb/domain/honeycomb_scoring.dart';
import 'package:flutter_test/flutter_test.dart';

/// A hand-built comb: centre G, outer AHLOTU. ALTHOUGH is the pangram.
HoneycombPuzzle _puzzle() => HoneycombPuzzle(
      requiredLetter: 'G',
      outerLetters: const ['A', 'H', 'L', 'O', 'T', 'U'],
      answers: const [
        'ALTHOUGH', // pangram: all seven letters
        'GOAL',
        'GOAT',
        'GOUT',
        'ALGA',
        'TOTAL', // no G — deliberately wrong, checked by the first test
      ],
    );

/// The same comb without the bad entry, for the rest of the tests.
HoneycombPuzzle _validPuzzle() => HoneycombPuzzle(
      requiredLetter: 'G',
      outerLetters: const ['A', 'H', 'L', 'O', 'T', 'U'],
      answers: const ['ALTHOUGH', 'GOAL', 'GOAT', 'GOUT', 'ALGA', 'GALA'],
    );

void main() {
  test('the fixture comb has seven distinct letters and a real pangram', () {
    final puzzle = _validPuzzle();
    expect(puzzle.allLetters.toSet(), hasLength(honeycombLetterCount));
    expect(puzzle.pangrams, {'ALTHOUGH'});
    expect(puzzle.isPangram('ALTHOUGH'), isTrue);
    expect(puzzle.isPangram('GOAL'), isFalse);
  });

  test('a puzzle can carry an answer that breaks its own rules', () {
    // Guarding the generator's job, not the app's: TOTAL has no G, so it
    // could never be typed on this comb. The bank test is what stops such
    // an entry shipping.
    expect(_puzzle().answers, contains('TOTAL'));
    final state = HoneycombGameState.initial(_puzzle());
    expect(
      state.rejectionFor('TOTAL'),
      HoneycombRejection.missingRequiredLetter,
    );
  });

  group('initial state', () {
    test('starts empty at the bottom rank', () {
      final state = HoneycombGameState.initial(_validPuzzle());
      expect(state.foundWords, isEmpty);
      expect(state.currentInput, '');
      expect(state.score, 0);
      expect(state.rank.name, honeycombRanks.first.name);
      expect(state.foundPangrams, isEmpty);
      expect(state.isComplete, isFalse);
      expect(state.remainingAnswers, _validPuzzle().answers.length);
      expect(state.outerLetterOrder, _validPuzzle().outerLetters);
    });

    test('max score counts every answer, pangram bonus included', () {
      final puzzle = _validPuzzle();
      // ALTHOUGH: 8 + 7 bonus. GOAL/GOAT/GOUT/ALGA/GALA: 1 each.
      expect(puzzle.maxScore, 8 + honeycombPangramBonus + 5);
    });
  });

  group('typing', () {
    test('accepts comb letters in any case and refuses the rest', () {
      var state = HoneycombGameState.initial(_validPuzzle());
      state = state.inputLetter('g').inputLetter('O');
      expect(state.currentInput, 'GO');
      expect(state.inputLetter('Z'), same(state));
      expect(state.inputLetter('B'), same(state));
    });

    test('backspace and clear walk the input back', () {
      final state = HoneycombGameState.initial(_validPuzzle())
          .inputLetter('G')
          .inputLetter('O')
          .inputLetter('A');
      expect(state.backspace().currentInput, 'GO');
      expect(state.clearInput().currentInput, '');
      expect(
        HoneycombGameState.initial(_validPuzzle()).backspace().currentInput,
        '',
      );
    });
  });

  group('rejections', () {
    late HoneycombGameState state;
    setUp(() => state = HoneycombGameState.initial(_validPuzzle()));

    test('a word under the minimum length is too short', () {
      expect(state.rejectionFor('GOA'), HoneycombRejection.tooShort);
    });

    test('a word without the centre letter is named as such', () {
      expect(state.rejectionFor('HALO'), HoneycombRejection.missingRequiredLetter);
    });

    test('a letter off the comb is named as such', () {
      expect(state.rejectionFor('GOES'), HoneycombRejection.letterNotOnBoard);
    });

    test('a well-formed non-answer is rejected as unknown', () {
      // GLUT uses only comb letters and contains G, but is not on the list.
      expect(state.rejectionFor('GLUT'), HoneycombRejection.notAnAnswer);
    });

    test('an answer is not rejected, in either case', () {
      expect(state.rejectionFor('GOAL'), isNull);
      expect(state.rejectionFor('goal'), isNull);
    });

    test('the complaint is the most useful one, not the first that fits', () {
      // GOES is both a non-answer and uses a letter off the comb; the
      // actionable complaint is the letter.
      expect(state.rejectionFor('GOES'), HoneycombRejection.letterNotOnBoard);
      // ZZZ is short *and* off-comb; length is the thing to fix first.
      expect(state.rejectionFor('ZZZ'), HoneycombRejection.tooShort);
    });
  });

  group('finding words', () {
    test('an accepted word scores and clears the input', () {
      final result = _play(HoneycombGameState.initial(_validPuzzle()), 'GOAL');
      expect(result.rejection, isNull);
      expect(result.state.foundWords, {'GOAL'});
      expect(result.state.currentInput, '');
      expect(result.state.score, 1);
      expect(result.state.remainingAnswers, 5);
    });

    test('a rejected word leaves the state untouched', () {
      final state = HoneycombGameState.initial(_validPuzzle())
          .inputLetter('G')
          .inputLetter('O');
      final result = state.submit();
      expect(result.rejection, HoneycombRejection.tooShort);
      expect(result.state, same(state));
    });

    test('the same word cannot be found twice', () {
      final found = _play(HoneycombGameState.initial(_validPuzzle()), 'GOAL');
      expect(found.state.rejectionFor('GOAL'), HoneycombRejection.alreadyFound);
      final again = _play(found.state, 'GOAL');
      expect(again.rejection, HoneycombRejection.alreadyFound);
      expect(again.state.foundWords, hasLength(1));
    });

    test('a pangram scores its length plus the bonus', () {
      final result =
          _play(HoneycombGameState.initial(_validPuzzle()), 'ALTHOUGH');
      expect(result.state.score, 8 + honeycombPangramBonus);
      expect(result.state.foundPangrams, {'ALTHOUGH'});
    });

    test('finding every answer completes the board at the top rank', () {
      var state = HoneycombGameState.initial(_validPuzzle());
      for (final word in _validPuzzle().answers) {
        state = _play(state, word).state;
      }
      expect(state.isComplete, isTrue);
      expect(state.remainingAnswers, 0);
      expect(state.score, state.maxScore);
      expect(state.rank.name, honeycombRanks.last.name);
    });

    test('rank climbs as words accumulate', () {
      var state = HoneycombGameState.initial(_validPuzzle());
      final startRank = state.rank.percentOfMax;
      state = _play(state, 'ALTHOUGH').state;
      expect(state.rank.percentOfMax, greaterThan(startRank));
    });
  });

  group('shuffling', () {
    test('reorders the outer letters without touching the centre', () {
      final state = HoneycombGameState.initial(_validPuzzle());
      final shuffled = state.shuffleOuterLetters(
        state.outerLetterOrder.reversed.toList(),
      );
      expect(shuffled.outerLetterOrder, isNot(state.outerLetterOrder));
      expect(shuffled.outerLetterOrder.toSet(), state.outerLetterOrder.toSet());
      expect(shuffled.puzzle.requiredLetter, 'G');
      // The centre letter is not part of the shuffled ring.
      expect(shuffled.outerLetterOrder, isNot(contains('G')));
    });

    test('does not disturb found words or score', () {
      final found = _play(HoneycombGameState.initial(_validPuzzle()), 'GOAL');
      final shuffled = found.state
          .shuffleOuterLetters(found.state.outerLetterOrder.reversed.toList());
      expect(shuffled.foundWords, found.state.foundWords);
      expect(shuffled.score, found.state.score);
    });
  });

  group('json', () {
    test('a puzzle round-trips', () {
      final puzzle = _validPuzzle();
      final restored = HoneycombPuzzle.fromJson(puzzle.toJson());
      expect(restored.requiredLetter, puzzle.requiredLetter);
      expect(restored.outerLetters.toSet(), puzzle.outerLetters.toSet());
      expect(restored.answers, puzzle.answers);
      expect(restored.maxScore, puzzle.maxScore);
      expect(restored.pangrams, puzzle.pangrams);
    });
  });
}

/// Types [word] onto a cleared input and submits it.
({HoneycombGameState state, HoneycombRejection? rejection}) _play(
  HoneycombGameState state,
  String word,
) {
  var typed = state.clearInput();
  for (final letter in word.split('')) {
    typed = typed.inputLetter(letter);
  }
  return typed.submit();
}
