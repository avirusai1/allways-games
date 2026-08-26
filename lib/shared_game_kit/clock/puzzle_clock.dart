/// Shared elapsed-time formatting for timed puzzles.
///
/// Lives in the game kit rather than inside whichever game needed it
/// first, so Sudoku and Tile Match (and anything timed after them) render
/// the same duration identically instead of one game importing another
/// game's screen.
library;

/// Formats [totalSeconds] the way a puzzle timer reads: m:ss, growing an
/// hours field only once a board has genuinely taken that long.
String formatPuzzleClock(int totalSeconds) {
  final seconds = totalSeconds % 60;
  final minutes = (totalSeconds ~/ 60) % 60;
  final hours = totalSeconds ~/ 3600;
  final mm = minutes.toString().padLeft(hours > 0 ? 2 : 1, '0');
  final ss = seconds.toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$mm:$ss' : '$mm:$ss';
}
