import 'groups_puzzle.dart';

enum GroupsStatus { playing, solved, lost }

/// What came of submitting a selection.
enum GroupsGuessOutcome {
  /// The four words are a category. It is now solved.
  correct,

  /// Three of the four share a category — worth saying, because it turns a
  /// wrong guess into information rather than just a lost life.
  oneAway,

  /// No three of them belong together.
  wrong,

  /// This exact set of four has already been tried, so it costs nothing.
  repeat,

  /// Fewer than four words are selected, or the puzzle is over.
  notReady,
}

/// Immutable snapshot of one Groups puzzle in progress.
class GroupsGameState {
  const GroupsGameState({
    required this.puzzle,
    required this.tileOrder,
    required this.selected,
    required this.solvedTags,
    required this.mistakes,
    required this.pastGuesses,
  });

  factory GroupsGameState.initial(
    GroupsPuzzle puzzle, {
    List<String>? tileOrder,
  }) =>
      GroupsGameState(
        puzzle: puzzle,
        tileOrder: tileOrder ?? puzzle.allWordTexts,
        selected: const {},
        solvedTags: const [],
        mistakes: 0,
        pastGuesses: const [],
      );

  final GroupsPuzzle puzzle;

  /// Display order of the words still in play.
  final List<String> tileOrder;

  final Set<String> selected;

  /// Category tags solved so far, in the order the player found them.
  final List<String> solvedTags;

  final int mistakes;

  /// Every set of four already submitted, so a repeat can be waved through
  /// instead of costing a life the player has already paid.
  final List<Set<String>> pastGuesses;

  List<GroupsCategory> get solvedCategories => [
        for (final tag in solvedTags)
          puzzle.categories.firstWhere((c) => c.tag == tag),
      ];

  List<GroupsCategory> get unsolvedCategories => [
        for (final category in puzzle.categories)
          if (!solvedTags.contains(category.tag)) category,
      ];

  /// Words still on the board, in display order.
  List<String> get remainingWords {
    final solvedWords = {
      for (final category in solvedCategories) ...category.wordTexts,
    };
    return [
      for (final word in tileOrder)
        if (!solvedWords.contains(word)) word,
    ];
  }

  int get mistakesRemaining => groupsMistakeLimit - mistakes;

  GroupsStatus get status {
    // Mistakes are checked first so that revealing the answers after a loss
    // fills in every category without the puzzle then reporting itself
    // solved. A player cannot reach four mistakes and four solved groups by
    // playing: the fourth mistake ends the puzzle before that.
    if (mistakes >= groupsMistakeLimit) return GroupsStatus.lost;
    if (solvedTags.length == groupsCategoryCount) return GroupsStatus.solved;
    return GroupsStatus.playing;
  }

  bool get isPlaying => status == GroupsStatus.playing;
  bool get canSubmit => isPlaying && selected.length == groupsWordsPerCategory;

  /// Adds or removes a word from the selection.
  ///
  /// Selecting past four is refused rather than silently dropping the
  /// oldest pick: a player who taps a fifth tile has usually mis-tapped,
  /// and quietly swapping one out would hide that.
  GroupsGameState toggleWord(String word) {
    if (!isPlaying) return this;
    if (!remainingWords.contains(word)) return this;

    if (selected.contains(word)) {
      return copyWith(selected: {...selected}..remove(word));
    }
    if (selected.length >= groupsWordsPerCategory) return this;
    return copyWith(selected: {...selected, word});
  }

  GroupsGameState deselectAll() =>
      selected.isEmpty ? this : copyWith(selected: const {});

  /// Reorders the words still in play. The solved rows stay where they are.
  GroupsGameState shuffleTiles(List<String> order) =>
      copyWith(tileOrder: order);

  /// How many of [words] share the most common category among them.
  int _bestOverlap(Set<String> words) {
    var best = 0;
    for (final category in puzzle.categories) {
      final overlap = category.wordTexts.intersection(words).length;
      if (overlap > best) best = overlap;
    }
    return best;
  }

  /// Submits the current selection.
  ({GroupsGameState state, GroupsGuessOutcome outcome, GroupsCategory? found})
      submit() {
    if (!canSubmit) {
      return (state: this, outcome: GroupsGuessOutcome.notReady, found: null);
    }

    final guess = {...selected};
    if (pastGuesses.any((past) => past.length == guess.length &&
        past.containsAll(guess))) {
      return (state: this, outcome: GroupsGuessOutcome.repeat, found: null);
    }

    final match = puzzle.categories.where((c) => c.wordTexts.containsAll(guess));
    if (match.isNotEmpty) {
      final category = match.first;
      return (
        state: copyWith(
          selected: const {},
          solvedTags: [...solvedTags, category.tag],
          pastGuesses: [...pastGuesses, guess],
        ),
        outcome: GroupsGuessOutcome.correct,
        found: category,
      );
    }

    final overlap = _bestOverlap(guess);
    return (
      state: copyWith(
        selected: const {},
        mistakes: mistakes + 1,
        pastGuesses: [...pastGuesses, guess],
      ),
      outcome: overlap == groupsWordsPerCategory - 1
          ? GroupsGuessOutcome.oneAway
          : GroupsGuessOutcome.wrong,
      found: null,
    );
  }

  /// Marks every category solved, for revealing the answers after a loss.
  GroupsGameState revealAll() {
    return copyWith(
      selected: const {},
      solvedTags: [
        ...solvedTags,
        for (final category in puzzle.byDifficulty)
          if (!solvedTags.contains(category.tag)) category.tag,
      ],
    );
  }

  GroupsGameState copyWith({
    List<String>? tileOrder,
    Set<String>? selected,
    List<String>? solvedTags,
    int? mistakes,
    List<Set<String>>? pastGuesses,
  }) {
    return GroupsGameState(
      puzzle: puzzle,
      tileOrder: tileOrder ?? this.tileOrder,
      selected: selected ?? this.selected,
      solvedTags: solvedTags ?? this.solvedTags,
      mistakes: mistakes ?? this.mistakes,
      pastGuesses: pastGuesses ?? this.pastGuesses,
    );
  }
}
