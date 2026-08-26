/// Scoring and rank rules for Honeycomb.
///
/// Pure Dart, no Flutter imports, so the offline generator and the unit
/// tests share exactly the scoring the app applies.
library;

const int honeycombLetterCount = 7;

/// Shorter than this and a seven-letter board would be swamped by
/// three-letter fragments, most of which nobody would think to try.
const int honeycombMinWordLength = 4;

/// Bonus on top of the length score for using all seven letters.
const int honeycombPangramBonus = 7;

/// Points for [word].
///
/// The shortest allowed word is worth a single point regardless of its
/// letters; past that a word scores its length, so reaching for longer
/// words is always worth more than piling up short ones. A pangram takes
/// the length score plus a flat bonus.
int honeycombScoreFor(String word, {required bool isPangram}) {
  final length = word.length;
  if (length < honeycombMinWordLength) return 0;
  final base = length == honeycombMinWordLength ? 1 : length;
  return isPangram ? base + honeycombPangramBonus : base;
}

/// A rung on the ladder from first word to every word.
class HoneycombRank {
  const HoneycombRank(this.name, this.percentOfMax);

  final String name;

  /// Share of the board's maximum score this rank starts at.
  final int percentOfMax;
}

/// The rank ladder, easiest first.
///
/// Named around the hive rather than borrowing any existing game's titles.
/// The early rungs are deliberately close together: a player who finds four
/// or five words should see the label move, because that early sense of
/// progress is what brings them back tomorrow.
const List<HoneycombRank> honeycombRanks = [
  HoneycombRank('Forager', 0),
  HoneycombRank('Scout', 4),
  HoneycombRank('Worker', 12),
  HoneycombRank('Builder', 25),
  HoneycombRank('Keeper', 40),
  HoneycombRank('Master', 58),
  HoneycombRank('Hive Mind', 78),
  HoneycombRank('Full Comb', 100),
];

/// The rank [score] earns on a board worth [maxScore].
HoneycombRank honeycombRankFor(int score, int maxScore) {
  if (maxScore <= 0) return honeycombRanks.first;
  final percent = score * 100 / maxScore;
  var earned = honeycombRanks.first;
  for (final rank in honeycombRanks) {
    if (percent + 1e-9 >= rank.percentOfMax) earned = rank;
  }
  return earned;
}

/// Score needed to reach [rank] on a board worth [maxScore].
///
/// Rounded up, so the displayed target is always a score that actually
/// earns the rank rather than one point short of it.
int honeycombScoreForRank(HoneycombRank rank, int maxScore) {
  return (maxScore * rank.percentOfMax + 99) ~/ 100;
}
