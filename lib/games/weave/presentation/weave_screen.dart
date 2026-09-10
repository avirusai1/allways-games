import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/streak.dart';
import '../../../shared_game_kit/difficulty/difficulty_picker.dart';
import '../../../shared_game_kit/share_card/share_card.dart';
import '../domain/weave_game_state.dart';
import '../domain/weave_puzzle.dart';
import 'weave_providers.dart';
import 'widgets/weave_board.dart';

const List<DifficultyOption<WeaveDifficulty>> _difficultyOptions = [
  DifficultyOption(
    value: WeaveDifficulty.easy,
    label: 'Easy',
    description: 'A loose grid, easy to stumble onto words',
    icon: Icons.sentiment_satisfied_outlined,
  ),
  DifficultyOption(
    value: WeaveDifficulty.medium,
    label: 'Medium',
    description: 'A fair number of incidental words',
    icon: Icons.sentiment_neutral_outlined,
  ),
  DifficultyOption(
    value: WeaveDifficulty.hard,
    label: 'Hard',
    description: 'A tight grid — every path has to count',
    icon: Icons.local_fire_department_outlined,
  ),
];

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
        final difficulty = ref
                .read(weaveGameControllerProvider.notifier)
                .currentDifficulty ??
            WeaveDifficulty.medium;
        showModalBottomSheet(
          context: context,
          backgroundColor: AppColors.background,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => _ResultSheet(state: value, difficulty: difficulty),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weave'),
        actions: [
          asyncState.maybeWhen(
            data: (state) => state == null
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Change difficulty',
                    icon: const Icon(Icons.tune),
                    onPressed: () => ref
                        .read(weaveGameControllerProvider.notifier)
                        .changeDifficulty(),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: asyncState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Could not load Weave: $err')),
          data: (state) => state == null
              ? _DifficultyPickerBody(
                  onSelect: (d) => ref
                      .read(weaveGameControllerProvider.notifier)
                      .selectDifficulty(d),
                )
              : _WeaveBody(state: state),
        ),
      ),
    );
  }
}

class _DifficultyPickerBody extends ConsumerWidget {
  const _DifficultyPickerBody({required this.onSelect});

  final ValueChanged<WeaveDifficulty> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final freePlay = ref.watch(weaveFreePlayStatsProvider);
    final solvedCounts = freePlay.maybeWhen(
      data: (stats) => {
        for (final d in WeaveDifficulty.values)
          d: stats.forDifficulty(d.name).solved,
      },
      orElse: () => const <WeaveDifficulty, int>{},
    );

    return DifficultyPicker<WeaveDifficulty>(
      title: 'Choose a difficulty',
      options: _difficultyOptions,
      solvedCounts: solvedCounts,
      onSelect: onSelect,
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
  const _ResultSheet({required this.state, required this.difficulty});

  final WeaveGameState state;
  final WeaveDifficulty difficulty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(weaveStatsProvider);
    final freePlayAsync = ref.watch(weaveFreePlayStatsProvider);
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
              final tier = freePlayAsync.maybeWhen(
                data: (fp) => fp.forDifficulty(difficulty.name),
                orElse: () => null,
              );
              return Row(
                children: [
                  _StatChip(
                    label: 'Streak',
                    value: '$current',
                    icon: Icons.local_fire_department,
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    label: 'Woven',
                    value: tier == null ? '—' : '${tier.solved}',
                    icon: Icons.check_circle_outline,
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    label: 'Fewest hints',
                    value: tier?.bestSeconds == null ? '—' : '${tier!.bestSeconds}',
                    icon: Icons.lightbulb_outline,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ref
                        .read(weaveGameControllerProvider.notifier)
                        .selectDifficulty(difficulty);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Play another'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(weaveGameControllerProvider.notifier).changeDifficulty();
                },
                child: const Text('Change difficulty'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => ShareCard.share(
                ShareCard.buildSummaryResultText(
                  appName: 'Allways Games',
                  gameName: 'Weave',
                  dayIndex: dayIndex,
                  score: '${state.puzzle.solutions.length}/'
                      '${state.puzzle.solutions.length}',
                  lines: [
                    '${difficulty.label} · ${state.puzzle.clue}',
                    '${state.foundBonusWords.length} bonus words',
                  ],
                ),
              ),
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('Share result'),
            ),
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
