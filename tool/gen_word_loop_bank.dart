// Offline content generator for the "Word Loop" game.
//
// Produces assets/content/word_loop/bank.json: one shared dictionary plus
// one board per calendar day, each with its twelve letters split three to
// a side and the shortest chain that covers it. Run with:
//   dart run tool/gen_word_loop_bank.dart [--days=730]
//
// Sources (both public domain / freely redistributable, never anyone
// else's puzzle content):
//   - tool/data/enable1.txt   : ENABLE1 word list
//   - tool/data/count_1w.txt  : Peter Norvig's word-frequency list, used
//     only to rank ENABLE1 words by commonness so a board's intended
//     answer is words people actually know.
//
// Boards are built backwards from their answer: take two common words that
// chain (the second starts with the first's last letter) and between them
// use exactly twelve distinct letters, then colour those letters onto four
// sides so both words can be traced. Sampling twelve random letters and
// hoping for a good board throws away almost every draw.
//
// Every board is verified before the file is written:
//   * the intended answer is playable and really does cover all twelve
//   * a search confirms par is the true shortest chain, and that it is 2
//   * the playable-word count and the number of two-word answers both sit
//     in the window that makes a board fun rather than hopeless or trivial
// A failure aborts the run rather than shipping a bad bank.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:allways_games/games/word_loop/domain/word_loop_box.dart';
import 'package:allways_games/games/word_loop/domain/word_loop_generator.dart';
import 'package:allways_games/games/word_loop/domain/word_loop_puzzle.dart';
import 'package:allways_games/games/word_loop/domain/word_loop_solver.dart';

const int defaultDayCount = 730;
const int baseSeed = 20240101;

/// How many of the most common words are eligible to be a board's intended
/// answer. Wide enough for variety, narrow enough that the answer is not a
/// word only a lexicographer knows.
const int seedVocabularySize = 20000;

/// A board must offer enough words to explore without being a haystack.
const int minPlayableWords = 120;
const int maxPlayableWords = 900;

/// Two-word answers a board may have. One is a needle; hundreds means the
/// board solves itself on the first thing a player types.
const int minTwoWordSolutions = 3;
const int maxTwoWordSolutions = 150;

/// How many boards may share a word in their answer.
///
/// A word with many distinct letters pairs with a great many partners, so
/// without a cap a handful of "hub" words (MOTORIZED, REVIEWERS) would
/// headline dozens of boards and the bank would feel repetitive.
const int maxWordReuse = 2;

/// Every board is a two-word board.
///
/// Par 1 means a single word covers all twelve letters, which is a
/// curiosity rather than a puzzle; par 3 or more stops reading as "the"
/// answer and makes the target vague. Requiring exactly two keeps the goal
/// legible: find the pair.
const int requiredPar = 2;

void main(List<String> args) {
  var dayCount = defaultDayCount;
  for (final arg in args) {
    if (arg.startsWith('--days=')) {
      dayCount = int.parse(arg.substring('--days='.length));
    }
  }

  final stopwatch = Stopwatch()..start();
  final dictionary = _loadDictionary();
  stdout.writeln(
    '${dictionary.playable.length} playable dictionary words, '
    '${dictionary.seeds.length} eligible as a board answer.',
  );

  final random = Random(baseSeed);
  final puzzles = <WordLoopPuzzle>[];
  final usedBoxes = <String>{};
  final wordUses = <String, int>{};
  var pairsTried = 0;
  var laidOut = 0;

  // The pair walk takes the first boards it finds, so an alphabetical seed
  // order would give every single board a first word starting "AB". Shuffle
  // with a fixed seed: spread across the alphabet, still reproducible.
  final seeds = List<String>.of(dictionary.seeds)..shuffle(Random(baseSeed));

  WordLoopGenerator.forEachSeedPair(seeds, (first, second) {
    pairsTried++;
    if (puzzles.length >= dayCount) return false;

    if ((wordUses[first] ?? 0) >= maxWordReuse) return true;
    if ((wordUses[second] ?? 0) >= maxWordReuse) return true;

    final box = WordLoopGenerator.layOut([first, second], random);
    if (box == null) return true;
    laidOut++;

    // The same twelve letters in the same arrangement can be reached from
    // different seed pairs; a player would just see yesterday's board.
    if (!usedBoxes.add(box.encode())) return true;

    final playable = WordLoopSolver.playableWords(box, dictionary.playable);
    if (playable.length < minPlayableWords) return true;
    if (playable.length > maxPlayableWords) return true;

    final twoWord = WordLoopSolver.findTwoWordSolutions(
      box,
      playable,
      limit: maxTwoWordSolutions + 1,
    );
    if (twoWord.length < minTwoWordSolutions) return true;
    if (twoWord.length > maxTwoWordSolutions) return true;

    final shortest = WordLoopSolver.findShortestChain(box, playable);
    if (shortest == null || shortest.length != requiredPar) return true;

    // Publish the seed pair, not the chain the search happened to find
    // first. Both are par, but the search walks the dictionary
    // alphabetically and so favours whatever obscure word sorts earliest
    // (EIGENMODE, EXPUNGER, ABLAUT); the seed pair was drawn from the most
    // common words in the language, which is what a revealed answer should
    // look like.
    final puzzle = WordLoopPuzzle(
      box: box,
      par: shortest.length,
      exampleSolution: [first, second],
      playableWordCount: playable.length,
      dictionary: dictionary.lookup,
    );
    _verify(puzzles.length, puzzle, [first, second], playable);
    puzzles.add(puzzle);
    wordUses[first] = (wordUses[first] ?? 0) + 1;
    wordUses[second] = (wordUses[second] ?? 0) + 1;

    if (puzzles.length % 100 == 0) {
      stdout.writeln(
        '${puzzles.length}/$dayCount boards '
        '(${stopwatch.elapsed.inSeconds}s elapsed)',
      );
    }
    return true;
  });

  if (puzzles.length < dayCount) {
    stderr.writeln(
      'Only built ${puzzles.length} boards from $pairsTried seed pairs '
      '($laidOut laid out). Loosen the acceptance windows or widen the '
      'seed vocabulary.',
    );
    exit(1);
  }

  // The pairs arrive alphabetically, so consecutive boards would otherwise
  // share a first word. A fixed-seed shuffle keeps the run reproducible.
  final ordered = List<WordLoopPuzzle>.of(puzzles)..shuffle(Random(baseSeed));

  // The dictionary is shipped once and shared by every board: validity is
  // "the dictionary has it AND this board can trace it", and the second
  // half is cheap to evaluate on device. Giving each board its own word
  // list would have made this file roughly thirty times larger.
  final bank = {
    'schemaVersion': 1,
    'game': 'word_loop',
    'generatedAt': '2024-01-01T00:00:00Z',
    'words': dictionary.playable,
    'puzzles': ordered.map((p) => p.toJson()).toList(),
  };

  final outDir = Directory('assets/content/word_loop');
  outDir.createSync(recursive: true);
  final outFile = File('${outDir.path}/bank.json');
  outFile.writeAsStringSync(jsonEncode(bank));

  final wordCounts = ordered.map((p) => p.playableWordCount).toList()..sort();
  stdout.writeln(
    'Wrote ${outFile.path}: ${ordered.length} verified boards from '
    '$pairsTried seed pairs in ${stopwatch.elapsed.inSeconds}s.',
  );
  stdout.writeln(
    '  playable words per board: min=${wordCounts.first} '
    'median=${wordCounts[wordCounts.length ~/ 2]} max=${wordCounts.last}',
  );
  stdout.writeln(
    '  file size: ${(outFile.lengthSync() / 1024).toStringAsFixed(0)} KiB',
  );
}

/// Aborts the run unless [puzzle] is sound.
void _verify(
  int slot,
  WordLoopPuzzle puzzle,
  List<String> seed,
  List<String> playable,
) {
  void fail(String reason) {
    stderr.writeln('Board $slot (${puzzle.box.encode()}): $reason');
    exit(1);
  }

  if (puzzle.box.letters.length != wordLoopLetterCount) {
    fail('does not carry $wordLoopLetterCount distinct letters');
  }
  for (final word in seed) {
    if (!puzzle.box.isPlayable(word.toUpperCase())) {
      fail('its own seed word "$word" is not playable on it');
    }
  }
  if (puzzle.exampleSolution.isEmpty) fail('has no published solution');
  if (puzzle.par != requiredPar) fail('par is ${puzzle.par}, not $requiredPar');
  if (puzzle.exampleSolution.length != puzzle.par) {
    fail('published solution is not par length');
  }

  // The published solution has to obey every rule the app will enforce.
  for (var i = 0; i < puzzle.exampleSolution.length; i++) {
    final word = puzzle.exampleSolution[i];
    if (!puzzle.box.isPlayable(word)) fail('solution word "$word" is unplayable');
    if (!puzzle.isValidWord(word)) fail('solution word "$word" is not in its own word list');
    if (i == 0) continue;
    final previous = puzzle.exampleSolution[i - 1];
    if (word[0] != previous[previous.length - 1]) {
      fail('solution does not chain at "$previous" -> "$word"');
    }
  }

  final covered = <String>{};
  for (final word in puzzle.exampleSolution) {
    covered.addAll(word.split(''));
  }
  if (covered.length != wordLoopLetterCount) {
    fail('published solution leaves ${wordLoopLetterCount - covered.length} '
        'letters unused');
  }

  if (puzzle.playableWordCount != playable.length) {
    fail('published word count disagrees with the board scan');
  }
  for (final word in playable) {
    if (!puzzle.isValidWord(word)) {
      fail('board scan produced "$word", which the app would reject');
    }
  }
}

/// ENABLE1 split into the words a board may use at all and the narrower
/// set a board's intended answer may be drawn from.
({List<String> playable, Set<String> lookup, List<String> seeds})
    _loadDictionary() {
  final enable1 = File('tool/data/enable1.txt');
  final frequencies = File('tool/data/count_1w.txt');
  if (!enable1.existsSync() || !frequencies.existsSync()) {
    stderr.writeln('Missing tool/data/enable1.txt or tool/data/count_1w.txt');
    exit(1);
  }

  final wordPattern = RegExp(r'^[a-z]+$');
  final playable = <String>[];
  final known = <String>{};

  for (final line in enable1.readAsLinesSync()) {
    final word = line.trim().toLowerCase();
    if (word.length < wordLoopMinWordLength) continue;
    if (!wordPattern.hasMatch(word)) continue;
    // A doubled letter can never be traced: the same letter is on one side,
    // and no word may take two letters from a side in a row. Dropping these
    // once here keeps them out of every per-board scan.
    if (_hasDoubledLetter(word)) continue;
    if (word.split('').toSet().length > wordLoopLetterCount) continue;
    final upper = word.toUpperCase();
    playable.add(upper);
    known.add(upper);
  }

  // Rank by real-world commonness so a board's answer is a word people
  // know, not the most obscure entry that happens to fit.
  final ranked = <String>[];
  for (final line in frequencies.readAsLinesSync()) {
    final parts = line.split('\t');
    if (parts.length != 2) continue;
    final word = parts[0].trim().toUpperCase();
    if (!known.contains(word)) continue;
    ranked.add(word);
    if (ranked.length >= seedVocabularySize) break;
  }

  // Seeds are sorted so the pair walk is deterministic run to run.
  return (playable: playable, lookup: known, seeds: ranked..sort());
}

bool _hasDoubledLetter(String word) {
  for (var i = 0; i + 1 < word.length; i++) {
    if (word[i] == word[i + 1]) return true;
  }
  return false;
}
