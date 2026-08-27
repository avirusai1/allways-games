// Offline content generator for the "Weave" game.
//
// Produces assets/content/weave/bank.json: one puzzle per calendar day,
// each a 6x7 letter grid tiled exactly by its theme words, one of which
// crosses from the top row to the bottom. Run with:
//   dart run tool/gen_weave_bank.dart [--days=1825]
//
// Sources:
//   - tool/data/weave_themes.json : authored theme word lists (original)
//   - tool/data/enable1.txt       : ENABLE1, public domain, used only to
//                                   detect words the grid contains by
//                                   accident
//   - tool/data/count_1w.txt      : word frequencies, used to decide which
//                                   accidental words are common enough to
//                                   be a problem
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:allways_games/games/weave/domain/weave_grid.dart';
import 'package:allways_games/games/weave/domain/weave_packer.dart';
import 'package:allways_games/games/weave/domain/weave_puzzle.dart';
import 'package:allways_games/games/weave/domain/weave_scanner.dart';

const int defaultDayCount = 1825;
const int baseSeed = 20240103;

/// An accidental word this long *and* common is a trap: the player traces
/// it, is told it is not a theme word, and concludes the puzzle is broken.
/// Shorter accidental finds are shipped as bonus words instead.
const int accidentalRejectLength = 9;

/// Shortest accidental find worth crediting as a bonus word.
const int bonusMinLength = 5;

/// How many attempts each day gets before it is skipped.
const int attemptsPerDay = 15;

void main(List<String> args) {
  var dayCount = defaultDayCount;
  for (final arg in args) {
    if (arg.startsWith('--days=')) {
      dayCount = int.parse(arg.substring('--days='.length));
    }
  }

  final themes = _loadThemes();
  stdout.writeln('${themes.length} authored themes.');

  final dictionary = _loadDictionary();
  final common = _loadCommon(dictionary);
  stdout.writeln(
    '${dictionary.length} dictionary words, ${common.length} common enough '
    'to reject a packing over.',
  );

  // Bonus words are drawn from the common slice at [bonusMinLength], not
  // from the whole dictionary at four letters: an eight-way grid of 42
  // cells traces hundreds of obscure four-letter strings, which would
  // bury the real finds and bloat the bank.
  final bonusTrie = WeaveScanner.buildTrie(
    common.where((w) => w.length >= bonusMinLength),
    minLength: bonusMinLength,
  );
  final commonTrie = WeaveScanner.buildTrie(
    common.where((w) => w.length >= accidentalRejectLength),
    minLength: accidentalRejectLength,
  );

  final puzzles = <WeavePuzzle>[];
  var rejected = 0;

  for (var day = 0; day < dayCount; day++) {
    // Per-day seed: regenerating with a larger --days never disturbs the
    // puzzles already published for earlier days.
    final rng = Random(baseSeed + day);

    WeavePuzzle? built;
    // A theme whose word lengths simply will not tile the grid must not
    // cost the day its puzzle, so fall through to the next theme rather
    // than shipping a bank with holes in it.
    for (var offset = 0; offset < themes.length && built == null; offset++) {
      final attemptTheme = themes[(day + offset) % themes.length];

      for (
        var attempt = 0;
        attempt < attemptsPerDay && built == null;
        attempt++
      ) {
        final words = WeavePacker.chooseWordSet(attemptTheme.words, rng);
        if (words == null) break;

        final packing = WeavePacker.pack(words, rng, nodeBudget: 150000);
        if (packing == null) continue;

        final letters = packing.letters;

        // Reject a grid that hides a long common word nobody meant to put
        // there.
        if (WeaveScanner.findAll(
          letters,
          commonTrie,
          minLength: accidentalRejectLength,
        ).isNotEmpty) {
          rejected++;
          continue;
        }

        final themeWords = {for (final p in packing.placements) p.word};
        final bonus = WeaveScanner.findAll(
          letters,
          bonusTrie,
          minLength: bonusMinLength,
        ).where((w) => !themeWords.contains(w)).toSet();

        built = WeavePuzzle(
          clue: attemptTheme.clue,
          letters: letters,
          spanner: packing.spanner,
          solutions: {for (final p in packing.placements) p.word: p.path},
          bonusWords: bonus,
        );
      }
    }

    if (built == null) {
      stderr.writeln('Day $day produced no packing from any theme.');
      continue;
    }
    _assertValid(built);
    puzzles.add(built);

    if ((day + 1) % 200 == 0) {
      stdout.writeln('${day + 1}/$dayCount ...');
    }
  }

  final bank = {
    'schemaVersion': 1,
    'game': 'weave',
    'generatedAt': '2024-01-03T00:00:00Z',
    'puzzles': puzzles.map((p) => p.toJson()).toList(),
  };

  final outDir = Directory('assets/content/weave');
  outDir.createSync(recursive: true);
  final outFile = File('${outDir.path}/bank.json');
  outFile.writeAsStringSync(jsonEncode(bank));

  final themeCounts = puzzles.map((p) => p.themeWords.length).toList()..sort();
  final bonusCounts = puzzles.map((p) => p.bonusWords.length).toList()..sort();
  stdout.writeln(
    'Wrote ${outFile.path}: ${puzzles.length} verified puzzles '
    '($rejected packings rejected for a long common accidental word).',
  );
  stdout.writeln(
    '  theme words per puzzle: min=${themeCounts.first} '
    'median=${themeCounts[themeCounts.length ~/ 2]} max=${themeCounts.last}',
  );
  stdout.writeln(
    '  bonus words per puzzle: min=${bonusCounts.first} '
    'median=${bonusCounts[bonusCounts.length ~/ 2]} max=${bonusCounts.last}',
  );
  stdout.writeln(
    '  file size: ${(outFile.lengthSync() / 1024).toStringAsFixed(0)} KiB',
  );
}

/// Hard gate: a puzzle only ships if its words genuinely tile the grid.
void _assertValid(WeavePuzzle puzzle) {
  if (puzzle.letters.length != weaveCellCount) {
    throw StateError('grid is ${puzzle.letters.length} cells');
  }
  if (puzzle.letters.any((l) => l.isEmpty)) {
    throw StateError('grid has an empty cell');
  }

  final covered = <int>{};
  for (final entry in puzzle.solutions.entries) {
    final word = entry.key;
    final path = entry.value;
    if (path.length != word.length) {
      throw StateError('$word path is ${path.length} cells');
    }
    if (!isWeavePathConnected(path)) {
      throw StateError('$word path is not a legal trace');
    }
    for (var i = 0; i < path.length; i++) {
      if (puzzle.letters[path[i]] != word[i]) {
        throw StateError('$word disagrees with the grid at ${path[i]}');
      }
      if (!covered.add(path[i])) {
        throw StateError('cell ${path[i]} is used by two theme words');
      }
    }
  }
  if (covered.length != weaveCellCount) {
    throw StateError('theme words cover ${covered.length}/$weaveCellCount');
  }

  final spannerPath = puzzle.solutions[puzzle.spanner];
  if (spannerPath == null || !spansGrid(spannerPath)) {
    throw StateError('spanner ${puzzle.spanner} does not span the grid');
  }
  if (puzzle.bonusWords.any(puzzle.solutions.containsKey)) {
    throw StateError('a bonus word is also a theme word');
  }
}

class _Theme {
  const _Theme(this.clue, this.words);
  final String clue;
  final List<String> words;
}

List<_Theme> _loadThemes() {
  final file = File('tool/data/weave_themes.json');
  if (!file.existsSync()) {
    stderr.writeln('Missing ${file.path}');
    exit(1);
  }
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return [
    for (final raw in (json['themes'] as List).cast<Map<String, dynamic>>())
      _Theme(
        raw['clue'] as String,
        (raw['words'] as List)
            .cast<String>()
            .map((w) => w.toUpperCase())
            .toList(),
      ),
  ];
}

Set<String> _loadDictionary() {
  final file = File('tool/data/enable1.txt');
  if (!file.existsSync()) {
    stderr.writeln('Missing ${file.path}');
    exit(1);
  }
  final letters = RegExp(r'^[a-z]+$');
  return file
      .readAsLinesSync()
      .map((w) => w.trim().toLowerCase())
      .where((w) => w.length >= 4 && letters.hasMatch(w))
      .map((w) => w.toUpperCase())
      .toSet();
}

/// The most frequent slice of the dictionary. A rare long word appearing
/// by accident is a curiosity; a common one is a trap.
Set<String> _loadCommon(Set<String> dictionary, {int take = 25000}) {
  final file = File('tool/data/count_1w.txt');
  if (!file.existsSync()) {
    stderr.writeln('Missing ${file.path}');
    exit(1);
  }
  final out = <String>{};
  for (final line in file.readAsLinesSync()) {
    if (out.length >= take) break;
    final parts = line.split('\t');
    if (parts.isEmpty) continue;
    final word = parts[0].trim().toUpperCase();
    if (dictionary.contains(word)) out.add(word);
  }
  return out;
}
