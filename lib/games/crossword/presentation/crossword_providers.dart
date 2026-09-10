import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/isar_provider.dart';
import '../../../core/stats/free_play_stats.dart';
import '../data/crossword_stats_repository.dart';
import '../domain/crossword_game_state.dart';
import '../domain/crossword_grid.dart';
import '../domain/crossword_puzzle.dart';
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

final crosswordFreePlayStatsProvider = FutureProvider<FreePlayStats>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return FreePlayStats('crossword', prefs);
});

/// Drives Crossword as free play: the player picks a difficulty, solves as
/// many grids of it as they like, and can switch difficulty at any time.
///
/// [state] is null while no grid is active — the screen reads that as
/// "show the difficulty picker".
class CrosswordGameController extends AsyncNotifier<CrosswordGameState?> {
  late CrosswordContentBank _bank;
  late CrosswordStatsRepository _stats;
  late FreePlayStats _freePlayStats;
  final Random _random = Random();
  CrosswordPuzzle? _lastPuzzle;
  CrosswordDifficulty? _currentDifficulty;
  Timer? _timer;

  /// The tier the active grid was drawn from — null before any difficulty
  /// is chosen.
  CrosswordDifficulty? get currentDifficulty => _currentDifficulty;

  @override
  Future<CrosswordGameState?> build() async {
    _bank = await ref.watch(crosswordContentBankProvider.future);
    _stats = await ref.watch(crosswordStatsRepositoryProvider.future);
    _freePlayStats = await ref.watch(crosswordFreePlayStatsProvider.future);
    ref.onDispose(() => _timer?.cancel());
    return null; // No difficulty chosen yet.
  }

  /// Starts a fresh grid of [difficulty], drawn at random from the bank.
  void selectDifficulty(CrosswordDifficulty difficulty) {
    final pool = _bank.puzzlesOfDifficulty(difficulty);
    if (pool.isEmpty) return;

    CrosswordPuzzle puzzle;
    do {
      puzzle = pool[_random.nextInt(pool.length)];
    } while (identical(puzzle, _lastPuzzle) && pool.length > 1);
    _lastPuzzle = puzzle;
    _currentDifficulty = difficulty;

    _startTimer();
    state = AsyncData(CrosswordGameState.initial(puzzle));
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

    // Streak is still "did you play today", independent of how many grids
    // that was — free play removes the one-per-day cap, not the reason to
    // come back daily.
    await _stats.recordCompletion(
      dayIndex: DailySeed.todayIndex(),
      won: true,
      elapsedSeconds: solved.elapsedSeconds,
    );
    if (_currentDifficulty != null) {
      await _freePlayStats.recordSolve(
        _currentDifficulty!.name,
        solved.elapsedSeconds,
      );
    }
    ref.invalidate(crosswordStatsProvider);
    ref.invalidate(crosswordFreePlayStatsProvider);
  }
}

final crosswordGameControllerProvider =
    AsyncNotifierProvider<CrosswordGameController, CrosswordGameState?>(
  CrosswordGameController.new,
);
