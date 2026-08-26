import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/streak.dart';
import '../../../shared_game_kit/clock/puzzle_clock.dart';
import '../../../shared_game_kit/share_card/share_card.dart';
import '../domain/tile_match_game_state.dart';
import 'tile_match_providers.dart';
import 'widgets/tile_match_board.dart';

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
      appBar: AppBar(title: const Text('Tile Match')),
      body: SafeArea(
        child: asyncState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text("Could not load today's board: $err"),
            ),
          ),
          data: (state) => _TileMatchBody(state: state),
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
                '${state.puzzle.layout.name} · ${state.remaining.length} left',
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
              'No matching pair is free. Undo a move, or come back tomorrow.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        if (state.status == TileMatchStatus.cleared)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Board cleared. A new one arrives tomorrow.',
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
                ? 'Every tile gone in ${formatPuzzleClock(state.elapsedSeconds)}.'
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
              final longest = StreakCalculator.longest(stats.clearedDayIndices);
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
                    label: 'Fastest',
                    value: stats.bestSeconds == null
                        ? '—'
                        : formatPuzzleClock(stats.bestSeconds!),
                    icon: Icons.timer_outlined,
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
                  gameName: 'Tile Match',
                  dayIndex: dayIndex,
                  score: cleared
                      ? formatPuzzleClock(state.elapsedSeconds)
                      : '${state.tilesCleared}/${state.puzzle.tileCount}',
                  lines: [state.puzzle.layout.name],
                ),
              );
            },
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
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
