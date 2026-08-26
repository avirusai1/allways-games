// Offline content generator for the "Honeycomb" game.
//
// Produces assets/content/honeycomb/bank.json: one board per calendar day,
// each with seven letters (one of them required in every answer) and the
// complete list of words those letters can make. Run with:
//   dart run tool/gen_honeycomb_bank.dart [--days=730]
//
// Sources (both public domain / freely redistributable, never anyone
// else's puzzle content):
//   - tool/data/enable1.txt   : ENABLE1 word list
//   - tool/data/count_1w.txt  : Peter Norvig's word-frequency list, used
//     to drop dictionary entries so obscure that nobody could be expected
//     to find them. On a "find every word" board an unfindable answer is
//     worse than no answer: it puts the top rank out of reach.
//
// Boards are built from pangram candidates: any word with exactly seven
// distinct letters defines a letter set that is guaranteed to have at
// least one pangram. Each of the seven letters is then tried as the
// required letter, and the resulting board is kept only if its answer
// count lands in the window that makes the board fun.
//
// Every board is verified before the file is written:
//   * every answer is long enough, uses only board letters, and contains
//     the required letter
//   * the board has at least one pangram
//   * the answer count sits inside the published window
// A failure aborts the run rather than shipping a bad bank.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:allways_games/games/honeycomb/domain/honeycomb_puzzle.dart';
import 'package:allways_games/games/honeycomb/domain/honeycomb_scoring.dart';

const int defaultDayCount = 730;
const int baseSeed = 20240101;

/// How many of the most common words count as findable.
///
/// ENABLE1 has 170k entries, a large share of which no ordinary player
/// would ever produce. Ranking by real-world frequency and keeping the top
/// slice is what stops the answer list filling with words that make the
/// top rank unreachable.
const int answerVocabularySize = 60000;

/// How many of the most common words may headline a board as its pangram.
///
/// The pangram is the board's hook — the word a player hunts for and the
/// one revealed at the end — so it has to be a word people actually know.
/// Drawing letter sets from the full answer vocabulary produced boards
/// headlined by LIMBECK and ROCKAWAY, which is not a hook.
const int pangramVocabularySize = 20000;

/// Answers a board may have.
///
/// Too few and the board is over in two minutes; too many and it becomes a
/// grind nobody finishes.
const int minAnswers = 20;
const int maxAnswers = 45;

/// A board needs a real hook, and a lone pangram nobody spots is not one.
/// Two or three give players a fair shot at the bonus.
const int maxPangrams = 4;

void main(List<String> args) {
  var dayCount = defaultDayCount;
  for (final arg in args) {
    if (arg.startsWith('--days=')) {
      dayCount = int.parse(arg.substring('--days='.length));
    }
  }

  final stopwatch = Stopwatch()..start();
  final vocabulary = _loadVocabulary();
  stdout.writeln(
    '${vocabulary.length} findable words, '
    '${vocabulary.take(pangramVocabularySize).where((w) => _distinctLetters(w).length == honeycombLetterCount).length} '
    'common pangram candidates.',
  );

  // Group words by their letter set: every board with that set has exactly
  // this candidate pool, so the expensive grouping happens once rather
  // than once per board.
  final byLetterSet = <String, List<String>>{};
  for (final word in vocabulary) {
    final letters = _distinctLetters(word);
    if (letters.length > honeycombLetterCount) continue;
    byLetterSet.putIfAbsent(_key(letters), () => []).add(word);
  }

  // Letter sets come from common seven-distinct-letter words only, so
  // every board is guaranteed a pangram a player might actually reach for.
  final headlineWords = vocabulary.take(pangramVocabularySize).toSet();
  final pangramSets = <String>{
    for (final word in headlineWords)
      if (_distinctLetters(word).length == honeycombLetterCount)
        _key(_distinctLetters(word)),
  };

  final boards = <HoneycombPuzzle>[];
  final usedLetterSets = <String>{};
  var considered = 0;

  final orderedSets = pangramSets.toList()..sort();
  // Shuffled under a fixed seed: taking them in alphabetical order would
  // make every early board start with A-heavy letter sets.
  orderedSets.shuffle(Random(baseSeed));

  for (final setKey in orderedSets) {
    if (boards.length >= dayCount) break;
    if (!usedLetterSets.add(setKey)) continue;

    final letters = setKey.split('');
    final pool = _wordsForLetterSet(letters, byLetterSet);
    considered++;

    // Each of the seven letters gives a different board from one letter
    // set; take at most one so the bank never shows near-identical combs
    // on consecutive days.
    final requiredOrder = List<String>.of(letters)..shuffle(Random(baseSeed + considered));
    for (final required in requiredOrder) {
      // Never repeat yesterday's centre letter. Players navigate a comb by
      // its middle cell, so two days running with the same one reads as the
      // app having failed to refresh.
      if (boards.isNotEmpty && boards.last.requiredLetter == required) continue;

      final answers = pool.where((w) => w.contains(required)).toList();
      if (answers.length < minAnswers || answers.length > maxAnswers) continue;

      final puzzle = HoneycombPuzzle(
        requiredLetter: required,
        outerLetters: letters.where((l) => l != required).toList(),
        answers: answers,
      );
      if (puzzle.pangrams.isEmpty) continue;
      if (puzzle.pangrams.length > maxPangrams) continue;
      // The board must have at least one pangram from the common slice,
      // not merely some obscure entry that happens to use all seven.
      if (!puzzle.pangrams.any(headlineWords.contains)) continue;

      _verify(boards.length, puzzle);
      boards.add(puzzle);
      break;
    }

    if (boards.length % 100 == 0 && boards.isNotEmpty) {
      stdout.writeln(
        '${boards.length}/$dayCount boards '
        '(${stopwatch.elapsed.inSeconds}s elapsed)',
      );
    }
  }

  if (boards.length < dayCount) {
    stderr.writeln(
      'Only built ${boards.length} boards from $considered letter sets. '
      'Widen the answer-count window or the vocabulary.',
    );
    exit(1);
  }

  final bank = {
    'schemaVersion': 1,
    'game': 'honeycomb',
    'generatedAt': '2024-01-01T00:00:00Z',
    'puzzles': boards.map((p) => p.toJson()).toList(),
  };

  final outDir = Directory('assets/content/honeycomb');
  outDir.createSync(recursive: true);
  final outFile = File('${outDir.path}/bank.json');
  outFile.writeAsStringSync(jsonEncode(bank));

  final answerCounts = boards.map((p) => p.answers.length).toList()..sort();
  final scores = boards.map((p) => p.maxScore).toList()..sort();
  stdout.writeln(
    'Wrote ${outFile.path}: ${boards.length} verified boards '
    'in ${stopwatch.elapsed.inSeconds}s.',
  );
  stdout.writeln(
    '  answers per board: min=${answerCounts.first} '
    'median=${answerCounts[answerCounts.length ~/ 2]} max=${answerCounts.last}',
  );
  stdout.writeln(
    '  max score: min=${scores.first} '
    'median=${scores[scores.length ~/ 2]} max=${scores.last}',
  );
  stdout.writeln(
    '  file size: ${(outFile.lengthSync() / 1024).toStringAsFixed(0)} KiB',
  );
}

/// Every vocabulary word whose letters are a subset of [letters].
///
/// Enumerates the subsets of the seven-letter set (127 of them) and looks
/// each up, which is far cheaper than scanning the whole vocabulary per
/// board.
List<String> _wordsForLetterSet(
  List<String> letters,
  Map<String, List<String>> byLetterSet,
) {
  final words = <String>[];
  for (var mask = 1; mask < 1 << honeycombLetterCount; mask++) {
    final subset = <String>[];
    for (var i = 0; i < honeycombLetterCount; i++) {
      if (mask & (1 << i) != 0) subset.add(letters[i]);
    }
    final bucket = byLetterSet[_key(subset.toSet())];
    if (bucket != null) words.addAll(bucket);
  }
  return words;
}

/// Aborts the run unless [puzzle] is sound.
void _verify(int slot, HoneycombPuzzle puzzle) {
  void fail(String reason) {
    stderr.writeln(
      'Board $slot (${puzzle.requiredLetter}|${puzzle.outerLetters.join()}): '
      '$reason',
    );
    exit(1);
  }

  if (puzzle.allLetters.toSet().length != honeycombLetterCount) {
    fail('does not carry $honeycombLetterCount distinct letters');
  }
  if (puzzle.answers.length < minAnswers || puzzle.answers.length > maxAnswers) {
    fail('has ${puzzle.answers.length} answers, outside $minAnswers-$maxAnswers');
  }
  if (puzzle.pangrams.isEmpty) fail('has no pangram');

  for (final word in puzzle.answers) {
    if (word.length < honeycombMinWordLength) {
      fail('answer "$word" is too short');
    }
    if (!word.contains(puzzle.requiredLetter)) {
      fail('answer "$word" is missing the required letter');
    }
    for (final letter in word.split('')) {
      if (!puzzle.letterSet.contains(letter)) {
        fail('answer "$word" uses $letter, which is not on the board');
      }
    }
  }

  if (puzzle.maxScore <= 0) fail('scores zero for a perfect board');
}

/// ENABLE1 narrowed to words a player could plausibly produce.
List<String> _loadVocabulary() {
  final enable1 = File('tool/data/enable1.txt');
  final frequencies = File('tool/data/count_1w.txt');
  if (!enable1.existsSync() || !frequencies.existsSync()) {
    stderr.writeln('Missing tool/data/enable1.txt or tool/data/count_1w.txt');
    exit(1);
  }

  final wordPattern = RegExp(r'^[a-z]+$');
  final known = <String>{};
  for (final line in enable1.readAsLinesSync()) {
    final word = line.trim().toLowerCase();
    if (word.length < honeycombMinWordLength) continue;
    if (!wordPattern.hasMatch(word)) continue;
    if (_distinctLetters(word.toUpperCase()).length > honeycombLetterCount) {
      continue;
    }
    known.add(word.toUpperCase());
  }

  final vocabulary = <String>[];
  for (final line in frequencies.readAsLinesSync()) {
    final parts = line.split('\t');
    if (parts.length != 2) continue;
    final word = parts[0].trim().toUpperCase();
    if (!known.contains(word)) continue;
    vocabulary.add(word);
    if (vocabulary.length >= answerVocabularySize) break;
  }
  return vocabulary..sort();
}

Set<String> _distinctLetters(String word) => word.split('').toSet();

/// Canonical key for a letter set: its letters, sorted.
String _key(Set<String> letters) => (letters.toList()..sort()).join();
