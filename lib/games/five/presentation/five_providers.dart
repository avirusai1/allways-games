import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/isar_provider.dart';
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

/// Drives one day's Five puzzle: loads today's answer, applies letter
/// input, validates + scores submissions, and persists the outcome once
/// the game ends. Today's puzzle can only be completed once; reopening a
/// finished puzzle shows its final won/lost state rather than a blank grid
/// (full guess-history replay isn't stored in this MVP).
class FiveGameController extends AsyncNotifier<FiveGameState> {
  late FiveContentBank _bank;
  late FiveStatsRepository _stats;
  late int _dayIndex;

  @override
  Future<FiveGameState> build() async {
    _bank = await ref.watch(fiveContentBankProvider.future);
    _stats = await ref.watch(fiveStatsRepositoryProvider.future);
    _dayIndex = DailySeed.todayIndex();
    final answer = _bank.puzzleForDayIndex(_dayIndex);

    final existing = await _stats.completionForDay(_dayIndex);
    if (existing != null) {
      return FiveGameState.initial(answer).copyWith(
        status: existing.won ? FiveStatus.won : FiveStatus.lost,
      );
    }
    return FiveGameState.initial(answer);
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
      await _stats.recordCompletion(
        dayIndex: _dayIndex,
        won: won,
        guessesUsed: newGuesses.length,
      );
      ref.invalidate(fiveStatsProvider);
    }
    return null;
  }
}

final fiveGameControllerProvider =
    AsyncNotifierProvider<FiveGameController, FiveGameState>(FiveGameController.new);
