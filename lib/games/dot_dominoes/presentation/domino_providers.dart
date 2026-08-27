import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/isar_provider.dart';
import '../data/domino_stats_repository.dart';
import '../domain/domino_game_state.dart';
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

class DominoGameController extends AsyncNotifier<DominoGameState> {
  late DominoStatsRepository _stats;
  late int _dayIndex;
  Timer? _timer;

  @override
  Future<DominoGameState> build() async {
    final bank = await ref.watch(dominoContentBankProvider.future);
    _stats = await ref.watch(dominoStatsRepositoryProvider.future);
    _dayIndex = DailySeed.todayIndex();
    final puzzle = bank.puzzleForDayIndex(_dayIndex);

    ref.onDispose(() => _timer?.cancel());

    final existing = await _stats.completionForDay(_dayIndex);
    if (existing != null && existing.won) {
      return DominoGameState.initial(puzzle).copyWith(
        placed: puzzle.solution,
        elapsedSeconds: existing.elapsedSeconds ?? 0,
      );
    }

    _startTimer();
    return DominoGameState.initial(puzzle);
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
    await _stats.recordCompletion(
      dayIndex: _dayIndex,
      won: true,
      elapsedSeconds: solved.elapsedSeconds,
    );
    ref.invalidate(dominoStatsProvider);
  }

  void clearBoard() {
    final current = state.valueOrNull;
    if (current == null || !current.isPlaying) return;
    state = AsyncData(current.copyWith(placed: const [], clearSelection: true));
  }
}

final dominoGameControllerProvider =
    AsyncNotifierProvider<DominoGameController, DominoGameState>(
  DominoGameController.new,
);
