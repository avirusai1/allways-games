import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../core/daily_seed/daily_seed.dart';
import '../domain/weave_puzzle.dart';

/// Loads assets/content/weave/bank.json (produced offline by
/// tool/gen_weave_bank.dart) and serves the deterministic daily puzzle.
class WeaveContentBank implements DailyPuzzleBank<WeavePuzzle> {
  WeaveContentBank._(this._puzzles);

  final List<WeavePuzzle> _puzzles;

  static Future<WeaveContentBank> load() async {
    final raw = await rootBundle.loadString('assets/content/weave/bank.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final puzzles = (json['puzzles'] as List)
        .cast<Map<String, dynamic>>()
        .map(WeavePuzzle.fromJson)
        .toList();
    return WeaveContentBank._(puzzles);
  }

  @override
  List<WeavePuzzle> get puzzles => _puzzles;

  @override
  WeavePuzzle puzzleForDayIndex(int dayIndex) =>
      _puzzles[dayIndex % _puzzles.length];

  @override
  WeavePuzzle puzzleForToday() => puzzleForDayIndex(DailySeed.todayIndex());
}
