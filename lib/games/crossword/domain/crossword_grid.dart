/// Grid geometry for the mini crossword.
///
/// Pure Dart, no Flutter imports, so the fill generator and the unit tests
/// share the geometry the app draws.
library;

const int crosswordSize = 5;
const int crosswordCellCount = crosswordSize * crosswordSize;

/// Shortest run of open squares that counts as an entry.
///
/// Two-letter entries are the mark of a bad grid: there are few of them,
/// they are all obscure, and every one has to be clued.
const int crosswordMinEntry = 3;

enum CrosswordDirection { across, down }

int crosswordRowOf(int index) => index ~/ crosswordSize;
int crosswordColOf(int index) => index % crosswordSize;
int crosswordIndexAt(int row, int col) => row * crosswordSize + col;

/// A run of open squares to be filled with one word.
class CrosswordSlot {
  const CrosswordSlot({
    required this.number,
    required this.direction,
    required this.cells,
  });

  /// The number shown in the grid's first square, shared between the
  /// across and down entry that start there.
  final int number;

  final CrosswordDirection direction;

  /// Cell indices in reading order.
  final List<int> cells;

  int get length => cells.length;

  String get label =>
      '$number ${direction == CrosswordDirection.across ? 'Across' : 'Down'}';
}

/// A black-square layout, written as rows where '#' is a blocked square.
class CrosswordPattern {
  const CrosswordPattern({required this.name, required this.rows});

  final String name;
  final List<String> rows;

  List<bool> get blocked => [
        for (final row in rows)
          for (final cell in row.split('')) cell == '#',
      ];
}

/// The layouts the generator draws from.
///
/// Every one is rotationally symmetric, the convention crossword solvers
/// expect, and every one has been checked to contain no entry shorter
/// than [crosswordMinEntry].
/// A fully open 5x5 is deliberately absent: it demands a double word
/// square, five across and five down all interlocking, which a few hundred
/// clued five-letter words cannot supply. Every pattern here has blocks.
const List<CrosswordPattern> crosswordPatterns = [
  CrosswordPattern(name: 'Stairs', rows: [
    '##...',
    '#....',
    '.....',
    '....#',
    '...##',
  ]),
  CrosswordPattern(name: 'Stairs Mirrored', rows: [
    '...##',
    '....#',
    '.....',
    '#....',
    '##...',
  ]),
  CrosswordPattern(name: 'Steps', rows: [
    '##...',
    '##...',
    '.....',
    '...##',
    '...##',
  ]),
  CrosswordPattern(name: 'Steps Mirrored', rows: [
    '...##',
    '...##',
    '.....',
    '##...',
    '##...',
  ]),
];

/// Extracts the numbered slots from a blocked-square layout.
///
/// Numbering follows the usual rule: scan in reading order and number a
/// square when it begins an across or a down entry.
List<CrosswordSlot> slotsFor(List<bool> blocked) {
  final slots = <CrosswordSlot>[];
  var number = 0;

  for (var index = 0; index < crosswordCellCount; index++) {
    if (blocked[index]) continue;
    final row = crosswordRowOf(index);
    final col = crosswordColOf(index);

    final startsAcross = (col == 0 || blocked[crosswordIndexAt(row, col - 1)]) &&
        col + 1 < crosswordSize &&
        !blocked[crosswordIndexAt(row, col + 1)];
    final startsDown = (row == 0 || blocked[crosswordIndexAt(row - 1, col)]) &&
        row + 1 < crosswordSize &&
        !blocked[crosswordIndexAt(row + 1, col)];

    if (!startsAcross && !startsDown) continue;
    number++;

    if (startsAcross) {
      final cells = <int>[];
      for (var c = col; c < crosswordSize; c++) {
        final at = crosswordIndexAt(row, c);
        if (blocked[at]) break;
        cells.add(at);
      }
      slots.add(CrosswordSlot(
        number: number,
        direction: CrosswordDirection.across,
        cells: cells,
      ));
    }

    if (startsDown) {
      final cells = <int>[];
      for (var r = row; r < crosswordSize; r++) {
        final at = crosswordIndexAt(r, col);
        if (blocked[at]) break;
        cells.add(at);
      }
      slots.add(CrosswordSlot(
        number: number,
        direction: CrosswordDirection.down,
        cells: cells,
      ));
    }
  }

  return slots;
}

/// Cell index to the number displayed in its corner, if any.
Map<int, int> slotNumbers(List<CrosswordSlot> slots) {
  final out = <int, int>{};
  for (final slot in slots) {
    out.putIfAbsent(slot.cells.first, () => slot.number);
  }
  return out;
}
