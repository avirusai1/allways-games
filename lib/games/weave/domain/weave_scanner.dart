import 'weave_grid.dart';

/// Prefix tree of the dictionary, built once and walked over every grid.
class WeaveTrie {
  final Map<String, WeaveTrie> children = {};
  bool isWord = false;
}

/// Finds every dictionary word traceable in a filled Weave grid.
///
/// This exists because of the failure a themed letter grid is prone to:
/// the theme words tile every cell, and the letters they happen to leave
/// adjacent can spell words nobody intended. A long, common accidental
/// word is worse than a distraction — the player traces it, is told it is
/// not a theme word, and reasonably concludes the puzzle is broken.
///
/// The generator uses this to reject bad packings; the game uses it to
/// credit the shorter accidental finds as bonus words instead of
/// rejecting the player outright.
class WeaveScanner {
  WeaveScanner._();

  static WeaveTrie buildTrie(Iterable<String> vocabulary, {int minLength = 4}) {
    final root = WeaveTrie();
    for (final raw in vocabulary) {
      final word = raw.toUpperCase();
      if (word.length < minLength) continue;
      var node = root;
      for (final letter in word.split('')) {
        node = node.children.putIfAbsent(letter, WeaveTrie.new);
      }
      node.isWord = true;
    }
    return root;
  }

  /// Every distinct word of at least [minLength] traceable in [letters].
  static Set<String> findAll(
    List<String> letters,
    WeaveTrie trie, {
    int minLength = 4,
  }) {
    final found = <String>{};
    final used = List<bool>.filled(weaveCellCount, false);

    void walk(int cell, WeaveTrie node, String prefix) {
      final next = node.children[letters[cell]];
      if (next == null) return;

      final word = prefix + letters[cell];
      used[cell] = true;
      if (next.isWord && word.length >= minLength) found.add(word);
      for (final neighbour in weaveAdjacency[cell]) {
        if (!used[neighbour]) walk(neighbour, next, word);
      }
      used[cell] = false;
    }

    for (var start = 0; start < weaveCellCount; start++) {
      walk(start, trie, '');
    }
    return found;
  }

  /// Traces [word] in [letters], returning the path or null if it is not
  /// traceable. Used at play time to check what the player drew.
  static List<int>? trace(List<String> letters, String word) {
    final target = word.toUpperCase();
    if (target.isEmpty) return null;
    final used = List<bool>.filled(weaveCellCount, false);
    final path = <int>[];

    bool descend(int cell, int position) {
      if (letters[cell] != target[position]) return false;
      used[cell] = true;
      path.add(cell);
      if (position == target.length - 1) return true;
      for (final neighbour in weaveAdjacency[cell]) {
        if (!used[neighbour] && descend(neighbour, position + 1)) return true;
      }
      path.removeLast();
      used[cell] = false;
      return false;
    }

    for (var start = 0; start < weaveCellCount; start++) {
      if (descend(start, 0)) return path;
    }
    return null;
  }
}
