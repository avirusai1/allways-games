import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/isar_provider.dart';
import '../../../core/stats/free_play_stats.dart';
import '../data/domino_stats_repository.dart';
import '../domain/domino_game_state.dart';
import '../domain/domino_puzzle.dart';
import '../generation/domino_content_bank.dart';

final dominoContentBankProvider = FutureProvider<DominoContentBank>((ref) {
  return DominoContentBank.load();
});

final dominoStatsRepositoryProvider =
    FutureProvider<DominoStatsRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return DominoStatsRepository(isar);
});

final dominoStatsProvider = FutureProvider<DominoGameStats>((ref) async {
  final repo = await ref.watch(dominoStatsRepositoryProvider.future);
  return repo.loadStats();
});

final dominoFreePlayStatsProvider = FutureProvider<FreePlayStats>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return FreePlayStats('dot_dominoes', prefs);
});

/// Drives Dot Dominoes as free play: the player picks a size/difficulty
/// tier, solves as many puzzles of it as they like, and can switch tiers
/// at any time.
///
/// [state] is null while no puzzle is active — the screen reads that as
/// "show the difficulty picker".
class DominoGameController extends AsyncNotifier<DominoGameState?> {
  late DominoContentBank _bank;
  late DominoStatsRepository _stats;
  late FreePlayStats _freePlayStats;
  final Random _random = Random();
  DominoPuzzle? _lastPuzzle;
  Timer? _timer;

  @override
  Future<DominoGameState?> build() async {
    _bank = await ref.watch(dominoContentBankProvider.future);
    _stats = await ref.watch(dominoStatsRepositoryProvider.future);
    _freePlayStats = await ref.watch(dominoFreePlayStatsProvider.future);
    ref.onDispose(() => _timer?.cancel());
    return null; // No difficulty chosen yet.
  }

  /// Starts a fresh puzzle with [dominoCount] dominoes, drawn at random
  /// from the bank.
  void selectDifficulty(int dominoCount) {
    final pool = _bank.puzzlesOfSize(dominoCount);
    if (pool.isEmpty) return;

    DominoPuzzle puzzle;
    do {
      puzzle = pool[_random.nextInt(pool.length)];
    } while (identical(puzzle, _lastPuzzle) && pool.length > 1);
    _lastPuzzle = puzzle;

    _startTimer();
    state = AsyncData(DominoGameState.initial(puzzle));
  }

  /// Back to the difficulty picker without recording anything.
  void changeDifficulty() {
    _timer?.cancel();
    state = const AsyncData(null);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = state.valueOrNull;
      if (current == null || !current.isPlaying) return;
      state = AsyncData(
        current.copyWith(elapsedSeconds: current.elapsedSeconds + 1),
      );
    });
  }

  void selectTray(int index) {
    final current = state.valueOrNull;
    if (current == null || !current.isPlaying) return;
    state = AsyncData(current.selectTray(index));
  }

  /// Places the held domino, or lifts one already on the board.
  Future<DominoPlaceOutcome?> tapCell(int cell, int? neighbour) async {
    final current = state.valueOrNull;
    if (current == null || !current.isPlaying) return null;

    if (current.pipsByCell.containsKey(cell)) {
      state = AsyncData(current.removeAt(cell));
      return null;
    }
    if (neighbour == null) return null;

    final result = current.place(cell, neighbour);
    if (result.outcome != DominoPlaceOutcome.placed) return result.outcome;

    state = AsyncData(result.state);
    if (result.state.status == DominoStatus.solved) {
      await _onSolved(result.state);
    }
    return result.outcome;
  }

  Future<void> _onSolved(DominoGameState solved) async {
    _timer?.cancel();

    // Streak is still "did you play today", independent of how many
    // puzzles that was — free play removes the one-per-day cap, not the
    // reason to come back daily.
    await _stats.recordCompletion(
      dayIndex: DailySeed.todayIndex(),
      won: true,
      elapsedSeconds: solved.elapsedSeconds,
    );
    await _freePlayStats.recordSolve(
      solved.puzzle.tray.length.toString(),
      solved.elapsedSeconds,
    );
    ref.invalidate(dominoStatsProvider);
    ref.invalidate(dominoFreePlayStatsProvider);
  }

  void clearBoard() {
    final current = state.valueOrNull;
    if (current == null || !current.isPlaying) return;
    state = AsyncData(current.copyWith(placed: const [], clearSelection: true));
  }
}

final dominoGameControllerProvider =
    AsyncNotifierProvider<DominoGameController, DominoGameState?>(
  DominoGameController.new,
);
