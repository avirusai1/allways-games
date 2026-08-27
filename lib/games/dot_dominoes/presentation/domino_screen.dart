import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/streak.dart';
import '../../../shared_game_kit/clock/puzzle_clock.dart';
import '../../../shared_game_kit/share_card/share_card.dart';
import '../domain/domino_board.dart';
import '../domain/domino_game_state.dart';
import 'domino_providers.dart';
import 'widgets/domino_board_view.dart';
import 'widgets/pip_face.dart';

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
            data: (state) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  formatPuzzleClock(state.elapsedSeconds),
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
          data: (state) => _Body(
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
                  'Fill the board so every region holds true',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                '$remaining left',
                style: Theme.of(context).textTheme.titleMedium,
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
            '${state.puzzle.tray.length} dominoes placed in '
            '${formatPuzzleClock(state.elapsedSeconds)}.',
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
                        : formatPuzzleClock(stats.bestSeconds!),
                    icon: Icons.timer_outlined,
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
                gameName: 'Dot Dominoes',
                dayIndex: dayIndex,
                score: formatPuzzleClock(state.elapsedSeconds),
                lines: ['${state.puzzle.tray.length} dominoes'],
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
