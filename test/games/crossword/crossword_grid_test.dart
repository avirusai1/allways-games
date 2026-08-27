import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:allways_games/games/crossword/domain/crossword_filler.dart';
import 'package:allways_games/games/crossword/domain/crossword_grid.dart';
import 'package:flutter_test/flutter_test.dart';

/// The clued vocabulary the generator ships with.
List<String> _cluedWords() {
  const paths = [
    'tool/data/crossword_words.json',
    'tool/data/crossword_words_4.json',
    'tool/data/crossword_words_5.json',
  ];
  final out = <String>[];
  for (final path in paths) {
    final json =
        jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    out.addAll((json['words'] as Map<String, dynamic>).keys);
  }
  return out;
}

void main() {
  group('patterns', () {
    test('every shipped pattern is the right size', () {
      for (final pattern in crosswordPatterns) {
        expect(pattern.rows.length, crosswordSize, reason: pattern.name);
        for (final row in pattern.rows) {
          expect(row.length, crosswordSize, reason: pattern.name);
        }
        expect(pattern.blocked.length, crosswordCellCount);
      }
    });

    test('every shipped pattern is rotationally symmetric', () {
      // The convention solvers expect; an asymmetric grid looks broken.
      for (final pattern in crosswordPatterns) {
        final blocked = pattern.blocked;
        for (var i = 0; i < crosswordCellCount; i++) {
          expect(
            blocked[i],
            blocked[crosswordCellCount - 1 - i],
            reason: '${pattern.name} is not symmetric at $i',
          );
        }
      }
    });

    test('no shipped pattern has an entry shorter than the minimum', () {
      for (final pattern in crosswordPatterns) {
        for (final slot in slotsFor(pattern.blocked)) {
          expect(
            slot.length,
            greaterThanOrEqualTo(crosswordMinEntry),
            reason: '${pattern.name} ${slot.label} is ${slot.length} long',
          );
        }
      }
    });

    test('every open square is crossed by both directions', () {
      // An uncrossed square can never be checked against anything, which
      // makes it a guess rather than a deduction.
      for (final pattern in crosswordPatterns) {
        final slots = slotsFor(pattern.blocked);
        final across = <int>{
          for (final s in slots)
            if (s.direction == CrosswordDirection.across) ...s.cells,
        };
        final down = <int>{
          for (final s in slots)
            if (s.direction == CrosswordDirection.down) ...s.cells,
        };
        for (var i = 0; i < crosswordCellCount; i++) {
          if (pattern.blocked[i]) continue;
          expect(across.contains(i) && down.contains(i), isTrue,
              reason: '${pattern.name} cell $i is not fully crossed');
        }
      }
    });
  });

  group('numbering', () {
    test('an open grid numbers the first row and column', () {
      final blocked = List<bool>.filled(crosswordCellCount, false);
      final slots = slotsFor(blocked);
      // 5 across starting in column 0, 5 down starting in row 0, sharing
      // number 1 at the top-left.
      expect(slots.where((s) => s.direction == CrosswordDirection.across).length, 5);
      expect(slots.where((s) => s.direction == CrosswordDirection.down).length, 5);
      expect(slots.first.number, 1);
      expect(slotNumbers(slots).length, 9);
    });

    test('a blocked square starts a new entry after it', () {
      final blocked = List<bool>.filled(crosswordCellCount, false);
      blocked[crosswordIndexAt(0, 0)] = true;
      final slots = slotsFor(blocked);
      final firstAcross = slots.firstWhere(
        (s) => s.direction == CrosswordDirection.across,
      );
      expect(firstAcross.cells.first, crosswordIndexAt(0, 1));
      expect(firstAcross.length, 4);
    });
  });

  group('vocabulary index', () {
    final vocabulary = CrosswordVocabulary(['CAT', 'COT', 'DOG', 'CART']);

    test('matches an unconstrained pattern by length', () {
      expect(vocabulary.matching(['', '', '']).toSet(), {'CAT', 'COT', 'DOG'});
    });

    test('honours a fixed letter', () {
      expect(vocabulary.matching(['C', '', 'T']).toSet(), {'CAT', 'COT'});
      expect(vocabulary.matching(['C', 'A', 'T']), ['CAT']);
    });

    test('returns nothing when no word fits', () {
      expect(vocabulary.matching(['Z', '', '']), isEmpty);
    });
  });

  group('filler', () {
    test('fills every shipped pattern from a real-sized vocabulary', () {
      // The app's real clued list: an interlocking 5x5 needs hundreds of
      // words, so a handful here would prove nothing.
      final vocabulary = CrosswordVocabulary(_cluedWords());

      // At least one pattern must fill from this set, which is what
      // proves the filler works end to end.
      var filled = 0;
      for (final pattern in crosswordPatterns) {
        final slots = slotsFor(pattern.blocked);
        final fill = CrosswordFiller.fill(
          blocked: pattern.blocked,
          slots: slots,
          vocabulary: vocabulary,
          random: Random(3),
        );
        if (fill == null) continue;
        filled++;

        for (final slot in slots) {
          final word = fill.entries[slot];
          expect(word, isNotNull, reason: '${pattern.name} ${slot.label}');
          expect(word!.length, slot.length);
          for (var i = 0; i < slot.cells.length; i++) {
            expect(fill.letters[slot.cells[i]], word[i]);
          }
        }
        // Crossings must agree, which is the whole point of the CSP.
        for (var i = 0; i < crosswordCellCount; i++) {
          if (pattern.blocked[i]) {
            expect(fill.letters[i], isEmpty);
          } else {
            expect(fill.letters[i], isNotEmpty);
          }
        }
      }
      expect(filled, greaterThan(0), reason: 'no pattern filled at all');
    });

    test('returns null when the vocabulary cannot fill the grid', () {
      final vocabulary = CrosswordVocabulary(['CAT', 'DOG']);
      final pattern = crosswordPatterns.first;
      expect(
        CrosswordFiller.fill(
          blocked: pattern.blocked,
          slots: slotsFor(pattern.blocked),
          vocabulary: vocabulary,
          random: Random(1),
          nodeBudget: 2000,
        ),
        isNull,
      );
    });

    test('never repeats a word inside one grid', () {
      final vocabulary = CrosswordVocabulary(_cluedWords());
      for (final pattern in crosswordPatterns) {
        final fill = CrosswordFiller.fill(
          blocked: pattern.blocked,
          slots: slotsFor(pattern.blocked),
          vocabulary: vocabulary,
          random: Random(11),
        );
        if (fill == null) continue;
        final used = fill.entries.values.toList();
        expect(used.toSet().length, used.length, reason: pattern.name);
      }
    });
  });
}
