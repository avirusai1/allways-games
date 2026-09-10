import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/isar_provider.dart';
import '../../../core/stats/free_play_stats.dart';
import '../data/word_loop_stats_repository.dart';
import '../domain/word_loop_game_state.dart';
import '../domain/word_loop_puzzle.dart';
import '../generation/word_loop_content_bank.dart';

final wordLoopContentBankProvider = FutureProvider<WordLoopContentBank>((ref) {
  return WordLoopContentBank.load();
});

final wordLoopStatsRepositoryProvider =
    FutureProvider<WordLoopStatsRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return WordLoopStatsRepository(isar);
});

final wordLoopStatsProvider = FutureProvider<WordLoopGameStats>((ref) async {
  final repo = await ref.watch(wordLoopStatsRepositoryProvider.future);
  return repo.loadStats();
});

final wordLoopFreePlayStatsProvider = FutureProvider<FreePlayStats>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return FreePlayStats('word_loop', prefs);
});

/// Drives Word Loop as free play: the player picks a difficulty, chains
/// through as many boards of it as they like, and can switch difficulty at
/// any time.
///
/// [state] is null while no board is active — the screen reads that as
/// "show the difficulty picker".
class WordLoopGameController extends AsyncNotifier<WordLoopGameState?> {
  late WordLoopContentBank _bank;
  late WordLoopStatsRepository _stats;
  late FreePlayStats _freePlayStats;
  final Random _random = Random();
  WordLoopPuzzle? _lastPuzzle;
  WordLoopDifficulty? _currentDifficulty;

  /// The tier the active board was drawn from, for the result sheet's
  /// "Play another" and stats lookup — null before any difficulty is
  /// chosen.
  WordLoopDifficulty? get currentDifficulty => _currentDifficulty;

  @override
  Future<WordLoopGameState?> build() async {
    _bank = await ref.watch(wordLoopContentBankProvider.future);
    _stats = await ref.watch(wordLoopStatsRepositoryProvider.future);
    _freePlayStats = await ref.watch(wordLoopFreePlayStatsProvider.future);
    return null; // No difficulty chosen yet.
  }

  /// Starts a fresh board of [difficulty], drawn at random from the bank.
  void selectDifficulty(WordLoopDifficulty difficulty) {
    final pool = _bank.puzzlesOfDifficulty(difficulty);
    if (pool.isEmpty) return;

    WordLoopPuzzle puzzle;
    do {
      puzzle = pool[_random.nextInt(pool.length)];
    } while (identical(puzzle, _lastPuzzle) && pool.length > 1);
    _lastPuzzle = puzzle;
    _currentDifficulty = difficulty;

    state = AsyncData(WordLoopGameState.initial(puzzle));
  }

  /// Back to the difficulty picker without recording anything.
  void changeDifficulty() {
    state = const AsyncData(null);
  }

  void inputLetter(String letter) => _apply((s) => s.inputLetter(letter));

  void backspace() => _apply((s) => s.backspace());

  void clearInput() => _apply((s) => s.clearInput());

  void undoWord() => _apply((s) => s.undoWord());

  /// Plays the current input, returning why it was refused, or null when
  /// the word was accepted.
  Future<WordLoopRejection?> submit() async {
    final current = state.valueOrNull;
    if (current == null || !current.isPlaying) return null;

    final result = current.submit();
    if (result.rejection != null) return result.rejection;

    state = AsyncData(result.state);
    if (!result.state.isPlaying) {
      // Streak is still "did you play today", independent of how many
      // boards that was — free play removes the one-per-day cap, not the
      // reason to come back daily.
      await _stats.recordCompletion(
        dayIndex: DailySeed.todayIndex(),
        wordsUsed: result.state.wordsUsed,
      );
      await _freePlayStats.recordSolve(
        (_currentDifficulty ?? WordLoopDifficulty.medium).name,
        result.state.wordsUsed,
      );
      ref.invalidate(wordLoopStatsProvider);
      ref.invalidate(wordLoopFreePlayStatsProvider);
    }
    return result.rejection;
  }

  void _apply(WordLoopGameState Function(WordLoopGameState) transition) {
    final current = state.valueOrNull;
    if (current == null) return;
    final next = transition(current);
    if (identical(next, current)) return;
    state = AsyncData(next);
  }
}

final wordLoopGameControllerProvider =
    AsyncNotifierProvider<WordLoopGameController, WordLoopGameState?>(
  WordLoopGameController.new,
);
