import 'dart:math';

import 'word_loop_box.dart';
import 'word_loop_solver.dart';

/// Builds Word Loop boards from a seed chain of words.
///
/// The board is derived from its intended answer rather than the other way
/// round: pick two common words that between them use exactly twelve
/// distinct letters, then find a side layout on which both can be traced.
/// Sampling random letter sets and hoping for a good board wastes almost
/// every draw.
class WordLoopGenerator {
  WordLoopGenerator._();

  /// Letter pairs that may not share a side, because they sit next to each
  /// other somewhere in [words].
  static Set<String> adjacencyConstraints(Iterable<String> words) {
    final pairs = <String>{};
    for (final word in words) {
      final upper = word.toUpperCase();
      for (var i = 0; i + 1 < upper.length; i++) {
        final a = upper[i];
        final b = upper[i + 1];
        // Store both orders so lookup never has to sort.
        pairs.add('$a$b');
        pairs.add('$b$a');
      }
    }
    return pairs;
  }

  /// Splits the twelve distinct letters of [words] across four sides so
  /// that every word in [words] is playable, or returns null when no such
  /// split exists.
  ///
  /// This is a graph colouring: letters are nodes, "adjacent somewhere in a
  /// seed word" are edges, the four sides are colours, and each colour must
  /// be used exactly three times. Twelve nodes is small enough for plain
  /// backtracking with a most-constrained-first ordering.
  static WordLoopBox? layOut(List<String> words, Random random) {
    final letters = <String>{};
    for (final word in words) {
      letters.addAll(word.toUpperCase().split(''));
    }
    if (letters.length != wordLoopLetterCount) return null;

    final constraints = adjacencyConstraints(words);
    // A letter adjacent to a letter is impossible to place: it would have
    // to sit on two different sides at once.
    if (letters.any((letter) => constraints.contains('$letter$letter'))) {
      return null;
    }

    final ordered = letters.toList()..shuffle(random);
    // Most-constrained letters first: they are the ones that make a
    // partial assignment fail, and failing early keeps the search small.
    ordered.sort((a, b) {
      int degree(String letter) =>
          letters.where((other) => constraints.contains('$letter$other')).length;
      return degree(b).compareTo(degree(a));
    });

    final assignment = <String, int>{};
    final sideCounts = List<int>.filled(wordLoopSideCount, 0);

    bool place(int position) {
      if (position == ordered.length) return true;
      final letter = ordered[position];

      final sideOrder = List<int>.generate(wordLoopSideCount, (i) => i)
        ..shuffle(random);
      for (final side in sideOrder) {
        if (sideCounts[side] >= wordLoopLettersPerSide) continue;
        final clashes = assignment.entries.any(
          (entry) => entry.value == side && constraints.contains('$letter${entry.key}'),
        );
        if (clashes) continue;

        assignment[letter] = side;
        sideCounts[side]++;
        if (place(position + 1)) return true;
        assignment.remove(letter);
        sideCounts[side]--;
      }
      return false;
    }

    if (!place(0)) return null;

    final sides = List<List<String>>.generate(wordLoopSideCount, (side) {
      return [
        for (final entry in assignment.entries)
          if (entry.value == side) entry.key,
      ]..sort();
    });
    return WordLoopBox(sides);
  }

  /// Ordered pairs from [candidates] that chain and between them use
  /// exactly twelve distinct letters.
  ///
  /// [onPair] is called for each hit and returns false to stop the search,
  /// so callers can take the first N without materialising every pair.
  static void forEachSeedPair(
    List<String> candidates,
    bool Function(String first, String second) onPair,
  ) {
    final byFirstLetter = <String, List<String>>{};
    for (final word in candidates) {
      byFirstLetter.putIfAbsent(word[0], () => []).add(word);
    }
    final maskOf = {
      for (final word in candidates) word: wordLoopLetterMask(word),
    };

    for (final first in candidates) {
      final followers = byFirstLetter[first[first.length - 1]];
      if (followers == null) continue;
      final firstMask = maskOf[first]!;
      for (final second in followers) {
        if (identical(first, second)) continue;
        final union = firstMask | maskOf[second]!;
        if (_bitCount(union) != wordLoopLetterCount) continue;
        if (!onPair(first, second)) return;
      }
    }
  }

  static int _bitCount(int mask) {
    var count = 0;
    var value = mask;
    while (value != 0) {
      value &= value - 1;
      count++;
    }
    return count;
  }
}
