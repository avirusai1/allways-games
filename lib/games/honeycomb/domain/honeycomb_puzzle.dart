import 'honeycomb_scoring.dart';

/// One published Honeycomb board: seven letters, one of which every answer
/// must use.
class HoneycombPuzzle {
  HoneycombPuzzle({
    required this.requiredLetter,
    required List<String> outerLetters,
    required List<String> answers,
  })  : outerLetters = List<String>.unmodifiable(
          outerLetters.map((l) => l.toUpperCase()),
        ),
        answers = Set<String>.unmodifiable(
          answers.map((w) => w.toUpperCase()),
        );

  factory HoneycombPuzzle.fromJson(Map<String, dynamic> json) {
    return HoneycombPuzzle(
      requiredLetter: json['required'] as String,
      outerLetters: (json['outer'] as String).split(''),
      answers: (json['answers'] as List).cast<String>(),
    );
  }

  /// The letter in the middle of the comb. Every answer must contain it.
  final String requiredLetter;

  /// The other six letters, which answers may use freely or not at all.
  final List<String> outerLetters;

  /// Every accepted word for this board, found exhaustively offline.
  ///
  /// Shipped per board rather than validating against a dictionary at
  /// runtime, because the game needs the *complete* answer set anyway: how
  /// far through the board a player is, and what the maximum score is, are
  /// both meaningless without it.
  final Set<String> answers;

  /// All seven letters, required letter first.
  List<String> get allLetters => [requiredLetter, ...outerLetters];

  Set<String> get letterSet => allLetters.toSet();

  /// Answers that use all seven letters.
  Set<String> get pangrams =>
      answers.where(isPangram).toSet();

  bool isPangram(String word) =>
      word.toUpperCase().split('').toSet().length == honeycombLetterCount &&
      word.toUpperCase().split('').toSet().containsAll(letterSet);

  bool isAnswer(String word) => answers.contains(word.toUpperCase());

  /// Score for finding every word on the board.
  int get maxScore => answers.fold(
        0,
        (total, word) =>
            total + honeycombScoreFor(word, isPangram: isPangram(word)),
      );

  Map<String, dynamic> toJson() => {
        'required': requiredLetter,
        'outer': outerLetters.join(),
        'answers': answers.toList()..sort(),
      };
}
