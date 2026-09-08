import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

/// One selectable tier on a difficulty picker.
class DifficultyOption<T> {
  const DifficultyOption({
    required this.value,
    required this.label,
    required this.description,
    required this.icon,
  });

  final T value;
  final String label;
  final String description;
  final IconData icon;
}

/// A "pick your difficulty" screen body, shared by every free-play game.
///
/// Games that used to load a single date-locked puzzle now start here
/// instead: the player commits to a tier up front, then plays as many
/// puzzles of it as they want.
class DifficultyPicker<T> extends StatelessWidget {
  const DifficultyPicker({
    super.key,
    required this.title,
    required this.options,
    required this.onSelect,
    this.solvedCounts = const {},
  });

  final String title;
  final List<DifficultyOption<T>> options;
  final ValueChanged<T> onSelect;

  /// Optional "N solved" count per option value, shown as a small badge so
  /// returning players see their own progress at a glance.
  final Map<T, int> solvedCounts;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            for (final option in options) ...[
              _DifficultyCard(
                option: option,
                solved: solvedCounts[option.value],
                onTap: () => onSelect(option.value),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _DifficultyCard<T> extends StatelessWidget {
  const _DifficultyCard({
    required this.option,
    required this.solved,
    required this.onTap,
  });

  final DifficultyOption<T> option;
  final int? solved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.surfaceAlt),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(option.icon, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.label, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      option.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (solved != null && solved! > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$solved solved',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
