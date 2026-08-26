import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/isar_provider.dart';
import '../data/honeycomb_repository.dart';
import '../domain/honeycomb_game_state.dart';
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

/// Drives one day's Honeycomb board.
///
/// Unlike the other games, this one saves after every accepted word: a
/// player works a board in several visits across the day, so quitting the
/// app must never cost them the words they have already found.
class HoneycombGameController extends AsyncNotifier<HoneycombGameState> {
  late HoneycombRepository _repository;
  late int _dayIndex;
  final Random _shuffleRandom = Random();

  @override
  Future<HoneycombGameState> build() async {
    final bank = await ref.watch(honeycombContentBankProvider.future);
    _repository = await ref.watch(honeycombRepositoryProvider.future);
    _dayIndex = DailySeed.todayIndex();

    final puzzle = bank.puzzleForDayIndex(_dayIndex);
    final found = await _repository.foundWordsForDay(_dayIndex);
    return HoneycombGameState.initial(puzzle).copyWith(foundWords: found);
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
    await _repository.saveProgress(
      dayIndex: _dayIndex,
      foundWords: result.state.foundWords,
      score: result.state.score,
      maxScore: result.state.maxScore,
    );
    ref.invalidate(honeycombStatsProvider);
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
    AsyncNotifierProvider<HoneycombGameController, HoneycombGameState>(
  HoneycombGameController.new,
);
