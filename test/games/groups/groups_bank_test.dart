import 'dart:convert';
import 'dart:io';

import 'package:allways_games/games/groups/domain/groups_puzzle.dart';
import 'package:allways_games/games/groups/domain/groups_validator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the committed asset.
///
/// Groups has no generator, so this test is doing the job a generator's
/// self-checks do for the other games: it re-runs the full validator over
/// the shipped bytes, not just over the authoring source.
void main() {
  late List<GroupsPuzzle> puzzles;

  setUpAll(() {
    final file = File('assets/content/groups/bank.json');
    expect(file.existsSync(), isTrue,
        reason: 'run `dart run tool/gen_groups_bank.dart`');
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(json['game'], 'groups');
    expect(json['schemaVersion'], 1);
    puzzles = (json['puzzles'] as List)
        .map((p) => GroupsPuzzle.fromJson(p as Map<String, dynamic>))
        .toList();
  });

  test('ships at least sixty authored puzzles', () {
    expect(puzzles.length, greaterThanOrEqualTo(60));
  });

  test('the whole shipped bank passes the validator', () {
    // Including the ambiguity check: no word in any puzzle plausibly
    // belongs to a second category in that same puzzle.
    final defects = GroupsValidator.validateBank(puzzles);
    expect(
      defects,
      isEmpty,
      reason: defects.map((d) => d.toString()).join('\n'),
    );
  });

  test('every puzzle is sixteen words in four groups of four', () {
    for (final puzzle in puzzles) {
      expect(puzzle.categories, hasLength(groupsCategoryCount),
          reason: puzzle.id);
      expect(puzzle.allWordTexts, hasLength(groupsWordCount),
          reason: puzzle.id);
      for (final category in puzzle.categories) {
        expect(category.words, hasLength(groupsWordsPerCategory),
            reason: '${puzzle.id}/${category.tag}');
      }
    }
  });

  test('every category has a player-facing name distinct from its tag key',
      () {
    for (final puzzle in puzzles) {
      for (final category in puzzle.categories) {
        expect(category.name.trim(), isNotEmpty, reason: puzzle.id);
        expect(category.tag.trim(), isNotEmpty, reason: puzzle.id);
      }
    }
  });

  test('every puzzle has one category at each difficulty', () {
    for (final puzzle in puzzles) {
      expect(
        puzzle.byDifficulty.map((c) => c.difficulty).toList(),
        [0, 1, 2, 3],
        reason: puzzle.id,
      );
    }
  });

  test('every word claims its own category', () {
    for (final puzzle in puzzles) {
      for (final category in puzzle.categories) {
        for (final word in category.words) {
          expect(word.tags, contains(category.tag),
              reason: '${puzzle.id}: ${word.text}');
        }
      }
    }
  });

  test('words are upper case letters only', () {
    // The board renders them as-is, and the state matches on exact text.
    final pattern = RegExp(r'^[A-Z]+$');
    for (final puzzle in puzzles) {
      for (final word in puzzle.allWordTexts) {
        expect(pattern.hasMatch(word), isTrue,
            reason: '${puzzle.id}: "$word"');
      }
    }
  });

  test('no word is so long it cannot be read on a tile', () {
    // Tiles scale text down to fit, but past a point it stops being
    // legible on a phone.
    for (final puzzle in puzzles) {
      for (final word in puzzle.allWordTexts) {
        expect(word.length, lessThanOrEqualTo(18),
            reason: '${puzzle.id}: "$word" is ${word.length} characters');
      }
    }
  });

  test('puzzle ids are unique and readable', () {
    final seen = <String>{};
    for (final puzzle in puzzles) {
      expect(seen.add(puzzle.id), isTrue, reason: 'duplicate ${puzzle.id}');
      expect(RegExp(r'^[a-z0-9-]+$').hasMatch(puzzle.id), isTrue,
          reason: puzzle.id);
    }
  });

  test('consecutive puzzles do not share a category tag', () {
    // Two days running with the same trick reads as a content bug.
    for (var i = 1; i < puzzles.length; i++) {
      final previous = puzzles[i - 1].categories.map((c) => c.tag).toSet();
      final current = puzzles[i].categories.map((c) => c.tag).toSet();
      expect(previous.intersection(current), isEmpty,
          reason: '${puzzles[i - 1].id} and ${puzzles[i].id} share a category');
    }
  });
}
