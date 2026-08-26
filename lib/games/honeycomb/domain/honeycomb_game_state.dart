import 'honeycomb_puzzle.dart';
import 'honeycomb_scoring.dart';

/// Why a submitted word was turned away.
enum HoneycombRejection {
  tooShort,
  missingRequiredLetter,
  letterNotOnBoard,
  notAnAnswer,
  alreadyFound,
}

/// Immutable snapshot of one Honeycomb board in progress.
///
/// Honeycomb has no losing state and no move limit: a player keeps finding
/// words until they stop. "Solved" means every answer has been found, which
/// most players will never reach — the rank ladder is the real goal.
class HoneycombGameState {
  const HoneycombGameState({
    required this.puzzle,
    required this.foundWords,
    required this.currentInput,
    required this.outerLetterOrder,
  });

  factory HoneycombGameState.initial(HoneycombPuzzle puzzle) =>
      HoneycombGameState(
        puzzle: puzzle,
        foundWords: const {},
        currentInput: '',
        outerLetterOrder: puzzle.outerLetters,
      );

  final HoneycombPuzzle puzzle;

  /// Words found so far.
  final Set<String> foundWords;

  final String currentInput;

  /// The six outer letters in their current display order.
  ///
  /// Shuffling them is the standard way out of a rut on this kind of board:
  /// seeing the same letters in a new arrangement genuinely shakes loose
  /// words the eye had stopped seeing.
  final List<String> outerLetterOrder;

  int get score => foundWords.fold(
        0,
        (total, word) =>
            total + honeycombScoreFor(word, isPangram: puzzle.isPangram(word)),
      );

  int get maxScore => puzzle.maxScore;

  HoneycombRank get rank => honeycombRankFor(score, maxScore);

  /// Pangrams found so far.
  Set<String> get foundPangrams =>
      foundWords.where(puzzle.isPangram).toSet();

  int get remainingAnswers => puzzle.answers.length - foundWords.length;

  /// True once every answer has been found.
  bool get isComplete => remainingAnswers == 0;

  HoneycombGameState inputLetter(String letter) {
    final upper = letter.toUpperCase();
    if (!puzzle.letterSet.contains(upper)) return this;
    return copyWith(currentInput: currentInput + upper);
  }

  HoneycombGameState backspace() {
    if (currentInput.isEmpty) return this;
    return copyWith(
      currentInput: currentInput.substring(0, currentInput.length - 1),
    );
  }

  HoneycombGameState clearInput() =>
      currentInput.isEmpty ? this : copyWith(currentInput: '');

  /// Reorders the outer letters. The required letter never moves — it is
  /// the one fixed point a player navigates by.
  HoneycombGameState shuffleOuterLetters(List<String> order) {
    return copyWith(outerLetterOrder: order);
  }

  /// Why [word] is not an answer right now, or null when it is.
  ///
  /// Ordered so the most useful complaint wins: telling a player their word
  /// is missing the centre letter is actionable, where "not an answer"
  /// is not.
  HoneycombRejection? rejectionFor(String word) {
    final upper = word.toUpperCase();
    if (upper.length < honeycombMinWordLength) {
      return HoneycombRejection.tooShort;
    }
    if (!upper.contains(puzzle.requiredLetter)) {
      return HoneycombRejection.missingRequiredLetter;
    }
    for (final letter in upper.split('')) {
      if (!puzzle.letterSet.contains(letter)) {
        return HoneycombRejection.letterNotOnBoard;
      }
    }
    if (foundWords.contains(upper)) return HoneycombRejection.alreadyFound;
    if (!puzzle.isAnswer(upper)) return HoneycombRejection.notAnAnswer;
    return null;
  }

  /// Submits the current input.
  ({HoneycombGameState state, HoneycombRejection? rejection}) submit() {
    final word = currentInput.toUpperCase();
    final rejection = rejectionFor(word);
    if (rejection != null) return (state: this, rejection: rejection);

    return (
      state: copyWith(
        foundWords: {...foundWords, word},
        currentInput: '',
      ),
      rejection: null,
    );
  }

  HoneycombGameState copyWith({
    Set<String>? foundWords,
    String? currentInput,
    List<String>? outerLetterOrder,
  }) {
    return HoneycombGameState(
      puzzle: puzzle,
      foundWords: foundWords ?? this.foundWords,
      currentInput: currentInput ?? this.currentInput,
      outerLetterOrder: outerLetterOrder ?? this.outerLetterOrder,
    );
  }
}
