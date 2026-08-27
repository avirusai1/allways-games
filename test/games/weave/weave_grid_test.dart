import 'dart:math';

import 'package:allways_games/games/weave/domain/weave_grid.dart';
import 'package:allways_games/games/weave/domain/weave_packer.dart';
import 'package:allways_games/games/weave/domain/weave_scanner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('geometry', () {
    test('index maps to row and column', () {
      expect(weaveRowOf(0), 0);
      expect(weaveColOf(0), 0);
      expect(weaveIndexAt(3, 4), 3 * weaveCols + 4);
      expect(weaveRowOf(weaveIndexAt(3, 4)), 3);
      expect(weaveColOf(weaveIndexAt(3, 4)), 4);
    });

    test('a corner has three neighbours, an interior cell has eight', () {
      expect(weaveAdjacency[0].length, 3);
      expect(weaveAdjacency[weaveIndexAt(3, 3)].length, 8);
    });

    test('neighbours are symmetric', () {
      for (var i = 0; i < weaveCellCount; i++) {
        for (final n in weaveAdjacency[i]) {
          expect(weaveAdjacency[n], contains(i));
        }
      }
    });
  });

  group('path rules', () {
    test('a stepwise adjacent path is connected', () {
      final path = [
        weaveIndexAt(0, 0),
        weaveIndexAt(1, 1), // diagonal steps are legal
        weaveIndexAt(2, 1),
      ];
      expect(isWeavePathConnected(path), isTrue);
    });

    test('a jump is rejected', () {
      expect(
        isWeavePathConnected([weaveIndexAt(0, 0), weaveIndexAt(3, 3)]),
        isFalse,
      );
    });

    test('reusing a cell is rejected', () {
      expect(
        isWeavePathConnected([
          weaveIndexAt(0, 0),
          weaveIndexAt(0, 1),
          weaveIndexAt(0, 0),
        ]),
        isFalse,
      );
    });

    test('spansGrid needs both edge rows', () {
      final down = [
        for (var row = 0; row < weaveRows; row++) weaveIndexAt(row, 2),
      ];
      expect(spansGrid(down), isTrue);
      expect(spansGrid(down.sublist(0, weaveRows - 1)), isFalse);
    });
  });

  group('word-set selection', () {
    test('chosen lengths sum to exactly the grid', () {
      final words = WeavePacker.chooseWordSet(
        const [
          'LIGHTHOUSE', 'BREAKWATER', 'TRAWLER', 'MOORING', 'ANCHOR',
          'JETTY', 'WHARF', 'BUOY', 'QUAY', 'MAST', 'CARGO', 'TIDE',
          'DOCK', 'CRANE', 'PONTOON',
        ],
        Random(1),
      );
      expect(words, isNotNull);
      expect(
        words!.fold<int>(0, (n, w) => n + w.length),
        weaveCellCount,
      );
      expect(words.any((w) => w.length >= weaveRows), isTrue);
    });

    test('a theme with no long word cannot span the grid', () {
      final words = WeavePacker.chooseWordSet(
        const ['CAT', 'DOG', 'BIRD', 'FISH', 'MOLE', 'DEER'],
        Random(1),
      );
      expect(words, isNull);
    });
  });

  group('packing', () {
    test('a successful packing tiles every cell exactly once', () {
      final rng = Random(7);
      // Retry: a single packing attempt failing is a normal outcome.
      for (var attempt = 0; attempt < 40; attempt++) {
        final words = WeavePacker.chooseWordSet(
          const [
            'LIGHTHOUSE', 'BREAKWATER', 'TRAWLER', 'MOORING', 'ANCHOR',
            'JETTY', 'WHARF', 'BUOY', 'QUAY', 'MAST', 'CARGO', 'TIDE',
            'DOCK', 'CRANE', 'PONTOON',
          ],
          rng,
        );
        if (words == null) continue;
        final packing = WeavePacker.pack(words, rng);
        if (packing == null) continue;

        final covered = <int>{};
        for (final placement in packing.placements) {
          expect(isWeavePathConnected(placement.path), isTrue);
          expect(placement.path.length, placement.word.length);
          for (final cell in placement.path) {
            expect(covered.add(cell), isTrue, reason: 'cell $cell reused');
          }
        }
        expect(covered.length, weaveCellCount);

        // Letters must agree with the placements that produced them.
        final letters = packing.letters;
        expect(letters.where((l) => l.isEmpty), isEmpty);
        for (final placement in packing.placements) {
          for (var i = 0; i < placement.path.length; i++) {
            expect(letters[placement.path[i]], placement.word[i]);
          }
        }

        // The declared spanner really does reach both edge rows.
        final spannerPath = packing.placements
            .firstWhere((p) => p.word == packing.spanner)
            .path;
        expect(spansGrid(spannerPath), isTrue);
        return;
      }
      fail('no packing found in 40 attempts');
    });
  });

  group('scanner', () {
    test('traces a word that is present and refuses one that is not', () {
      final letters = List<String>.filled(weaveCellCount, 'X');
      letters[weaveIndexAt(0, 0)] = 'C';
      letters[weaveIndexAt(0, 1)] = 'A';
      letters[weaveIndexAt(0, 2)] = 'T';

      final path = WeaveScanner.trace(letters, 'CAT');
      expect(path, isNotNull);
      expect(isWeavePathConnected(path!), isTrue);
      expect(WeaveScanner.trace(letters, 'DOG'), isNull);
    });

    test('findAll reports a word the grid contains', () {
      final letters = List<String>.filled(weaveCellCount, 'Q');
      letters[weaveIndexAt(0, 0)] = 'W';
      letters[weaveIndexAt(0, 1)] = 'O';
      letters[weaveIndexAt(0, 2)] = 'R';
      letters[weaveIndexAt(0, 3)] = 'D';

      final trie = WeaveScanner.buildTrie(['WORD'], minLength: 4);
      expect(WeaveScanner.findAll(letters, trie), contains('WORD'));
    });
  });
}
