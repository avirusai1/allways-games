import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../core/daily_seed/daily_seed.dart';
import '../domain/word_loop_puzzle.dart';

/// Loads assets/content/word_loop/bank.json (produced offline by
/// tool/gen_word_loop_bank.dart).
///
/// The file holds one shared dictionary and one lightweight descriptor per
/// board, so every board can be materialised up front without the asset
/// carrying a word list per day.
class WordLoopContentBank implements DailyPuzzleBank<WordLoopPuzzle> {
  WordLoopContentBank._(this._puzzles, this.dictionary)
      : _tiers = _bucketByWordCount(_puzzles);

  final List<WordLoopPuzzle> _puzzles;

  /// Every word the app accepts on any board.
  final Set<String> dictionary;

  final Map<WordLoopDifficulty, List<WordLoopPuzzle>> _tiers;

  static Future<WordLoopContentBank> load() async {
    final raw = await rootBundle.loadString('assets/content/word_loop/bank.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final dictionary = (json['words'] as List).cast<String>().toSet();
    final puzzles = (json['puzzles'] as List)
        .map((p) => WordLoopPuzzle.fromJson(p as Map<String, dynamic>, dictionary))
        .toList(growable: false);
    return WordLoopContentBank._(puzzles, dictionary);
  }

  @override
  List<WordLoopPuzzle> get puzzles => _puzzles;

  @override
  WordLoopPuzzle puzzleForDayIndex(int dayIndex) =>
      _puzzles[dayIndex % _puzzles.length];

  @override
  WordLoopPuzzle puzzleForToday() => puzzleForDayIndex(DailySeed.todayIndex());

  /// Every puzzle of [difficulty], for free play where the player picks a
  /// tier up front rather than getting whatever today's calendar slot is.
  List<WordLoopPuzzle> puzzlesOfDifficulty(WordLoopDifficulty difficulty) =>
      _tiers[difficulty] ?? const [];

  /// Splits the bank into thirds by playable-word count. Sorting first
  /// means each tier is a real difficulty band rather than an arbitrary
  /// slice — the bottom third genuinely has the fewest paths to a solve.
  static Map<WordLoopDifficulty, List<WordLoopPuzzle>> _bucketByWordCount(
    List<WordLoopPuzzle> puzzles,
  ) {
    final sorted = [...puzzles]
      ..sort((a, b) => a.playableWordCount.compareTo(b.playableWordCount));
    final third = sorted.length ~/ 3;
    return {
      WordLoopDifficulty.hard: sorted.sublist(0, third),
      WordLoopDifficulty.medium: sorted.sublist(third, third * 2),
      WordLoopDifficulty.easy: sorted.sublist(third * 2),
    };
  }
}
