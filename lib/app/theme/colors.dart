import 'package:flutter/material.dart';

/// Original color palette for Allways Games.
///
/// Deliberately distinct from NYT Games' black/white crossword icon style
/// and from Wordle's green/yellow/gray tile scheme.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1F5B4C); // deep teal
  static const Color primaryContainer = Color(0xFFD7ECE3);
  static const Color secondary = Color(0xFFE0862F); // warm amber accent
  static const Color secondaryContainer = Color(0xFFFCE6C8);

  static const Color background = Color(0xFFFBF7F0); // warm cream
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF1EBDD);

  static const Color textPrimary = Color(0xFF20241F);
  static const Color textSecondary = Color(0xFF5B6259);

  // Puzzle feedback states (Wordle-style guess grids etc.)
  // Chosen to be visually distinct from Wordle's exact green/yellow/gray.
  static const Color feedbackCorrect = Color(0xFF2E7D5B); // spruce green
  static const Color feedbackPresent = Color(0xFFE0862F); // amber
  static const Color feedbackAbsent = Color(0xFFB9B2A2); // warm stone gray

  static const Color streakFlame = Color(0xFFD9491A);

  // Shared grid chrome (Sudoku, Crossword, Weave, Tile Match). Kept here
  // rather than per game so every grid in the app reads as one family.
  static const Color gridLine = Color(0xFFD9D2C4);
  static const Color gridLineStrong = Color(0xFF6E6A5F);

  /// Cell the player has tapped.
  static const Color cellSelected = Color(0xFFBFDED2);

  /// Cells sharing a row, column or box with the selection.
  static const Color cellPeer = Color(0xFFEDF4F1);

  /// Cells already holding the same digit as the selection.
  static const Color cellMatch = Color(0xFFD7ECE3);

  /// An entry that disagrees with the solution.
  static const Color cellError = Color(0xFFF7DAD5);
  static const Color textError = Color(0xFFB3261E);

  /// Digits the player entered, as opposed to the puzzle's own clues.
  static const Color textEntered = Color(0xFF1F5B4C);

  static const ColorScheme scheme = ColorScheme.light(
    primary: primary,
    primaryContainer: primaryContainer,
    secondary: secondary,
    secondaryContainer: secondaryContainer,
    surface: surface,
    error: Color(0xFFB3261E),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: textPrimary,
    onError: Colors.white,
  );
}
