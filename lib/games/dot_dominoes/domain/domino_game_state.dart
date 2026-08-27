import 'domino_board.dart';
import 'domino_puzzle.dart';

enum DominoStatus { playing, solved }

/// What came of trying to place a domino.
enum DominoPlaceOutcome {
  placed,

  /// The two cells are not both empty, or not adjacent.
  blocked,

  /// That domino is not in the tray, or all of its copies are down.
  notInTray,
}

class DominoPlaceResult {
  const DominoPlaceResult(this.outcome, this.state);

  final DominoPlaceOutcome outcome;
  final DominoGameState state;
}

/// Immutable snapshot of one Dot Dominoes game.
class DominoGameState {
  const DominoGameState({
    required this.puzzle,
    required this.placed,
    required this.selectedTrayIndex,
    required this.flipped,
    required this.elapsedSeconds,
  });

  factory DominoGameState.initial(DominoPuzzle puzzle) => DominoGameState(
        puzzle: puzzle,
        placed: const [],
        selectedTrayIndex: null,
        flipped: false,
        elapsedSeconds: 0,
      );

  final DominoPuzzle puzzle;
  final List<DominoPlacement> placed;

  /// Which tray domino the player is holding.
  final int? selectedTrayIndex;

  /// Whether the held domino is reversed.
  final bool flipped;

  final int elapsedSeconds;

  bool get isPlaying => status == DominoStatus.playing;

  /// Cell to the pips showing on it.
  Map<int, int> get pipsByCell => {
        for (final p in placed) ...{p.cellA: p.pipsA, p.cellB: p.pipsB},
      };

  /// Tray indices already on the board.
  Set<int> get usedTrayIndices {
    final used = <int>{};
    for (final placement in placed) {
      for (var i = 0; i < puzzle.tray.length; i++) {
        if (used.contains(i)) continue;
        if (puzzle.tray[i] == placement.domino) {
          used.add(i);
          break;
        }
      }
    }
    return used;
  }

  bool get boardFull => pipsByCell.length == puzzle.cells.length;

  DominoStatus get status {
    if (!boardFull) return DominoStatus.playing;
    final pips = List<int?>.filled(dominoCellCount, null);
    pipsByCell.forEach((cell, value) => pips[cell] = value);
    for (final region in puzzle.regions) {
      if (!region.isSatisfiable(pips)) return DominoStatus.playing;
    }
    return DominoStatus.solved;
  }

  /// Regions that are full but wrong, so the player can see where the
  /// board has gone astray without being told the answer.
  Set<int> get brokenRegions {
    final pips = List<int?>.filled(dominoCellCount, null);
    pipsByCell.forEach((cell, value) => pips[cell] = value);

    final broken = <int>{};
    for (var i = 0; i < puzzle.regions.length; i++) {
      final region = puzzle.regions[i];
      final full = region.cells.every((c) => pips[c] != null);
      if (full && !region.isSatisfiable(pips)) broken.add(i);
    }
    return broken;
  }

  DominoGameState copyWith({
    List<DominoPlacement>? placed,
    int? selectedTrayIndex,
    bool clearSelection = false,
    bool? flipped,
    int? elapsedSeconds,
  }) {
    return DominoGameState(
      puzzle: puzzle,
      placed: placed ?? this.placed,
      selectedTrayIndex:
          clearSelection ? null : (selectedTrayIndex ?? this.selectedTrayIndex),
      flipped: flipped ?? this.flipped,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }

  /// Places the held domino across [cellA] and [cellB].
  DominoPlaceResult place(int cellA, int cellB) {
    final index = selectedTrayIndex;
    if (index == null || usedTrayIndices.contains(index)) {
      return DominoPlaceResult(DominoPlaceOutcome.notInTray, this);
    }
    if (!puzzle.present[cellA] || !puzzle.present[cellB]) {
      return DominoPlaceResult(DominoPlaceOutcome.blocked, this);
    }
    if (!dominoAdjacency[cellA].contains(cellB)) {
      return DominoPlaceResult(DominoPlaceOutcome.blocked, this);
    }
    final occupied = pipsByCell;
    if (occupied.containsKey(cellA) || occupied.containsKey(cellB)) {
      return DominoPlaceResult(DominoPlaceOutcome.blocked, this);
    }

    final domino = puzzle.tray[index];
    return DominoPlaceResult(
      DominoPlaceOutcome.placed,
      copyWith(
        placed: [
          ...placed,
          DominoPlacement(
            cellA: cellA,
            cellB: cellB,
            pipsA: flipped ? domino.high : domino.low,
            pipsB: flipped ? domino.low : domino.high,
          ),
        ],
        clearSelection: true,
        flipped: false,
      ),
    );
  }

  /// Lifts whichever domino covers [cell] back to the tray.
  DominoGameState removeAt(int cell) {
    final remaining = placed
        .where((p) => p.cellA != cell && p.cellB != cell)
        .toList();
    if (remaining.length == placed.length) return this;
    return copyWith(placed: remaining);
  }

  DominoGameState selectTray(int index) {
    if (usedTrayIndices.contains(index)) return this;
    if (selectedTrayIndex == index) {
      // Tapping the held domino again turns it round, which is how a
      // player reverses one without a separate control.
      return copyWith(flipped: !flipped);
    }
    return copyWith(selectedTrayIndex: index, flipped: false);
  }
}
