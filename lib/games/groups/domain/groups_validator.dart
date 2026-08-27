import 'groups_puzzle.dart';

/// A problem found in an authored Groups puzzle.
class GroupsDefect {
  const GroupsDefect(this.puzzleId, this.message);

  final String puzzleId;
  final String message;

  @override
  String toString() => '$puzzleId: $message';
}

/// Checks authored Groups puzzles for the faults that make a puzzle unfair.
///
/// Groups is the one game in the roster with no generator behind it — the
/// puzzles are written by hand — so this validator is what stands in for
/// one. It runs in the content tool before the bank is written *and* in
/// the unit tests against the shipped bank, because a puzzle with two
/// defensible answers is not a hard puzzle, it is a broken one.
class GroupsValidator {
  GroupsValidator._();

  static List<GroupsDefect> validate(GroupsPuzzle puzzle) {
    final defects = <GroupsDefect>[];
    void defect(String message) =>
        defects.add(GroupsDefect(puzzle.id, message));

    if (puzzle.id.trim().isEmpty) defect('has no id');

    if (puzzle.categories.length != groupsCategoryCount) {
      defect('has ${puzzle.categories.length} categories, '
          'expected $groupsCategoryCount');
      // Everything below assumes four categories.
      return defects;
    }

    for (final category in puzzle.categories) {
      if (category.words.length != groupsWordsPerCategory) {
        defect('category "${category.tag}" has ${category.words.length} '
            'words, expected $groupsWordsPerCategory');
      }
      if (category.name.trim().isEmpty) {
        defect('category "${category.tag}" has no display name');
      }
      if (category.tag.trim().isEmpty) {
        defect('category "${category.name}" has no tag');
      }
    }

    final tags = puzzle.categories.map((c) => c.tag).toList();
    if (tags.toSet().length != tags.length) {
      defect('reuses a category tag: $tags');
    }
    final names = puzzle.categories.map((c) => c.name).toList();
    if (names.toSet().length != names.length) {
      defect('reuses a category name: $names');
    }

    final difficulties = puzzle.categories.map((c) => c.difficulty).toList();
    if (difficulties.toSet().length != difficulties.length ||
        difficulties.any((d) => d < 0 || d >= groupsCategoryCount)) {
      defect('difficulties must be 0..${groupsCategoryCount - 1} exactly '
          'once each, got $difficulties');
    }

    final words = puzzle.allWordTexts;
    if (words.length != groupsWordCount) {
      defect('has ${words.length} words, expected $groupsWordCount');
    }
    if (words.toSet().length != words.length) {
      final duplicates = <String>{};
      final seen = <String>{};
      for (final word in words) {
        if (!seen.add(word)) duplicates.add(word);
      }
      defect('repeats ${duplicates.join(', ')}');
    }
    for (final word in words) {
      if (word != word.toUpperCase() || word.trim().isEmpty) {
        defect('word "$word" should be non-empty and upper case');
      }
    }

    // The ambiguity check. A word must claim its own category, and must not
    // claim any of the other three — a word that plausibly belongs to two
    // of this puzzle's groups gives the player a defensible wrong answer.
    for (final category in puzzle.categories) {
      final otherTags = {
        for (final other in puzzle.categories)
          if (other.tag != category.tag) other.tag,
      };
      for (final word in category.words) {
        if (word.tags.isEmpty) {
          defect('"${word.text}" declares no tags');
          continue;
        }
        if (!word.tags.contains(category.tag)) {
          defect('"${word.text}" is filed under "${category.tag}" but does '
              'not claim that tag (claims ${word.tags.join(', ')})');
        }
        final collisions = word.tags.intersection(otherTags);
        if (collisions.isNotEmpty) {
          defect('"${word.text}" fits both "${category.tag}" and '
              '${collisions.map((t) => '"$t"').join(', ')} in this puzzle');
        }
      }
    }

    return defects;
  }

  /// Validates a whole bank, adding the cross-puzzle checks.
  static List<GroupsDefect> validateBank(List<GroupsPuzzle> puzzles) {
    final defects = <GroupsDefect>[
      for (final puzzle in puzzles) ...validate(puzzle),
    ];

    final seenIds = <String>{};
    for (final puzzle in puzzles) {
      if (!seenIds.add(puzzle.id)) {
        defects.add(GroupsDefect(puzzle.id, 'duplicate puzzle id'));
      }
    }

    // A single category may recur in a later puzzle — the bank is partly
    // composed by recombining authored categories, so that is by design and
    // only one group of four is familiar. What must never recur is a whole
    // puzzle: the same four categories together would play identically.
    final seenPuzzles = <String, String>{};
    for (final puzzle in puzzles) {
      final key = (puzzle.categories.map((c) => c.tag).toList()..sort()).join('|');
      final previous = seenPuzzles[key];
      if (previous != null) {
        defects.add(GroupsDefect(
          puzzle.id,
          'is the same four categories as $previous',
        ));
      }
      seenPuzzles[key] = puzzle.id;
    }

    return defects;
  }

  /// Checks the hand-authored source, which is held to a stricter rule than
  /// the shipped bank: no authored category may duplicate another.
  ///
  /// Recombination is only safe if the pool it draws from has no
  /// accidental twins, so this is where a category written twice by hand
  /// gets caught — not in the bank, where reuse is intentional.
  static List<GroupsDefect> validateAuthoredSource(List<GroupsPuzzle> puzzles) {
    final defects = validateBank(puzzles);

    final seenCategories = <String, String>{};
    for (final puzzle in puzzles) {
      for (final category in puzzle.categories) {
        final key = (category.wordTexts.toList()..sort()).join('|');
        final previous = seenCategories[key];
        if (previous != null) {
          defects.add(GroupsDefect(
            puzzle.id,
            'category "${category.name}" repeats one from $previous',
          ));
        }
        seenCategories[key] = puzzle.id;
      }
    }

    return defects;
  }
}
