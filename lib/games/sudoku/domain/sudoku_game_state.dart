import 'sudoku_board.dart';

enum SudokuStatus { playing, solved }

/// Immutable snapshot of one Sudoku game in progress.
class SudokuGameState {
  const SudokuGameState({
    required this.puzzle,
    required this.entries,
    required this.notes,
    required this.selectedIndex,
    required this.status,
    required this.notesMode,
    required this.elapsedSeconds,
  });

  factory SudokuGameState.initial(SudokuPuzzle puzzle) => SudokuGameState(
        puzzle: puzzle,
        entries: List<int>.from(puzzle.givens),
        notes: List<Set<int>>.generate(sudokuCellCount, (_) => <int>{}),
        selectedIndex: null,
        status: SudokuStatus.playing,
        notesMode: false,
        elapsedSeconds: 0,
      );

  final SudokuPuzzle puzzle;

  /// Current board contents, seeded from the givens.
  final List<int> entries;

  /// Pencil marks per cell.
  final List<Set<int>> notes;

  final int? selectedIndex;
  final SudokuStatus status;
  final bool notesMode;
  final int elapsedSeconds;

  bool isGiven(int index) => puzzle.givens[index] != emptyCell;
  bool get isPlaying => status == SudokuStatus.playing;

  Set<int> get conflicts => findConflicts(entries);

  int get remainingCells =>
      entries.where((value) => value == emptyCell).length;

  /// How many of each digit are still placeable, so the number pad can dim
  /// digits that are already used nine times.
  Map<int, int> get remainingPerDigit {
    final counts = <int, int>{for (var d = 1; d <= sudokuSize; d++) d: sudokuSize};
    for (final value in entries) {
      if (value != emptyCell) counts[value] = (counts[value] ?? 0) - 1;
    }
    return counts;
  }

  SudokuGameState copyWith({
    List<int>? entries,
    List<Set<int>>? notes,
    int? selectedIndex,
    bool clearSelection = false,
    SudokuStatus? status,
    bool? notesMode,
    int? elapsedSeconds,
  }) {
    return SudokuGameState(
      puzzle: puzzle,
      entries: entries ?? this.entries,
      notes: notes ?? this.notes,
      selectedIndex:
          clearSelection ? null : (selectedIndex ?? this.selectedIndex),
      status: status ?? this.status,
      notesMode: notesMode ?? this.notesMode,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }
}
