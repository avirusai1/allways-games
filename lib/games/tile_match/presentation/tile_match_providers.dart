import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/isar_provider.dart';
import '../data/tile_match_stats_repository.dart';
import '../domain/tile_layout.dart';
import '../domain/tile_match_game_state.dart';
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

/// Drives one day's Tile Match board.
class TileMatchGameController extends AsyncNotifier<TileMatchGameState> {
  late TileMatchStatsRepository _stats;
  late int _dayIndex;
  Timer? _timer;

  @override
  Future<TileMatchGameState> build() async {
    final bank = await ref.watch(tileMatchContentBankProvider.future);
    _stats = await ref.watch(tileMatchStatsRepositoryProvider.future);
    _dayIndex = DailySeed.todayIndex();

    final puzzle = bank.puzzleForDayIndex(_dayIndex);
    final initial = TileMatchGameState.initial(puzzle);

    final existing = await _stats.completionForDay(_dayIndex);
    if (existing != null) {
      return initial.copyWith(
        // A cleared day shows an empty board; a day that ended stuck is
        // left as it was rather than replayed for a better result.
        remaining: existing.won ? <TileSlot>{} : initial.remaining,
        elapsedSeconds: existing.elapsedSeconds ?? 0,
      );
    }

    _startClock();
    ref.onDispose(() => _timer?.cancel());
    return initial;
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
    await _stats.recordCompletion(
      dayIndex: _dayIndex,
      cleared: finished.status == TileMatchStatus.cleared,
      elapsedSeconds: finished.elapsedSeconds,
    );
    ref.invalidate(tileMatchStatsProvider);
  }
}

final tileMatchGameControllerProvider =
    AsyncNotifierProvider<TileMatchGameController, TileMatchGameState>(
  TileMatchGameController.new,
);
