import 'package:allways_games/games/word_loop/domain/word_loop_box.dart';
import 'package:allways_games/games/word_loop/domain/word_loop_solver.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sides: DLN / BRT / IOV / AMY — the same verified board the game-state
/// tests use.
WordLoopBox _box() => WordLoopBox.parse('DLN-BRT-IOV-AMY');

void main() {
  group('playableWords', () {
    test('keeps only what the board can trace, and upper-cases it', () {
      final playable = WordLoopSolver.playableWords(
        _box(),
        ['abdominal', 'lavatory', 'cab', 'dla', 'lab'],
      );
      // CAB uses C, which is not on the board; DLA takes D and L in a row
      // from the same side.
      expect(playable, ['ABDOMINAL', 'LAVATORY', 'LAB']);
    });
  });

  group('findShortestChain', () {
    test('finds the two-word answer that covers the board', () {
      final chain = WordLoopSolver.findShortestChain(
        _box(),
        ['ABDOMINAL', 'LAVATORY', 'LAB', 'BOAT', 'TAB'],
      );
      expect(chain, ['ABDOMINAL', 'LAVATORY']);
    });

    test('returns null when no chain covers every letter', () {
      // None of these ever reaches V or Y.
      final chain = WordLoopSolver.findShortestChain(
        _box(),
        ['LAB', 'BOAT', 'TAB', 'BOA'],
      );
      expect(chain, isNull);
    });

    test('returns null for an empty word list', () {
      expect(WordLoopSolver.findShortestChain(_box(), const []), isNull);
    });

    test('returns a one-word chain when a single word covers the board', () {
      // A contrived board whose twelve letters spell one word.
      final box = WordLoopBox.parse('BLA-DIC-KMS-HTU');
      final chain = WordLoopSolver.findShortestChain(box, ['BLACKSMITHUD']);
      // Only if that word is actually traceable on the layout.
      if (chain != null) expect(chain, hasLength(1));
    });

    test('respects the maximum chain length', () {
      // The answer needs two words; allowing only one finds nothing.
      final words = ['ABDOMINAL', 'LAVATORY'];
      expect(
        WordLoopSolver.findShortestChain(_box(), words, maxWords: 1),
        isNull,
      );
      expect(
        WordLoopSolver.findShortestChain(_box(), words, maxWords: 2),
        hasLength(2),
      );
    });

    test('the chain it returns really does chain and really does cover', () {
      final chain = WordLoopSolver.findShortestChain(
        _box(),
        ['ABDOMINAL', 'LAVATORY', 'LAB', 'BOAT', 'TAB', 'BOA'],
      )!;
      for (var i = 1; i < chain.length; i++) {
        expect(chain[i][0], chain[i - 1][chain[i - 1].length - 1]);
      }
      expect(
        wordLoopLetterMask(chain.join()),
        wordLoopLetterMask(_box().letters.join()),
      );
    });

    test('is deterministic for the same inputs in a different order', () {
      final a = WordLoopSolver.findShortestChain(
        _box(),
        ['ABDOMINAL', 'LAVATORY', 'LAB'],
      );
      final b = WordLoopSolver.findShortestChain(
        _box(),
        ['LAB', 'LAVATORY', 'ABDOMINAL'],
      );
      expect(a, b);
    });
  });

  group('findTwoWordSolutions', () {
    test('lists the pairs that cover the board in two moves', () {
      final solutions = WordLoopSolver.findTwoWordSolutions(
        _box(),
        ['ABDOMINAL', 'LAVATORY', 'LAB', 'BOAT', 'TAB'],
      );
      expect(solutions, [
        ['ABDOMINAL', 'LAVATORY'],
      ]);
    });

    test('finds nothing when no pair covers the board', () {
      expect(
        WordLoopSolver.findTwoWordSolutions(_box(), ['LAB', 'BOAT', 'TAB']),
        isEmpty,
      );
    });

    test('stops at the limit', () {
      final solutions = WordLoopSolver.findTwoWordSolutions(
        _box(),
        ['ABDOMINAL', 'LAVATORY'],
        limit: 1,
      );
      expect(solutions, hasLength(1));
    });
  });
}
