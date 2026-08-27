import 'crossword_grid.dart';

/// One entry in a published puzzle: where it sits, its answer, its clue.
class CrosswordEntry {
  const CrosswordEntry({
    required this.number,
    required this.direction,
    required this.cells,
    required this.answer,
    required this.clue,
  });

  final int number;
  final CrosswordDirection direction;
  final List<int> cells;
  final String answer;
  final String clue;

  String get label =>
      '$number ${direction == CrosswordDirection.across ? 'Across' : 'Down'}';

  factory CrosswordEntry.fromJson(Map<String, dynamic> json) => CrosswordEntry(
        number: json['n'] as int,
        direction: json['d'] == 'a'
            ? CrosswordDirection.across
            : CrosswordDirection.down,
        cells: (json['c'] as List).cast<int>(),
        answer: json['a'] as String,
        clue: json['q'] as String,
      );

  Map<String, dynamic> toJson() => {
        'n': number,
        'd': direction == CrosswordDirection.across ? 'a' : 'd',
        'c': cells,
        'a': answer,
        'q': clue,
      };
}

class CrosswordPuzzle {
  CrosswordPuzzle({
    required this.blocked,
    required this.solution,
    required this.entries,
  });

  /// [crosswordCellCount] flags; true where the square is black.
  final List<bool> blocked;

  /// [crosswordCellCount] letters; empty string on blocked squares.
  final List<String> solution;

  final List<CrosswordEntry> entries;

  List<CrosswordEntry> get across => entries
      .where((e) => e.direction == CrosswordDirection.across)
      .toList()
    ..sort((a, b) => a.number.compareTo(b.number));

  List<CrosswordEntry> get down => entries
      .where((e) => e.direction == CrosswordDirection.down)
      .toList()
    ..sort((a, b) => a.number.compareTo(b.number));

  Map<int, int> get numbers => {
        for (final entry in entries) ...{entry.cells.first: entry.number},
      };

  factory CrosswordPuzzle.fromJson(Map<String, dynamic> json) =>
      CrosswordPuzzle(
        blocked: (json['blocked'] as String).split('').map((c) => c == '1').toList(),
        solution: (json['solution'] as String).split(''),
        entries: (json['entries'] as List)
            .cast<Map<String, dynamic>>()
            .map(CrosswordEntry.fromJson)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'blocked': blocked.map((b) => b ? '1' : '0').join(),
        // Blocked squares carry a space so the string stays a fixed width
        // and indexes line up with the grid.
        'solution': solution.map((l) => l.isEmpty ? ' ' : l).join(),
        'entries': entries.map((e) => e.toJson()).toList(),
      };
}
