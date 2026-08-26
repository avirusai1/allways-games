import 'word_loop_box.dart';
import 'word_loop_puzzle.dart';
import 'word_loop_solver.dart';

enum WordLoopStatus { playing, solved }

/// Why a submitted word was turned away. The screen maps these to copy;
/// keeping them as values rather than strings keeps the rules testable
/// without asserting on wording.
enum WordLoopRejection {
  tooShort,
  letterNotOnBoard,
  sameSideTwice,
  notAWord,
  alreadyUsed,
  wrongStartingLetter,
}

/// Immutable snapshot of one Word Loop board in progress.
///
/// Word Loop has no losing state: a player can keep chaining words forever
/// and the board is scored on how many words it took against par. All rule
/// transitions are pure functions returning a new state.
class WordLoopGameState {
  const WordLoopGameState({
    required this.puzzle,
    required this.chain,
    required this.currentInput,
    required this.status,
  });

  factory WordLoopGameState.initial(WordLoopPuzzle puzzle) =>
      WordLoopGameState(
        puzzle: puzzle,
        chain: const [],
        currentInput: '',
        status: WordLoopStatus.playing,
      );

  final WordLoopPuzzle puzzle;

  /// Words played so far, in order.
  final List<String> chain;

  final String currentInput;
  final WordLoopStatus status;

  bool get isPlaying => status == WordLoopStatus.playing;

  /// Letter every next word must start with, or null at the start of a
  /// board when any letter will do.
  String? get requiredStartingLetter =>
      chain.isEmpty ? null : chain.last[chain.last.length - 1];

  /// Letters the chain has used so far.
  Set<String> get usedLetters {
    final used = <String>{};
    for (final word in chain) {
      used.addAll(word.split(''));
    }
    return used;
  }

  Set<String> get remainingLetters => puzzle.box.letters.difference(usedLetters);

  /// True once the chain covers every letter on the board.
  bool get coversBoard => remainingLetters.isEmpty;

  /// Words used against par; equal to par is a perfect solve.
  int get wordsUsed => chain.length;

  WordLoopGameState inputLetter(String letter) {
    if (!isPlaying) return this;
    final upper = letter.toUpperCase();
    if (!puzzle.box.containsLetter(upper)) return this;
    return copyWith(currentInput: currentInput + upper);
  }

  WordLoopGameState backspace() {
    if (!isPlaying || currentInput.isEmpty) return this;
    return copyWith(
      currentInput: currentInput.substring(0, currentInput.length - 1),
    );
  }

  WordLoopGameState clearInput() =>
      isPlaying ? copyWith(currentInput: '') : this;

  /// Why [word] cannot be played right now, or null when it is legal.
  ///
  /// The order matters: the most specific complaint a player can act on
  /// comes first, so "that letter is not on the board" beats the generic
  /// "not a word".
  WordLoopRejection? rejectionFor(String word) {
    final upper = word.toUpperCase();
    if (upper.length < wordLoopMinWordLength) return WordLoopRejection.tooShort;

    final required = requiredStartingLetter;
    if (required != null && upper[0] != required) {
      return WordLoopRejection.wrongStartingLetter;
    }

    int? previousSide;
    for (final letter in upper.split('')) {
      final side = puzzle.box.sideOf(letter);
      if (side == null) return WordLoopRejection.letterNotOnBoard;
      if (side == previousSide) return WordLoopRejection.sameSideTwice;
      previousSide = side;
    }

    if (!puzzle.isValidWord(upper)) return WordLoopRejection.notAWord;
    if (chain.contains(upper)) return WordLoopRejection.alreadyUsed;
    return null;
  }

  /// Plays the current input.
  ///
  /// Returns the unchanged state paired with a reason when the word is not
  /// legal, so the caller can surface the complaint without having to
  /// re-derive it.
  ({WordLoopGameState state, WordLoopRejection? rejection}) submit() {
    if (!isPlaying) return (state: this, rejection: null);
    final word = currentInput.toUpperCase();
    final rejection = rejectionFor(word);
    if (rejection != null) return (state: this, rejection: rejection);

    final newChain = [...chain, word];
    final covered = wordLoopLetterMask(newChain.join()) ==
        wordLoopLetterMask(puzzle.box.letters.join());

    return (
      state: copyWith(
        chain: newChain,
        // The next word must start where this one ended, so seeding the
        // input with that letter saves a tap on every single turn.
        currentInput: covered ? '' : word[word.length - 1],
        status: covered ? WordLoopStatus.solved : WordLoopStatus.playing,
      ),
      rejection: null,
    );
  }

  /// Takes back the most recent word.
  WordLoopGameState undoWord() {
    if (!isPlaying || chain.isEmpty) return this;
    final newChain = chain.sublist(0, chain.length - 1);
    return copyWith(
      chain: newChain,
      currentInput: newChain.isEmpty
          ? ''
          : newChain.last[newChain.last.length - 1],
    );
  }

  WordLoopGameState copyWith({
    List<String>? chain,
    String? currentInput,
    WordLoopStatus? status,
  }) {
    return WordLoopGameState(
      puzzle: puzzle,
      chain: chain ?? this.chain,
      currentInput: currentInput ?? this.currentInput,
      status: status ?? this.status,
    );
  }
}
