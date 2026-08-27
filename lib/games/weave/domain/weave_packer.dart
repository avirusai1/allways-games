import 'dart:math';

import 'weave_grid.dart';

/// One word laid into the grid, with the cells it occupies in order.
class WeavePlacement {
  const WeavePlacement({required this.word, required this.path});

  final String word;
  final List<int> path;
}

class WeavePacking {
  const WeavePacking({required this.placements, required this.spanner});

  final List<WeavePlacement> placements;

  /// The word whose path reaches both the top and bottom rows.
  final String spanner;

  /// The grid's letters, derived from the placements.
  List<String> get letters {
    final out = List<String>.filled(weaveCellCount, '');
    for (final placement in placements) {
      for (var i = 0; i < placement.path.length; i++) {
        out[placement.path[i]] = placement.word[i];
      }
    }
    return out;
  }
}

/// Packs a set of theme words into the grid so that together they cover
/// every cell exactly once, with one word spanning top to bottom.
///
/// This is the hard part of Weave. A plain word search hides words in a
/// grid of filler; here there is no filler at all — the words *are* the
/// grid, so the chosen word lengths must sum to exactly [weaveCellCount]
/// and their paths must tile it perfectly.
class WeavePacker {
  WeavePacker._();

  /// Chooses a subset of [themeWords] whose lengths sum to exactly the
  /// cell count, including at least one word long enough to span the grid.
  ///
  /// Exact subset-sum rather than a greedy fill: greedily taking words
  /// until the grid is nearly full almost always strands a remainder no
  /// remaining word can match.
  static List<String>? chooseWordSet(
    List<String> themeWords,
    Random rng, {
    int minWords = 5,
    int maxWords = 9,
  }) {
    final usable = themeWords
        .map((w) => w.toUpperCase())
        .where((w) => w.length >= 4 && w.length <= weaveCellCount)
        .toSet()
        .toList()
      ..shuffle(rng);

    final spanners = usable.where((w) => w.length >= weaveRows).toList();
    if (spanners.isEmpty) return null;

    for (final spanner in spanners) {
      // Shortest first, so the search settles on many short words rather
      // than a few long ones. Long words are far harder to tile: they bend
      // through more of the grid and strand awkward regions behind them.
      final rest = usable.where((w) => w != spanner).toList()
        ..sort((a, b) => a.length.compareTo(b.length));
      final target = weaveCellCount - spanner.length;
      final subset = _subsetSum(rest, target, minWords - 1, maxWords - 1);
      if (subset != null) return [spanner, ...subset];
    }
    return null;
  }

  /// Depth-first exact subset-sum over word lengths.
  static List<String>? _subsetSum(
    List<String> words,
    int target,
    int minCount,
    int maxCount,
  ) {
    final chosen = <String>[];

    bool search(int index, int remaining) {
      if (remaining == 0) {
        return chosen.length >= minCount && chosen.length <= maxCount;
      }
      if (index >= words.length || chosen.length >= maxCount) return false;
      for (var i = index; i < words.length; i++) {
        final word = words[i];
        if (word.length > remaining) continue;
        chosen.add(word);
        if (search(i + 1, remaining - word.length)) return true;
        chosen.removeLast();
      }
      return false;
    }

    return search(0, target) ? List<String>.of(chosen) : null;
  }

  /// Lays [words] into the grid. Returns null if no packing was found
  /// inside [nodeBudget] — a normal outcome, the caller retries with a
  /// different word set or seed.
  static WeavePacking? pack(
    List<String> words,
    Random rng, {
    int nodeBudget = 120000,
  }) {
    final totalLength = words.fold<int>(0, (n, w) => n + w.length);
    if (totalLength != weaveCellCount) return null;

    // Longest first: the constrained words are far easier to place while
    // the grid is still empty.
    final ordered = List<String>.of(words)
      ..sort((a, b) => b.length.compareTo(a.length));

    final occupied = List<bool>.filled(weaveCellCount, false);
    final placements = <WeavePlacement>[];
    var nodes = 0;

    /// Whether the empty cells can still hold every word left to place.
    ///
    /// Words must occupy contiguous regions, so an empty region smaller
    /// than the shortest remaining word can never be filled. Catching that
    /// here prunes far more than discovering it several words later.
    bool regionsViable(int shortestRemaining) {
      final seen = List<bool>.filled(weaveCellCount, false);
      for (var start = 0; start < weaveCellCount; start++) {
        if (occupied[start] || seen[start]) continue;
        var size = 0;
        final stack = <int>[start];
        seen[start] = true;
        while (stack.isNotEmpty) {
          final cell = stack.removeLast();
          size++;
          for (final next in weaveAdjacency[cell]) {
            if (!occupied[next] && !seen[next]) {
              seen[next] = true;
              stack.add(next);
            }
          }
        }
        if (size < shortestRemaining) return false;
      }
      return true;
    }

    bool placeWord(int wordIndex) {
      if (wordIndex == ordered.length) return true;
      final word = ordered[wordIndex];

      final shortestRemaining = ordered
          .sublist(wordIndex + 1)
          .fold<int>(weaveCellCount, (n, w) => w.length < n ? w.length : n);

      final path = <int>[];

      bool descend(int position) {
        if (nodes++ > nodeBudget) return false;
        if (position == word.length) {
          placements.add(WeavePlacement(word: word, path: List<int>.of(path)));
          if (wordIndex + 1 == ordered.length ||
              (regionsViable(shortestRemaining) && placeWord(wordIndex + 1))) {
            return true;
          }
          placements.removeLast();
          return false;
        }

        final candidates = position == 0
            ? (List<int>.generate(weaveCellCount, (i) => i)..shuffle(rng))
            : (List<int>.of(weaveAdjacency[path.last])..shuffle(rng));

        for (final cell in candidates) {
          if (occupied[cell]) continue;
          occupied[cell] = true;
          path.add(cell);
          if (descend(position + 1)) return true;
          path.removeLast();
          occupied[cell] = false;
        }
        return false;
      }

      return descend(0);
    }

    if (!placeWord(0)) return null;

    // The spanner must be a theme word that reaches both edge rows.
    final spanning = placements.where((p) => spansGrid(p.path)).toList();
    if (spanning.isEmpty) return null;
    // Prefer the longest spanning word: it is the strongest theme clue.
    spanning.sort((a, b) => b.word.length.compareTo(a.word.length));

    return WeavePacking(placements: placements, spanner: spanning.first.word);
  }
}
