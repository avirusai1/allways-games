import 'tile_board.dart';
import 'tile_face.dart';
import 'tile_layout.dart';
import 'tile_match_puzzle.dart';

enum TileMatchStatus {
  /// Tiles remain and at least one pair can still be taken.
  playing,

  /// Every tile has been cleared.
  cleared,

  /// Tiles remain but no two free tiles match. The board is over — this is
  /// the losing state the genre turns on.
  stuck,
}

/// One reversible pick-up.
class TileMatchMove {
  const TileMatchMove(this.first, this.second);

  final TileSlot first;
  final TileSlot second;
}

/// Immutable snapshot of one Tile Match board in progress.
class TileMatchGameState {
  const TileMatchGameState({
    required this.puzzle,
    required this.remaining,
    required this.selected,
    required this.history,
    required this.elapsedSeconds,
  });

  factory TileMatchGameState.initial(TileMatchPuzzle puzzle) =>
      TileMatchGameState(
        puzzle: puzzle,
        remaining: puzzle.allSlots,
        selected: null,
        history: const [],
        elapsedSeconds: 0,
      );

  final TileMatchPuzzle puzzle;

  /// Tiles still on the board.
  final Set<TileSlot> remaining;

  /// The tile awaiting a partner, if any.
  final TileSlot? selected;

  final List<TileMatchMove> history;
  final int elapsedSeconds;

  Set<TileSlot> get freeSlots => TileBoard.freeSlots(remaining).toSet();

  /// Moves available right now. Empty with tiles left means a dead board.
  List<(TileSlot, TileSlot)> get availableMoves =>
      TileBoard.availableMoves(remaining, puzzle.faces);

  TileMatchStatus get status {
    if (remaining.isEmpty) return TileMatchStatus.cleared;
    return availableMoves.isEmpty
        ? TileMatchStatus.stuck
        : TileMatchStatus.playing;
  }

  bool get isPlaying => status == TileMatchStatus.playing;
  bool get canUndo => history.isNotEmpty;
  int get tilesCleared => puzzle.tileCount - remaining.length;

  TileFace? faceAt(TileSlot slot) => puzzle.faces[slot];

  bool isFree(TileSlot slot) => TileBoard.isFree(slot, remaining);

  /// Taps [slot].
  ///
  /// Tapping a blocked tile does nothing; tapping the selected tile
  /// deselects it; tapping a matching free tile takes the pair; tapping any
  /// other free tile moves the selection there — which is what a player
  /// expects when they change their mind mid-pair.
  TileMatchGameState tap(TileSlot slot) {
    if (!remaining.contains(slot)) return this;
    if (!isFree(slot)) return this;
    if (status == TileMatchStatus.cleared) return this;

    if (selected == null) return copyWith(selected: slot);
    if (selected == slot) return copyWith(clearSelection: true);

    if (puzzle.faces[selected] != puzzle.faces[slot]) {
      return copyWith(selected: slot);
    }

    return copyWith(
      remaining: {...remaining}
        ..remove(selected!)
        ..remove(slot),
      clearSelection: true,
      history: [...history, TileMatchMove(selected!, slot)],
    );
  }

  /// Puts the last pair back.
  ///
  /// Undo matters more here than in most games: a board can be made
  /// unwinnable by a single wrong pick long before that becomes visible,
  /// and without undo the only remedy would be starting the day over.
  TileMatchGameState undo() {
    if (history.isEmpty) return this;
    final move = history.last;
    return copyWith(
      remaining: {...remaining, move.first, move.second},
      clearSelection: true,
      history: history.sublist(0, history.length - 1),
    );
  }

  /// A pair that can be taken right now, for the hint button.
  (TileSlot, TileSlot)? hint() {
    final moves = availableMoves;
    return moves.isEmpty ? null : moves.first;
  }

  TileMatchGameState tick() =>
      isPlaying ? copyWith(elapsedSeconds: elapsedSeconds + 1) : this;

  TileMatchGameState copyWith({
    Set<TileSlot>? remaining,
    TileSlot? selected,
    bool clearSelection = false,
    List<TileMatchMove>? history,
    int? elapsedSeconds,
  }) {
    return TileMatchGameState(
      puzzle: puzzle,
      remaining: remaining ?? this.remaining,
      selected: clearSelection ? null : (selected ?? this.selected),
      history: history ?? this.history,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }
}
