import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/streak.dart';
import '../../../shared_game_kit/difficulty/difficulty_picker.dart';
import '../../../shared_game_kit/share_card/share_card.dart';
import '../domain/word_loop_game_state.dart';
import '../domain/word_loop_puzzle.dart';
import 'widgets/word_loop_board.dart';
import 'word_loop_providers.dart';

/// Player-facing copy for each way a word can be turned away.
String wordLoopRejectionMessage(WordLoopRejection rejection) {
  return switch (rejection) {
    WordLoopRejection.tooShort => 'Words need at least three letters',
    WordLoopRejection.letterNotOnBoard => 'That letter is not on the board',
    WordLoopRejection.sameSideTwice =>
      'Two letters in a row from the same side',
    WordLoopRejection.notAWord => 'Not a word we know',
    WordLoopRejection.alreadyUsed => 'You have played that word already',
    WordLoopRejection.wrongStartingLetter =>
      'Start with the last letter of your previous word',
  };
}

const List<DifficultyOption<WordLoopDifficulty>> _difficultyOptions = [
  DifficultyOption(
    value: WordLoopDifficulty.easy,
    label: 'Easy',
    description: 'Plenty of words fit this board',
    icon: Icons.sentiment_satisfied_outlined,
  ),
  DifficultyOption(
    value: WordLoopDifficulty.medium,
    label: 'Medium',
    description: 'A fair spread of options',
    icon: Icons.sentiment_neutral_outlined,
  ),
  DifficultyOption(
    value: WordLoopDifficulty.hard,
    label: 'Hard',
    description: 'Few words fit — plan your path',
    icon: Icons.local_fire_department_outlined,
  ),
];

class WordLoopScreen extends ConsumerWidget {
  const WordLoopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(wordLoopGameControllerProvider);

    ref.listen(wordLoopGameControllerProvider, (previous, next) {
      final wasPlaying = previous?.valueOrNull?.isPlaying ?? false;
      final value = next.valueOrNull;
      if (value == null || !wasPlaying || value.isPlaying) return;
      _showResultSheet(context, ref, value);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Loop'),
        actions: [
          asyncState.maybeWhen(
            data: (state) => state == null
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Change difficulty',
                    icon: const Icon(Icons.tune),
                    onPressed: () => ref
                        .read(wordLoopGameControllerProvider.notifier)
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
              child: Text('Could not load Word Loop: $err'),
            ),
          ),
          data: (state) => state == null
              ? _DifficultyPickerBody(
                  onSelect: (d) => ref
                      .read(wordLoopGameControllerProvider.notifier)
                      .selectDifficulty(d),
                )
              : _WordLoopBody(state: state),
        ),
      ),
    );
  }

  void _showResultSheet(
    BuildContext context,
    WidgetRef ref,
    WordLoopGameState state,
  ) {
    final difficulty =
        ref.read(wordLoopGameControllerProvider.notifier).currentDifficulty ??
            WordLoopDifficulty.medium;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ResultSheet(
        state: state,
        dayIndex: DailySeed.todayIndex(),
        difficulty: difficulty,
      ),
    );
  }
}

class _DifficultyPickerBody extends ConsumerWidget {
  const _DifficultyPickerBody({required this.onSelect});

  final ValueChanged<WordLoopDifficulty> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final freePlay = ref.watch(wordLoopFreePlayStatsProvider);
    final solvedCounts = freePlay.maybeWhen(
      data: (stats) => {
        for (final d in WordLoopDifficulty.values)
          d: stats.forDifficulty(d.name).solved,
      },
      orElse: () => const <WordLoopDifficulty, int>{},
    );

    return DifficultyPicker<WordLoopDifficulty>(
      title: 'Choose a difficulty',
      options: _difficultyOptions,
      solvedCounts: solvedCounts,
      onSelect: onSelect,
    );
  }
}

class _WordLoopBody extends ConsumerWidget {
  const _WordLoopBody({required this.state});

  final WordLoopGameState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(wordLoopGameControllerProvider.notifier);
    final remaining = state.remainingLetters.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Words: ${state.wordsUsed}  ·  Par ${state.puzzle.par}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                remaining == 0 ? 'All letters used' : '$remaining letters left',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        if (state.chain.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                for (final word in state.chain)
                  Chip(
                    label: Text(word),
                    backgroundColor: AppColors.primaryContainer,
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            state.currentInput.isEmpty ? ' ' : state.currentInput,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: AppColors.primary,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: WordLoopBoardView(
              box: state.puzzle.box,
              currentInput: state.currentInput,
              usedLetters: state.usedLetters,
              onLetterTap: controller.inputLetter,
            ),
          ),
        ),
        if (!state.isPlaying)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Board complete!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: state.isPlaying ? controller.backspace : null,
                  child: const Text('Delete'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: state.isPlaying && state.chain.isNotEmpty
                      ? controller.undoWord
                      : null,
                  child: const Text('Undo word'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: state.isPlaying
                      ? () async {
                          final rejection = await controller.submit();
                          if (rejection == null || !context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(wordLoopRejectionMessage(rejection)),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      : null,
                  child: const Text('Enter'),
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
  const _ResultSheet({
    required this.state,
    required this.dayIndex,
    required this.difficulty,
  });

  final WordLoopGameState state;
  final int dayIndex;
  final WordLoopDifficulty difficulty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(wordLoopStatsProvider);
    final freePlayAsync = ref.watch(wordLoopFreePlayStatsProvider);
    final par = state.puzzle.par;
    final used = state.wordsUsed;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            used <= par ? 'Perfect!' : 'Board covered',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            used <= par
                ? 'You covered all twelve letters in $used words — par.'
                : 'You covered all twelve letters in $used words. Par is $par.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'A par answer: ${state.puzzle.exampleSolution.join(' → ')}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          statsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (stats) {
              final current =
                  StreakCalculator.current(stats.solvedDayIndices, dayIndex);
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
                    label: 'Fewest',
                    value: tier?.bestSeconds == null
                        ? '$used'
                        : '${tier!.bestSeconds}',
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
                    ref
                        .read(wordLoopGameControllerProvider.notifier)
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
                      .read(wordLoopGameControllerProvider.notifier)
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
                    gameName: 'Word Loop',
                    dayIndex: dayIndex,
                    score: '$used/$par',
                    // The words themselves are deliberately left out: a
                    // share card that spoils this exact board for a friend
                    // who's about to play it is one nobody can post.
                    lines: ['${difficulty.label} · covered all 12 letters'],
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
