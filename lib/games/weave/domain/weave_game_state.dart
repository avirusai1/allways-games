import 'weave_puzzle.dart';

/// What came of a traced path.
enum WeaveTraceOutcome {
  /// A theme word, now marked on the grid.
  themeWord,

  /// A real word that is not part of the theme. Enough of these earn a
  /// hint, which is how the grid's unavoidable accidental words are turned
  /// into something useful rather than a dead end.
  bonusWord,

  /// Already found.
  alreadyFound,

  /// Not a word this grid contains.
  notAWord,
}

class WeaveTraceResult {
  const WeaveTraceResult(this.outcome, this.state, {this.earnedHint = false});

  final WeaveTraceOutcome outcome;
  final WeaveGameState state;
  final bool earnedHint;
}

/// Bonus words needed to earn one hint.
const int weaveBonusPerHint = 3;

enum WeaveStatus { playing, solved }

class WeaveGameState {
  const WeaveGameState({
    required this.puzzle,
    required this.foundThemeWords,
    required this.foundBonusWords,
    required this.hintsAvailable,
    required this.revealedHintWords,
  });

  factory WeaveGameState.initial(WeavePuzzle puzzle) => WeaveGameState(
        puzzle: puzzle,
        foundThemeWords: const {},
        foundBonusWords: const {},
        hintsAvailable: 0,
        revealedHintWords: const {},
      );

  final WeavePuzzle puzzle;
  final Set<String> foundThemeWords;
  final Set<String> foundBonusWords;
  final int hintsAvailable;

  /// Theme words a hint has pointed at but the player has not traced.
  final Set<String> revealedHintWords;

  WeaveStatus get status => foundThemeWords.length == puzzle.solutions.length
      ? WeaveStatus.solved
      : WeaveStatus.playing;

  bool get isPlaying => status == WeaveStatus.playing;
  int get remaining => puzzle.solutions.length - foundThemeWords.length;
  bool get spannerFound => foundThemeWords.contains(puzzle.spanner);

  /// Cells already claimed by a found theme word, for drawing the grid.
  Set<int> get foundCells => {
        for (final word in foundThemeWords) ...?puzzle.solutions[word],
      };

  /// Submits [word]. The path itself is validated by the caller against
  /// the grid; this decides what the word means for the game.
  WeaveTraceResult trace(String word) {
    final target = word.toUpperCase();

    if (foundThemeWords.contains(target) || foundBonusWords.contains(target)) {
      return WeaveTraceResult(WeaveTraceOutcome.alreadyFound, this);
    }

    if (puzzle.solutions.containsKey(target)) {
      return WeaveTraceResult(
        WeaveTraceOutcome.themeWord,
        copyWith(
          foundThemeWords: {...foundThemeWords, target},
          revealedHintWords: {...revealedHintWords}..remove(target),
        ),
      );
    }

    if (puzzle.bonusWords.contains(target)) {
      final bonus = {...foundBonusWords, target};
      // Every third bonus word earns a hint.
      final earned = bonus.length % weaveBonusPerHint == 0;
      return WeaveTraceResult(
        WeaveTraceOutcome.bonusWord,
        copyWith(
          foundBonusWords: bonus,
          hintsAvailable: hintsAvailable + (earned ? 1 : 0),
        ),
        earnedHint: earned,
      );
    }

    return WeaveTraceResult(WeaveTraceOutcome.notAWord, this);
  }

  /// Spends a hint to reveal one unfound theme word.
  WeaveGameState useHint() {
    if (hintsAvailable <= 0) return this;
    final unfound = puzzle.solutions.keys
        .where((w) => !foundThemeWords.contains(w))
        .where((w) => !revealedHintWords.contains(w))
        .toList();
    if (unfound.isEmpty) return this;
    return copyWith(
      hintsAvailable: hintsAvailable - 1,
      revealedHintWords: {...revealedHintWords, unfound.first},
    );
  }

  WeaveGameState copyWith({
    Set<String>? foundThemeWords,
    Set<String>? foundBonusWords,
    int? hintsAvailable,
    Set<String>? revealedHintWords,
  }) {
    return WeaveGameState(
      puzzle: puzzle,
      foundThemeWords: foundThemeWords ?? this.foundThemeWords,
      foundBonusWords: foundBonusWords ?? this.foundBonusWords,
      hintsAvailable: hintsAvailable ?? this.hintsAvailable,
      revealedHintWords: revealedHintWords ?? this.revealedHintWords,
    );
  }
}
