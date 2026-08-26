import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/isar_provider.dart';
import '../data/groups_stats_repository.dart';
import '../domain/groups_game_state.dart';
import '../domain/groups_puzzle.dart';
import '../generation/groups_content_bank.dart';

final groupsContentBankProvider = FutureProvider<GroupsContentBank>((ref) {
  return GroupsContentBank.load();
});

final groupsStatsRepositoryProvider =
    FutureProvider<GroupsStatsRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return GroupsStatsRepository(isar);
});

final groupsStatsProvider = FutureProvider<GroupsGameStats>((ref) async {
  final repo = await ref.watch(groupsStatsRepositoryProvider.future);
  return repo.loadStats();
});

/// Drives one day's Groups puzzle.
class GroupsGameController extends AsyncNotifier<GroupsGameState> {
  late GroupsStatsRepository _stats;
  late int _dayIndex;
  final Random _shuffleRandom = Random();

  @override
  Future<GroupsGameState> build() async {
    final bank = await ref.watch(groupsContentBankProvider.future);
    _stats = await ref.watch(groupsStatsRepositoryProvider.future);
    _dayIndex = DailySeed.todayIndex();

    final puzzle = bank.puzzleForDayIndex(_dayIndex);

    // The board is shuffled per day rather than per launch: everyone
    // playing today sees the same arrangement, so "the one in the corner"
    // means the same thing to two people talking about it. The day index
    // seeds it, so closing and reopening does not reshuffle the puzzle
    // under the player either.
    final order = List<String>.of(puzzle.allWordTexts)
      ..shuffle(Random(_dayIndex));
    final initial = GroupsGameState.initial(puzzle, tileOrder: order);

    final existing = await _stats.completionForDay(_dayIndex);
    if (existing != null) {
      // A finished day shows its answers rather than being replayed.
      return initial
          .copyWith(mistakes: existing.won ? 0 : groupsMistakeLimit)
          .revealAll();
    }
    return initial;
  }

  void toggleWord(String word) => _apply((s) => s.toggleWord(word));

  void deselectAll() => _apply((s) => s.deselectAll());

  void shuffleTiles() {
    _apply((s) {
      final order = List<String>.of(s.tileOrder)..shuffle(_shuffleRandom);
      return s.shuffleTiles(order);
    });
  }

  /// Submits the current selection and reports what happened, so the screen
  /// can say "one away" rather than the player being left to guess why a
  /// life disappeared.
  Future<({GroupsGuessOutcome outcome, GroupsCategory? found})> submit() async {
    final current = state.valueOrNull;
    if (current == null) {
      return (outcome: GroupsGuessOutcome.notReady, found: null);
    }

    final result = current.submit();
    if (result.outcome == GroupsGuessOutcome.notReady ||
        result.outcome == GroupsGuessOutcome.repeat) {
      return (outcome: result.outcome, found: result.found);
    }

    var next = result.state;
    if (next.status == GroupsStatus.lost) next = next.revealAll();
    state = AsyncData(next);

    if (current.isPlaying && !next.isPlaying) {
      await _stats.recordCompletion(
        dayIndex: _dayIndex,
        solved: next.status == GroupsStatus.solved,
        mistakes: next.mistakes,
      );
      ref.invalidate(groupsStatsProvider);
    }
    return (outcome: result.outcome, found: result.found);
  }

  void _apply(GroupsGameState Function(GroupsGameState) transition) {
    final current = state.valueOrNull;
    if (current == null) return;
    final next = transition(current);
    if (identical(next, current)) return;
    state = AsyncData(next);
  }
}

final groupsGameControllerProvider =
    AsyncNotifierProvider<GroupsGameController, GroupsGameState>(
  GroupsGameController.new,
);
