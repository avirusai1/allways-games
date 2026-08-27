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

/// Authored source files, read in order.
const List<String> sourceFiles = [
  'tool/data/groups_puzzles.json',
];

/// Total days of puzzles to ship. Override with --days=N.
///
/// The authored puzzles come first; the rest are composed by recombining
/// the authored categories (see [_compose]).
const int defaultDayCount = 730;

void main(List<String> args) {
  var dayCount = defaultDayCount;
  for (final arg in args) {
    if (arg.startsWith('--days=')) {
      dayCount = int.parse(arg.substring('--days='.length));
    }
  }

  final puzzles = <GroupsPuzzle>[];
  for (final path in sourceFiles) {
    final source = File(path);
    if (!source.existsSync()) {
      stderr.writeln('Missing $path');
      exit(1);
    }
    final json = jsonDecode(source.readAsStringSync()) as Map<String, dynamic>;
    for (final raw in (json['puzzles'] as List).cast<Map<String, dynamic>>()) {
      puzzles.add(_expand(raw));
    }
  }

  final defects = GroupsValidator.validateAuthoredSource(puzzles);
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

  // Hand-authoring cannot keep up with a daily game, so the remaining days
  // are composed by recombining the authored categories.
  //
  // Known tradeoff, accepted deliberately: an authored puzzle picks its
  // four categories to bait each other (stage-lighting kit next to
  // ___LIGHT), and a recombined one cannot. Composed puzzles are flatter
  // and easier than authored ones. They are still fair - every one goes
  // through the same validator - but the fix for the quality gap is more
  // authored puzzles, not more composition.
  if (dayCount > ordered.length) {
    final composed = _compose(
      authored: ordered,
      wanted: dayCount - ordered.length,
    );
    ordered.addAll(composed);
    stdout.writeln(
      '${composed.length} composed from the authored category pool.',
    );
  }

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

/// Builds extra puzzles by drawing one category from each difficulty band
/// of the authored pool.
///
/// A composition is kept only if it survives [GroupsValidator], which is
/// what rules out the two ways recombination goes wrong: the same word
/// appearing in two categories, and a word whose declared senses reach a
/// category it is not filed under.
List<GroupsPuzzle> _compose({
  required List<GroupsPuzzle> authored,
  required int wanted,
}) {
  // Bands keep an authored category at the difficulty it was written for,
  // so a category written as the easy one stays the easy one.
  final bands = <int, List<GroupsCategory>>{0: [], 1: [], 2: [], 3: []};
  for (final puzzle in authored) {
    for (final category in puzzle.categories) {
      bands[category.difficulty]!.add(category);
    }
  }
  for (final entry in bands.entries) {
    if (entry.value.isEmpty) {
      stderr.writeln('No authored categories at difficulty ${entry.key}');
      exit(1);
    }
  }

  final rng = Random(baseSeed + 1);
  final composed = <GroupsPuzzle>[];
  final usedCombinations = <String>{};

  // How recently each category was used, so a player does not meet the
  // same group twice in a fortnight.
  final lastUsedAt = <String, int>{};
  const minGapDays = 21;

  var attempts = 0;
  final maxAttempts = wanted * 400;

  while (composed.length < wanted && attempts < maxAttempts) {
    attempts++;
    final day = composed.length;

    final picks = <GroupsCategory>[];
    for (var difficulty = 0; difficulty < groupsCategoryCount; difficulty++) {
      final band = bands[difficulty]!;
      picks.add(band[rng.nextInt(band.length)]);
    }

    final tags = picks.map((c) => c.tag).toList();
    if (tags.toSet().length != tags.length) continue;

    if (tags.any((t) => day - (lastUsedAt[t] ?? -minGapDays * 2) < minGapDays)) {
      continue;
    }

    final key = (tags.toList()..sort()).join('|');
    if (!usedCombinations.add(key)) continue;

    final candidate = GroupsPuzzle(
      id: 'mix-${composed.length.toString().padLeft(4, '0')}',
      categories: picks,
    );
    if (GroupsValidator.validate(candidate).isNotEmpty) continue;

    for (final tag in tags) {
      lastUsedAt[tag] = day;
    }
    composed.add(candidate);
  }

  if (composed.length < wanted) {
    stdout.writeln(
      'Composed only ${composed.length} of $wanted after $attempts attempts; '
      'the authored pool limits how many distinct fair puzzles exist.',
    );
  }
  return composed;
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
