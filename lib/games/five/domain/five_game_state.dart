import 'letter_state.dart';

const int fiveWordLength = 5;
const int fiveMaxGuesses = 6;

enum FiveStatus { playing, won, lost }

/// Immutable snapshot of one Five game in progress. Pure Dart, no Flutter
/// dependency, so game rules are independently unit-testable.
class FiveGameState {
  const FiveGameState({
    required this.answer,
    required this.submittedGuesses,
    required this.evaluations,
    required this.currentInput,
    required this.status,
    this.restoredGuessesUsed,
  });

  factory FiveGameState.initial(String answer) => FiveGameState(
        answer: answer,
        submittedGuesses: const [],
        evaluations: const [],
        currentInput: '',
        status: FiveStatus.playing,
      );

  final String answer;
  final List<String> submittedGuesses;
  final List<List<LetterState>> evaluations;
  final String currentInput;
  final FiveStatus status;

  /// Guesses used on a day reopened after it finished in an earlier app
  /// session. The letter-by-letter grid isn't persisted (only the outcome
  /// is), so [submittedGuesses] comes back empty on a cold reopen — this
  /// carries the one number that *is* persisted, so the screen can still
  /// say "solved in 3/6" instead of falling back to a misleading "0/6".
  final int? restoredGuessesUsed;

  /// True when this is a finished day reopened cold: no guesses are held
  /// in memory to render as a grid, only the persisted outcome.
  bool get isRestoredWithoutHistory =>
      status != FiveStatus.playing && submittedGuesses.isEmpty;

  /// Guesses used, whichever source has it.
  int get guessesUsedForDisplay =>
      submittedGuesses.isNotEmpty ? submittedGuesses.length : (restoredGuessesUsed ?? 0);

  bool get canEditInput => status == FiveStatus.playing;
  bool get canSubmit => currentInput.length == fiveWordLength && canEditInput;
  int get remainingGuesses => fiveMaxGuesses - submittedGuesses.length;

  /// Per-letter best-known state across all guesses so far, for coloring
  /// the on-screen keyboard (correct beats present beats absent).
  Map<String, LetterState> get keyboardStates {
    final states = <String, LetterState>{};
    for (var g = 0; g < evaluations.length; g++) {
      final guess = submittedGuesses[g];
      final row = evaluations[g];
      for (var i = 0; i < row.length; i++) {
        final letter = guess[i];
        final existing = states[letter];
        if (existing == null || _rank(row[i]) > _rank(existing)) {
          states[letter] = row[i];
        }
      }
    }
    return states;
  }

  static int _rank(LetterState state) => switch (state) {
        LetterState.correct => 2,
        LetterState.present => 1,
        LetterState.absent => 0,
        LetterState.empty => -1,
      };

  FiveGameState copyWith({
    List<String>? submittedGuesses,
    List<List<LetterState>>? evaluations,
    String? currentInput,
    FiveStatus? status,
    int? restoredGuessesUsed,
  }) {
    return FiveGameState(
      answer: answer,
      submittedGuesses: submittedGuesses ?? this.submittedGuesses,
      evaluations: evaluations ?? this.evaluations,
      currentInput: currentInput ?? this.currentInput,
      status: status ?? this.status,
      restoredGuessesUsed: restoredGuessesUsed ?? this.restoredGuessesUsed,
    );
  }
}
