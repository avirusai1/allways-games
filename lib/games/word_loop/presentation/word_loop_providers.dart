import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/isar_provider.dart';
import '../data/word_loop_stats_repository.dart';
import '../domain/word_loop_game_state.dart';
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

/// Drives one day's Word Loop board: forwards input to the pure
/// [WordLoopGameState] transitions and records the solve.
///
/// Unlike Five and Sudoku, a finished day here is restored as *finished*
/// with its word count intact rather than replayed, since the board has no
/// losing state and replaying it would just let the count be improved
/// after the fact.
class WordLoopGameController extends AsyncNotifier<WordLoopGameState> {
  late WordLoopStatsRepository _stats;
  late int _dayIndex;

  @override
  Future<WordLoopGameState> build() async {
    final bank = await ref.watch(wordLoopContentBankProvider.future);
    _stats = await ref.watch(wordLoopStatsRepositoryProvider.future);
    _dayIndex = DailySeed.todayIndex();

    final puzzle = bank.puzzleForDayIndex(_dayIndex);
    final initial = WordLoopGameState.initial(puzzle);

    final existing = await _stats.completionForDay(_dayIndex);
    if (existing != null) {
      // The chain itself is not stored, so show the board's own answer as
      // the finished state rather than pretending to replay the player's.
      return initial.copyWith(
        chain: puzzle.exampleSolution,
        status: WordLoopStatus.solved,
      );
    }
    return initial;
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
      await _stats.recordCompletion(
        dayIndex: _dayIndex,
        wordsUsed: result.state.wordsUsed,
      );
      ref.invalidate(wordLoopStatsProvider);
    }
    return null;
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
    AsyncNotifierProvider<WordLoopGameController, WordLoopGameState>(
  WordLoopGameController.new,
);
