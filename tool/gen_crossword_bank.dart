// Offline content generator for the 5x5 mini "Crossword".
//
// Produces assets/content/crossword/bank.json: one mini per calendar day,
// each a filled grid with an original clue for every entry. Run with:
//   dart run tool/gen_crossword_bank.dart [--days=1825]
//
// Source: tool/data/crossword_words*.json — the app's own clued
// vocabulary. The fill draws only from it, deliberately: a grid filled
// from a plain dictionary is a grid the app cannot clue, so the constraint
// belongs in the fill rather than being discovered afterwards.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:allways_games/games/crossword/domain/crossword_filler.dart';
import 'package:allways_games/games/crossword/domain/crossword_grid.dart';
import 'package:allways_games/games/crossword/domain/crossword_puzzle.dart';

const int defaultDayCount = 1825;
const int baseSeed = 20240104;

/// Answers from the previous few days, kept out of the next fill so
/// consecutive puzzles do not all lean on the same convenient words.
const int recentMemory = 40;

const List<String> sourceFiles = [
  'tool/data/crossword_words.json',
  'tool/data/crossword_words_4.json',
  'tool/data/crossword_words_5.json',
];

void main(List<String> args) {
  var dayCount = defaultDayCount;
  for (final arg in args) {
    if (arg.startsWith('--days=')) {
      dayCount = int.parse(arg.substring('--days='.length));
    }
  }

  final clues = _loadClues();
  stdout.writeln('${clues.length} clued words available to the fill.');

  // Built once and reused: rebuilding the posting lists per fill is what
  // makes a generator like this too slow to finish.
  final vocabulary = CrosswordVocabulary(clues.keys);

  final puzzles = <CrosswordPuzzle>[];
  final recent = <String>[];
  final patternUse = <String, int>{};

  for (var day = 0; day < dayCount; day++) {
    // Per-day seed: regenerating with a larger --days never disturbs the
    // puzzles already published for earlier days.
    final rng = Random(baseSeed + day);

    CrosswordPuzzle? built;
    String? usedPattern;

    for (var offset = 0;
        offset < crosswordPatterns.length && built == null;
        offset++) {
      final pattern = crosswordPatterns[(day + offset) % crosswordPatterns.length];
      final blocked = pattern.blocked;
      final slots = slotsFor(blocked);

      final fill = CrosswordFiller.fill(
        blocked: blocked,
        slots: slots,
        vocabulary: vocabulary,
        random: rng,
        exclude: recent.toSet(),
      );
      if (fill == null) continue;

      built = CrosswordPuzzle(
        blocked: blocked,
        solution: fill.letters,
        entries: [
          for (final slot in slots)
            CrosswordEntry(
              number: slot.number,
              direction: slot.direction,
              cells: slot.cells,
              answer: fill.entries[slot]!,
              clue: clues[fill.entries[slot]!]!,
            ),
        ],
      );
      usedPattern = pattern.name;
    }

    if (built == null) {
      stderr.writeln('Day $day produced no fill from any pattern.');
      continue;
    }

    _assertValid(built, clues);
    puzzles.add(built);
    patternUse[usedPattern!] = (patternUse[usedPattern] ?? 0) + 1;

    for (final entry in built.entries) {
      recent.add(entry.answer);
    }
    while (recent.length > recentMemory) {
      recent.removeAt(0);
    }

    if ((day + 1) % 200 == 0) stdout.writeln('${day + 1}/$dayCount ...');
  }

  final bank = {
    'schemaVersion': 1,
    'game': 'crossword',
    'generatedAt': '2024-01-04T00:00:00Z',
    'puzzles': puzzles.map((p) => p.toJson()).toList(),
  };

  final outDir = Directory('assets/content/crossword');
  outDir.createSync(recursive: true);
  final outFile = File('${outDir.path}/bank.json');
  outFile.writeAsStringSync(jsonEncode(bank));

  final distinct = <String>{
    for (final puzzle in puzzles)
      for (final entry in puzzle.entries) entry.answer,
  };

  stdout.writeln('Wrote ${outFile.path}: ${puzzles.length} verified minis.');
  for (final entry in patternUse.entries) {
    stdout.writeln('  ${entry.key}: ${entry.value} grids');
  }
  stdout.writeln('  ${distinct.length} distinct answers used');
  stdout.writeln(
    '  file size: ${(outFile.lengthSync() / 1024).toStringAsFixed(0)} KiB',
  );
}

/// Hard gate: a puzzle only ships if the grid and its entries agree.
void _assertValid(CrosswordPuzzle puzzle, Map<String, String> clues) {
  if (puzzle.solution.length != crosswordCellCount) {
    throw StateError('grid is ${puzzle.solution.length} cells');
  }
  for (var i = 0; i < crosswordCellCount; i++) {
    final blank = puzzle.solution[i].isEmpty;
    if (blank != puzzle.blocked[i]) {
      throw StateError('cell $i is ${blank ? 'blank' : 'filled'} but '
          '${puzzle.blocked[i] ? 'blocked' : 'open'}');
    }
  }

  for (final entry in puzzle.entries) {
    if (entry.answer.length != entry.cells.length) {
      throw StateError('${entry.answer} does not fit ${entry.label}');
    }
    if (entry.answer.length < crosswordMinEntry) {
      throw StateError('${entry.label} is only ${entry.answer.length} long');
    }
    for (var i = 0; i < entry.cells.length; i++) {
      if (puzzle.solution[entry.cells[i]] != entry.answer[i]) {
        throw StateError('${entry.answer} disagrees with the grid');
      }
    }
    if (!clues.containsKey(entry.answer)) {
      throw StateError('${entry.answer} has no clue');
    }
    if (entry.clue.trim().isEmpty) {
      throw StateError('${entry.answer} has an empty clue');
    }
  }

  // Every open square must belong to both an across and a down entry, or
  // it could never be checked by a crossing.
  final acrossCells = <int>{
    for (final e in puzzle.across) ...e.cells,
  };
  final downCells = <int>{
    for (final e in puzzle.down) ...e.cells,
  };
  for (var i = 0; i < crosswordCellCount; i++) {
    if (puzzle.blocked[i]) continue;
    if (!acrossCells.contains(i) || !downCells.contains(i)) {
      throw StateError('cell $i is not crossed by both directions');
    }
  }

  final answers = puzzle.entries.map((e) => e.answer).toList();
  if (answers.toSet().length != answers.length) {
    throw StateError('a word appears twice in one grid');
  }
}

Map<String, String> _loadClues() {
  final out = <String, String>{};
  for (final path in sourceFiles) {
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('Missing $path');
      exit(1);
    }
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    (json['words'] as Map<String, dynamic>).forEach((word, clue) {
      out[word.toUpperCase()] = clue as String;
    });
  }
  return out;
}
