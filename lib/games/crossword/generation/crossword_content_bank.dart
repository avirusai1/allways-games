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
}
