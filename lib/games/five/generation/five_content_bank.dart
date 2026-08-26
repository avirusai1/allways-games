import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../core/daily_seed/daily_seed.dart';

/// Loads assets/content/five/bank.json (produced offline by
/// tool/gen_five_bank.dart) and exposes the deterministic daily answer plus
/// guess validation.
class FiveContentBank implements DailyPuzzleBank<String> {
  FiveContentBank._(this._answers, this._validGuesses);

  final List<String> _answers;
  final Set<String> _validGuesses;

  static Future<FiveContentBank> load() async {
    final raw = await rootBundle.loadString('assets/content/five/bank.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final answers = (json['answers'] as List).cast<String>();
    final validGuesses = (json['validGuesses'] as List).cast<String>().toSet();
    return FiveContentBank._(answers, validGuesses);
  }

  @override
  List<String> get puzzles => _answers;

  @override
  String puzzleForDayIndex(int dayIndex) => _answers[dayIndex % _answers.length];

  @override
  String puzzleForToday() => puzzleForDayIndex(DailySeed.todayIndex());

  bool isValidGuess(String word) => _validGuesses.contains(word.toLowerCase());
}
