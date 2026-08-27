import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/streak.dart';
import '../../../shared_game_kit/share_card/share_card.dart';
import '../domain/weave_game_state.dart';
import 'weave_providers.dart';
import 'widgets/weave_board.dart';

class WeaveScreen extends ConsumerWidget {
  const WeaveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(weaveGameControllerProvider);

    ref.listen(weaveGameControllerProvider, (previous, next) {
      final wasPlaying = previous?.valueOrNull?.isPlaying ?? false;
      final value = next.valueOrNull;
      if (value == null) return;
      if (wasPlaying && value.status == WeaveStatus.solved) {
        showModalBottomSheet(
          context: context,
          backgroundColor: AppColors.background,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => _ResultSheet(state: value),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Weave')),
      body: SafeArea(
        child: asyncState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) =>
              Center(child: Text("Could not load today's puzzle: $err")),
          data: (state) => _WeaveBody(state: state),
        ),
      ),
    );
  }
}

class _WeaveBody extends ConsumerWidget {
  const _WeaveBody({required this.state});

  final WeaveGameState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(weaveGameControllerProvider.notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  state.puzzle.clue,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '${state.foundThemeWords.length}/${state.puzzle.solutions.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                state.spannerFound
                    ? 'Theme word found'
                    : 'Find the word that crosses the grid',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              Text(
                '${state.foundBonusWords.length} bonus',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: WeaveBoard(
                state: state,
                onWordTraced: (word) async {
                  final result = await controller.submit(word);
                  if (result == null || !context.mounted) return;
                  final message = switch (result.outcome) {
                    WeaveTraceOutcome.themeWord => '$word — theme word!',
                    WeaveTraceOutcome.bonusWord => result.earnedHint
                        ? '$word — bonus word, hint earned'
                        : '$word — bonus word',
                    WeaveTraceOutcome.alreadyFound => 'Already found',
                    WeaveTraceOutcome.notAWord => null,
                  };
                  if (message == null) return;
                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(SnackBar(
                      content: Text(message),
                      duration: const Duration(milliseconds: 1200),
                    ));
                },
              ),
            ),
          ),
        ),
        if (state.revealedHintWords.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text(
              'Hint: ${state.revealedHintWords.join(', ')}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.hintsAvailable > 0 && state.isPlaying
                      ? controller.useHint
                      : null,
                  icon: const Icon(Icons.lightbulb_outline, size: 18),
                  label: Text(
                    state.hintsAvailable > 0
                        ? 'Hint (${state.hintsAvailable})'
                        : 'Trace ${weaveBonusPerHint - state.foundBonusWords.length % weaveBonusPerHint} more for a hint',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultSheet extends ConsumerWidget {
  const _ResultSheet({required this.state});

  final WeaveGameState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(weaveStatsProvider);
    final dayIndex = DailySeed.todayIndex();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Woven!', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'All ${state.puzzle.solutions.length} theme words found, '
            'plus ${state.foundBonusWords.length} bonus.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          statsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (stats) {
              final current =
                  StreakCalculator.current(stats.wonDayIndices, dayIndex);
              final longest = StreakCalculator.longest(stats.wonDayIndices);
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
                    label: 'Played',
                    value: '${stats.totalPlayed}',
                    icon: Icons.calendar_today,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => ShareCard.share(
              ShareCard.buildSummaryResultText(
                appName: 'Allways Games',
                gameName: 'Weave',
                dayIndex: dayIndex,
                score: '${state.puzzle.solutions.length}/'
                    '${state.puzzle.solutions.length}',
                lines: [
                  state.puzzle.clue,
                  '${state.foundBonusWords.length} bonus words',
                ],
              ),
            ),
            icon: const Icon(Icons.share_outlined),
            label: const Text('Share result'),
          ),
        ],
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
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
