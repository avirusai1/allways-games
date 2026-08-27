import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../core/daily_seed/daily_seed.dart';
import '../domain/domino_puzzle.dart';

/// Loads assets/content/dot_dominoes/bank.json (produced offline by
/// tool/gen_dot_dominoes_bank.dart) and serves the daily puzzle.
class DominoContentBank implements DailyPuzzleBank<DominoPuzzle> {
  DominoContentBank._(this._puzzles);

  final List<DominoPuzzle> _puzzles;

  static Future<DominoContentBank> load() async {
    final raw =
        await rootBundle.loadString('assets/content/dot_dominoes/bank.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final puzzles = (json['puzzles'] as List)
        .cast<Map<String, dynamic>>()
        .map(DominoPuzzle.fromJson)
        .toList();
    return DominoContentBank._(puzzles);
  }

  @override
  List<DominoPuzzle> get puzzles => _puzzles;

  @override
  DominoPuzzle puzzleForDayIndex(int dayIndex) =>
      _puzzles[dayIndex % _puzzles.length];

  @override
  DominoPuzzle puzzleForToday() => puzzleForDayIndex(DailySeed.todayIndex());
}
