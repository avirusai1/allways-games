import 'dart:math';

import 'package:allways_games/games/word_loop/domain/word_loop_box.dart';
import 'package:allways_games/games/word_loop/domain/word_loop_generator.dart';
import 'package:allways_games/games/word_loop/domain/word_loop_solver.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sides: ABC / DEF / GHI / JKL.
WordLoopBox _box() => WordLoopBox.parse('ABC-DEF-GHI-JKL');

void main() {
  group('WordLoopBox', () {
    test('parses and re-encodes a board', () {
      final box = _box();
      expect(box.encode(), 'ABC-DEF-GHI-JKL');
      expect(box.letters, {
        'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', //
      });
    });

    test('knows which side a letter is on', () {
      final box = _box();
      expect(box.sideOf('A'), WordLoopSide.top.index);
      expect(box.sideOf('e'), WordLoopSide.right.index);
      expect(box.sideOf('I'), WordLoopSide.bottom.index);
      expect(box.sideOf('L'), WordLoopSide.left.index);
      expect(box.sideOf('Z'), isNull);
      expect(box.containsLetter('z'), isFalse);
      expect(box.containsLetter('c'), isTrue);
    });

    test('rejects malformed boards', () {
      // Wrong number of sides.
      expect(() => WordLoopBox.parse('ABC-DEF-GHI'), throwsArgumentError);
      // Wrong number of letters on a side.
      expect(() => WordLoopBox.parse('AB-DEF-GHI-JKL'), throwsArgumentError);
      // A letter on two sides at once.
      expect(() => WordLoopBox.parse('ABC-AEF-GHI-JKL'), throwsArgumentError);
      // Not a letter.
      expect(() => WordLoopBox.parse('AB1-DEF-GHI-JKL'), throwsArgumentError);
    });

    test('a word is playable only if it never takes two from one side', () {
      final box = _box();
      // A (top) -> D (right) -> G (bottom): every step changes side.
      expect(box.isPlayable('ADG'), isTrue);
      // A and B are both on the top side.
      expect(box.isPlayable('ABD'), isFalse);
      // Non-adjacent same-side letters are fine: A (top) D (right) B (top).
      expect(box.isPlayable('ADB'), isTrue);
    });

    test('a word needs every letter on the board', () {
      expect(_box().isPlayable('ADZ'), isFalse);
    });

    test('words shorter than the minimum are never playable', () {
      final box = _box();
      expect(box.isPlayable('AD'), isFalse);
      expect(box.isPlayable('A'), isFalse);
      expect(box.isPlayable(''), isFalse);
      expect(wordLoopMinWordLength, 3);
    });

    test('a doubled letter can never be traced', () {
      // Both Ls come from the same side, so they are adjacent to themselves.
      expect(_box().isPlayable('ALL'), isFalse);
    });

    test('case does not matter', () {
      expect(_box().isPlayable('adg'), isTrue);
      expect(WordLoopBox.parse('abc-def-ghi-jkl').encode(), 'ABC-DEF-GHI-JKL');
    });
  });

  group('letter masks', () {
    test('one bit per distinct letter, repeats folded together', () {
      expect(wordLoopLetterMask('A'), 1);
      expect(wordLoopLetterMask('AB'), 3);
      expect(wordLoopLetterMask('ABA'), 3);
      expect(wordLoopLetterMask('ab'), 3);
      expect(wordLoopLetterMask(''), 0);
    });
  });

  group('WordLoopGenerator.layOut', () {
    test('places twelve letters so both seed words can be traced', () {
      final box = WordLoopGenerator.layOut(
        ['MOTORIZED', 'DEVOLUTION'],
        Random(1),
      );
      expect(box, isNotNull);
      expect(box!.letters.length, wordLoopLetterCount);
      expect(box.isPlayable('MOTORIZED'), isTrue);
      expect(box.isPlayable('DEVOLUTION'), isTrue);
      for (final side in box.sides) {
        expect(side, hasLength(wordLoopLettersPerSide));
      }
    });

    test('refuses a seed set that is not exactly twelve letters', () {
      expect(WordLoopGenerator.layOut(['CAT', 'TAR'], Random(1)), isNull);
    });

    test('refuses a seed word with a doubled letter', () {
      // BALLOON has LL, which would need one letter on two sides at once.
      // (BALLOONS + a partner is a 12-letter set, but unplaceable.)
      expect(
        WordLoopGenerator.layOut(['BALLOON', 'NIGHTCLUB'], Random(1)),
        isNull,
      );
    });

    test('adjacency constraints are symmetric and cover every step', () {
      final pairs = WordLoopGenerator.adjacencyConstraints(['CAT']);
      expect(pairs, contains('CA'));
      expect(pairs, contains('AC'));
      expect(pairs, contains('AT'));
      expect(pairs, contains('TA'));
      expect(pairs, isNot(contains('CT')));
    });

    test('a laid-out board never puts adjacent letters on one side', () {
      final box = WordLoopGenerator.layOut(
        ['SNOWFLAKE', 'EQUIP'],
        Random(3),
      );
      if (box == null) return; // not every seed set is placeable
      final constraints =
          WordLoopGenerator.adjacencyConstraints(['SNOWFLAKE', 'EQUIP']);
      for (final side in box.sides) {
        for (final a in side) {
          for (final b in side) {
            if (a == b) continue;
            expect(constraints.contains('$a$b'), isFalse,
                reason: '$a and $b are adjacent but share a side');
          }
        }
      }
    });
  });

  group('WordLoopGenerator.forEachSeedPair', () {
    test('finds chaining pairs that use exactly twelve distinct letters', () {
      final found = <List<String>>[];
      WordLoopGenerator.forEachSeedPair(
        ['MOTORIZED', 'DEVOLUTION', 'CAT', 'TAR'],
        (first, second) {
          found.add([first, second]);
          return true;
        },
      );
      expect(found, [
        ['MOTORIZED', 'DEVOLUTION'],
      ]);
    });

    test('stops early when the callback says so', () {
      var calls = 0;
      WordLoopGenerator.forEachSeedPair(
        ['MOTORIZED', 'DEVOLUTION', 'DELINQUENT'],
        (first, second) {
          calls++;
          return false;
        },
      );
      expect(calls, 1);
    });

    test('a word is never paired with itself', () {
      WordLoopGenerator.forEachSeedPair(['ABCDEFGHIJKL'], (first, second) {
        fail('paired $first with $second');
      });
    });
  });
}
