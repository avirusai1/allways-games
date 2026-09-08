import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/streak.dart';
import '../../../core/stats/free_play_stats.dart';
import '../../../shared_game_kit/clock/puzzle_clock.dart';
import '../../../shared_game_kit/difficulty/difficulty_picker.dart';
import '../../../shared_game_kit/grid/puzzle_grid.dart';
import '../../../shared_game_kit/share_card/share_card.dart';
import '../data/sudoku_stats_repository.dart';
import '../domain/sudoku_board.dart';
import '../domain/sudoku_game_state.dart';
import 'sudoku_providers.dart';
import 'widgets/number_pad.dart';
import 'widgets/sudoku_cell.dart';

/// Sudoku's clock is the app's shared puzzle clock; kept as a named
/// alias so the screen reads in its own terms.
String formatDuration(int totalSeconds) => formatPuzzleClock(totalSeconds);

const List<DifficultyOption<SudokuDifficulty>> _difficultyOptions = [
  DifficultyOption(
    value: SudokuDifficulty.easy,
    label: 'Easy',
    description: 'A relaxed grid to warm up on',
    icon: Icons.sentiment_satisfied_outlined,
  ),
  DifficultyOption(
    value: SudokuDifficulty.medium,
    label: 'Medium',
    description: 'A fair, steady challenge',
    icon: Icons.sentiment_neutral_outlined,
  ),
  DifficultyOption(
    value: SudokuDifficulty.hard,
    label: 'Hard',
    description: 'Sparse givens, real deduction',
    icon: Icons.local_fire_department_outlined,
  ),
];

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
            data: (state) => state == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Center(
                      child: Text(
                        formatDuration(state.elapsedSeconds),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          asyncState.maybeWhen(
            data: (state) => state == null
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Change difficulty',
                    icon: const Icon(Icons.tune),
                    onPressed: () => ref
                        .read(sudokuGameControllerProvider.notifier)
                        .changeDifficulty(),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: asyncState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Could not load Sudoku: $err')),
          data: (state) => state == null
              ? _DifficultyPickerBody(
                  onSelect: (d) => ref
                      .read(sudokuGameControllerProvider.notifier)
                      .selectDifficulty(d),
                )
              : _SudokuBody(state: state),
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

class _DifficultyPickerBody extends ConsumerWidget {
  const _DifficultyPickerBody({required this.onSelect});

  final ValueChanged<SudokuDifficulty> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final freePlay = ref.watch(sudokuFreePlayStatsProvider);
    final solvedCounts = freePlay.maybeWhen(
      data: (stats) => {
        for (final d in SudokuDifficulty.values)
          d: stats.forDifficulty(d.name).solved,
      },
      orElse: () => const <SudokuDifficulty, int>{},
    );

    return DifficultyPicker<SudokuDifficulty>(
      title: 'Choose a difficulty',
      options: _difficultyOptions,
      solvedCounts: solvedCounts,
      onSelect: onSelect,
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
    final freePlayAsync = ref.watch(sudokuFreePlayStatsProvider);
    final difficulty = state.puzzle.difficulty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Solved!', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            '${difficulty.label} in ${formatDuration(state.elapsedSeconds)}.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          _StatsRow(statsAsync: statsAsync, freePlayAsync: freePlayAsync, difficulty: difficulty),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ref
                        .read(sudokuGameControllerProvider.notifier)
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
                  ref.read(sudokuGameControllerProvider.notifier).changeDifficulty();
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
                'Allways Games Sudoku\n'
                '${difficulty.label} · ${formatDuration(state.elapsedSeconds)}',
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.statsAsync,
    required this.freePlayAsync,
    required this.difficulty,
  });

  final AsyncValue<SudokuGameStats> statsAsync;
  final AsyncValue<FreePlayStats> freePlayAsync;
  final SudokuDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final streak = statsAsync.maybeWhen(
      data: (stats) => StreakCalculator.current(
        stats.wonDayIndices,
        DailySeed.todayIndex(),
      ),
      orElse: () => null,
    );
    final tier = freePlayAsync.maybeWhen(
      data: (fp) => fp.forDifficulty(difficulty.name),
      orElse: () => null,
    );

    return Row(
      children: [
        _StatChip(
          label: 'Streak',
          value: streak == null ? '—' : '$streak',
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
          value: tier?.bestSeconds == null ? '—' : formatDuration(tier!.bestSeconds!),
          icon: Icons.timer_outlined,
        ),
      ],
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
