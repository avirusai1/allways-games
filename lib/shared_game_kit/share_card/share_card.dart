import 'package:share_plus/share_plus.dart';

import '../../games/five/domain/letter_state.dart';

/// Generic shareable-result text builder, reused by every guess-grid game.
///
/// Deliberately uses its own square glyphs (🟩🟧⬜) rather than the
/// green/yellow/white combination closely associated with Wordle's result
/// share cards.
class ShareCard {
  ShareCard._();

  static const String _correctGlyph = '🟩';
  static const String _presentGlyph = '🟧';
  static const String _absentGlyph = '⬜';

  static String buildResultText({
    required String appName,
    required String gameName,
    required int dayIndex,
    required List<List<LetterState>> evaluations,
    required bool won,
    required int maxGuesses,
  }) {
    final buffer = StringBuffer();
    final score = won ? '${evaluations.length}/$maxGuesses' : 'X/$maxGuesses';
    buffer.writeln('$appName $gameName #$dayIndex $score');
    buffer.writeln();
    for (final row in evaluations) {
      buffer.writeln(row.map(_glyphFor).join());
    }
    return buffer.toString().trim();
  }

  /// Result text for games that have no guess grid to draw.
  ///
  /// Same headline shape as [buildResultText] so every game's share card
  /// reads as coming from the same app, with each game supplying its own
  /// body [lines] (a time, a word count, a tier).
  static String buildSummaryResultText({
    required String appName,
    required String gameName,
    required int dayIndex,
    required String score,
    List<String> lines = const [],
  }) {
    final buffer = StringBuffer()..writeln('$appName $gameName #$dayIndex $score');
    if (lines.isNotEmpty) {
      buffer.writeln();
      for (final line in lines) {
        buffer.writeln(line);
      }
    }
    return buffer.toString().trim();
  }

  static Future<void> share(String text) {
    return Share.share(text);
  }

  static String _glyphFor(LetterState state) {
    switch (state) {
      case LetterState.correct:
        return _correctGlyph;
      case LetterState.present:
        return _presentGlyph;
      case LetterState.absent:
      case LetterState.empty:
        return _absentGlyph;
    }
  }
}
