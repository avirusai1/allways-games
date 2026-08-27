import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/isar_provider.dart';
import '../data/crossword_stats_repository.dart';
import '../domain/crossword_game_state.dart';
import '../domain/crossword_grid.dart';
import '../generation/crossword_content_bank.dart';

final crosswordContentBankProvider =
    FutureProvider<CrosswordContentBank>((ref) {
  return CrosswordContentBank.load();
});

final crosswordStatsRepositoryProvider =
    FutureProvider<CrosswordStatsRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return CrosswordStatsRepository(isar);
});

final crosswordStatsProvider = FutureProvider<CrosswordGameStats>((ref) async {
  final repo = await ref.watch(crosswordStatsRepositoryProvider.future);
  return repo.loadStats();
});

class CrosswordGameController extends AsyncNotifier<CrosswordGameState> {
  late CrosswordStatsRepository _stats;
  late int _dayIndex;
  Timer? _timer;

  @override
  Future<CrosswordGameState> build() async {
    final bank = await ref.watch(crosswordContentBankProvider.future);
    _stats = await ref.watch(crosswordStatsRepositoryProvider.future);
    _dayIndex = DailySeed.todayIndex();
    final puzzle = bank.puzzleForDayIndex(_dayIndex);

    ref.onDispose(() => _timer?.cancel());

    final existing = await _stats.completionForDay(_dayIndex);
    if (existing != null && existing.won) {
      return CrosswordGameState.initial(puzzle).copyWith(
        entered: List<String>.from(puzzle.solution),
        elapsedSeconds: existing.elapsedSeconds ?? 0,
      );
    }

    _startTimer();
    return CrosswordGameState.initial(puzzle);
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

  /// Tapping the selected cell again flips between across and down, which
  /// is how a crossword is normally navigated on a touch screen.
  void selectCell(int index) {
    final current = state.valueOrNull;
    if (current == null || !current.isPlaying) return;
    if (current.puzzle.blocked[index]) return;

    if (current.selectedCell == index) {
      state = AsyncData(current.copyWith(
        direction: current.direction == CrosswordDirection.across
            ? CrosswordDirection.down
            : CrosswordDirection.across,
      ));
      return;
    }
    state = AsyncData(current.copyWith(selectedCell: index));
  }

  void toggleDirection() {
    final current = state.valueOrNull;
    if (current == null || !current.isPlaying) return;
    state = AsyncData(current.copyWith(
      direction: current.direction == CrosswordDirection.across
          ? CrosswordDirection.down
          : CrosswordDirection.across,
    ));
  }

  Future<void> enterLetter(String letter) async {
    final current = state.valueOrNull;
    if (current == null || !current.isPlaying) return;

    final entered = List<String>.from(current.entered)
      ..[current.selectedCell] = letter.toUpperCase();
    final next = current.copyWith(
      entered: entered,
      selectedCell: current.nextCellInEntry() ?? current.selectedCell,
    );
    state = AsyncData(next);

    if (next.status == CrosswordStatus.solved) await _onSolved(next);
  }

  void backspace() {
    final current = state.valueOrNull;
    if (current == null || !current.isPlaying) return;

    final entered = List<String>.from(current.entered);
    if (entered[current.selectedCell].isNotEmpty) {
      entered[current.selectedCell] = '';
      state = AsyncData(current.copyWith(entered: entered));
      return;
    }
    // Already empty: step back and clear that one instead.
    final previous = current.previousCellInEntry();
    if (previous == null) return;
    entered[previous] = '';
    state = AsyncData(
      current.copyWith(entered: entered, selectedCell: previous),
    );
  }

  /// Fills the selected cell from the solution.
  Future<void> revealCell() async {
    final current = state.valueOrNull;
    if (current == null || !current.isPlaying) return;

    final index = current.selectedCell;
    final entered = List<String>.from(current.entered)
      ..[index] = current.puzzle.solution[index];
    final next = current.copyWith(
      entered: entered,
      revealedCells: {...current.revealedCells, index},
      selectedCell: current.nextCellInEntry() ?? index,
    );
    state = AsyncData(next);

    if (next.status == CrosswordStatus.solved) await _onSolved(next);
  }

  Future<void> _onSolved(CrosswordGameState solved) async {
    _timer?.cancel();
    await _stats.recordCompletion(
      dayIndex: _dayIndex,
      won: true,
      elapsedSeconds: solved.elapsedSeconds,
    );
    ref.invalidate(crosswordStatsProvider);
  }
}

final crosswordGameControllerProvider =
    AsyncNotifierProvider<CrosswordGameController, CrosswordGameState>(
  CrosswordGameController.new,
);
