import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../core/daily_seed/daily_seed.dart';
import '../domain/groups_puzzle.dart';

/// Loads assets/content/groups/bank.json (validated offline by
/// tool/gen_groups_bank.dart).
class GroupsContentBank implements DailyPuzzleBank<GroupsPuzzle> {
  GroupsContentBank._(this._puzzles);

  final List<GroupsPuzzle> _puzzles;

  static Future<GroupsContentBank> load() async {
    final raw = await rootBundle.loadString('assets/content/groups/bank.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final puzzles = (json['puzzles'] as List)
        .map((p) => GroupsPuzzle.fromJson(p as Map<String, dynamic>))
        .toList(growable: false);
    return GroupsContentBank._(puzzles);
  }

  @override
  List<GroupsPuzzle> get puzzles => _puzzles;

  @override
  GroupsPuzzle puzzleForDayIndex(int dayIndex) =>
      _puzzles[dayIndex % _puzzles.length];

  @override
  GroupsPuzzle puzzleForToday() => puzzleForDayIndex(DailySeed.todayIndex());
}
