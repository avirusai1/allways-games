import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../core/daily_seed/daily_seed.dart';
import '../domain/sudoku_board.dart';

/// Loads assets/content/sudoku/bank.json (produced offline by
/// tool/gen_sudoku_bank.dart) and serves the deterministic daily puzzle.
class SudokuContentBank implements DailyPuzzleBank<SudokuPuzzle> {
  SudokuContentBank._(this._puzzles);

  final List<SudokuPuzzle> _puzzles;

  static Future<SudokuContentBank> load() async {
    final raw = await rootBundle.loadString('assets/content/sudoku/bank.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final puzzles = (json['puzzles'] as List)
        .cast<Map<String, dynamic>>()
        .map(SudokuPuzzle.fromJson)
        .toList();
    return SudokuContentBank._(puzzles);
  }

  @override
  List<SudokuPuzzle> get puzzles => _puzzles;

  @override
  SudokuPuzzle puzzleForDayIndex(int dayIndex) =>
      _puzzles[dayIndex % _puzzles.length];

  @override
  SudokuPuzzle puzzleForToday() => puzzleForDayIndex(DailySeed.todayIndex());
}
