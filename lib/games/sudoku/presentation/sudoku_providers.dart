import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/isar_provider.dart';
import '../../../core/stats/free_play_stats.dart';
import '../data/sudoku_stats_repository.dart';
import '../domain/sudoku_board.dart';
import '../domain/sudoku_game_state.dart';
import '../generation/sudoku_content_bank.dart';

final sudokuContentBankProvider = FutureProvider<SudokuContentBank>((ref) {
  return SudokuContentBank.load();
});

final sudokuStatsRepositoryProvider =
    FutureProvider<SudokuStatsRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return SudokuStatsRepository(isar);
});

final sudokuStatsProvider = FutureProvider<SudokuGameStats>((ref) async {
  final repo = await ref.watch(sudokuStatsRepositoryProvider.future);
  return repo.loadStats();
});

final sudokuFreePlayStatsProvider = FutureProvider<FreePlayStats>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return FreePlayStats('sudoku', prefs);
});

/// Drives Sudoku as free play: the player picks a difficulty, solves as
/// many puzzles of it as they like, and can switch difficulty at any time.
///
/// [state] is null while no puzzle is active — the screen reads that as
/// "show the difficulty picker" rather than modelling picker-vs-playing as
/// two separate provider types.
class SudokuGameController extends AsyncNotifier<SudokuGameState?> {
  late SudokuContentBank _bank;
  late SudokuStatsRepository _stats;
  late FreePlayStats _freePlayStats;
  final Random _random = Random();
  SudokuPuzzle? _lastPuzzle;
  Timer? _timer;

  @override
  Future<SudokuGameState?> build() async {
    _bank = await ref.watch(sudokuContentBankProvider.future);
    _stats = await ref.watch(sudokuStatsRepositoryProvider.future);
    _freePlayStats = await ref.watch(sudokuFreePlayStatsProvider.future);
    ref.onDispose(() => _timer?.cancel());
    return null; // No difficulty chosen yet.
  }

  /// Starts a fresh puzzle of [difficulty], drawn at random from the bank.
  void selectDifficulty(SudokuDifficulty difficulty) {
    final pool = _bank.puzzlesOfDifficulty(difficulty);
    if (pool.isEmpty) return;

    SudokuPuzzle puzzle;
    do {
      puzzle = pool[_random.nextInt(pool.length)];
    } while (identical(puzzle, _lastPuzzle) && pool.length > 1);
    _lastPuzzle = puzzle;

    _startTimer();
    state = AsyncData(SudokuGameState.initial(puzzle));
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

  void selectCell(int index) {
    final current = state.valueOrNull;
    if (current == null || !current.isPlaying) return;

    if (current.selectedIndex == index) {
      state = AsyncData(current.copyWith(clearSelection: true));
      return;
    }
    state = AsyncData(current.copyWith(selectedIndex: index));
  }

  void toggleNotesMode() {
    final current = state.valueOrNull;
    if (current == null || !current.isPlaying) return;
    state = AsyncData(current.copyWith(notesMode: !current.notesMode));
  }

  Future<void> enterDigit(int digit) async {
    final current = state.valueOrNull;
    final index = current?.selectedIndex;
    if (current == null || index == null || !current.isPlaying) return;
    if (current.isGiven(index)) return;

    if (current.notesMode) {
      final notes = _copyNotes(current.notes);
      notes[index].contains(digit)
          ? notes[index].remove(digit)
          : notes[index].add(digit);
      state = AsyncData(current.copyWith(notes: notes));
      return;
    }

    final entries = List<int>.from(current.entries);
    // Tapping the digit already in the cell clears it.
    entries[index] = entries[index] == digit ? emptyCell : digit;

    final notes = _copyNotes(current.notes)..[index].clear();

    final next = current.copyWith(entries: entries, notes: notes);
    state = AsyncData(next);

    if (isComplete(entries)) {
      await _onSolved(next);
    }
  }

  Future<void> clearCell() async {
    final current = state.valueOrNull;
    final index = current?.selectedIndex;
    if (current == null || index == null || !current.isPlaying) return;
    if (current.isGiven(index)) return;

    final entries = List<int>.from(current.entries)..[index] = emptyCell;
    final notes = _copyNotes(current.notes)..[index].clear();
    state = AsyncData(current.copyWith(entries: entries, notes: notes));
  }

  Future<void> _onSolved(SudokuGameState solvedState) async {
    _timer?.cancel();
    state = AsyncData(
      solvedState.copyWith(status: SudokuStatus.solved, clearSelection: true),
    );

    // Streak is still "did you play today", independent of how many
    // puzzles that was — free play removes the one-per-day cap, not the
    // reason to come back daily.
    await _stats.recordCompletion(
      dayIndex: DailySeed.todayIndex(),
      won: true,
      elapsedSeconds: solvedState.elapsedSeconds,
    );
    await _freePlayStats.recordSolve(
      solvedState.puzzle.difficulty.name,
      solvedState.elapsedSeconds,
    );
    ref.invalidate(sudokuStatsProvider);
    ref.invalidate(sudokuFreePlayStatsProvider);
  }

  static List<Set<int>> _copyNotes(List<Set<int>> notes) =>
      notes.map((s) => Set<int>.from(s)).toList();
}

final sudokuGameControllerProvider =
    AsyncNotifierProvider<SudokuGameController, SudokuGameState?>(
  SudokuGameController.new,
);
