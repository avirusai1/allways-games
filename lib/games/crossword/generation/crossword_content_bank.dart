import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../core/daily_seed/daily_seed.dart';
import '../domain/crossword_puzzle.dart';

/// Loads assets/content/crossword/bank.json (produced offline by
/// tool/gen_crossword_bank.dart) and serves the deterministic daily mini.
class CrosswordContentBank implements DailyPuzzleBank<CrosswordPuzzle> {
  CrosswordContentBank._(this._puzzles);

  final List<CrosswordPuzzle> _puzzles;

  static Future<CrosswordContentBank> load() async {
    final raw =
        await rootBundle.loadString('assets/content/crossword/bank.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final puzzles = (json['puzzles'] as List)
        .cast<Map<String, dynamic>>()
        .map(CrosswordPuzzle.fromJson)
        .toList();
    return CrosswordContentBank._(puzzles);
  }

  @override
  List<CrosswordPuzzle> get puzzles => _puzzles;

  @override
  CrosswordPuzzle puzzleForDayIndex(int dayIndex) =>
      _puzzles[dayIndex % _puzzles.length];

  @override
  CrosswordPuzzle puzzleForToday() => puzzleForDayIndex(DailySeed.todayIndex());

  /// Every puzzle of [difficulty], for free play where the player picks a
  /// tier up front rather than getting whatever today's calendar slot is.
  /// The bank ships exactly two black-square counts, 6 and 8 — 8 (fewer
  /// open cells to fill) is Easy, 6 is Hard.
  List<CrosswordPuzzle> puzzlesOfDifficulty(CrosswordDifficulty difficulty) {
    return _puzzles.where((p) {
      final blockedCount = p.blocked.where((b) => b).length;
      final isEasy = blockedCount >= _easyMinBlockedCount;
      return difficulty == CrosswordDifficulty.easy ? isEasy : !isEasy;
    }).toList();
  }

  /// Midpoint between the two shipped block counts (6 and 8), so a change
  /// to the generator's patterns wouldn't silently need this file's
  /// threshold hand-edited too — anything at or above 7 counts as Easy.
  static const int _easyMinBlockedCount = 7;
}
