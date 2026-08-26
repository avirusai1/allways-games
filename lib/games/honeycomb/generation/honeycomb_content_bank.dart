import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../core/daily_seed/daily_seed.dart';
import '../domain/honeycomb_puzzle.dart';

/// Loads assets/content/honeycomb/bank.json (produced offline by
/// tool/gen_honeycomb_bank.dart).
class HoneycombContentBank implements DailyPuzzleBank<HoneycombPuzzle> {
  HoneycombContentBank._(this._puzzles);

  final List<HoneycombPuzzle> _puzzles;

  static Future<HoneycombContentBank> load() async {
    final raw = await rootBundle.loadString('assets/content/honeycomb/bank.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final puzzles = (json['puzzles'] as List)
        .map((p) => HoneycombPuzzle.fromJson(p as Map<String, dynamic>))
        .toList(growable: false);
    return HoneycombContentBank._(puzzles);
  }

  @override
  List<HoneycombPuzzle> get puzzles => _puzzles;

  @override
  HoneycombPuzzle puzzleForDayIndex(int dayIndex) =>
      _puzzles[dayIndex % _puzzles.length];

  @override
  HoneycombPuzzle puzzleForToday() => puzzleForDayIndex(DailySeed.todayIndex());
}
