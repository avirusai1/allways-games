import 'package:allways_games/games/groups/domain/groups_game_state.dart';
import 'package:allways_games/games/groups/domain/groups_puzzle.dart';
import 'package:flutter_test/flutter_test.dart';

GroupsCategory _category(String tag, int difficulty, List<String> words) {
  return GroupsCategory(
    tag: tag,
    name: tag,
    difficulty: difficulty,
    words: [for (final w in words) GroupsWord(text: w, tags: {tag})],
  );
}

GroupsPuzzle _puzzle() => GroupsPuzzle(
      id: 'test',
      categories: [
        _category('alpha', 0, ['AONE', 'ATWO', 'ATHREE', 'AFOUR']),
        _category('beta', 1, ['BONE', 'BTWO', 'BTHREE', 'BFOUR']),
        _category('gamma', 2, ['CONE', 'CTWO', 'CTHREE', 'CFOUR']),
        _category('delta', 3, ['DONE', 'DTWO', 'DTHREE', 'DFOUR']),
      ],
    );

/// Selects [words] then submits.
({GroupsGameState state, GroupsGuessOutcome outcome, GroupsCategory? found})
    _guess(GroupsGameState state, List<String> words) {
  var next = state.deselectAll();
  for (final word in words) {
    next = next.toggleWord(word);
  }
  return next.submit();
}

void main() {
  group('initial state', () {
    test('all sixteen words are in play', () {
      final state = GroupsGameState.initial(_puzzle());
      expect(state.remainingWords, hasLength(groupsWordCount));
      expect(state.selected, isEmpty);
      expect(state.solvedTags, isEmpty);
      expect(state.mistakes, 0);
      expect(state.mistakesRemaining, groupsMistakeLimit);
      expect(state.status, GroupsStatus.playing);
      expect(state.canSubmit, isFalse);
    });

    test('a supplied tile order is honoured', () {
      final order = _puzzle().allWordTexts.reversed.toList();
      final state = GroupsGameState.initial(_puzzle(), tileOrder: order);
      expect(state.remainingWords, order);
    });
  });

  group('selecting', () {
    test('tapping selects and tapping again deselects', () {
      var state = GroupsGameState.initial(_puzzle()).toggleWord('AONE');
      expect(state.selected, {'AONE'});
      state = state.toggleWord('AONE');
      expect(state.selected, isEmpty);
    });

    test('a fifth pick is refused rather than swapping one out', () {
      // Silently dropping the oldest pick would hide a mis-tap.
      var state = GroupsGameState.initial(_puzzle());
      for (final word in ['AONE', 'ATWO', 'ATHREE', 'AFOUR']) {
        state = state.toggleWord(word);
      }
      expect(state.canSubmit, isTrue);
      final refused = state.toggleWord('BONE');
      expect(refused, same(state));
      expect(refused.selected, hasLength(4));
    });

    test('a word not on the board cannot be selected', () {
      final state = GroupsGameState.initial(_puzzle());
      expect(state.toggleWord('NOTHERE'), same(state));
    });

    test('clear empties the selection', () {
      final state = GroupsGameState.initial(_puzzle())
          .toggleWord('AONE')
          .toggleWord('ATWO')
          .deselectAll();
      expect(state.selected, isEmpty);
      expect(state.deselectAll(), same(state));
    });
  });

  group('guessing', () {
    test('submitting fewer than four does nothing', () {
      final state = GroupsGameState.initial(_puzzle()).toggleWord('AONE');
      final result = state.submit();
      expect(result.outcome, GroupsGuessOutcome.notReady);
      expect(result.state, same(state));
    });

    test('a correct group is solved and leaves the board', () {
      final result = _guess(
        GroupsGameState.initial(_puzzle()),
        ['AONE', 'ATWO', 'ATHREE', 'AFOUR'],
      );
      expect(result.outcome, GroupsGuessOutcome.correct);
      expect(result.found?.tag, 'alpha');
      expect(result.state.solvedTags, ['alpha']);
      expect(result.state.remainingWords, hasLength(12));
      expect(result.state.remainingWords, isNot(contains('AONE')));
      expect(result.state.mistakes, 0);
      expect(result.state.selected, isEmpty);
    });

    test('three from one group and one from another is one away', () {
      final result = _guess(
        GroupsGameState.initial(_puzzle()),
        ['AONE', 'ATWO', 'ATHREE', 'BONE'],
      );
      expect(result.outcome, GroupsGuessOutcome.oneAway);
      expect(result.state.mistakes, 1);
      expect(result.state.solvedTags, isEmpty);
    });

    test('a scattered guess is simply wrong', () {
      final result = _guess(
        GroupsGameState.initial(_puzzle()),
        ['AONE', 'ATWO', 'BONE', 'CONE'],
      );
      expect(result.outcome, GroupsGuessOutcome.wrong);
      expect(result.state.mistakes, 1);
    });

    test('two and two is wrong, not one away', () {
      final result = _guess(
        GroupsGameState.initial(_puzzle()),
        ['AONE', 'ATWO', 'BONE', 'BTWO'],
      );
      expect(result.outcome, GroupsGuessOutcome.wrong);
    });

    test('repeating a guess costs nothing', () {
      // The player already paid for this mistake once.
      final first = _guess(
        GroupsGameState.initial(_puzzle()),
        ['AONE', 'ATWO', 'BONE', 'CONE'],
      );
      expect(first.state.mistakes, 1);

      final repeat = _guess(
        first.state,
        ['AONE', 'ATWO', 'BONE', 'CONE'],
      );
      expect(repeat.outcome, GroupsGuessOutcome.repeat);
      expect(repeat.state.mistakes, 1);
      // The guess is not recorded a second time either, so the history
      // cannot grow without bound from a player tapping submit repeatedly.
      expect(repeat.state.pastGuesses, hasLength(1));
      expect(repeat.state.solvedTags, isEmpty);
    });

    test('a repeat is recognised whatever order the words were tapped in', () {
      final first = _guess(
        GroupsGameState.initial(_puzzle()),
        ['AONE', 'ATWO', 'BONE', 'CONE'],
      );
      final repeat = _guess(
        first.state,
        ['CONE', 'BONE', 'ATWO', 'AONE'],
      );
      expect(repeat.outcome, GroupsGuessOutcome.repeat);
    });
  });

  group('finishing', () {
    test('four groups solves the puzzle', () {
      var state = GroupsGameState.initial(_puzzle());
      for (final tag in ['alpha', 'beta', 'gamma', 'delta']) {
        final words = _puzzle()
            .categories
            .firstWhere((c) => c.tag == tag)
            .wordTexts
            .toList();
        state = _guess(state, words).state;
      }
      expect(state.status, GroupsStatus.solved);
      expect(state.isPlaying, isFalse);
      expect(state.remainingWords, isEmpty);
      expect(state.mistakes, 0);
    });

    test('four mistakes loses the puzzle', () {
      var state = GroupsGameState.initial(_puzzle());
      final wrongGuesses = [
        ['AONE', 'ATWO', 'BONE', 'CONE'],
        ['AONE', 'ATWO', 'BONE', 'DONE'],
        ['AONE', 'ATWO', 'CONE', 'DONE'],
        ['AONE', 'BTWO', 'CONE', 'DONE'],
      ];
      for (var i = 0; i < wrongGuesses.length; i++) {
        state = _guess(state, wrongGuesses[i]).state;
        expect(state.mistakes, i + 1);
      }
      expect(state.status, GroupsStatus.lost);
      expect(state.mistakesRemaining, 0);
      expect(state.isPlaying, isFalse);
    });

    test('a finished puzzle takes no more input', () {
      var state = GroupsGameState.initial(_puzzle());
      for (final tag in ['alpha', 'beta', 'gamma', 'delta']) {
        final words = _puzzle()
            .categories
            .firstWhere((c) => c.tag == tag)
            .wordTexts
            .toList();
        state = _guess(state, words).state;
      }
      expect(state.toggleWord('AONE'), same(state));
      expect(state.submit().outcome, GroupsGuessOutcome.notReady);
    });
  });

  group('revealing', () {
    test('revealing after a loss fills the board but does not claim a win',
        () {
      // The bug this guards: filling in every category made the status
      // getter report "solved" for a puzzle the player had just lost.
      var state = GroupsGameState.initial(_puzzle());
      final wrongGuesses = [
        ['AONE', 'ATWO', 'BONE', 'CONE'],
        ['AONE', 'ATWO', 'BONE', 'DONE'],
        ['AONE', 'ATWO', 'CONE', 'DONE'],
        ['AONE', 'BTWO', 'CONE', 'DONE'],
      ];
      for (final guess in wrongGuesses) {
        state = _guess(state, guess).state;
      }
      final revealed = state.revealAll();
      expect(revealed.solvedTags, hasLength(groupsCategoryCount));
      expect(revealed.remainingWords, isEmpty);
      expect(revealed.status, GroupsStatus.lost);
    });

    test('revealing lists the categories easiest first', () {
      final revealed = GroupsGameState.initial(_puzzle()).revealAll();
      expect(
        revealed.solvedCategories.map((c) => c.difficulty),
        [0, 1, 2, 3],
      );
    });

    test('revealing keeps the groups already found in the order found', () {
      final solved =
          _guess(GroupsGameState.initial(_puzzle()), ['CONE', 'CTWO', 'CTHREE', 'CFOUR'])
              .state;
      final revealed = solved.revealAll();
      expect(revealed.solvedTags.first, 'gamma');
      expect(revealed.solvedTags, hasLength(groupsCategoryCount));
    });
  });

  group('shuffling', () {
    test('reorders the board without disturbing progress', () {
      final solved = _guess(
        GroupsGameState.initial(_puzzle()),
        ['AONE', 'ATWO', 'ATHREE', 'AFOUR'],
      ).state;
      final shuffled =
          solved.shuffleTiles(solved.tileOrder.reversed.toList());
      expect(shuffled.remainingWords.toSet(), solved.remainingWords.toSet());
      expect(shuffled.remainingWords, isNot(solved.remainingWords));
      expect(shuffled.solvedTags, solved.solvedTags);
      expect(shuffled.mistakes, solved.mistakes);
    });
  });

  group('json', () {
    test('a puzzle round-trips', () {
      final puzzle = _puzzle();
      final restored = GroupsPuzzle.fromJson(puzzle.toJson());
      expect(restored.id, puzzle.id);
      expect(restored.allWordTexts, puzzle.allWordTexts);
      for (final category in puzzle.categories) {
        final match =
            restored.categories.firstWhere((c) => c.tag == category.tag);
        expect(match.name, category.name);
        expect(match.difficulty, category.difficulty);
        expect(match.wordTexts, category.wordTexts);
      }
    });

    test('categoryOf finds a word, and reports nothing for a stranger', () {
      expect(_puzzle().categoryOf('CONE')?.tag, 'gamma');
      expect(_puzzle().categoryOf('NOTHERE'), isNull);
    });
  });
}
