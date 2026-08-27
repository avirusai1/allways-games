import 'package:allways_games/games/groups/domain/groups_puzzle.dart';
import 'package:allways_games/games/groups/domain/groups_validator.dart';
import 'package:flutter_test/flutter_test.dart';

GroupsCategory _category(
  String tag,
  int difficulty,
  List<String> words, {
  Map<String, Set<String>> extraTags = const {},
  String? name,
}) {
  return GroupsCategory(
    tag: tag,
    name: name ?? tag,
    difficulty: difficulty,
    words: [
      for (final word in words)
        GroupsWord(text: word, tags: {tag, ...?extraTags[word]}),
    ],
  );
}

/// A clean four-by-four puzzle for the tests to break in specific ways.
GroupsPuzzle _puzzle({List<GroupsCategory>? categories, String id = 'test'}) =>
    GroupsPuzzle(
      id: id,
      categories: categories ??
          [
            _category('alpha', 0, ['AONE', 'ATWO', 'ATHREE', 'AFOUR']),
            _category('beta', 1, ['BONE', 'BTWO', 'BTHREE', 'BFOUR']),
            _category('gamma', 2, ['CONE', 'CTWO', 'CTHREE', 'CFOUR']),
            _category('delta', 3, ['DONE', 'DTWO', 'DTHREE', 'DFOUR']),
          ],
    );

void main() {
  test('a well-formed puzzle has no defects', () {
    expect(GroupsValidator.validate(_puzzle()), isEmpty);
  });

  group('shape', () {
    test('the wrong number of categories is caught', () {
      final puzzle = GroupsPuzzle(
        id: 'short',
        categories: [_category('alpha', 0, ['AONE', 'ATWO', 'ATHREE', 'AFOUR'])],
      );
      expect(GroupsValidator.validate(puzzle), isNotEmpty);
    });

    test('the wrong number of words in a category is caught', () {
      final puzzle = _puzzle(categories: [
        _category('alpha', 0, ['AONE', 'ATWO', 'ATHREE']),
        _category('beta', 1, ['BONE', 'BTWO', 'BTHREE', 'BFOUR']),
        _category('gamma', 2, ['CONE', 'CTWO', 'CTHREE', 'CFOUR']),
        _category('delta', 3, ['DONE', 'DTWO', 'DTHREE', 'DFOUR']),
      ]);
      expect(
        GroupsValidator.validate(puzzle).map((d) => d.message).join(),
        contains('3 words'),
      );
    });

    test('a repeated word is caught', () {
      final puzzle = _puzzle(categories: [
        _category('alpha', 0, ['AONE', 'ATWO', 'ATHREE', 'AFOUR']),
        _category('beta', 1, ['AONE', 'BTWO', 'BTHREE', 'BFOUR']),
        _category('gamma', 2, ['CONE', 'CTWO', 'CTHREE', 'CFOUR']),
        _category('delta', 3, ['DONE', 'DTWO', 'DTHREE', 'DFOUR']),
      ]);
      expect(
        GroupsValidator.validate(puzzle).map((d) => d.message).join(),
        contains('AONE'),
      );
    });

    test('duplicate difficulties are caught', () {
      final puzzle = _puzzle(categories: [
        _category('alpha', 0, ['AONE', 'ATWO', 'ATHREE', 'AFOUR']),
        _category('beta', 0, ['BONE', 'BTWO', 'BTHREE', 'BFOUR']),
        _category('gamma', 2, ['CONE', 'CTWO', 'CTHREE', 'CFOUR']),
        _category('delta', 3, ['DONE', 'DTWO', 'DTHREE', 'DFOUR']),
      ]);
      expect(
        GroupsValidator.validate(puzzle).map((d) => d.message).join(),
        contains('difficulties'),
      );
    });

    test('a lower-case word is caught', () {
      final puzzle = _puzzle(categories: [
        _category('alpha', 0, ['aone', 'ATWO', 'ATHREE', 'AFOUR']),
        _category('beta', 1, ['BONE', 'BTWO', 'BTHREE', 'BFOUR']),
        _category('gamma', 2, ['CONE', 'CTWO', 'CTHREE', 'CFOUR']),
        _category('delta', 3, ['DONE', 'DTWO', 'DTHREE', 'DFOUR']),
      ]);
      expect(GroupsValidator.validate(puzzle), isNotEmpty);
    });

    test('a duplicated category tag or name is caught', () {
      final byTag = _puzzle(categories: [
        _category('alpha', 0, ['AONE', 'ATWO', 'ATHREE', 'AFOUR']),
        _category('alpha', 1, ['BONE', 'BTWO', 'BTHREE', 'BFOUR'],
            name: 'other'),
        _category('gamma', 2, ['CONE', 'CTWO', 'CTHREE', 'CFOUR']),
        _category('delta', 3, ['DONE', 'DTWO', 'DTHREE', 'DFOUR']),
      ]);
      expect(GroupsValidator.validate(byTag), isNotEmpty);

      final byName = _puzzle(categories: [
        _category('alpha', 0, ['AONE', 'ATWO', 'ATHREE', 'AFOUR'],
            name: 'Same'),
        _category('beta', 1, ['BONE', 'BTWO', 'BTHREE', 'BFOUR'], name: 'Same'),
        _category('gamma', 2, ['CONE', 'CTWO', 'CTHREE', 'CFOUR']),
        _category('delta', 3, ['DONE', 'DTWO', 'DTHREE', 'DFOUR']),
      ]);
      expect(GroupsValidator.validate(byName), isNotEmpty);
    });
  });

  group('ambiguity', () {
    test('a word that fits a second category in the puzzle is caught', () {
      // This is the check the whole validator exists for: a puzzle where a
      // word has a defensible home in two groups is broken, not hard.
      final puzzle = _puzzle(categories: [
        _category('alpha', 0, ['AONE', 'ATWO', 'ATHREE', 'AFOUR'],
            extraTags: {'AONE': {'gamma'}}),
        _category('beta', 1, ['BONE', 'BTWO', 'BTHREE', 'BFOUR']),
        _category('gamma', 2, ['CONE', 'CTWO', 'CTHREE', 'CFOUR']),
        _category('delta', 3, ['DONE', 'DTWO', 'DTHREE', 'DFOUR']),
      ]);
      final defects = GroupsValidator.validate(puzzle);
      expect(defects, hasLength(1));
      expect(defects.first.message, contains('AONE'));
      expect(defects.first.message, contains('gamma'));
    });

    test('a sense that matches no other category in the puzzle is fine', () {
      // Declaring that a word has other meanings is not itself a problem —
      // only a collision with this puzzle's other groups is.
      final puzzle = _puzzle(categories: [
        _category('alpha', 0, ['AONE', 'ATWO', 'ATHREE', 'AFOUR'],
            extraTags: {'AONE': {'something-else-entirely'}}),
        _category('beta', 1, ['BONE', 'BTWO', 'BTHREE', 'BFOUR']),
        _category('gamma', 2, ['CONE', 'CTWO', 'CTHREE', 'CFOUR']),
        _category('delta', 3, ['DONE', 'DTWO', 'DTHREE', 'DFOUR']),
      ]);
      expect(GroupsValidator.validate(puzzle), isEmpty);
    });

    test('a word that does not claim its own category is caught', () {
      final puzzle = _puzzle(categories: [
        GroupsCategory(
          tag: 'alpha',
          name: 'alpha',
          difficulty: 0,
          words: const [
            GroupsWord(text: 'AONE', tags: {'unrelated'}),
            GroupsWord(text: 'ATWO', tags: {'alpha'}),
            GroupsWord(text: 'ATHREE', tags: {'alpha'}),
            GroupsWord(text: 'AFOUR', tags: {'alpha'}),
          ],
        ),
        _category('beta', 1, ['BONE', 'BTWO', 'BTHREE', 'BFOUR']),
        _category('gamma', 2, ['CONE', 'CTWO', 'CTHREE', 'CFOUR']),
        _category('delta', 3, ['DONE', 'DTWO', 'DTHREE', 'DFOUR']),
      ]);
      expect(
        GroupsValidator.validate(puzzle).map((d) => d.message).join(),
        contains('does not claim'),
      );
    });

    test('a word with no tags at all is caught', () {
      final puzzle = _puzzle(categories: [
        GroupsCategory(
          tag: 'alpha',
          name: 'alpha',
          difficulty: 0,
          words: const [
            GroupsWord(text: 'AONE', tags: {}),
            GroupsWord(text: 'ATWO', tags: {'alpha'}),
            GroupsWord(text: 'ATHREE', tags: {'alpha'}),
            GroupsWord(text: 'AFOUR', tags: {'alpha'}),
          ],
        ),
        _category('beta', 1, ['BONE', 'BTWO', 'BTHREE', 'BFOUR']),
        _category('gamma', 2, ['CONE', 'CTWO', 'CTHREE', 'CFOUR']),
        _category('delta', 3, ['DONE', 'DTWO', 'DTHREE', 'DFOUR']),
      ]);
      expect(
        GroupsValidator.validate(puzzle).map((d) => d.message).join(),
        contains('declares no tags'),
      );
    });
  });

  group('bank-level checks', () {
    test('a duplicate puzzle id is caught', () {
      final defects = GroupsValidator.validateBank([_puzzle(), _puzzle()]);
      expect(
        defects.map((d) => d.message).join(),
        contains('duplicate puzzle id'),
      );
    });

    test('a category repeated verbatim is caught in the authored source', () {
      final second = GroupsPuzzle(
        id: 'other',
        categories: [
          // Same four words as the first puzzle's alpha group.
          _category('alpha2', 0, ['AONE', 'ATWO', 'ATHREE', 'AFOUR']),
          _category('beta2', 1, ['EONE', 'ETWO', 'ETHREE', 'EFOUR']),
          _category('gamma2', 2, ['FONE', 'FTWO', 'FTHREE', 'FFOUR']),
          _category('delta2', 3, ['GONE', 'GTWO', 'GTHREE', 'GFOUR']),
        ],
      );
      expect(
        GroupsValidator.validateAuthoredSource([_puzzle(), second])
            .map((d) => d.message)
            .join(),
        contains('repeats one from'),
      );
    });

    test('a shared category is allowed in the shipped bank', () {
      // The bank is partly composed by recombining authored categories, so
      // one group recurring in a different set of four is by design.
      final second = GroupsPuzzle(
        id: 'other',
        categories: [
          _category('alpha2', 0, ['AONE', 'ATWO', 'ATHREE', 'AFOUR']),
          _category('beta2', 1, ['EONE', 'ETWO', 'ETHREE', 'EFOUR']),
          _category('gamma2', 2, ['FONE', 'FTWO', 'FTHREE', 'FFOUR']),
          _category('delta2', 3, ['GONE', 'GTWO', 'GTHREE', 'GFOUR']),
        ],
      );
      expect(GroupsValidator.validateBank([_puzzle(), second]), isEmpty);
    });

    test('the same four categories twice is caught', () {
      // One shared group is fine; a whole repeated puzzle would play
      // identically on two days.
      expect(
        GroupsValidator.validateBank([_puzzle(), _puzzle(id: 'other')])
            .map((d) => d.message)
            .join(),
        contains('same four categories'),
      );
    });

    test('a word may appear in different puzzles', () {
      // Reusing a word across days is normal and must not be flagged.
      final second = GroupsPuzzle(
        id: 'other',
        categories: [
          _category('alpha2', 0, ['AONE', 'ETWO', 'ETHREE', 'EFOUR']),
          _category('beta2', 1, ['FONE', 'FTWO', 'FTHREE', 'FFOUR']),
          _category('gamma2', 2, ['GONE', 'GTWO', 'GTHREE', 'GFOUR']),
          _category('delta2', 3, ['HONE', 'HTWO', 'HTHREE', 'HFOUR']),
        ],
      );
      expect(GroupsValidator.validateBank([_puzzle(), second]), isEmpty);
    });
  });
}
