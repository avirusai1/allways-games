import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/isar_provider.dart';
import '../../../core/stats/free_play_stats.dart';
import '../data/tile_match_stats_repository.dart';
import '../domain/tile_layout.dart';
import '../domain/tile_match_game_state.dart';
import '../domain/tile_match_puzzle.dart';
import '../generation/tile_match_content_bank.dart';

final tileMatchContentBankProvider =
    FutureProvider<TileMatchContentBank>((ref) {
  return TileMatchContentBank.load();
});

final tileMatchStatsRepositoryProvider =
    FutureProvider<TileMatchStatsRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return TileMatchStatsRepository(isar);
});

final tileMatchStatsProvider = FutureProvider<TileMatchGameStats>((ref) async {
  final repo = await ref.watch(tileMatchStatsRepositoryProvider.future);
  return repo.loadStats();
});

final tileMatchFreePlayStatsProvider = FutureProvider<FreePlayStats>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return FreePlayStats('tile_match', prefs);
});

/// Drives Tile Match as free play: the player picks a board size, clears
/// (or gets stuck on) as many boards of it as they like, and can switch
/// size at any time.
///
/// [state] is null while no board is active — the screen reads that as
/// "show the difficulty picker".
class TileMatchGameController extends AsyncNotifier<TileMatchGameState?> {
  late TileMatchContentBank _bank;
  late TileMatchStatsRepository _stats;
  late FreePlayStats _freePlayStats;
  final Random _random = Random();
  TileMatchPuzzle? _lastPuzzle;
  Timer? _timer;

  @override
  Future<TileMatchGameState?> build() async {
    _bank = await ref.watch(tileMatchContentBankProvider.future);
    _stats = await ref.watch(tileMatchStatsRepositoryProvider.future);
    _freePlayStats = await ref.watch(tileMatchFreePlayStatsProvider.future);
    ref.onDispose(() => _timer?.cancel());
    return null; // No board size chosen yet.
  }

  /// Starts a fresh board on [layoutName], drawn at random from the bank.
  void selectDifficulty(String layoutName) {
    final pool = _bank.puzzlesOfLayout(layoutName);
    if (pool.isEmpty) return;

    TileMatchPuzzle puzzle;
    do {
      puzzle = pool[_random.nextInt(pool.length)];
    } while (identical(puzzle, _lastPuzzle) && pool.length > 1);
    _lastPuzzle = puzzle;

    _startClock();
    state = AsyncData(TileMatchGameState.initial(puzzle));
  }

  /// Back to the difficulty picker without recording anything.
  void changeDifficulty() {
    _timer?.cancel();
    state = const AsyncData(null);
  }

  void _startClock() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = state.valueOrNull;
      if (current == null) return;
      if (!current.isPlaying) {
        _timer?.cancel();
        return;
      }
      state = AsyncData(current.tick());
    });
  }

  void tapTile(TileSlot slot) => _apply((s) => s.tap(slot));

  void undo() => _apply((s) => s.undo());

  /// Selects one half of an available pair, so the player is shown where to
  /// look rather than having the move made for them.
  void hint() {
    _apply((s) {
      final move = s.hint();
      return move == null ? s : s.copyWith(selected: move.$1);
    });
  }

  void _apply(TileMatchGameState Function(TileMatchGameState) transition) {
    final current = state.valueOrNull;
    if (current == null) return;
    final next = transition(current);
    if (identical(next, current)) return;
    state = AsyncData(next);
    if (current.isPlaying && !next.isPlaying) {
      unawaited(_finish(next));
    } else if (!current.isPlaying && next.isPlaying) {
      // Undoing out of a dead board puts the player back in the game, so
      // the clock has to start again — otherwise the rest of the board is
      // played for free.
      _startClock();
    }
  }

  Future<void> _finish(TileMatchGameState finished) async {
    _timer?.cancel();
    final cleared = finished.status == TileMatchStatus.cleared;

    // Streak is still "did you play today", independent of how many boards
    // that was — free play removes the one-per-day cap, not the reason to
    // come back daily.
    await _stats.recordCompletion(
      dayIndex: DailySeed.todayIndex(),
      cleared: cleared,
      elapsedSeconds: finished.elapsedSeconds,
    );
    if (cleared) {
      await _freePlayStats.recordSolve(
        finished.puzzle.layout.name,
        finished.elapsedSeconds,
      );
    }
    ref.invalidate(tileMatchStatsProvider);
    ref.invalidate(tileMatchFreePlayStatsProvider);
  }
}

final tileMatchGameControllerProvider =
    AsyncNotifierProvider<TileMatchGameController, TileMatchGameState?>(
  TileMatchGameController.new,
);
