import 'word_loop_box.dart';

/// One published Word Loop board.
///
/// Boards do not carry their own word list. Whether a word counts is
/// `dictionary contains it` AND `the board can trace it`, and the board
/// half is cheap to evaluate — so every board shares one dictionary rather
/// than shipping a few hundred words each, which would have made the asset
/// roughly thirty times larger for no gain.
class WordLoopPuzzle {
  const WordLoopPuzzle({
    required this.box,
    required this.par,
    required this.exampleSolution,
    required this.playableWordCount,
    required this.dictionary,
  });

  factory WordLoopPuzzle.fromJson(
    Map<String, dynamic> json,
    Set<String> dictionary,
  ) {
    return WordLoopPuzzle(
      box: WordLoopBox.parse(json['box'] as String),
      par: json['par'] as int,
      exampleSolution: (json['solution'] as List).cast<String>(),
      playableWordCount: json['wordCount'] as int,
      dictionary: dictionary,
    );
  }

  final WordLoopBox box;

  /// Fewest words any chain needs to cover the board. The player's score is
  /// read against this.
  final int par;

  /// One chain that does it, revealed after the board is finished.
  final List<String> exampleSolution;

  /// How many dictionary words this board can trace, counted offline by
  /// the generator so the app can show progress without a full scan.
  final int playableWordCount;

  /// Every word the app accepts anywhere, shared by all boards.
  final Set<String> dictionary;

  bool isValidWord(String word) {
    final upper = word.toUpperCase();
    return dictionary.contains(upper) && box.isPlayable(upper);
  }

  Map<String, dynamic> toJson() => {
        'box': box.encode(),
        'par': par,
        'solution': exampleSolution,
        'wordCount': playableWordCount,
      };
}
