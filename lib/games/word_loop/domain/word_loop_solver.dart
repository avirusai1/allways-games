import 'word_loop_box.dart';

/// Bit `n` set means the letter `A + n` appears.
int wordLoopLetterMask(String word) {
  var mask = 0;
  for (final unit in word.toUpperCase().codeUnits) {
    if (unit < 0x41 || unit > 0x5A) continue;
    mask |= 1 << (unit - 0x41);
  }
  return mask;
}

/// Chain search over a Word Loop board.
///
/// A solution is a sequence of playable dictionary words where each word
/// starts with the previous word's last letter, and the sequence between
/// them uses all twelve of the board's letters.
///
/// The search runs over (last letter, letters covered so far) states —
/// 26 x 2^12 reachable at most — so shortest-chain queries are cheap
/// enough for the generator to run on every candidate board.
class WordLoopSolver {
  WordLoopSolver._();

  /// The shortest chain covering every letter of [box], or null if no
  /// chain of at most [maxWords] words does.
  ///
  /// Ties are broken toward the alphabetically earliest word list, so the
  /// same board always yields the same published solution.
  static List<String>? findShortestChain(
    WordLoopBox box,
    List<String> playableWords, {
    int maxWords = 5,
  }) {
    final target = wordLoopLetterMask(box.letters.join());
    final words = List<String>.of(playableWords)..sort();
    if (words.isEmpty) return null;

    final byFirstLetter = <String, List<String>>{};
    for (final word in words) {
      byFirstLetter.putIfAbsent(word[0], () => []).add(word);
    }
    final maskOf = {for (final word in words) word: wordLoopLetterMask(word)};

    // State key packs the chain's last letter with the covered-letter mask;
    // two chains that agree on both are interchangeable from here on, so
    // only the first (shortest, then alphabetically earliest) is kept.
    int keyFor(String lastLetter, int mask) =>
        (lastLetter.codeUnitAt(0) - 0x41) << 26 | mask;

    final seen = <int>{};
    var frontier = <({String last, int mask, List<String> chain})>[];

    for (final word in words) {
      final mask = maskOf[word]!;
      final last = word[word.length - 1];
      if (mask == target) return [word];
      if (seen.add(keyFor(last, mask))) {
        frontier.add((last: last, mask: mask, chain: [word]));
      }
    }

    for (var depth = 2; depth <= maxWords && frontier.isNotEmpty; depth++) {
      final next = <({String last, int mask, List<String> chain})>[];
      for (final state in frontier) {
        for (final word in byFirstLetter[state.last] ?? const <String>[]) {
          final mask = state.mask | maskOf[word]!;
          final chain = [...state.chain, word];
          if (mask == target) return chain;
          final last = word[word.length - 1];
          if (seen.add(keyFor(last, mask))) {
            next.add((last: last, mask: mask, chain: chain));
          }
        }
      }
      frontier = next;
    }
    return null;
  }

  /// Every ordered pair of words that covers the whole board in two moves.
  ///
  /// The generator uses the size of this set to judge a board: a board with
  /// only one two-word answer is a needle in a haystack, and one with
  /// hundreds gives itself away.
  static List<List<String>> findTwoWordSolutions(
    WordLoopBox box,
    List<String> playableWords, {
    int limit = 1000,
  }) {
    final target = wordLoopLetterMask(box.letters.join());
    final byFirstLetter = <String, List<String>>{};
    for (final word in playableWords) {
      byFirstLetter.putIfAbsent(word[0], () => []).add(word);
    }

    final solutions = <List<String>>[];
    for (final first in playableWords) {
      final firstMask = wordLoopLetterMask(first);
      final followers = byFirstLetter[first[first.length - 1]];
      if (followers == null) continue;
      for (final second in followers) {
        if (firstMask | wordLoopLetterMask(second) != target) continue;
        solutions.add([first, second]);
        if (solutions.length >= limit) return solutions;
      }
    }
    return solutions;
  }

  /// Words from [dictionary] that can actually be traced on [box].
  static List<String> playableWords(WordLoopBox box, Iterable<String> dictionary) {
    return [
      for (final word in dictionary)
        if (box.isPlayable(word)) word.toUpperCase(),
    ];
  }
}
