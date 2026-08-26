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
  WordLoopContentBank._(this._puzzles, this.dictionary);

  final List<WordLoopPuzzle> _puzzles;

  /// Every word the app accepts on any board.
  final Set<String> dictionary;

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
}
