import 'dart:convert';
import 'dart:io';

import 'package:allways_games/games/honeycomb/domain/honeycomb_puzzle.dart';
import 'package:allways_games/games/honeycomb/domain/honeycomb_scoring.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the committed asset, not just the generator that wrote it.
void main() {
  late List<HoneycombPuzzle> puzzles;

  setUpAll(() {
    final file = File('assets/content/honeycomb/bank.json');
    expect(file.existsSync(), isTrue,
        reason: 'run `dart run tool/gen_honeycomb_bank.dart`');
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(json['game'], 'honeycomb');
    expect(json['schemaVersion'], 1);
    puzzles = (json['puzzles'] as List)
        .map((p) => HoneycombPuzzle.fromJson(p as Map<String, dynamic>))
        .toList();
  });

  test('ships enough combs that they do not repeat within a year', () {
    expect(puzzles.length, greaterThanOrEqualTo(365));
  });

  test('every comb has seven distinct letters', () {
    for (var i = 0; i < puzzles.length; i++) {
      final puzzle = puzzles[i];
      expect(puzzle.allLetters, hasLength(honeycombLetterCount), reason: '$i');
      expect(puzzle.letterSet, hasLength(honeycombLetterCount), reason: '$i');
      expect(puzzle.outerLetters, isNot(contains(puzzle.requiredLetter)),
          reason: 'comb $i repeats its centre letter on the ring');
      expect(RegExp(r'^[A-Z]$').hasMatch(puzzle.requiredLetter), isTrue,
          reason: '$i');
    }
  });

  test('every answer is one the app would accept', () {
    // The single most important property of this bank: an answer the game
    // itself would reject is an answer no player can ever find, and it
    // puts the top rank permanently out of reach.
    for (var i = 0; i < puzzles.length; i++) {
      final puzzle = puzzles[i];
      for (final word in puzzle.answers) {
        expect(word.length, greaterThanOrEqualTo(honeycombMinWordLength),
            reason: 'comb $i: "$word" is too short');
        expect(word.contains(puzzle.requiredLetter), isTrue,
            reason: 'comb $i: "$word" is missing '
                '${puzzle.requiredLetter}');
        for (final letter in word.split('')) {
          expect(puzzle.letterSet, contains(letter),
              reason: 'comb $i: "$word" uses $letter, which is off the comb');
        }
        expect(RegExp(r'^[A-Z]+$').hasMatch(word), isTrue, reason: '$i: $word');
      }
    }
  });

  test('every comb has at least one pangram, and not too many', () {
    for (var i = 0; i < puzzles.length; i++) {
      expect(puzzles[i].pangrams, isNotEmpty, reason: 'comb $i has no pangram');
      expect(puzzles[i].pangrams.length, lessThanOrEqualTo(4), reason: '$i');
    }
  });

  test('a pangram really does use all seven letters', () {
    for (var i = 0; i < puzzles.length; i++) {
      for (final pangram in puzzles[i].pangrams) {
        expect(pangram.split('').toSet(), puzzles[i].letterSet, reason: '$i');
      }
    }
  });

  test('answer counts sit in the window that makes a comb playable', () {
    for (var i = 0; i < puzzles.length; i++) {
      expect(puzzles[i].answers.length, inInclusiveRange(20, 45),
          reason: 'comb $i has ${puzzles[i].answers.length} answers');
    }
  });

  test('every comb is worth a sensible number of points', () {
    for (var i = 0; i < puzzles.length; i++) {
      final maxScore = puzzles[i].maxScore;
      expect(maxScore, greaterThan(0), reason: 'comb $i scores nothing');
      // Every rank must be reachable, which means distinct thresholds.
      final thresholds = honeycombRanks
          .map((r) => honeycombScoreForRank(r, maxScore))
          .toList();
      expect(thresholds.last, maxScore, reason: 'comb $i');
      for (var r = 1; r < thresholds.length; r++) {
        expect(thresholds[r], greaterThanOrEqualTo(thresholds[r - 1]),
            reason: 'comb $i rank thresholds must not go backwards');
      }
    }
  });

  test('no two combs use the same seven letters', () {
    final seen = <String>{};
    for (var i = 0; i < puzzles.length; i++) {
      final key = (puzzles[i].allLetters.toList()..sort()).join();
      expect(seen.add(key), isTrue, reason: 'comb $i repeats letter set $key');
    }
  });

  test('no two consecutive combs share a centre letter', () {
    // Not a correctness property, but players navigate a comb by its middle
    // cell, so two days running with the same one reads as the app having
    // failed to refresh.
    for (var i = 1; i < puzzles.length; i++) {
      expect(puzzles[i].requiredLetter, isNot(puzzles[i - 1].requiredLetter),
          reason: 'combs ${i - 1} and $i share a centre letter');
    }
  });

  test('answers are stored deduplicated', () {
    for (var i = 0; i < puzzles.length; i++) {
      expect(puzzles[i].answers.length, greaterThan(0), reason: '$i');
      // The model stores answers in a Set, so a duplicated entry in the
      // file would silently shrink the count the generator verified.
      expect(puzzles[i].answers.toSet().length, puzzles[i].answers.length);
    }
  });
}
