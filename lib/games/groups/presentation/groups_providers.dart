import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/isar_provider.dart';
import '../../../core/stats/free_play_stats.dart';
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

/// Cumulative "played as many as you like" count. Groups has no content
/// axis to hang a real Easy/Medium/Hard picker on — every puzzle mixes a
/// straightforward, a tricky and two in-between categories by design — so
/// unlike the other free-play games this one has no difficulty tiers, just
/// unlimited random puzzles.
final groupsFreePlayStatsProvider = FutureProvider<FreePlayStats>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return FreePlayStats('groups', prefs);
});

/// Drives Groups as free play: a fresh random puzzle every time, with no
/// one-per-day lock.
///
/// Unlike the other converted games, Groups has no per-puzzle difficulty
/// signal in its content — every puzzle is built the same way, one
/// category at each of four difficulty levels — so there is no picker
/// screen here: [build] draws a puzzle immediately, and [newPuzzle] draws
/// another any time the player wants one.
class GroupsGameController extends AsyncNotifier<GroupsGameState> {
  late GroupsContentBank _bank;
  late GroupsStatsRepository _stats;
  late FreePlayStats _freePlayStats;
  final Random _random = Random();
  final Random _shuffleRandom = Random();
  GroupsPuzzle? _lastPuzzle;

  @override
  Future<GroupsGameState> build() async {
    _bank = await ref.watch(groupsContentBankProvider.future);
    _stats = await ref.watch(groupsStatsRepositoryProvider.future);
    _freePlayStats = await ref.watch(groupsFreePlayStatsProvider.future);
    return _freshState();
  }

  GroupsGameState _freshState() {
    final pool = _bank.puzzles;
    GroupsPuzzle puzzle;
    do {
      puzzle = pool[_random.nextInt(pool.length)];
    } while (identical(puzzle, _lastPuzzle) && pool.length > 1);
    _lastPuzzle = puzzle;

    final order = List<String>.of(puzzle.allWordTexts)..shuffle(_shuffleRandom);
    return GroupsGameState.initial(puzzle, tileOrder: order);
  }

  /// Starts a new random puzzle, discarding the current one.
  void newPuzzle() {
    state = AsyncData(_freshState());
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
      // Streak is still "did you play today", independent of how many
      // puzzles that was — free play removes the one-per-day cap, not the
      // reason to come back daily.
      await _stats.recordCompletion(
        dayIndex: DailySeed.todayIndex(),
        solved: next.status == GroupsStatus.solved,
        mistakes: next.mistakes,
      );
      if (next.status == GroupsStatus.solved) {
        await _freePlayStats.recordSolve('all', next.mistakes);
      }
      ref.invalidate(groupsStatsProvider);
      ref.invalidate(groupsFreePlayStatsProvider);
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
