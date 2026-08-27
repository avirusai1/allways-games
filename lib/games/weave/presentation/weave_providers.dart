import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/isar_provider.dart';
import '../data/weave_stats_repository.dart';
import '../domain/weave_game_state.dart';
import '../generation/weave_content_bank.dart';

final weaveContentBankProvider = FutureProvider<WeaveContentBank>((ref) {
  return WeaveContentBank.load();
});

final weaveStatsRepositoryProvider =
    FutureProvider<WeaveStatsRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return WeaveStatsRepository(isar);
});

final weaveStatsProvider = FutureProvider<WeaveGameStats>((ref) async {
  final repo = await ref.watch(weaveStatsRepositoryProvider.future);
  return repo.loadStats();
});

/// Drives one day's Weave: accepting traced words, awarding hints, and
/// persisting the result once every theme word is found.
class WeaveGameController extends AsyncNotifier<WeaveGameState> {
  late WeaveStatsRepository _stats;
  late int _dayIndex;

  @override
  Future<WeaveGameState> build() async {
    final bank = await ref.watch(weaveContentBankProvider.future);
    _stats = await ref.watch(weaveStatsRepositoryProvider.future);
    _dayIndex = DailySeed.todayIndex();
    final puzzle = bank.puzzleForDayIndex(_dayIndex);

    final existing = await _stats.completionForDay(_dayIndex);
    if (existing != null && existing.won) {
      // Already solved today: show the finished grid rather than a blank
      // one (per-word progress is not persisted in v1).
      return WeaveGameState.initial(puzzle).copyWith(
        foundThemeWords: puzzle.solutions.keys.toSet(),
      );
    }
    return WeaveGameState.initial(puzzle);
  }

  /// Submits a traced word. Returns the outcome so the screen can say what
  /// happened without duplicating the rules.
  Future<WeaveTraceResult?> submit(String word) async {
    final current = state.valueOrNull;
    if (current == null || !current.isPlaying) return null;

    final result = current.trace(word);
    if (identical(result.state, current)) return result;

    state = AsyncData(result.state);

    if (result.state.status == WeaveStatus.solved) {
      await _stats.recordCompletion(dayIndex: _dayIndex, won: true);
      ref.invalidate(weaveStatsProvider);
    }
    return result;
  }

  void useHint() {
    final current = state.valueOrNull;
    if (current == null || !current.isPlaying) return;
    state = AsyncData(current.useHint());
  }
}

final weaveGameControllerProvider =
    AsyncNotifierProvider<WeaveGameController, WeaveGameState>(
  WeaveGameController.new,
);
