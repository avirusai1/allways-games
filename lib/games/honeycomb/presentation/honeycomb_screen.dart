import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/streak.dart';
import '../../../shared_game_kit/share_card/share_card.dart';
import '../domain/honeycomb_game_state.dart';
import '../domain/honeycomb_scoring.dart';
import 'honeycomb_providers.dart';
import 'widgets/honeycomb_cells.dart';

/// Player-facing copy for each way a word can be turned away.
String honeycombRejectionMessage(HoneycombRejection rejection) {
  return switch (rejection) {
    HoneycombRejection.tooShort =>
      'Words need at least $honeycombMinWordLength letters',
    HoneycombRejection.missingRequiredLetter => 'Use the centre letter',
    HoneycombRejection.letterNotOnBoard => 'That letter is not in the comb',
    HoneycombRejection.notAnAnswer => 'Not a word we know',
    HoneycombRejection.alreadyFound => 'Already found',
  };
}

class HoneycombScreen extends ConsumerWidget {
  const HoneycombScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(honeycombGameControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Honeycomb'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Progress',
            onPressed: asyncState.valueOrNull == null
                ? null
                : () => _showProgressSheet(context, asyncState.value!),
          ),
        ],
      ),
      body: SafeArea(
        child: asyncState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text("Could not load today's comb: $err"),
            ),
          ),
          data: (state) => _HoneycombBody(state: state),
        ),
      ),
    );
  }

  void _showProgressSheet(BuildContext context, HoneycombGameState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ProgressSheet(state: state, dayIndex: DailySeed.todayIndex()),
    );
  }
}

class _HoneycombBody extends ConsumerWidget {
  const _HoneycombBody({required this.state});

  final HoneycombGameState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(honeycombGameControllerProvider.notifier);

    return Column(
      children: [
        _RankBar(state: state),
        if (state.foundWords.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final word in state.foundWords.toList()..sort())
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Chip(
                      label: Text(word),
                      backgroundColor: state.puzzle.isPangram(word)
                          ? AppColors.secondaryContainer
                          : AppColors.primaryContainer,
                      side: BorderSide.none,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
        const Spacer(),
        Text(
          state.currentInput.isEmpty ? ' ' : state.currentInput,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),
        HoneycombCluster(
          requiredLetter: state.puzzle.requiredLetter,
          outerLetters: state.outerLetterOrder,
          onLetterTap: controller.inputLetter,
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.backspace,
                  child: const Text('Delete'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: controller.shuffleLetters,
                icon: const Icon(Icons.autorenew_rounded),
                tooltip: 'Shuffle letters',
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final rejection = await controller.submit();
                    if (rejection == null || !context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(honeycombRejectionMessage(rejection)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text('Enter'),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

/// Current rank, score, and how far it is to the next rung.
class _RankBar extends StatelessWidget {
  const _RankBar({required this.state});

  final HoneycombGameState state;

  @override
  Widget build(BuildContext context) {
    final rank = state.rank;
    final next = honeycombRanks
        .where((r) => r.percentOfMax > rank.percentOfMax)
        .firstOrNull;
    final progress = state.maxScore == 0 ? 0.0 : state.score / state.maxScore;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(rank.name, style: Theme.of(context).textTheme.titleMedium),
              Text(
                '${state.score} pts · ${state.foundWords.length}/'
                '${state.puzzle.answers.length} words',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            next == null
                ? 'Every word found — nothing left in this comb.'
                : '${honeycombScoreForRank(next, state.maxScore) - state.score} '
                    'to ${next.name}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ProgressSheet extends ConsumerWidget {
  const _ProgressSheet({required this.state, required this.dayIndex});

  final HoneycombGameState state;
  final int dayIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(honeycombStatsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.rank.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '${state.score} of ${state.maxScore} points · '
              '${state.foundPangrams.length}/${state.puzzle.pangrams.length} '
              'pangrams',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            for (final rank in honeycombRanks)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      state.score >= honeycombScoreForRank(rank, state.maxScore)
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(rank.name)),
                    Text(
                      '${honeycombScoreForRank(rank, state.maxScore)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            statsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (stats) {
                final current =
                    StreakCalculator.current(stats.goalDayIndices, dayIndex);
                final longest = StreakCalculator.longest(stats.goalDayIndices);
                return Row(
                  children: [
                    _StatChip(
                      label: 'Streak',
                      value: '$current',
                      icon: Icons.local_fire_department,
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      label: 'Best',
                      value: '$longest',
                      icon: Icons.emoji_events_outlined,
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      label: 'Top score',
                      value: '${stats.bestScore ?? state.score}',
                      icon: Icons.star_outline_rounded,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                ShareCard.share(
                  ShareCard.buildSummaryResultText(
                    appName: 'Allways Games',
                    gameName: 'Honeycomb',
                    dayIndex: dayIndex,
                    score: state.rank.name,
                    // Words are left out on purpose: everyone plays the
                    // same comb today, and a card that lists answers is a
                    // card nobody can post.
                    lines: [
                      '${state.score} pts · ${state.foundWords.length} words'
                          '${state.foundPangrams.isEmpty ? '' : ' · pangram!'}',
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share progress'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
