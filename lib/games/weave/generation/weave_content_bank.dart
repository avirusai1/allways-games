import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../core/daily_seed/daily_seed.dart';
import '../domain/weave_puzzle.dart';

/// Loads assets/content/weave/bank.json (produced offline by
/// tool/gen_weave_bank.dart) and serves the deterministic daily puzzle.
class WeaveContentBank implements DailyPuzzleBank<WeavePuzzle> {
  WeaveContentBank._(this._puzzles) : _tiers = _bucketByBonusCount(_puzzles);

  final List<WeavePuzzle> _puzzles;
  final Map<WeaveDifficulty, List<WeavePuzzle>> _tiers;

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

  /// Every puzzle of [difficulty], for free play where the player picks a
  /// tier up front rather than getting whatever today's calendar slot is.
  List<WeavePuzzle> puzzlesOfDifficulty(WeaveDifficulty difficulty) =>
      _tiers[difficulty] ?? const [];

  /// Splits the bank into thirds by bonus-word count. Sorting first means
  /// each tier is a real difficulty band: the bottom third genuinely has
  /// the fewest incidental words to stumble onto.
  static Map<WeaveDifficulty, List<WeavePuzzle>> _bucketByBonusCount(
    List<WeavePuzzle> puzzles,
  ) {
    final sorted = [...puzzles]
      ..sort((a, b) => a.bonusWords.length.compareTo(b.bonusWords.length));
    final third = sorted.length ~/ 3;
    return {
      WeaveDifficulty.hard: sorted.sublist(0, third),
      WeaveDifficulty.medium: sorted.sublist(third, third * 2),
      WeaveDifficulty.easy: sorted.sublist(third * 2),
    };
  }
}
