/// Geometry and letter rules for a Word Loop board.
///
/// The board is a square with three letters printed along each of its four
/// sides — twelve distinct letters in all. Pure Dart: no Flutter imports,
/// so the generator script and the unit tests share this code with the app.
library;

const int wordLoopSideCount = 4;
const int wordLoopLettersPerSide = 3;
const int wordLoopLetterCount = wordLoopSideCount * wordLoopLettersPerSide;

/// Two-letter words are trivial on a twelve-letter board and make the
/// chain rule meaningless, so the shortest playable word is three letters.
const int wordLoopMinWordLength = 3;

/// The four sides of the square, in the order they are laid out.
enum WordLoopSide { top, right, bottom, left }

/// One board: twelve letters split three to a side.
class WordLoopBox {
  WordLoopBox(List<List<String>> sides)
      : sides = List<List<String>>.unmodifiable([
          for (final side in sides)
            List<String>.unmodifiable(
              side.map((letter) => letter.toUpperCase()),
            ),
        ]) {
    if (this.sides.length != wordLoopSideCount) {
      throw ArgumentError('A box needs exactly $wordLoopSideCount sides.');
    }
    for (final side in this.sides) {
      if (side.length != wordLoopLettersPerSide) {
        throw ArgumentError(
          'Each side needs exactly $wordLoopLettersPerSide letters.',
        );
      }
    }
    for (var i = 0; i < this.sides.length; i++) {
      for (final letter in this.sides[i]) {
        if (letter.length != 1 || !_isLetter(letter)) {
          throw ArgumentError('"$letter" is not a single A-Z letter.');
        }
        if (_sideOfLetter.containsKey(letter)) {
          throw ArgumentError('Letter $letter appears on more than one side.');
        }
        _sideOfLetter[letter] = i;
      }
    }
  }

  factory WordLoopBox.parse(String encoded) {
    final sides = encoded.toUpperCase().split('-');
    return WordLoopBox([for (final side in sides) side.split('')]);
  }

  final List<List<String>> sides;
  final Map<String, int> _sideOfLetter = {};

  /// Side index of [letter], or null when the board does not carry it.
  int? sideOf(String letter) => _sideOfLetter[letter.toUpperCase()];

  bool containsLetter(String letter) =>
      _sideOfLetter.containsKey(letter.toUpperCase());

  Set<String> get letters => _sideOfLetter.keys.toSet();

  /// Whether [word] can be traced on this board.
  ///
  /// Checks only the board's own rules — long enough, every letter present,
  /// and no two consecutive letters taken from the same side (the rule that
  /// makes the board a puzzle rather than an anagram). Whether the word is
  /// a real word is a separate question the content bank answers.
  bool isPlayable(String word) {
    final upper = word.toUpperCase();
    if (upper.length < wordLoopMinWordLength) return false;

    int? previousSide;
    for (final letter in upper.split('')) {
      final side = _sideOfLetter[letter];
      if (side == null) return false;
      if (side == previousSide) return false;
      previousSide = side;
    }
    return true;
  }

  /// Encodes the board as `ABC-DEF-GHI-JKL`.
  String encode() => sides.map((side) => side.join()).join('-');

  static bool _isLetter(String char) {
    final code = char.codeUnitAt(0);
    return code >= 0x41 && code <= 0x5A;
  }
}
