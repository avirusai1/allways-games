import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/streak.dart';
import '../../../shared_game_kit/clock/puzzle_clock.dart';
import '../../../shared_game_kit/difficulty/difficulty_picker.dart';
import '../../../shared_game_kit/share_card/share_card.dart';
import '../domain/tile_layout.dart';
import '../domain/tile_match_game_state.dart';
import 'tile_match_providers.dart';
import 'widgets/tile_match_board.dart';

const List<DifficultyOption<String>> _difficultyOptions = [
  DifficultyOption(
    value: 'Long Hall',
    label: 'Easy',
    description: '78 tiles, a gentle start',
    icon: Icons.sentiment_satisfied_outlined,
  ),
  DifficultyOption(
    value: 'Spire',
    label: 'Medium',
    description: '82 tiles, more to track',
    icon: Icons.sentiment_neutral_outlined,
  ),
  DifficultyOption(
    value: 'Terrace',
    label: 'Hard',
    description: '88 tiles, nowhere to hide',
    icon: Icons.local_fire_department_outlined,
  ),
];

class TileMatchScreen extends ConsumerWidget {
  const TileMatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(tileMatchGameControllerProvider);

    ref.listen(tileMatchGameControllerProvider, (previous, next) {
      final wasPlaying = previous?.valueOrNull?.isPlaying ?? false;
      final value = next.valueOrNull;
      if (value == null || !wasPlaying || value.isPlaying) return;
      _showResultSheet(context, value);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tile Match'),
        actions: [
          asyncState.maybeWhen(
            data: (state) => state == null
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Change difficulty',
                    icon: const Icon(Icons.tune),
                    onPressed: () => ref
                        .read(tileMatchGameControllerProvider.notifier)
                        .changeDifficulty(),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: asyncState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load Tile Match: $err'),
            ),
          ),
          data: (state) => state == null
              ? _DifficultyPickerBody(
                  onSelect: (layout) => ref
                      .read(tileMatchGameControllerProvider.notifier)
                      .selectDifficulty(layout),
                )
              : _TileMatchBody(state: state),
        ),
      ),
    );
  }

  void _showResultSheet(BuildContext context, TileMatchGameState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          _ResultSheet(state: state, dayIndex: DailySeed.todayIndex()),
    );
  }
}

class _DifficultyPickerBody extends ConsumerWidget {
  const _DifficultyPickerBody({required this.onSelect});

  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final freePlay = ref.watch(tileMatchFreePlayStatsProvider);
    final solvedCounts = freePlay.maybeWhen(
      data: (stats) => {
        for (final layout in tileMatchDifficultyTiers)
          layout: stats.forDifficulty(layout).solved,
      },
      orElse: () => const <String, int>{},
    );

    return DifficultyPicker<String>(
      title: 'Choose a board size',
      options: _difficultyOptions,
      solvedCounts: solvedCounts,
      onSelect: onSelect,
    );
  }
}

class _TileMatchBody extends ConsumerWidget {
  const _TileMatchBody({required this.state});

  final TileMatchGameState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(tileMatchGameControllerProvider.notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${tileMatchDifficultyLabel(state.puzzle.layout.name)} · '
                '${state.remaining.length} left',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                formatPuzzleClock(state.elapsedSeconds),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        Expanded(
          child: InteractiveViewer(
            minScale: 0.6,
            maxScale: 2.5,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TileMatchBoardView(
                  state: state,
                  onTileTap: controller.tapTile,
                ),
              ),
            ),
          ),
        ),
        if (state.status == TileMatchStatus.stuck)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'No matching pair is free. Undo a move, or try another board.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        if (state.status == TileMatchStatus.cleared)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Board cleared!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.canUndo ? controller.undo : null,
                  icon: const Icon(Icons.undo_rounded, size: 18),
                  label: const Text('Undo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: state.isPlaying ? controller.hint : null,
                  icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                  label: const Text('Hint'),
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
  const _ResultSheet({required this.state, required this.dayIndex});

  final TileMatchGameState state;
  final int dayIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(tileMatchStatsProvider);
    final freePlayAsync = ref.watch(tileMatchFreePlayStatsProvider);
    final layoutName = state.puzzle.layout.name;
    final cleared = state.status == TileMatchStatus.cleared;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cleared ? 'Cleared!' : 'Stuck',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            cleared
                ? '${tileMatchDifficultyLabel(layoutName)} in '
                    '${formatPuzzleClock(state.elapsedSeconds)}.'
                : '${state.tilesCleared} of ${state.puzzle.tileCount} tiles '
                    'cleared before the board ran dry.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (!cleared) ...[
            const SizedBox(height: 8),
            Text(
              // Worth saying plainly: the board was clearable, so a stuck
              // board is a wrong turn rather than bad luck.
              'Every board can be cleared — undo a few pairs and try a '
              'different order.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 16),
          statsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (stats) {
              final current =
                  StreakCalculator.current(stats.clearedDayIndices, dayIndex);
              final tier = freePlayAsync.maybeWhen(
                data: (fp) => fp.forDifficulty(layoutName),
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
                    label: 'Solved',
                    value: tier == null ? '—' : '${tier.solved}',
                    icon: Icons.check_circle_outline,
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    label: 'Best',
                    value: tier?.bestSeconds == null
                        ? '—'
                        : formatPuzzleClock(tier!.bestSeconds!),
                    icon: Icons.timer_outlined,
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
                        .read(tileMatchGameControllerProvider.notifier)
                        .selectDifficulty(layoutName);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Play another'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref
                      .read(tileMatchGameControllerProvider.notifier)
                      .changeDifficulty();
                },
                child: const Text('Change difficulty'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                ShareCard.share(
                  ShareCard.buildSummaryResultText(
                    appName: 'Allways Games',
                    gameName: 'Tile Match',
                    dayIndex: dayIndex,
                    score: cleared
                        ? formatPuzzleClock(state.elapsedSeconds)
                        : '${state.tilesCleared}/${state.puzzle.tileCount}',
                    lines: [tileMatchDifficultyLabel(layoutName)],
                  ),
                );
              },
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
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
