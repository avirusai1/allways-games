import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/streak.dart';
import '../../../shared_game_kit/clock/puzzle_clock.dart';
import '../../../shared_game_kit/difficulty/difficulty_picker.dart';
import '../../../shared_game_kit/keyboard/on_screen_keyboard.dart';
import '../../../shared_game_kit/share_card/share_card.dart';
import '../domain/crossword_game_state.dart';
import '../domain/crossword_grid.dart';
import '../domain/crossword_puzzle.dart';
import 'crossword_providers.dart';
import 'widgets/crossword_board.dart';

const List<DifficultyOption<CrosswordDifficulty>> _difficultyOptions = [
  DifficultyOption(
    value: CrosswordDifficulty.easy,
    label: 'Easy',
    description: 'More black squares, fewer to fill',
    icon: Icons.sentiment_satisfied_outlined,
  ),
  DifficultyOption(
    value: CrosswordDifficulty.hard,
    label: 'Hard',
    description: 'A more open grid, more to fill',
    icon: Icons.local_fire_department_outlined,
  ),
];

class CrosswordScreen extends ConsumerStatefulWidget {
  const CrosswordScreen({super.key});

  @override
  ConsumerState<CrosswordScreen> createState() => _CrosswordScreenState();
}

class _CrosswordScreenState extends ConsumerState<CrosswordScreen> {
  bool _showMistakes = false;

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(crosswordGameControllerProvider);

    ref.listen(crosswordGameControllerProvider, (previous, next) {
      final wasPlaying = previous?.valueOrNull?.isPlaying ?? false;
      final value = next.valueOrNull;
      if (value == null) return;
      if (wasPlaying && value.status == CrosswordStatus.solved) {
        final difficulty = ref
                .read(crosswordGameControllerProvider.notifier)
                .currentDifficulty ??
            CrosswordDifficulty.easy;
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
        title: const Text('Crossword'),
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
                        .read(crosswordGameControllerProvider.notifier)
                        .changeDifficulty(),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: asyncState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Could not load Crossword: $err')),
          data: (state) => state == null
              ? _DifficultyPickerBody(
                  onSelect: (d) => ref
                      .read(crosswordGameControllerProvider.notifier)
                      .selectDifficulty(d),
                )
              : _Body(
                  state: state,
                  showMistakes: _showMistakes,
                  onToggleMistakes: () =>
                      setState(() => _showMistakes = !_showMistakes),
                ),
        ),
      ),
    );
  }
}

class _DifficultyPickerBody extends ConsumerWidget {
  const _DifficultyPickerBody({required this.onSelect});

  final ValueChanged<CrosswordDifficulty> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final freePlay = ref.watch(crosswordFreePlayStatsProvider);
    final solvedCounts = freePlay.maybeWhen(
      data: (stats) => {
        for (final d in CrosswordDifficulty.values)
          d: stats.forDifficulty(d.name).solved,
      },
      orElse: () => const <CrosswordDifficulty, int>{},
    );

    return DifficultyPicker<CrosswordDifficulty>(
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
    required this.showMistakes,
    required this.onToggleMistakes,
  });

  final CrosswordGameState state;
  final bool showMistakes;
  final VoidCallback onToggleMistakes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(crosswordGameControllerProvider.notifier);
    final entry = state.currentEntry;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CrosswordBoard(
            state: state,
            onCellTap: controller.selectCell,
            showMistakes: showMistakes,
          ),
        ),
        // The clue for wherever the cursor is, repeated large so the
        // player is not hunting the list for the one they are typing.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Material(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: controller.toggleDirection,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Text(
                      entry == null
                          ? ''
                          : '${entry.number}'
                              '${entry.direction == CrosswordDirection.across ? 'A' : 'D'}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry?.clue ?? '',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    const Icon(Icons.swap_horiz, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: state.isPlaying ? controller.revealCell : null,
                icon: const Icon(Icons.lightbulb_outline, size: 18),
                label: const Text('Reveal letter'),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onToggleMistakes,
                icon: Icon(
                  showMistakes ? Icons.visibility_off : Icons.spellcheck,
                  size: 18,
                ),
                label: Text(showMistakes ? 'Hide' : 'Check'),
              ),
            ],
          ),
        ),
        // The full clue list, in the space between the buttons and the
        // keyboard. A mini is short enough that seeing every clue at once
        // is part of solving it — leaving that space empty wasted the
        // most useful part of the screen.
        Expanded(
          child: _ClueList(
            state: state,
            onSelect: (entry) {
              controller.selectCell(entry.cells.first);
              if (state.direction != entry.direction) {
                controller.toggleDirection();
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: OnScreenKeyboard(
            letterStates: const {},
            onLetter: controller.enterLetter,
            onBackspace: controller.backspace,
            onSubmit: controller.toggleDirection,
          ),
        ),
      ],
    );
  }
}

/// Across and down clues side by side, with the current one picked out.
class _ClueList extends StatelessWidget {
  const _ClueList({required this.state, required this.onSelect});

  final CrosswordGameState state;
  final ValueChanged<CrosswordEntry> onSelect;

  @override
  Widget build(BuildContext context) {
    final current = state.currentEntry;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _ClueColumn(
              title: 'ACROSS',
              entries: state.puzzle.across,
              current: current,
              solved: state.entered,
              onSelect: onSelect,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ClueColumn(
              title: 'DOWN',
              entries: state.puzzle.down,
              current: current,
              solved: state.entered,
              onSelect: onSelect,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClueColumn extends StatelessWidget {
  const _ClueColumn({
    required this.title,
    required this.entries,
    required this.current,
    required this.solved,
    required this.onSelect,
  });

  final String title;
  final List<CrosswordEntry> entries;
  final CrosswordEntry? current;
  final List<String> solved;
  final ValueChanged<CrosswordEntry> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 10,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isCurrent = current != null &&
                  current!.number == entry.number &&
                  current!.direction == entry.direction;
              // A clue whose squares are all filled is struck through, so
              // the list shows what is left rather than just what exists.
              final done = entry.cells.every((c) => solved[c].isNotEmpty);
              return InkWell(
                onTap: () => onSelect(entry),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    '${entry.number}. ${entry.clue}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          fontWeight:
                              isCurrent ? FontWeight.w700 : FontWeight.w400,
                          color: isCurrent
                              ? AppColors.textPrimary
                              : (done
                                  ? AppColors.textSecondary
                                      .withValues(alpha: 0.5)
                                  : AppColors.textSecondary),
                        ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ResultSheet extends ConsumerWidget {
  const _ResultSheet({required this.state, required this.difficulty});

  final CrosswordGameState state;
  final CrosswordDifficulty difficulty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(crosswordStatsProvider);
    final freePlayAsync = ref.watch(crosswordFreePlayStatsProvider);
    final dayIndex = DailySeed.todayIndex();
    final revealed = state.revealedCells.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Solved!', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            revealed == 0
                ? '${difficulty.label} in ${formatPuzzleClock(state.elapsedSeconds)}, '
                    'unaided.'
                : '${difficulty.label} in ${formatPuzzleClock(state.elapsedSeconds)}, '
                    'with $revealed letter${revealed == 1 ? '' : 's'} revealed.',
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
                    label: 'Solved',
                    value: tier == null ? '—' : '${tier.solved}',
                    icon: Icons.check_circle_outline,
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    label: 'Fastest',
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
                        .read(crosswordGameControllerProvider.notifier)
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
                  ref
                      .read(crosswordGameControllerProvider.notifier)
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
              onPressed: () => ShareCard.share(
                ShareCard.buildSummaryResultText(
                  appName: 'Allways Games',
                  gameName: 'Crossword',
                  dayIndex: dayIndex,
                  score: formatPuzzleClock(state.elapsedSeconds),
                  lines: [
                    difficulty.label,
                    if (revealed == 0) 'No letters revealed' else '$revealed revealed',
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
