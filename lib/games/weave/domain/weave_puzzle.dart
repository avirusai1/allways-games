import 'weave_grid.dart';

/// One published Weave puzzle.
class WeavePuzzle {
  WeavePuzzle({
    required this.clue,
    required this.letters,
    required this.spanner,
    required Map<String, List<int>> solutions,
    required Set<String> bonusWords,
  })  : solutions = Map<String, List<int>>.unmodifiable(solutions),
        bonusWords = Set<String>.unmodifiable(bonusWords);

  /// The theme, shown to the player up front. Weave is not a guessing
  /// game about the theme; the difficulty is finding the words.
  final String clue;

  /// [weaveCellCount] letters, row by row.
  final List<String> letters;

  /// The theme word that reaches both the top and bottom rows.
  final String spanner;

  /// Theme word to the path that traces it.
  final Map<String, List<int>> solutions;

  /// Real words the grid happens to contain that are not theme words.
  /// Finding these earns a hint rather than being rejected.
  final Set<String> bonusWords;

  List<String> get themeWords => solutions.keys.toList();

  factory WeavePuzzle.fromJson(Map<String, dynamic> json) => WeavePuzzle(
        clue: json['clue'] as String,
        letters: (json['letters'] as String).split(''),
        spanner: json['spanner'] as String,
        solutions: {
          for (final entry in (json['solutions'] as Map<String, dynamic>).entries)
            entry.key: (entry.value as List).cast<int>(),
        },
        bonusWords: (json['bonus'] as List).cast<String>().toSet(),
      );

  Map<String, dynamic> toJson() => {
        'clue': clue,
        'letters': letters.join(),
        'spanner': spanner,
        'solutions': solutions,
        'bonus': bonusWords.toList()..sort(),
      };
}
