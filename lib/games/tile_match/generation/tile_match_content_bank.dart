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

  /// Every puzzle built on [layoutName], for free play where the player
  /// picks a board size up front rather than getting whatever today's
  /// calendar slot is. The three shipped layouts differ in tile count
  /// (Long Hall 78, Spire 82, Terrace 88), so this is a real size/difficulty
  /// tier, not a cosmetic label on identical boards.
  List<TileMatchPuzzle> puzzlesOfLayout(String layoutName) =>
      _puzzles.where((p) => p.layout.name == layoutName).toList();
}
