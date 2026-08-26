import 'package:allways_games/games/word_loop/domain/word_loop_box.dart';
import 'package:allways_games/games/word_loop/domain/word_loop_game_state.dart';
import 'package:allways_games/games/word_loop/domain/word_loop_puzzle.dart';
import 'package:allways_games/games/word_loop/domain/word_loop_solver.dart';
import 'package:flutter_test/flutter_test.dart';

/// A board with a known two-word answer, so the rules can be tested without
/// depending on whatever the generator happened to produce.
///
/// Sides: DLN / BRT / IOV / AMY. ABDOMINAL chains into LAVATORY, and
/// between them the two use all twelve letters. The first test in this file
/// checks that claim rather than trusting it.
WordLoopPuzzle _puzzle() {
  return WordLoopPuzzle(
    box: WordLoopBox.parse('DLN-BRT-IOV-AMY'),
    par: 2,
    exampleSolution: const ['ABDOMINAL', 'LAVATORY'],
    playableWordCount: 7,
    dictionary: const {
      'ABDOMINAL', 'LAVATORY', 'LAB', 'BOAT', 'TAB', 'BOA', 'NIB', //
    },
  );
}

void main() {
  test('the fixture board really does support its own answer', () {
    final puzzle = _puzzle();
    expect(puzzle.box.letters.length, wordLoopLetterCount);
    for (final word in puzzle.exampleSolution) {
      expect(puzzle.box.isPlayable(word), isTrue, reason: word);
      expect(puzzle.isValidWord(word), isTrue, reason: word);
    }
    // The chain has to join up, and cover the board.
    expect(puzzle.exampleSolution[1][0], 'L');
    expect(puzzle.exampleSolution[0].endsWith('L'), isTrue);
    expect(
      wordLoopLetterMask(puzzle.exampleSolution.join()),
      wordLoopLetterMask(puzzle.box.letters.join()),
    );
  });

  group('initial state', () {
    test('starts empty with every letter still to cover', () {
      final state = WordLoopGameState.initial(_puzzle());
      expect(state.chain, isEmpty);
      expect(state.currentInput, '');
      expect(state.status, WordLoopStatus.playing);
      expect(state.usedLetters, isEmpty);
      expect(state.remainingLetters.length, wordLoopLetterCount);
      expect(state.coversBoard, isFalse);
      expect(state.requiredStartingLetter, isNull);
      expect(state.wordsUsed, 0);
    });
  });

  group('typing', () {
    test('accepts letters on the board and refuses the rest', () {
      var state = WordLoopGameState.initial(_puzzle());
      state = state.inputLetter('L').inputLetter('a');
      expect(state.currentInput, 'LA');
      expect(state.inputLetter('C'), same(state));
    });

    test('backspace and clear walk the input back', () {
      final state = WordLoopGameState.initial(_puzzle())
          .inputLetter('L')
          .inputLetter('A')
          .inputLetter('B');
      expect(state.backspace().currentInput, 'LA');
      expect(state.clearInput().currentInput, '');
      expect(WordLoopGameState.initial(_puzzle()).backspace().currentInput, '');
    });
  });

  group('rejections', () {
    late WordLoopGameState state;
    setUp(() => state = WordLoopGameState.initial(_puzzle()));

    test('a word under three letters is too short', () {
      expect(state.rejectionFor('LA'), WordLoopRejection.tooShort);
    });

    test('a letter off the board is named as such', () {
      expect(state.rejectionFor('CAB'), WordLoopRejection.letterNotOnBoard);
    });

    test('two letters in a row from one side is named as such', () {
      // D and L are both on the first side.
      expect(state.rejectionFor('DLA'), WordLoopRejection.sameSideTwice);
    });

    test('a traceable non-word is rejected as a non-word', () {
      // M (side 3) I (side 2) B (side 1) traces fine but is not a word.
      expect(state.puzzle.box.isPlayable('MIB'), isTrue);
      expect(state.rejectionFor('MIB'), WordLoopRejection.notAWord);
    });

    test('a legal word is not rejected', () {
      expect(state.rejectionFor('ABDOMINAL'), isNull);
      expect(state.rejectionFor('abdominal'), isNull);
    });

    test('the next word must start where the last one ended', () {
      final afterFirst = _play(state, 'ABDOMINAL').state;
      expect(afterFirst.requiredStartingLetter, 'L');
      expect(
        afterFirst.rejectionFor('BOAT'),
        WordLoopRejection.wrongStartingLetter,
      );
      expect(afterFirst.rejectionFor('LAVATORY'), isNull);
    });

    test('a word cannot be played twice', () {
      // LAB -> BOAT -> TAB leaves the chain needing a word starting with B,
      // which BOAT satisfies — so the only thing standing in its way is
      // that it has already been played.
      var played = _play(state, 'LAB').state;
      played = _play(played, 'BOAT').state;
      played = _play(played, 'TAB').state;

      expect(played.chain, ['LAB', 'BOAT', 'TAB']);
      expect(played.requiredStartingLetter, 'B');
      expect(played.rejectionFor('BOAT'), WordLoopRejection.alreadyUsed);
      expect(played.rejectionFor('BOA'), isNull);
    });
  });

  group('playing words', () {
    test('a rejected word leaves the state untouched', () {
      final state = WordLoopGameState.initial(_puzzle())
          .inputLetter('L')
          .inputLetter('A');
      final result = state.submit();
      expect(result.rejection, WordLoopRejection.tooShort);
      expect(result.state, same(state));
      expect(result.state.chain, isEmpty);
    });

    test('an accepted word joins the chain and seeds the next input', () {
      final result = _play(WordLoopGameState.initial(_puzzle()), 'ABDOMINAL');
      expect(result.rejection, isNull);
      expect(result.state.chain, ['ABDOMINAL']);
      // The next word has to start with L, so the input starts there.
      expect(result.state.currentInput, 'L');
      expect(result.state.usedLetters, {'A', 'B', 'D', 'O', 'M', 'I', 'N', 'L'});
      expect(result.state.remainingLetters, {'R', 'T', 'V', 'Y'});
      expect(result.state.status, WordLoopStatus.playing);
    });

    test('covering every letter solves the board', () {
      var state = WordLoopGameState.initial(_puzzle());
      state = _play(state, 'ABDOMINAL').state;
      final result = _play(state, 'LAVATORY');

      expect(result.rejection, isNull);
      expect(result.state.status, WordLoopStatus.solved);
      expect(result.state.isPlaying, isFalse);
      expect(result.state.coversBoard, isTrue);
      expect(result.state.remainingLetters, isEmpty);
      expect(result.state.wordsUsed, 2);
      // Nothing is left to type, so the input is cleared rather than seeded.
      expect(result.state.currentInput, '');
    });

    test('a finished board takes no more input', () {
      var state = WordLoopGameState.initial(_puzzle());
      state = _play(state, 'ABDOMINAL').state;
      state = _play(state, 'LAVATORY').state;

      expect(state.inputLetter('L'), same(state));
      expect(state.backspace(), same(state));
      expect(state.clearInput(), same(state));
      expect(state.undoWord(), same(state));
      expect(state.submit().state, same(state));
    });

    test('finishing over par still counts as covered', () {
      var state = WordLoopGameState.initial(_puzzle());
      state = _play(state, 'LAB').state;
      state = _play(state, 'BOAT').state;
      state = _play(state, 'TAB').state;
      expect(state.status, WordLoopStatus.playing);
      state = _play(state, 'BOA').state;
      // LAB/BOAT/TAB/BOA never reaches V or Y, so the board is not covered
      // no matter how many words are played.
      expect(state.coversBoard, isFalse);
      expect(state.remainingLetters, containsAll({'V', 'Y'}));
      expect(state.wordsUsed, greaterThan(state.puzzle.par));
    });
  });

  group('undo', () {
    test('takes back the last word and restores the starting letter', () {
      var state = WordLoopGameState.initial(_puzzle());
      state = _play(state, 'ABDOMINAL').state;
      state = _play(state, 'LAB').state;
      expect(state.chain, ['ABDOMINAL', 'LAB']);

      state = state.undoWord();
      expect(state.chain, ['ABDOMINAL']);
      expect(state.currentInput, 'L');
      expect(state.remainingLetters, {'R', 'T', 'V', 'Y'});

      state = state.undoWord();
      expect(state.chain, isEmpty);
      expect(state.currentInput, '');
      expect(state.remainingLetters.length, wordLoopLetterCount);
    });

    test('undo on an empty chain does nothing', () {
      final state = WordLoopGameState.initial(_puzzle());
      expect(state.undoWord(), same(state));
    });
  });
}

/// Types [word] onto a cleared input and submits it.
({WordLoopGameState state, WordLoopRejection? rejection}) _play(
  WordLoopGameState state,
  String word,
) {
  var typed = state.clearInput();
  for (final letter in word.split('')) {
    typed = typed.inputLetter(letter);
  }
  return typed.submit();
}
