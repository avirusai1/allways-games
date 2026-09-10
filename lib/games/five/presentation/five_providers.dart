import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/isar_provider.dart';
import '../../../core/stats/free_play_stats.dart';
import '../data/five_stats_repository.dart';
import '../domain/five_game_state.dart';
import '../domain/guess_evaluator.dart';
import '../generation/five_content_bank.dart';

final fiveContentBankProvider = FutureProvider<FiveContentBank>((ref) {
  return FiveContentBank.load();
});

final fiveStatsRepositoryProvider = FutureProvider<FiveStatsRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return FiveStatsRepository(isar);
});

final fiveStatsProvider = FutureProvider<FiveGameStats>((ref) async {
  final repo = await ref.watch(fiveStatsRepositoryProvider.future);
  return repo.loadStats();
});

final fiveFreePlayStatsProvider = FutureProvider<FreePlayStats>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return FreePlayStats('five', prefs);
});

/// Drives Five as free play: the player picks a difficulty, guesses as
/// many words of it as they like, and can switch difficulty at any time.
///
/// [state] is null while no word is active — the screen reads that as
/// "show the difficulty picker".
class FiveGameController extends AsyncNotifier<FiveGameState?> {
  late FiveContentBank _bank;
  late FiveStatsRepository _stats;
  late FreePlayStats _freePlayStats;
  final Random _random = Random();
  String? _lastAnswer;
  FiveDifficulty? _currentDifficulty;

  /// The tier the active word was drawn from — null before any difficulty
  /// is chosen.
  FiveDifficulty? get currentDifficulty => _currentDifficulty;

  @override
  Future<FiveGameState?> build() async {
    _bank = await ref.watch(fiveContentBankProvider.future);
    _stats = await ref.watch(fiveStatsRepositoryProvider.future);
    _freePlayStats = await ref.watch(fiveFreePlayStatsProvider.future);
    return null; // No difficulty chosen yet.
  }

  /// Starts a fresh word of [difficulty], drawn at random from the bank.
  void selectDifficulty(FiveDifficulty difficulty) {
    final pool = _bank.puzzlesOfDifficulty(difficulty);
    if (pool.isEmpty) return;

    String answer;
    do {
      answer = pool[_random.nextInt(pool.length)];
    } while (answer == _lastAnswer && pool.length > 1);
    _lastAnswer = answer;
    _currentDifficulty = difficulty;

    state = AsyncData(FiveGameState.initial(answer));
  }

  /// Back to the difficulty picker without recording anything.
  void changeDifficulty() {
    state = const AsyncData(null);
  }

  void inputLetter(String letter) {
    final current = state.valueOrNull;
    if (current == null || !current.canEditInput) return;
    if (current.currentInput.length >= fiveWordLength) return;
    state = AsyncData(
      current.copyWith(currentInput: current.currentInput + letter.toLowerCase()),
    );
  }

  void backspace() {
    final current = state.valueOrNull;
    if (current == null || !current.canEditInput || current.currentInput.isEmpty) return;
    state = AsyncData(
      current.copyWith(
        currentInput: current.currentInput.substring(0, current.currentInput.length - 1),
      ),
    );
  }

  /// Returns a user-facing error message if the guess couldn't be
  /// submitted (e.g. not a real word), otherwise null.
  Future<String?> submit() async {
    final current = state.valueOrNull;
    if (current == null || !current.canSubmit) return null;

    final guess = current.currentInput;
    if (!_bank.isValidGuess(guess)) {
      return 'Not a valid word';
    }

    final evaluation = evaluateGuess(guess: guess, answer: current.answer);
    final newGuesses = [...current.submittedGuesses, guess];
    final newEvaluations = [...current.evaluations, evaluation];
    final won = guess == current.answer;
    final outOfGuesses = newGuesses.length >= fiveMaxGuesses;
    final newStatus = won
        ? FiveStatus.won
        : (outOfGuesses ? FiveStatus.lost : FiveStatus.playing);

    state = AsyncData(
      current.copyWith(
        submittedGuesses: newGuesses,
        evaluations: newEvaluations,
        currentInput: '',
        status: newStatus,
      ),
    );

    if (newStatus != FiveStatus.playing) {
      // Streak is still "did you play today", independent of how many
      // words that was — free play removes the one-per-day cap, not the
      // reason to come back daily.
      await _stats.recordCompletion(
        dayIndex: DailySeed.todayIndex(),
        won: won,
        guessesUsed: newGuesses.length,
      );
      if (won && _currentDifficulty != null) {
        await _freePlayStats.recordSolve(_currentDifficulty!.name, newGuesses.length);
      }
      ref.invalidate(fiveStatsProvider);
      ref.invalidate(fiveFreePlayStatsProvider);
    }
    return null;
  }
}

final fiveGameControllerProvider =
    AsyncNotifierProvider<FiveGameController, FiveGameState?>(FiveGameController.new);
