import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/daily_seed/daily_seed.dart';
import '../../../core/persistence/streak.dart';
import '../../../shared_game_kit/share_card/share_card.dart';
import '../domain/groups_game_state.dart';
import '../domain/groups_puzzle.dart';
import 'groups_providers.dart';

/// Colour per difficulty rank, easiest first.
///
/// The app's own palette, not any other game's. Rank is also spelled out in
/// the solved row's text, so the colour is a reinforcement rather than the
/// only signal.
const List<Color> groupsDifficultyColors = [
  Color(0xFF8FBF6F), // fresh green — the most obvious group
  Color(0xFFE9C46A), // wheat
  Color(0xFF6BA8C4), // slate blue
  Color(0xFF9B6BA8), // plum — the most oblique
];

const List<String> groupsDifficultyLabels = [
  'Straightforward',
  'Warmer',
  'Tricky',
  'Sneaky',
];

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(groupsGameControllerProvider);

    ref.listen(groupsGameControllerProvider, (previous, next) {
      final wasPlaying = previous?.valueOrNull?.isPlaying ?? false;
      final value = next.valueOrNull;
      if (value == null || !wasPlaying || value.isPlaying) return;
      _showResultSheet(context, value);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      body: SafeArea(
        child: asyncState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text("Could not load today's puzzle: $err"),
            ),
          ),
          data: (state) => _GroupsBody(state: state),
        ),
      ),
    );
  }

  void _showResultSheet(BuildContext context, GroupsGameState state) {
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

class _GroupsBody extends ConsumerWidget {
  const _GroupsBody({required this.state});

  final GroupsGameState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(groupsGameControllerProvider.notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Find four groups of four',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Row(
                children: [
                  for (var i = 0; i < groupsMistakeLimit; i++)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.circle,
                        size: 10,
                        color: i < state.mistakesRemaining
                            ? AppColors.primary
                            : AppColors.gridLine,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                for (final category in state.solvedCategories)
                  _SolvedRow(category: category),
                _WordGrid(
                  words: state.remainingWords,
                  selected: state.selected,
                  enabled: state.isPlaying,
                  onTap: controller.toggleWord,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: state.isPlaying ? controller.shuffleTiles : null,
                  child: const Text('Shuffle'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: state.isPlaying && state.selected.isNotEmpty
                      ? controller.deselectAll
                      : null,
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: state.canSubmit
                      ? () async {
                          final result = await controller.submit();
                          if (!context.mounted) return;
                          final message = _messageFor(result.outcome);
                          if (message == null) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      : null,
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Null for a correct guess: the row appearing is feedback enough.
  static String? _messageFor(GroupsGuessOutcome outcome) => switch (outcome) {
        GroupsGuessOutcome.correct => null,
        GroupsGuessOutcome.oneAway => 'One away',
        GroupsGuessOutcome.wrong => 'Not a group',
        GroupsGuessOutcome.repeat => 'You already tried those four',
        GroupsGuessOutcome.notReady => null,
      };
}

class _SolvedRow extends StatelessWidget {
  const _SolvedRow({required this.category});

  final GroupsCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: groupsDifficultyColors[category.difficulty],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // The rank in words as well as in colour, so the difficulty
          // ordering is readable without relying on hue.
          Text(
            groupsDifficultyLabels[category.difficulty],
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            category.name.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 0.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            category.wordTexts.join(', '),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _WordGrid extends StatelessWidget {
  const _WordGrid({
    required this.words,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final List<String> words;
  final Set<String> selected;
  final bool enabled;
  final void Function(String word) onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 3),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.05,
      ),
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        final isSelected = selected.contains(word);
        return Material(
          color: isSelected ? AppColors.primary : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: enabled ? () => onTap(word) : null,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    word,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color:
                          isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ResultSheet extends ConsumerWidget {
  const _ResultSheet({required this.state, required this.dayIndex});

  final GroupsGameState state;
  final int dayIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(groupsStatsProvider);
    final solved = state.status == GroupsStatus.solved;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            solved
                ? (state.mistakes == 0 ? 'Perfect!' : 'Solved!')
                : 'Out of guesses',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            solved
                ? 'All four groups with ${state.mistakes} '
                    '${state.mistakes == 1 ? 'mistake' : 'mistakes'}.'
                : 'The answers are on the board. A new puzzle arrives '
                    'tomorrow.',
            style: Theme.of(context).textTheme.bodyLarge,
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
                    label: 'Perfect',
                    value: '${stats.perfectCount}',
                    icon: Icons.workspace_premium_outlined,
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
                  gameName: 'Groups',
                  dayIndex: dayIndex,
                  score: solved
                      ? '${state.mistakes}/$groupsMistakeLimit'
                      : 'X/$groupsMistakeLimit',
                  // The category names would give the whole puzzle away, so
                  // the card carries the score alone.
                  lines: [
                    '${state.solvedTags.length}/$groupsCategoryCount groups',
                  ],
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
