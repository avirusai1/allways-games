// Content tool for the "Groups" game.
//
// Reads the authored puzzles in tool/data/groups_puzzles.json, expands the
// compact authoring format, validates them, and writes
// assets/content/groups/bank.json. Run with:
//   dart run tool/gen_groups_bank.dart
//
// Groups is the one game in the roster with no generator behind it. A
// program can build a Sudoku or a word ladder, but it cannot know that
// four things belong together in a way a person will find satisfying, so
// these puzzles are written by hand. Every category and word list is
// original work for this app; nothing is transcribed from any published
// puzzle.
//
// What this tool does instead of generating is *check*. The authoring
// format lists, for each word, any other category it could plausibly
// belong to; the tool then refuses any puzzle where a word's senses touch
// a second category in that same puzzle. A puzzle with two defensible
// answers is not a hard puzzle, it is a broken one, and that is the
// failure hand-authored content is most prone to.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:allways_games/games/groups/domain/groups_puzzle.dart';
import 'package:allways_games/games/groups/domain/groups_validator.dart';

const int baseSeed = 20240101;

void main() {
  final source = File('tool/data/groups_puzzles.json');
  if (!source.existsSync()) {
    stderr.writeln('Missing ${source.path}');
    exit(1);
  }

  final json = jsonDecode(source.readAsStringSync()) as Map<String, dynamic>;
  final puzzles = <GroupsPuzzle>[];

  for (final raw in (json['puzzles'] as List).cast<Map<String, dynamic>>()) {
    puzzles.add(_expand(raw));
  }

  final defects = GroupsValidator.validateBank(puzzles);
  if (defects.isNotEmpty) {
    stderr.writeln('${defects.length} problem(s) in the authored puzzles:');
    for (final defect in defects) {
      stderr.writeln('  $defect');
    }
    exit(1);
  }

  // The authored file is grouped by theme as it was written, so shipping it
  // in that order would give players runs of similar puzzles. A fixed-seed
  // shuffle spreads them out and still reproduces byte for byte.
  final ordered = List<GroupsPuzzle>.of(puzzles)..shuffle(Random(baseSeed));

  final bank = {
    'schemaVersion': 1,
    'game': 'groups',
    'generatedAt': '2024-01-01T00:00:00Z',
    'puzzles': ordered.map((p) => p.toJson()).toList(),
  };

  final outDir = Directory('assets/content/groups');
  outDir.createSync(recursive: true);
  final outFile = File('${outDir.path}/bank.json');
  outFile.writeAsStringSync(jsonEncode(bank));

  final wordCount = ordered.fold<int>(0, (n, p) => n + p.allWords.length);
  final distinctWords = <String>{
    for (final puzzle in ordered) ...puzzle.allWordTexts,
  };

  stdout.writeln(
    'Wrote ${outFile.path}: ${ordered.length} validated puzzles, '
    '$wordCount words (${distinctWords.length} distinct).',
  );
  stdout.writeln(
    '  file size: ${(outFile.lengthSync() / 1024).toStringAsFixed(0)} KiB',
  );
}

/// Expands one authored puzzle into the shipped model.
///
/// The authoring format lists only a word's *extra* senses; its own
/// category tag is added here so it never has to be repeated by hand (and
/// so it can never be forgotten).
GroupsPuzzle _expand(Map<String, dynamic> raw) {
  final categories = <GroupsCategory>[];
  for (final rawCategory
      in (raw['categories'] as List).cast<Map<String, dynamic>>()) {
    final tag = rawCategory['tag'] as String;
    final words = <GroupsWord>[];
    (rawCategory['words'] as Map<String, dynamic>).forEach((text, extraTags) {
      words.add(GroupsWord(
        text: text,
        tags: {tag, ...(extraTags as List).cast<String>()},
      ));
    });
    categories.add(GroupsCategory(
      tag: tag,
      name: rawCategory['name'] as String,
      difficulty: rawCategory['difficulty'] as int,
      words: words,
    ));
  }
  return GroupsPuzzle(id: raw['id'] as String, categories: categories);
}
