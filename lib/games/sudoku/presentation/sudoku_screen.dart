import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/streak.dart';
import '../../../shared_game_kit/grid/puzzle_grid.dart';
import '../../../shared_game_kit/share_card/share_card.dart';
import '../domain/sudoku_board.dart';
import '../domain/sudoku_game_state.dart';
import 'sudoku_providers.dart';
import 'widgets/number_pad.dart';
import 'widgets/sudoku_cell.dart';

String formatDuration(int totalSeconds) {
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class SudokuScreen extends ConsumerWidget {
  const SudokuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(sudokuGameControllerProvider);

    ref.listen(sudokuGameControllerProvider, (previous, next) {
      final wasPlaying = previous?.valueOrNull?.status == SudokuStatus.playing;
      final value = next.valueOrNull;
      if (value == null) return;
      if (wasPlaying && value.status == SudokuStatus.solved) {
        _showResultSheet(context, value);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sudoku'),
        actions: [
          asyncState.maybeWhen(
            data: (state) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  formatDuration(state.elapsedSeconds),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: asyncState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) =>
              Center(child: Text("Could not load today's puzzle: $err")),
          data: (state) => _SudokuBody(state: state),
        ),
      ),
    );
  }

  void _showResultSheet(BuildContext context, SudokuGameState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ResultSheet(state: state),
    );
  }
}

class _SudokuBody extends ConsumerWidget {
  const _SudokuBody({required this.state});

  final SudokuGameState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(sudokuGameControllerProvider.notifier);
    final conflicts = state.conflicts;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Row(
            children: [
              Text(
                state.puzzle.difficulty.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              if (state.status == SudokuStatus.solved)
                Text('Solved', style: Theme.of(context).textTheme.titleMedium)
              else
                Text(
                  '${state.remainingCells} left',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: PuzzleGrid(
                size: sudokuSize,
                majorEvery: sudokuBoxSize,
                onCellTap: controller.selectCell,
                cellBuilder: (context, index) => SudokuCell(
                  state: state,
                  index: index,
                  conflicts: conflicts,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: NumberPad(
            remainingPerDigit: state.remainingPerDigit,
            notesMode: state.notesMode,
            enabled: state.isPlaying,
            onDigit: controller.enterDigit,
            onClear: controller.clearCell,
            onToggleNotes: controller.toggleNotesMode,
          ),
        ),
      ],
    );
  }
}

class _ResultSheet extends ConsumerWidget {
  const _ResultSheet({required this.state});

  final SudokuGameState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(sudokuStatsProvider);
    final dayIndex = DailySeed.todayIndex();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Solved!', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            '${state.puzzle.difficulty.label} in '
            '${formatDuration(state.elapsedSeconds)}.',
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
                    label: 'Fastest',
                    value: stats.bestSeconds == null
                        ? '—'
                        : formatDuration(stats.bestSeconds!),
                    icon: Icons.timer_outlined,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => ShareCard.share(
              'Allways Games Sudoku #$dayIndex\n'
              '${state.puzzle.difficulty.label} · '
              '${formatDuration(state.elapsedSeconds)}',
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
