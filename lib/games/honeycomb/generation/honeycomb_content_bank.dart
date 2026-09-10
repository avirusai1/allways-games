import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../core/daily_seed/daily_seed.dart';
import '../domain/honeycomb_puzzle.dart';

/// Loads assets/content/honeycomb/bank.json (produced offline by
/// tool/gen_honeycomb_bank.dart).
class HoneycombContentBank implements DailyPuzzleBank<HoneycombPuzzle> {
  HoneycombContentBank._(this._puzzles) : _tiers = _bucketByAnswerCount(_puzzles);

  final List<HoneycombPuzzle> _puzzles;
  final Map<HoneycombDifficulty, List<HoneycombPuzzle>> _tiers;

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

  /// Every puzzle of [difficulty], for free play where the player picks a
  /// tier up front rather than getting whatever today's calendar slot is.
  List<HoneycombPuzzle> puzzlesOfDifficulty(HoneycombDifficulty difficulty) =>
      _tiers[difficulty] ?? const [];

  /// Splits the bank into thirds by answer count. Sorting first means each
  /// tier is a real difficulty band: the bottom third genuinely has the
  /// fewest words left to find.
  static Map<HoneycombDifficulty, List<HoneycombPuzzle>> _bucketByAnswerCount(
    List<HoneycombPuzzle> puzzles,
  ) {
    final sorted = [...puzzles]
      ..sort((a, b) => a.answers.length.compareTo(b.answers.length));
    final third = sorted.length ~/ 3;
    return {
      HoneycombDifficulty.hard: sorted.sublist(0, third),
      HoneycombDifficulty.medium: sorted.sublist(third, third * 2),
      HoneycombDifficulty.easy: sorted.sublist(third * 2),
    };
  }
}
