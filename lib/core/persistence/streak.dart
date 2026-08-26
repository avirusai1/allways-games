/// Pure streak calculation, shared by every game's stats screen.
///
/// [wonDayIndices] is the set of dayIndex values the player won for a given
/// game. [todayIndex] is today's DailySeed.todayIndex().
class StreakCalculator {
  StreakCalculator._();

  /// Current streak: consecutive won days ending at today or yesterday
  /// (yesterday still counts so the streak doesn't drop before today's
  /// puzzle has been attempted).
  static int current(Set<int> wonDayIndices, int todayIndex) {
    int streak = 0;
    int day = wonDayIndices.contains(todayIndex) ? todayIndex : todayIndex - 1;
    while (wonDayIndices.contains(day)) {
      streak++;
      day--;
    }
    return streak;
  }

  /// Longest streak ever achieved across all recorded days.
  static int longest(Set<int> wonDayIndices) {
    if (wonDayIndices.isEmpty) return 0;
    final sorted = wonDayIndices.toList()..sort();
    int longest = 1;
    int running = 1;
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i] == sorted[i - 1] + 1) {
        running++;
        longest = running > longest ? running : longest;
      } else {
        running = 1;
      }
    }
    return longest;
  }
}
