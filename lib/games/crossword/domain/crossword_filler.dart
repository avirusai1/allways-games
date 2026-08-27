import 'dart:math';

import 'crossword_grid.dart';

/// Words grouped by length with a per-(position, letter) posting list.
///
/// Built once and reused across every fill. Rescanning the whole
/// vocabulary at each node is what makes a naive filler too slow to
/// finish: with an index, "which 4-letter words have R third?" is a set
/// lookup instead of a scan.
class CrosswordVocabulary {
  CrosswordVocabulary(Iterable<String> words) {
    for (final raw in words) {
      final word = raw.toUpperCase();
      _byLength.putIfAbsent(word.length, () => <String>[]).add(word);
      for (var i = 0; i < word.length; i++) {
        _postings
            .putIfAbsent(word.length, () => {})
            .putIfAbsent((i, word[i]), () => <String>{})
            .add(word);
      }
    }
  }

  final Map<int, List<String>> _byLength = {};
  final Map<int, Map<(int, String), Set<String>>> _postings = {};

  List<String> ofLength(int length) => _byLength[length] ?? const [];

  /// Words of [length] matching [pattern], where an empty entry is a gap.
  ///
  /// Intersects the smallest posting lists first, so a slot with three
  /// letters already crossing it resolves against a handful of candidates
  /// rather than every word of that length.
  List<String> matching(List<String> pattern) {
    final length = pattern.length;
    final constraints = <(int, String)>[
      for (var i = 0; i < length; i++)
        if (pattern[i].isNotEmpty) (i, pattern[i]),
    ];
    if (constraints.isEmpty) return ofLength(length);

    final postings = _postings[length];
    if (postings == null) return const [];

    final sets = <Set<String>>[];
    for (final key in constraints) {
      final set = postings[key];
      if (set == null || set.isEmpty) return const [];
      sets.add(set);
    }
    sets.sort((a, b) => a.length.compareTo(b.length));

    final out = <String>[];
    for (final candidate in sets.first) {
      var ok = true;
      for (var i = 1; i < sets.length && ok; i++) {
        ok = sets[i].contains(candidate);
      }
      if (ok) out.add(candidate);
    }
    return out;
  }
}

class CrosswordFill {
  const CrosswordFill({required this.letters, required this.entries});

  /// [crosswordCellCount] letters; blocked squares are empty strings.
  final List<String> letters;

  /// Slot to the word placed in it.
  final Map<CrosswordSlot, String> entries;
}

/// Fills a blocked-square layout with interlocking words.
///
/// This is a constraint problem, not a search for one word at a time:
/// every open square belongs to both an across and a down entry, so
/// choosing a word for one slot constrains its crossings immediately.
class CrosswordFiller {
  CrosswordFiller._();

  /// Fills [slots] over [blocked]. Returns null when no fill exists
  /// within [nodeBudget] — a normal outcome; the caller retries with a
  /// different pattern or seed.
  ///
  /// [exclude] keeps recently published answers out, so consecutive days
  /// do not all lean on the same handful of convenient words.
  static CrosswordFill? fill({
    required List<bool> blocked,
    required List<CrosswordSlot> slots,
    required CrosswordVocabulary vocabulary,
    required Random random,
    Set<String> exclude = const {},
    int nodeBudget = 80000,
  }) {
    final letters = List<String>.filled(crosswordCellCount, '');
    final placed = <CrosswordSlot, String>{};
    final used = <String>{};
    var nodes = 0;

    List<String> patternFor(CrosswordSlot slot) =>
        [for (final cell in slot.cells) letters[cell]];

    bool descend() {
      if (nodes++ > nodeBudget) return false;
      if (placed.length == slots.length) return true;

      // Most-constrained slot first: the one with fewest candidates is
      // where the search will fail, so failing there early prunes most.
      CrosswordSlot? target;
      List<String>? best;
      for (final slot in slots) {
        if (placed.containsKey(slot)) continue;
        final candidates = vocabulary.matching(patternFor(slot));
        if (best == null || candidates.length < best.length) {
          best = candidates;
          target = slot;
          if (candidates.isEmpty) break;
        }
      }
      if (target == null || best == null || best.isEmpty) return false;

      final options = List<String>.of(best)..shuffle(random);
      for (final word in options) {
        if (used.contains(word)) continue;
        if (exclude.contains(word)) continue;

        // Remember what this slot filled in, so a failed branch restores
        // exactly the squares it wrote and not its crossings'.
        final written = <int>[];
        var ok = true;
        for (var i = 0; i < target.cells.length; i++) {
          final cell = target.cells[i];
          if (letters[cell].isEmpty) {
            letters[cell] = word[i];
            written.add(cell);
          } else if (letters[cell] != word[i]) {
            ok = false;
            break;
          }
        }

        if (ok) {
          placed[target] = word;
          used.add(word);
          if (descend()) return true;
          placed.remove(target);
          used.remove(word);
        }

        for (final cell in written) {
          letters[cell] = '';
        }
      }
      return false;
    }

    if (!descend()) return null;
    return CrosswordFill(letters: letters, entries: Map.of(placed));
  }
}
