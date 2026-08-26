import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../core/daily_seed/daily_seed.dart';
import '../domain/tile_match_puzzle.dart';

/// Loads assets/content/tile_match/bank.json (produced offline by
/// tool/gen_tile_match_bank.dart).
class TileMatchContentBank implements DailyPuzzleBank<TileMatchPuzzle> {
  TileMatchContentBank._(this._puzzles);

  final List<TileMatchPuzzle> _puzzles;

  static Future<TileMatchContentBank> load() async {
    final raw =
        await rootBundle.loadString('assets/content/tile_match/bank.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final puzzles = (json['puzzles'] as List)
        .map((p) => TileMatchPuzzle.fromJson(p as Map<String, dynamic>))
        .toList(growable: false);
    return TileMatchContentBank._(puzzles);
  }

  @override
  List<TileMatchPuzzle> get puzzles => _puzzles;

  @override
  TileMatchPuzzle puzzleForDayIndex(int dayIndex) =>
      _puzzles[dayIndex % _puzzles.length];

  @override
  TileMatchPuzzle puzzleForToday() => puzzleForDayIndex(DailySeed.todayIndex());
}
