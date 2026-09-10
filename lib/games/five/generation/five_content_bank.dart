import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../core/daily_seed/daily_seed.dart';

enum FiveDifficulty { easy, medium, hard }

extension FiveDifficultyLabel on FiveDifficulty {
  String get label => switch (this) {
        FiveDifficulty.easy => 'Easy',
        FiveDifficulty.medium => 'Medium',
        FiveDifficulty.hard => 'Hard',
      };
}

/// Loads assets/content/five/bank.json (produced offline by
/// tool/gen_five_bank.dart) and exposes the deterministic daily answer plus
/// guess validation.
class FiveContentBank implements DailyPuzzleBank<String> {
  FiveContentBank._(this._answers, this._validGuesses)
      : _tiers = _bucketByLetterDifficulty(_answers);

  final List<String> _answers;
  final Set<String> _validGuesses;
  final Map<FiveDifficulty, List<String>> _tiers;

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

  /// Every answer of [difficulty], for free play where the player picks a
  /// tier up front rather than getting whatever today's calendar slot is.
  List<String> puzzlesOfDifficulty(FiveDifficulty difficulty) =>
      _tiers[difficulty] ?? const [];

  /// Rough Scrabble-style letter frequency: common letters score low, rare
  /// ones score high. Ties break on how many distinct letters the word
  /// uses — a word with repeated letters gives fewer positions to narrow
  /// down from, which is a real source of difficulty this genre turns on.
  static const Map<String, int> _letterRarity = {
    'e': 1, 'a': 1, 'i': 1, 'o': 1, 'n': 1, 'r': 1, 't': 1, 'l': 1, 's': 1,
    'u': 1,
    'd': 2, 'g': 2,
    'b': 3, 'c': 3, 'm': 3, 'p': 3,
    'f': 4, 'h': 4, 'v': 4, 'w': 4, 'y': 4,
    'k': 5,
    'j': 8, 'x': 8,
    'q': 10, 'z': 10,
  };

  static int _difficultyScore(String word) {
    final letters = word.toLowerCase().split('');
    final rarity = letters.fold<int>(0, (sum, l) => sum + (_letterRarity[l] ?? 3));
    final uniqueCount = letters.toSet().length;
    return rarity + (word.length - uniqueCount) * 3;
  }

  /// Splits the bank into thirds by that score. Sorting first means each
  /// tier is a real difficulty band rather than an arbitrary slice.
  static Map<FiveDifficulty, List<String>> _bucketByLetterDifficulty(
    List<String> answers,
  ) {
    final sorted = [...answers]
      ..sort((a, b) => _difficultyScore(a).compareTo(_difficultyScore(b)));
    final third = sorted.length ~/ 3;
    return {
      FiveDifficulty.easy: sorted.sublist(0, third),
      FiveDifficulty.medium: sorted.sublist(third, third * 2),
      FiveDifficulty.hard: sorted.sublist(third * 2),
    };
  }
}
