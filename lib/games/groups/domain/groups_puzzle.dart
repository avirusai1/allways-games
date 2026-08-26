/// One published Groups puzzle: sixteen words that split into four hidden
/// categories of four.
///
/// Pure Dart, no Flutter imports, so the offline verifier and the unit
/// tests share the model the app plays against.
library;

const int groupsCategoryCount = 4;
const int groupsWordsPerCategory = 4;
const int groupsWordCount = groupsCategoryCount * groupsWordsPerCategory;

/// Guesses a player may get wrong before the puzzle is lost.
const int groupsMistakeLimit = 4;

/// One word as it appears in a puzzle, with every category it could
/// plausibly belong to.
///
/// The tag list is the whole point of this type. A program cannot know
/// that BASS is both a fish and a musical range, so that knowledge is
/// authored alongside the word and checked mechanically: a word whose tags
/// touch two of a puzzle's categories makes that puzzle ambiguous, and the
/// content verifier refuses it.
class GroupsWord {
  const GroupsWord({required this.text, required this.tags});

  factory GroupsWord.fromJson(Map<String, dynamic> json) => GroupsWord(
        text: json['w'] as String,
        tags: Set<String>.unmodifiable((json['tags'] as List).cast<String>()),
      );

  final String text;

  /// Every category tag this word could reasonably be filed under,
  /// including its own.
  final Set<String> tags;

  Map<String, dynamic> toJson() => {
        'w': text,
        'tags': tags.toList()..sort(),
      };
}

/// One of a puzzle's four categories.
class GroupsCategory {
  GroupsCategory({
    required this.tag,
    required this.name,
    required this.difficulty,
    required List<GroupsWord> words,
  }) : words = List<GroupsWord>.unmodifiable(words);

  factory GroupsCategory.fromJson(Map<String, dynamic> json) => GroupsCategory(
        tag: json['tag'] as String,
        name: json['name'] as String,
        difficulty: json['difficulty'] as int,
        words: (json['words'] as List)
            .map((w) => GroupsWord.fromJson(w as Map<String, dynamic>))
            .toList(),
      );

  /// Machine key for the category, used by the ambiguity check.
  final String tag;

  /// What the player is shown once they find it.
  final String name;

  /// 0 is the most obvious group, 3 the most oblique. Drives the colour a
  /// solved row is given and the order the answers are revealed in.
  final int difficulty;

  final List<GroupsWord> words;

  Set<String> get wordTexts => words.map((w) => w.text).toSet();

  Map<String, dynamic> toJson() => {
        'tag': tag,
        'name': name,
        'difficulty': difficulty,
        'words': words.map((w) => w.toJson()).toList(),
      };
}

class GroupsPuzzle {
  GroupsPuzzle({required this.id, required List<GroupsCategory> categories})
      : categories = List<GroupsCategory>.unmodifiable(categories);

  factory GroupsPuzzle.fromJson(Map<String, dynamic> json) => GroupsPuzzle(
        id: json['id'] as String,
        categories: (json['categories'] as List)
            .map((c) => GroupsCategory.fromJson(c as Map<String, dynamic>))
            .toList(),
      );

  /// Stable identifier, so a puzzle can be referred to in a bug report
  /// without depending on which day it happens to land on.
  final String id;

  final List<GroupsCategory> categories;

  List<GroupsWord> get allWords => [
        for (final category in categories) ...category.words,
      ];

  List<String> get allWordTexts => allWords.map((w) => w.text).toList();

  /// The category a word belongs to, or null if the word is not in this
  /// puzzle.
  GroupsCategory? categoryOf(String word) {
    for (final category in categories) {
      if (category.wordTexts.contains(word)) return category;
    }
    return null;
  }

  /// Categories easiest first.
  List<GroupsCategory> get byDifficulty =>
      [...categories]..sort((a, b) => a.difficulty.compareTo(b.difficulty));

  Map<String, dynamic> toJson() => {
        'id': id,
        'categories': categories.map((c) => c.toJson()).toList(),
      };
}
