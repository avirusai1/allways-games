import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/isar_provider.dart';
import '../../../core/stats/free_play_stats.dart';
import '../data/weave_stats_repository.dart';
import '../domain/weave_game_state.dart';
import '../domain/weave_puzzle.dart';
import '../generation/weave_content_bank.dart';

final weaveContentBankProvider = FutureProvider<WeaveContentBank>((ref) {
  return WeaveContentBank.load();
});

final weaveStatsRepositoryProvider =
    FutureProvider<WeaveStatsRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return WeaveStatsRepository(isar);
});

final weaveStatsProvider = FutureProvider<WeaveGameStats>((ref) async {
  final repo = await ref.watch(weaveStatsRepositoryProvider.future);
  return repo.loadStats();
});

final weaveFreePlayStatsProvider = FutureProvider<FreePlayStats>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return FreePlayStats('weave', prefs);
});

/// Drives Weave as free play: the player picks a difficulty, weaves
/// through as many grids of it as they like, and can switch difficulty at
/// any time.
///
/// [state] is null while no grid is active — the screen reads that as
/// "show the difficulty picker".
class WeaveGameController extends AsyncNotifier<WeaveGameState?> {
  late WeaveContentBank _bank;
  late WeaveStatsRepository _stats;
  late FreePlayStats _freePlayStats;
  final Random _random = Random();
  WeavePuzzle? _lastPuzzle;
  WeaveDifficulty? _currentDifficulty;

  /// The tier the active grid was drawn from — null before any difficulty
  /// is chosen.
  WeaveDifficulty? get currentDifficulty => _currentDifficulty;

  @override
  Future<WeaveGameState?> build() async {
    _bank = await ref.watch(weaveContentBankProvider.future);
    _stats = await ref.watch(weaveStatsRepositoryProvider.future);
    _freePlayStats = await ref.watch(weaveFreePlayStatsProvider.future);
    return null; // No difficulty chosen yet.
  }

  /// Starts a fresh grid of [difficulty], drawn at random from the bank.
  void selectDifficulty(WeaveDifficulty difficulty) {
    final pool = _bank.puzzlesOfDifficulty(difficulty);
    if (pool.isEmpty) return;

    WeavePuzzle puzzle;
    do {
      puzzle = pool[_random.nextInt(pool.length)];
    } while (identical(puzzle, _lastPuzzle) && pool.length > 1);
    _lastPuzzle = puzzle;
    _currentDifficulty = difficulty;

    state = AsyncData(WeaveGameState.initial(puzzle));
  }

  /// Back to the difficulty picker without recording anything.
  void changeDifficulty() {
    state = const AsyncData(null);
  }

  /// Submits a traced word. Returns the outcome so the screen can say what
  /// happened without duplicating the rules.
  Future<WeaveTraceResult?> submit(String word) async {
    final current = state.valueOrNull;
    if (current == null || !current.isPlaying) return null;

    final result = current.trace(word);
    if (identical(result.state, current)) return result;

    state = AsyncData(result.state);

    if (result.state.status == WeaveStatus.solved) {
      // Streak is still "did you play today", independent of how many
      // grids that was — free play removes the one-per-day cap, not the
      // reason to come back daily.
      await _stats.recordCompletion(dayIndex: DailySeed.todayIndex(), won: true);
      if (_currentDifficulty != null) {
        await _freePlayStats.recordSolve(
          _currentDifficulty!.name,
          result.state.hintsSpent,
        );
      }
      ref.invalidate(weaveStatsProvider);
      ref.invalidate(weaveFreePlayStatsProvider);
    }
    return result;
  }

  void useHint() {
    final current = state.valueOrNull;
    if (current == null || !current.isPlaying) return;
    state = AsyncData(current.useHint());
  }
}

final weaveGameControllerProvider =
    AsyncNotifierProvider<WeaveGameController, WeaveGameState?>(
  WeaveGameController.new,
);
