import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/isar_provider.dart';
import '../../../core/stats/free_play_stats.dart';
import '../data/honeycomb_repository.dart';
import '../domain/honeycomb_game_state.dart';
import '../domain/honeycomb_puzzle.dart';
import '../generation/honeycomb_content_bank.dart';

final honeycombContentBankProvider = FutureProvider<HoneycombContentBank>((ref) {
  return HoneycombContentBank.load();
});

final honeycombRepositoryProvider =
    FutureProvider<HoneycombRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return HoneycombRepository(isar);
});

final honeycombStatsProvider = FutureProvider<HoneycombGameStats>((ref) async {
  final repo = await ref.watch(honeycombRepositoryProvider.future);
  return repo.loadStats();
});

final honeycombFreePlayStatsProvider = FutureProvider<FreePlayStats>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return FreePlayStats('honeycomb', prefs);
});

/// Drives Honeycomb as free play: the player picks a difficulty and works
/// through as many boards of it as they like, switching at any time.
///
/// [state] is null while no board is active — the screen reads that as
/// "show the difficulty picker". Unlike the timed games, a board here has
/// no natural end (finding every word is out of reach on most boards), so
/// there is no "solved" transition to a result sheet the way Sudoku or
/// Word Loop has — the player just keeps going, or taps the tune icon for
/// a new board.
class HoneycombGameController extends AsyncNotifier<HoneycombGameState?> {
  late HoneycombContentBank _bank;
  late HoneycombRepository _repository;
  late FreePlayStats _freePlayStats;
  final Random _random = Random();
  final Random _shuffleRandom = Random();
  HoneycombPuzzle? _lastPuzzle;
  HoneycombDifficulty? _currentDifficulty;

  /// The tier the active board was drawn from — null before any difficulty
  /// is chosen.
  HoneycombDifficulty? get currentDifficulty => _currentDifficulty;

  @override
  Future<HoneycombGameState?> build() async {
    _bank = await ref.watch(honeycombContentBankProvider.future);
    _repository = await ref.watch(honeycombRepositoryProvider.future);
    _freePlayStats = await ref.watch(honeycombFreePlayStatsProvider.future);
    return null; // No difficulty chosen yet.
  }

  /// Starts a fresh board of [difficulty], drawn at random from the bank.
  void selectDifficulty(HoneycombDifficulty difficulty) {
    final pool = _bank.puzzlesOfDifficulty(difficulty);
    if (pool.isEmpty) return;

    HoneycombPuzzle puzzle;
    do {
      puzzle = pool[_random.nextInt(pool.length)];
    } while (identical(puzzle, _lastPuzzle) && pool.length > 1);
    _lastPuzzle = puzzle;
    _currentDifficulty = difficulty;

    state = AsyncData(HoneycombGameState.initial(puzzle));
  }

  /// Back to the difficulty picker without losing today's streak progress
  /// (already saved after every accepted word).
  void changeDifficulty() {
    state = const AsyncData(null);
  }

  void inputLetter(String letter) => _apply((s) => s.inputLetter(letter));

  void backspace() => _apply((s) => s.backspace());

  void clearInput() => _apply((s) => s.clearInput());

  void shuffleLetters() {
    _apply((s) {
      final order = List<String>.of(s.outerLetterOrder)..shuffle(_shuffleRandom);
      return s.shuffleOuterLetters(order);
    });
  }

  /// Submits the current input, returning why it was refused or null when
  /// the word was accepted.
  Future<HoneycombRejection?> submit() async {
    final current = state.valueOrNull;
    if (current == null) return null;

    final result = current.submit();
    if (result.rejection != null) return result.rejection;

    state = AsyncData(result.state);

    // Streak is still "did you reach the goal rank today", independent of
    // which specific board that was on — free play removes the
    // one-board-per-day cap, not the reason to come back daily.
    await _repository.recordSession(
      dayIndex: DailySeed.todayIndex(),
      score: result.state.score,
      maxScore: result.state.maxScore,
    );
    ref.invalidate(honeycombStatsProvider);

    if (result.state.isComplete && _currentDifficulty != null) {
      await _freePlayStats.recordSolve(
        _currentDifficulty!.name,
        result.state.score,
        higherIsBetter: true,
      );
      ref.invalidate(honeycombFreePlayStatsProvider);
    }
    return null;
  }

  void _apply(HoneycombGameState Function(HoneycombGameState) transition) {
    final current = state.valueOrNull;
    if (current == null) return;
    final next = transition(current);
    if (identical(next, current)) return;
    state = AsyncData(next);
  }
}

final honeycombGameControllerProvider =
    AsyncNotifierProvider<HoneycombGameController, HoneycombGameState?>(
  HoneycombGameController.new,
);
