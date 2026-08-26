/// Shared deterministic date -> puzzle-index logic used by every game module.
///
/// Every game picks "today's puzzle" the same way: compute [dayIndex] from
/// the device's local calendar date, then index into that game's
/// pre-generated content bank. Same formula everywhere keeps all 9 games'
/// daily rollover behavior consistent and makes the archive screens trivial
/// (an archive entry is just a past [dayIndex] against the same bank).
class DailySeed {
  DailySeed._();

  /// Epoch predates any real launch date so early archive entries exist
  /// for testing. Never change this once puzzle banks are generated against
  /// it — doing so would shift every user's daily puzzle.
  static final DateTime epoch = DateTime(2024, 1, 1);

  /// Day index for [date] (device local date, time-of-day ignored).
  static int dayIndexFor(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    return local.difference(epoch).inDays;
  }

  /// Day index for "today" on the device's local clock.
  static int todayIndex() => dayIndexFor(DateTime.now());
}

/// A game's puzzle content bank: a fixed, ordered list of pre-generated
/// puzzles produced offline (see tool/gen_*.dart) and shipped as a bundled
/// asset. Lookup is a simple modulo index, never on-device generation.
abstract class DailyPuzzleBank<T> {
  List<T> get puzzles;

  T puzzleForDayIndex(int dayIndex) {
    if (puzzles.isEmpty) {
      throw StateError('Puzzle bank is empty.');
    }
    return puzzles[dayIndex % puzzles.length];
  }

  T puzzleForToday() => puzzleForDayIndex(DailySeed.todayIndex());
}
