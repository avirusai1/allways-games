import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/streak.dart';
import '../../../shared_game_kit/difficulty/difficulty_picker.dart';
import '../../../shared_game_kit/keyboard/on_screen_keyboard.dart';
import '../../../shared_game_kit/share_card/share_card.dart';
import '../domain/five_game_state.dart';
import '../generation/five_content_bank.dart';
import 'five_providers.dart';
import 'widgets/guess_grid.dart';

const List<DifficultyOption<FiveDifficulty>> _difficultyOptions = [
  DifficultyOption(
    value: FiveDifficulty.easy,
    label: 'Easy',
    description: 'Common letters, few repeats',
    icon: Icons.sentiment_satisfied_outlined,
  ),
  DifficultyOption(
    value: FiveDifficulty.medium,
    label: 'Medium',
    description: 'A fair mix of letters',
    icon: Icons.sentiment_neutral_outlined,
  ),
  DifficultyOption(
    value: FiveDifficulty.hard,
    label: 'Hard',
    description: 'Rare letters, or repeats to untangle',
    icon: Icons.local_fire_department_outlined,
  ),
];

class FiveScreen extends ConsumerWidget {
  const FiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(fiveGameControllerProvider);

    ref.listen(fiveGameControllerProvider, (previous, next) {
      final prevStatus = previous?.valueOrNull?.status;
      final nextValue = next.valueOrNull;
      if (nextValue == null) return;
      final justFinished = prevStatus == FiveStatus.playing &&
          nextValue.status != FiveStatus.playing;
      if (justFinished) {
        _showResultSheet(context, ref, nextValue);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Five'),
        actions: [
          asyncState.maybeWhen(
            data: (state) => state == null
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Change difficulty',
                    icon: const Icon(Icons.tune),
                    onPressed: () => ref
                        .read(fiveGameControllerProvider.notifier)
                        .changeDifficulty(),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: asyncState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Could not load Five: $err')),
          data: (state) => state == null
              ? _DifficultyPickerBody(
                  onSelect: (d) => ref
                      .read(fiveGameControllerProvider.notifier)
                      .selectDifficulty(d),
                )
              : Column(
                  children: [
                    const SizedBox(height: 12),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(child: GuessGrid(state: state)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: OnScreenKeyboard(
                        letterStates: {
                          for (final e in state.keyboardStates.entries)
                            e.key.toUpperCase(): e.value,
                        },
                        onLetter: (l) =>
                            ref.read(fiveGameControllerProvider.notifier).inputLetter(l),
                        onBackspace: () =>
                            ref.read(fiveGameControllerProvider.notifier).backspace(),
                        onSubmit: () async {
                          final error =
                              await ref.read(fiveGameControllerProvider.notifier).submit();
                          if (error != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error), duration: const Duration(seconds: 1)),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _showResultSheet(BuildContext context, WidgetRef ref, FiveGameState state) {
    final difficulty =
        ref.read(fiveGameControllerProvider.notifier).currentDifficulty ??
            FiveDifficulty.medium;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) =>
          _ResultSheet(state: state, dayIndex: DailySeed.todayIndex(), difficulty: difficulty),
    );
  }
}

class _DifficultyPickerBody extends ConsumerWidget {
  const _DifficultyPickerBody({required this.onSelect});

  final ValueChanged<FiveDifficulty> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final freePlay = ref.watch(fiveFreePlayStatsProvider);
    final solvedCounts = freePlay.maybeWhen(
      data: (stats) => {
        for (final d in FiveDifficulty.values)
          d: stats.forDifficulty(d.name).solved,
      },
      orElse: () => const <FiveDifficulty, int>{},
    );

    return DifficultyPicker<FiveDifficulty>(
      title: 'Choose a difficulty',
      options: _difficultyOptions,
      solvedCounts: solvedCounts,
      onSelect: onSelect,
    );
  }
}

class _ResultSheet extends ConsumerWidget {
  const _ResultSheet({
    required this.state,
    required this.dayIndex,
    required this.difficulty,
  });

  final FiveGameState state;
  final int dayIndex;
  final FiveDifficulty difficulty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(fiveStatsProvider);
    final freePlayAsync = ref.watch(fiveFreePlayStatsProvider);
    final won = state.status == FiveStatus.won;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            won ? 'Solved!' : 'Out of guesses',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            won
                ? 'You got it in ${state.submittedGuesses.length}/$fiveMaxGuesses.'
                : 'The word was ${state.answer.toUpperCase()}.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          statsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (stats) {
              final current = StreakCalculator.current(stats.wonDayIndices, dayIndex);
              final tier = freePlayAsync.maybeWhen(
                data: (fp) => fp.forDifficulty(difficulty.name),
                orElse: () => null,
              );
              return Row(
                children: [
                  _StatChip(label: 'Streak', value: '$current', icon: Icons.local_fire_department),
                  const SizedBox(width: 12),
                  _StatChip(
                    label: 'Solved',
                    value: tier == null ? '—' : '${tier.solved}',
                    icon: Icons.check_circle_outline,
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    label: 'Fewest',
                    value: tier?.bestSeconds == null ? '—' : '${tier!.bestSeconds}',
                    icon: Icons.short_text_rounded,
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
                    ref.read(fiveGameControllerProvider.notifier).selectDifficulty(difficulty);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Play another'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(fiveGameControllerProvider.notifier).changeDifficulty();
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
                final text = ShareCard.buildResultText(
                  appName: 'Allways Games',
                  gameName: 'Five',
                  dayIndex: dayIndex,
                  evaluations: state.evaluations,
                  won: won,
                  maxGuesses: fiveMaxGuesses,
                );
                ShareCard.share(text);
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
  const _StatChip({required this.label, required this.value, required this.icon});

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
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
