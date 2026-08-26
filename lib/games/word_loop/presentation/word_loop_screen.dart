import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/streak.dart';
import '../../../shared_game_kit/share_card/share_card.dart';
import '../domain/word_loop_game_state.dart';
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

class WordLoopScreen extends ConsumerWidget {
  const WordLoopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(wordLoopGameControllerProvider);

    ref.listen(wordLoopGameControllerProvider, (previous, next) {
      final wasPlaying = previous?.valueOrNull?.isPlaying ?? false;
      final value = next.valueOrNull;
      if (value == null || !wasPlaying || value.isPlaying) return;
      _showResultSheet(context, value);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Word Loop')),
      body: SafeArea(
        child: asyncState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text("Could not load today's board: $err"),
            ),
          ),
          data: (state) => _WordLoopBody(state: state),
        ),
      ),
    );
  }

  void _showResultSheet(BuildContext context, WordLoopGameState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ResultSheet(state: state, dayIndex: DailySeed.todayIndex()),
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
              'Board complete. A new one arrives tomorrow.',
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
  const _ResultSheet({required this.state, required this.dayIndex});

  final WordLoopGameState state;
  final int dayIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(wordLoopStatsProvider);
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
              final longest = StreakCalculator.longest(stats.solvedDayIndices);
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
                    label: 'Fewest',
                    value: '${stats.bestWordCount ?? used}',
                    icon: Icons.short_text_rounded,
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
                  gameName: 'Word Loop',
                  dayIndex: dayIndex,
                  score: '$used/$par',
                  // The words themselves are deliberately left out: this is
                  // the same board everyone plays today, and a share card
                  // that spoils it is a share card nobody can post.
                  lines: ['Covered all 12 letters'],
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
