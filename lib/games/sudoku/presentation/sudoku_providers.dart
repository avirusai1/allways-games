import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/isar_provider.dart';
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

/// Drives one day's Sudoku: cell selection, digit entry, pencil notes, the
/// play timer, and persisting the result on completion.
class SudokuGameController extends AsyncNotifier<SudokuGameState> {
  late SudokuStatsRepository _stats;
  late int _dayIndex;
  Timer? _timer;

  @override
  Future<SudokuGameState> build() async {
    final bank = await ref.watch(sudokuContentBankProvider.future);
    _stats = await ref.watch(sudokuStatsRepositoryProvider.future);
    _dayIndex = DailySeed.todayIndex();
    final puzzle = bank.puzzleForDayIndex(_dayIndex);

    ref.onDispose(() => _timer?.cancel());

    final existing = await _stats.completionForDay(_dayIndex);
    if (existing != null && existing.won) {
      // Already solved today: show the completed board rather than a
      // partially-filled one (per-cell progress isn't persisted in v1).
      return SudokuGameState.initial(puzzle).copyWith(
        entries: List<int>.from(puzzle.solution),
        status: SudokuStatus.solved,
        elapsedSeconds: existing.elapsedSeconds ?? 0,
      );
    }

    _startTimer();
    return SudokuGameState.initial(puzzle);
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
    state = AsyncData(
      current.selectedIndex == index
          ? current.copyWith(clearSelection: true)
          : current.copyWith(selectedIndex: index),
    );
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
    await _stats.recordCompletion(
      dayIndex: _dayIndex,
      won: true,
      elapsedSeconds: solvedState.elapsedSeconds,
    );
    ref.invalidate(sudokuStatsProvider);
  }

  static List<Set<int>> _copyNotes(List<Set<int>> notes) =>
      notes.map((s) => Set<int>.from(s)).toList();
}

final sudokuGameControllerProvider =
    AsyncNotifierProvider<SudokuGameController, SudokuGameState>(
  SudokuGameController.new,
);
