import 'crossword_grid.dart';
import 'crossword_puzzle.dart';

enum CrosswordStatus { playing, solved }

/// Immutable snapshot of one mini crossword in progress.
class CrosswordGameState {
  const CrosswordGameState({
    required this.puzzle,
    required this.entered,
    required this.selectedCell,
    required this.direction,
    required this.revealedCells,
    required this.elapsedSeconds,
  });

  factory CrosswordGameState.initial(CrosswordPuzzle puzzle) {
    final firstOpen = List<int>.generate(crosswordCellCount, (i) => i)
        .firstWhere((i) => !puzzle.blocked[i], orElse: () => 0);
    return CrosswordGameState(
      puzzle: puzzle,
      entered: List<String>.filled(crosswordCellCount, ''),
      selectedCell: firstOpen,
      direction: CrosswordDirection.across,
      revealedCells: const {},
      elapsedSeconds: 0,
    );
  }

  final CrosswordPuzzle puzzle;
  final List<String> entered;
  final int selectedCell;
  final CrosswordDirection direction;

  /// Cells a hint filled in, drawn differently so the player can see what
  /// they were given rather than what they worked out.
  final Set<int> revealedCells;

  final int elapsedSeconds;

  bool get isPlaying => status == CrosswordStatus.playing;

  CrosswordStatus get status {
    for (var i = 0; i < crosswordCellCount; i++) {
      if (puzzle.blocked[i]) continue;
      if (entered[i] != puzzle.solution[i]) return CrosswordStatus.playing;
    }
    return CrosswordStatus.solved;
  }

  int get remainingCells {
    var count = 0;
    for (var i = 0; i < crosswordCellCount; i++) {
      if (!puzzle.blocked[i] && entered[i].isEmpty) count++;
    }
    return count;
  }

  /// The entry the selection currently sits in, which is what the clue
  /// bar shows.
  CrosswordEntry? get currentEntry {
    for (final entry in puzzle.entries) {
      if (entry.direction == direction && entry.cells.contains(selectedCell)) {
        return entry;
      }
    }
    // A cell always belongs to both directions, but guard anyway.
    for (final entry in puzzle.entries) {
      if (entry.cells.contains(selectedCell)) return entry;
    }
    return null;
  }

  /// Cells of the current entry, highlighted as a group.
  Set<int> get highlightedCells => currentEntry?.cells.toSet() ?? const {};

  /// Letters that disagree with the solution, once the player asks to be
  /// checked. Not shown automatically: a mini is short enough that
  /// constant correction removes the puzzle.
  Set<int> wrongCells() {
    final out = <int>{};
    for (var i = 0; i < crosswordCellCount; i++) {
      if (puzzle.blocked[i]) continue;
      if (entered[i].isNotEmpty && entered[i] != puzzle.solution[i]) {
        out.add(i);
      }
    }
    return out;
  }

  CrosswordGameState copyWith({
    List<String>? entered,
    int? selectedCell,
    CrosswordDirection? direction,
    Set<int>? revealedCells,
    int? elapsedSeconds,
  }) {
    return CrosswordGameState(
      puzzle: puzzle,
      entered: entered ?? this.entered,
      selectedCell: selectedCell ?? this.selectedCell,
      direction: direction ?? this.direction,
      revealedCells: revealedCells ?? this.revealedCells,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }

  /// Next open cell along [direction] from [selectedCell], for advancing
  /// the cursor after a letter is typed.
  int? nextCellInEntry() {
    final entry = currentEntry;
    if (entry == null) return null;
    final position = entry.cells.indexOf(selectedCell);
    if (position < 0 || position + 1 >= entry.cells.length) return null;
    return entry.cells[position + 1];
  }

  int? previousCellInEntry() {
    final entry = currentEntry;
    if (entry == null) return null;
    final position = entry.cells.indexOf(selectedCell);
    if (position <= 0) return null;
    return entry.cells[position - 1];
  }
}
