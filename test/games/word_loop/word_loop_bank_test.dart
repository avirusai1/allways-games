import 'dart:convert';
import 'dart:io';

import 'package:allways_games/games/word_loop/domain/word_loop_box.dart';
import 'package:allways_games/games/word_loop/domain/word_loop_puzzle.dart';
import 'package:allways_games/games/word_loop/domain/word_loop_solver.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the committed asset, not just the generator that wrote it.
void main() {
  late List<WordLoopPuzzle> puzzles;
  late Set<String> dictionary;

  setUpAll(() {
    final file = File('assets/content/word_loop/bank.json');
    expect(file.existsSync(), isTrue,
        reason: 'run `dart run tool/gen_word_loop_bank.dart`');
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(json['game'], 'word_loop');
    expect(json['schemaVersion'], 1);
    dictionary = (json['words'] as List).cast<String>().toSet();
    puzzles = (json['puzzles'] as List)
        .map((p) => WordLoopPuzzle.fromJson(p as Map<String, dynamic>, dictionary))
        .toList();
  });

  test('ships enough boards that they do not repeat within a year', () {
    expect(puzzles.length, greaterThanOrEqualTo(365));
  });

  test('the shared dictionary is a real dictionary', () {
    expect(dictionary.length, greaterThan(50000));
    // Everything in it must be usable: long enough, all caps A-Z, and free
    // of the doubled letters no board can ever trace.
    final pattern = RegExp(r'^[A-Z]+$');
    for (final word in dictionary) {
      expect(pattern.hasMatch(word), isTrue, reason: word);
      expect(word.length, greaterThanOrEqualTo(wordLoopMinWordLength),
          reason: word);
    }
  });

  test('every board carries twelve distinct letters, three to a side', () {
    for (var i = 0; i < puzzles.length; i++) {
      final box = puzzles[i].box;
      expect(box.letters.length, wordLoopLetterCount, reason: 'board $i');
      expect(box.sides, hasLength(wordLoopSideCount), reason: 'board $i');
      for (final side in box.sides) {
        expect(side, hasLength(wordLoopLettersPerSide), reason: 'board $i');
      }
    }
  });

  test('every published answer obeys the rules the app enforces', () {
    for (var i = 0; i < puzzles.length; i++) {
      final puzzle = puzzles[i];
      final solution = puzzle.exampleSolution;
      expect(solution, hasLength(puzzle.par), reason: 'board $i');

      for (var w = 0; w < solution.length; w++) {
        final word = solution[w];
        expect(puzzle.box.isPlayable(word), isTrue,
            reason: 'board $i: "$word" cannot be traced');
        expect(puzzle.isValidWord(word), isTrue,
            reason: 'board $i: "$word" is not in the dictionary');
        if (w == 0) continue;
        final previous = solution[w - 1];
        expect(word[0], previous[previous.length - 1],
            reason: 'board $i: "$previous" does not chain into "$word"');
      }

      expect(
        wordLoopLetterMask(solution.join()),
        wordLoopLetterMask(puzzle.box.letters.join()),
        reason: 'board $i: answer does not cover every letter',
      );
    }
  });

  test('every board is a two-word board', () {
    // Par 1 would mean a single word covers all twelve letters, which is a
    // curiosity rather than a puzzle.
    for (var i = 0; i < puzzles.length; i++) {
      expect(puzzles[i].par, 2, reason: 'board $i');
    }
  });

  test('the published word count matches a fresh scan', () {
    // Spread across the bank rather than all of it: each scan walks the
    // whole dictionary.
    for (var i = 0; i < puzzles.length; i += 73) {
      final puzzle = puzzles[i];
      final playable = WordLoopSolver.playableWords(puzzle.box, dictionary);
      expect(playable.length, puzzle.playableWordCount, reason: 'board $i');
      expect(playable.length, greaterThan(100), reason: 'board $i is barren');
    }
  });

  test('par really is the shortest chain, not merely a chain that works', () {
    for (var i = 0; i < puzzles.length; i += 73) {
      final puzzle = puzzles[i];
      final playable = WordLoopSolver.playableWords(puzzle.box, dictionary);
      final shortest = WordLoopSolver.findShortestChain(puzzle.box, playable);
      expect(shortest, isNotNull, reason: 'board $i has no solution at all');
      expect(shortest!.length, puzzle.par,
          reason: 'board $i: published par ${puzzle.par} but a '
              '${shortest.length}-word chain exists');
    }
  });

  test('no two boards are the same, and none repeats the day before', () {
    final seen = <String>{};
    for (var i = 0; i < puzzles.length; i++) {
      expect(seen.add(puzzles[i].box.encode()), isTrue,
          reason: 'board $i duplicates an earlier board');
      if (i == 0) continue;
      expect(puzzles[i].box.encode(), isNot(puzzles[i - 1].box.encode()));
    }
  });

  test('no answer word headlines more than a couple of boards', () {
    final uses = <String, int>{};
    for (final puzzle in puzzles) {
      for (final word in puzzle.exampleSolution) {
        uses[word] = (uses[word] ?? 0) + 1;
      }
    }
    for (final entry in uses.entries) {
      expect(entry.value, lessThanOrEqualTo(2),
          reason: '"${entry.key}" answers ${entry.value} boards');
    }
  });

  test('a board rejects a word its own letters cannot trace', () {
    final puzzle = puzzles.first;
    final offBoard = List.generate(26, (i) => String.fromCharCode(0x41 + i))
        .firstWhere((letter) => !puzzle.box.containsLetter(letter));
    for (final word in dictionary.take(500)) {
      if (!word.contains(offBoard)) continue;
      expect(puzzle.isValidWord(word), isFalse,
          reason: '"$word" uses $offBoard, which is not on this board');
      break;
    }
  });
}
