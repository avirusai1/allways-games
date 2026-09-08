import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/streak.dart';
import '../../../shared_game_kit/clock/puzzle_clock.dart';
import '../../../shared_game_kit/difficulty/difficulty_picker.dart';
import '../../../shared_game_kit/share_card/share_card.dart';
import '../../../core/stats/free_play_stats.dart';
import '../data/domino_stats_repository.dart';
import '../domain/domino_board.dart';
import '../domain/domino_game_state.dart';
import 'domino_providers.dart';
import 'widgets/domino_board_view.dart';
import 'widgets/pip_face.dart';

const List<DifficultyOption<int>> _difficultyOptions = [
  DifficultyOption(
    value: 3,
    label: 'Easy',
    description: '3 dominoes, a gentle start',
    icon: Icons.sentiment_satisfied_outlined,
  ),
  DifficultyOption(
    value: 4,
    label: 'Medium',
    description: '4 dominoes, more to juggle',
    icon: Icons.sentiment_neutral_outlined,
  ),
  DifficultyOption(
    value: 5,
    label: 'Hard',
    description: '5 dominoes, every region matters',
    icon: Icons.local_fire_department_outlined,
  ),
];

class DominoScreen extends ConsumerStatefulWidget {
  const DominoScreen({super.key});

  @override
  ConsumerState<DominoScreen> createState() => _DominoScreenState();
}

class _DominoScreenState extends ConsumerState<DominoScreen> {
  /// First half of a placement in progress.
  int? _pendingCell;

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(dominoGameControllerProvider);

    ref.listen(dominoGameControllerProvider, (previous, next) {
      final wasPlaying = previous?.valueOrNull?.isPlaying ?? false;
      final value = next.valueOrNull;
      if (value == null) return;
      if (wasPlaying && value.status == DominoStatus.solved) {
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
      appBar: AppBar(
        title: const Text('Dot Dominoes'),
        actions: [
          asyncState.maybeWhen(
            data: (state) => state == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Center(
                      child: Text(
                        formatPuzzleClock(state.elapsedSeconds),
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
                        .read(dominoGameControllerProvider.notifier)
                        .changeDifficulty(),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: asyncState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) =>
              Center(child: Text('Could not load Dot Dominoes: $err')),
          data: (state) => state == null
              ? _DifficultyPickerBody(
                  onSelect: (count) => ref
                      .read(dominoGameControllerProvider.notifier)
                      .selectDifficulty(count),
                )
              : _Body(
                  state: state,
                  pendingCell: _pendingCell,
                  onCellTap: (cell) => _handleCellTap(state, cell),
                  onClear: () {
                    setState(() => _pendingCell = null);
                    ref.read(dominoGameControllerProvider.notifier).clearBoard();
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _handleCellTap(DominoGameState state, int cell) async {
    final controller = ref.read(dominoGameControllerProvider.notifier);

    // A filled cell is a request to take that domino back.
    if (state.pipsByCell.containsKey(cell)) {
      setState(() => _pendingCell = null);
      await controller.tapCell(cell, null);
      return;
    }

    if (state.selectedTrayIndex == null) {
      _say('Pick a domino from the tray first');
      return;
    }

    final pending = _pendingCell;
    if (pending == null) {
      setState(() => _pendingCell = cell);
      return;
    }
    if (pending == cell) {
      setState(() => _pendingCell = null);
      return;
    }
    if (!dominoAdjacency[pending].contains(cell)) {
      // Not next to the first half; treat it as starting again there.
      setState(() => _pendingCell = cell);
      return;
    }

    final outcome = await controller.tapCell(pending, cell);
    setState(() => _pendingCell = null);
    if (outcome == DominoPlaceOutcome.blocked) {
      _say('That domino will not fit there');
    }
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1400),
      ));
  }
}

class _DifficultyPickerBody extends ConsumerWidget {
  const _DifficultyPickerBody({required this.onSelect});

  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final freePlay = ref.watch(dominoFreePlayStatsProvider);
    final solvedCounts = freePlay.maybeWhen(
      data: (stats) => {
        for (final size in dominoDifficultyTiers)
          size: stats.forDifficulty(size.toString()).solved,
      },
      orElse: () => const <int, int>{},
    );

    return DifficultyPicker<int>(
      title: 'Choose a difficulty',
      options: _difficultyOptions,
      solvedCounts: solvedCounts,
      onSelect: onSelect,
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.state,
    required this.pendingCell,
    required this.onCellTap,
    required this.onClear,
  });

  final DominoGameState state;
  final int? pendingCell;
  final ValueChanged<int> onCellTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(dominoGameControllerProvider.notifier);
    final used = state.usedTrayIndices;
    final remaining = state.puzzle.tray.length - used.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  dominoDifficultyLabel(state.puzzle.tray.length),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '$remaining left',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DominoBoardView(
            state: state,
            pendingCell: pendingCell,
            onCellTap: onCellTap,
          ),
        ),
        // What the region symbols mean. The rules are this app's own, so
        // a player has never seen them before and a legend is not
        // optional.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Text(
            _legendFor(state),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < state.puzzle.tray.length; i++)
                _TrayDomino(
                  domino: state.puzzle.tray[i],
                  used: used.contains(i),
                  selected: state.selectedTrayIndex == i,
                  flipped: state.selectedTrayIndex == i && state.flipped,
                  onTap: () => controller.selectTray(i),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Text(
                state.selectedTrayIndex == null
                    ? 'Tap a domino, then two cells'
                    : 'Tap it again to turn it round',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: state.placed.isEmpty ? null : onClear,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Clear'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Describes only the rules this board actually uses.
  String _legendFor(DominoGameState state) {
    final seen = <DominoRule>{};
    final parts = <String>[];
    for (final region in state.puzzle.regions) {
      if (!seen.add(region.rule)) continue;
      parts.add(switch (region.rule) {
        DominoRule.sum => 'a number means the pips add up to it',
        DominoRule.same => '= means every pip the same',
        DominoRule.allDifferent => '≠ means every pip different',
        DominoRule.lessThan => '<n means every pip under n',
        DominoRule.greaterThan => '>n means every pip over n',
      });
    }
    return parts.join(' · ');
  }
}

class _TrayDomino extends StatelessWidget {
  const _TrayDomino({
    required this.domino,
    required this.used,
    required this.selected,
    required this.flipped,
    required this.onTap,
  });

  final Domino domino;
  final bool used;
  final bool selected;
  final bool flipped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final low = flipped ? domino.high : domino.low;
    final high = flipped ? domino.low : domino.high;

    return Opacity(
      opacity: used ? 0.25 : 1,
      child: GestureDetector(
        onTap: used ? null : onTap,
        child: Container(
          width: 74,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.surfaceAlt,
              width: selected ? 2.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(child: PipFace(value: low, colour: AppColors.primary)),
              Container(width: 1, color: AppColors.gridLine),
              Expanded(child: PipFace(value: high, colour: AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultSheet extends ConsumerWidget {
  const _ResultSheet({required this.state});

  final DominoGameState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dominoStatsProvider);
    final freePlayAsync = ref.watch(dominoFreePlayStatsProvider);
    final dominoCount = state.puzzle.tray.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Solved!', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            '${dominoDifficultyLabel(dominoCount)} · $dominoCount dominoes '
            'in ${formatPuzzleClock(state.elapsedSeconds)}.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          _StatsRow(
            statsAsync: statsAsync,
            freePlayAsync: freePlayAsync,
            dominoCount: dominoCount,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ref
                        .read(dominoGameControllerProvider.notifier)
                        .selectDifficulty(dominoCount);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Play another'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(dominoGameControllerProvider.notifier).changeDifficulty();
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
                  gameName: 'Dot Dominoes',
                  dayIndex: DailySeed.todayIndex(),
                  score: formatPuzzleClock(state.elapsedSeconds),
                  lines: ['$dominoCount dominoes'],
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.statsAsync,
    required this.freePlayAsync,
    required this.dominoCount,
  });

  final AsyncValue<DominoGameStats> statsAsync;
  final AsyncValue<FreePlayStats> freePlayAsync;
  final int dominoCount;

  @override
  Widget build(BuildContext context) {
    final streak = statsAsync.maybeWhen(
      data: (stats) =>
          StreakCalculator.current(stats.wonDayIndices, DailySeed.todayIndex()),
      orElse: () => null,
    );
    final tier = freePlayAsync.maybeWhen(
      data: (fp) => fp.forDifficulty(dominoCount.toString()),
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
          value: tier?.bestSeconds == null
              ? '—'
              : formatPuzzleClock(tier!.bestSeconds!),
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
