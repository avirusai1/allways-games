import 'dart:convert';
import 'dart:io';

import 'package:allways_games/games/tile_match/domain/tile_board.dart';
import 'package:allways_games/games/tile_match/domain/tile_layout.dart';
import 'package:allways_games/games/tile_match/domain/tile_match_puzzle.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the committed asset, not just the generator that wrote it.
void main() {
  late List<TileMatchPuzzle> puzzles;

  setUpAll(() {
    final file = File('assets/content/tile_match/bank.json');
    expect(file.existsSync(), isTrue,
        reason: 'run `dart run tool/gen_tile_match_bank.dart`');
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(json['game'], 'tile_match');
    expect(json['schemaVersion'], 1);
    puzzles = (json['puzzles'] as List)
        .map((p) => TileMatchPuzzle.fromJson(p as Map<String, dynamic>))
        .toList();
  });

  test('ships enough boards that they do not repeat within a year', () {
    expect(puzzles.length, greaterThanOrEqualTo(365));
  });

  test('every board fills its layout exactly', () {
    for (var i = 0; i < puzzles.length; i++) {
      final puzzle = puzzles[i];
      expect(puzzle.faces.length, puzzle.layout.slots.length, reason: '$i');
      for (final slot in puzzle.layout.slots) {
        expect(puzzle.faces[slot], isNotNull,
            reason: 'board $i has no face at $slot');
      }
    }
  });

  test('every face appears an even number of times', () {
    // An odd count means at least one tile can never be paired off, however
    // well the board is played.
    for (var i = 0; i < puzzles.length; i++) {
      final counts = <int, int>{};
      for (final face in puzzles[i].faces.values) {
        counts[face.id] = (counts[face.id] ?? 0) + 1;
      }
      for (final entry in counts.entries) {
        expect(entry.value.isEven, isTrue,
            reason: 'board $i: face ${entry.key} appears ${entry.value} times');
      }
    }
  });

  test('a sample of shipped boards is provably clearable', () {
    // The property the whole game rests on. Clearing search costs real work
    // per board, so this walks a spread rather than all 730; the generator
    // proved every board at write time and this confirms the file still
    // holds those boards.
    for (var i = 0; i < puzzles.length; i += 37) {
      final puzzle = puzzles[i];
      expect(
        TileBoard.isSolvable(puzzle.allSlots, puzzle.faces),
        isTrue,
        reason: 'board $i (${puzzle.layout.name}) cannot be cleared',
      );
    }
  });

  test('every board opens with at least one move available', () {
    // A board that is dead on arrival would pass a clearability check only
    // if it were empty, but this is cheap and catches it directly.
    for (var i = 0; i < puzzles.length; i++) {
      final puzzle = puzzles[i];
      expect(
        TileBoard.availableMoves(puzzle.allSlots, puzzle.faces),
        isNotEmpty,
        reason: 'board $i has no opening move',
      );
    }
  });

  test('boards use a known layout, and all three appear', () {
    final names = tileLayouts.map((l) => l.name).toSet();
    final used = <String, int>{};
    for (final puzzle in puzzles) {
      expect(names, contains(puzzle.layout.name));
      used[puzzle.layout.name] = (used[puzzle.layout.name] ?? 0) + 1;
    }
    for (final name in names) {
      expect(used[name] ?? 0, greaterThan(0), reason: '$name never appears');
    }
  });

  test('consecutive days do not repeat a board', () {
    for (var i = 1; i < puzzles.length; i++) {
      expect(jsonEncode(puzzles[i].toJson()),
          isNot(jsonEncode(puzzles[i - 1].toJson())),
          reason: 'board $i repeats the day before');
    }
  });

  test('no two boards in the bank are identical', () {
    final seen = <String>{};
    for (var i = 0; i < puzzles.length; i++) {
      expect(seen.add(jsonEncode(puzzles[i].toJson())), isTrue,
          reason: 'board $i duplicates an earlier board');
    }
  });
}
