import 'package:allways_games/games/weave/domain/weave_game_state.dart';
import 'package:allways_games/games/weave/domain/weave_grid.dart';
import 'package:allways_games/games/weave/domain/weave_puzzle.dart';
import 'package:flutter_test/flutter_test.dart';

/// A hand-built puzzle with two disjoint theme words, as a real packing
/// always has: one along the top row, one down the last column.
///
/// They must not share a cell — the top row and the last column would
/// collide at (0, 5), so the row word stops one short of it.
const String _alpha = 'ABCDE'; // row 0, columns 0..4
const String _spanner = 'FGHIJKL'; // column 5, every row

WeavePuzzle _puzzle() {
  final letters = List<String>.filled(weaveCellCount, 'Z');

  final alphaPath = [
    for (var col = 0; col < _alpha.length; col++) weaveIndexAt(0, col),
  ];
  for (var i = 0; i < alphaPath.length; i++) {
    letters[alphaPath[i]] = _alpha[i];
  }

  final spannerPath = [
    for (var row = 0; row < weaveRows; row++) weaveIndexAt(row, weaveCols - 1),
  ];
  for (var i = 0; i < spannerPath.length; i++) {
    letters[spannerPath[i]] = _spanner[i];
  }

  return WeavePuzzle(
    clue: 'Test theme',
    letters: letters,
    spanner: _spanner,
    solutions: {_alpha: alphaPath, _spanner: spannerPath},
    bonusWords: {'ZEBRA', 'CRATE'},
  );
}

void main() {
  test('initial state has nothing found', () {
    final state = WeaveGameState.initial(_puzzle());
    expect(state.foundThemeWords, isEmpty);
    expect(state.foundBonusWords, isEmpty);
    expect(state.hintsAvailable, 0);
    expect(state.status, WeaveStatus.playing);
    expect(state.remaining, 2);
  });

  test('tracing a theme word marks it found', () {
    final puzzle = _puzzle();
    final result = WeaveGameState.initial(puzzle).trace(_alpha);
    expect(result.outcome, WeaveTraceOutcome.themeWord);
    expect(result.state.foundThemeWords, contains(_alpha));
    expect(result.state.remaining, 1);
  });

  test('finding every theme word solves the puzzle', () {
    final puzzle = _puzzle();
    var state = WeaveGameState.initial(puzzle);
    for (final word in puzzle.solutions.keys) {
      state = state.trace(word).state;
    }
    expect(state.status, WeaveStatus.solved);
    expect(state.remaining, 0);
    expect(state.foundCells.length, _alpha.length + _spanner.length);
  });

  test('a non-word is rejected without changing state', () {
    final state = WeaveGameState.initial(_puzzle());
    final result = state.trace('QQQQ');
    expect(result.outcome, WeaveTraceOutcome.notAWord);
    expect(identical(result.state, state), isTrue);
  });

  test('re-tracing a found word is recognised and costs nothing', () {
    var state = WeaveGameState.initial(_puzzle());
    state = state.trace(_alpha).state;
    final repeat = state.trace(_alpha);
    expect(repeat.outcome, WeaveTraceOutcome.alreadyFound);
    expect(repeat.state.foundThemeWords.length, 1);
  });

  test('every third bonus word earns a hint', () {
    final puzzle = WeavePuzzle(
      clue: 'x',
      letters: List<String>.filled(weaveCellCount, 'Z'),
      spanner: 'S',
      solutions: const {'S': []},
      bonusWords: const {'ONE', 'TWO', 'SIX'},
    );
    var state = WeaveGameState.initial(puzzle);

    state = state.trace('ONE').state;
    expect(state.hintsAvailable, 0);
    state = state.trace('TWO').state;
    expect(state.hintsAvailable, 0);

    final third = state.trace('SIX');
    expect(third.earnedHint, isTrue);
    expect(third.state.hintsAvailable, 1);
  });

  test('a hint reveals an unfound theme word and spends itself', () {
    final puzzle = _puzzle();
    var state = WeaveGameState.initial(puzzle).copyWith(hintsAvailable: 1);
    state = state.useHint();
    expect(state.hintsAvailable, 0);
    expect(state.revealedHintWords, hasLength(1));
    expect(puzzle.solutions.keys, contains(state.revealedHintWords.first));
  });

  test('a hint with none available does nothing', () {
    final state = WeaveGameState.initial(_puzzle());
    expect(identical(state.useHint(), state), isTrue);
  });

  test('tracing a revealed word clears it from the hint list', () {
    final puzzle = _puzzle();
    var state = WeaveGameState.initial(puzzle)
        .copyWith(hintsAvailable: 1)
        .useHint();
    final revealed = state.revealedHintWords.first;
    state = state.trace(revealed).state;
    expect(state.revealedHintWords, isEmpty);
    expect(state.foundThemeWords, contains(revealed));
  });

  test('a puzzle round-trips through json', () {
    final puzzle = _puzzle();
    final restored = WeavePuzzle.fromJson(puzzle.toJson());
    expect(restored.clue, puzzle.clue);
    expect(restored.letters, puzzle.letters);
    expect(restored.spanner, puzzle.spanner);
    expect(restored.solutions.keys.toSet(), puzzle.solutions.keys.toSet());
    expect(restored.bonusWords, puzzle.bonusWords);
  });
}
