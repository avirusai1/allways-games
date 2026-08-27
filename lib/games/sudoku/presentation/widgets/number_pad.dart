import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../domain/sudoku_board.dart';

/// Digit entry pad. Digits already placed nine times are dimmed and
/// disabled so the player isn't offered impossible inputs.
class NumberPad extends StatelessWidget {
  const NumberPad({
    super.key,
    required this.remainingPerDigit,
    required this.onDigit,
    required this.onClear,
    required this.notesMode,
    required this.onToggleNotes,
    required this.enabled,
  });

  final Map<int, int> remainingPerDigit;
  final ValueChanged<int> onDigit;
  final VoidCallback onClear;
  final bool notesMode;
  final VoidCallback onToggleNotes;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ToolButton(
              icon: notesMode ? Icons.edit_note : Icons.edit_outlined,
              label: notesMode ? 'Notes on' : 'Notes',
              active: notesMode,
              onTap: enabled ? onToggleNotes : null,
            ),
            const SizedBox(width: 12),
            _ToolButton(
              icon: Icons.backspace_outlined,
              label: 'Erase',
              active: false,
              onTap: enabled ? onClear : null,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(sudokuSize, (i) {
            final digit = i + 1;
            final remaining = remainingPerDigit[digit] ?? 0;
            return _DigitKey(
              digit: digit,
              exhausted: remaining <= 0,
              onTap: enabled && remaining > 0 ? () => onDigit(digit) : null,
            );
          }),
        ),
      ],
    );
  }
}

class _DigitKey extends StatelessWidget {
  const _DigitKey({
    required this.digit,
    required this.exhausted,
    required this.onTap,
  });

  final int digit;
  final bool exhausted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: exhausted ? AppColors.surfaceAlt.withValues(alpha: 0.4) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.surfaceAlt),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$digit',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: exhausted ? AppColors.textSecondary.withValues(alpha: 0.4) : AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.primaryContainer : AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.surfaceAlt),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}
