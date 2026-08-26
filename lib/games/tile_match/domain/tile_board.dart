import 'tile_face.dart';
import 'tile_layout.dart';

/// The rules that decide which tiles can be picked up, and whether a board
/// can be cleared at all.
///
/// Pure Dart, shared by the offline generator, the unit tests and the app.
class TileBoard {
  TileBoard._();

  /// Whether [slot] can be picked up given the tiles still on the board.
  ///
  /// Two conditions, both necessary: nothing rests directly on top of it,
  /// and at least one side neighbour on its own layer is gone. The side
  /// rule is what turns a stack into a puzzle — without it a player would
  /// simply peel the layers off in any order.
  static bool isFree(TileSlot slot, Set<TileSlot> remaining) {
    if (!remaining.contains(slot)) return false;

    final above = TileSlot(layer: slot.layer + 1, row: slot.row, col: slot.col);
    if (remaining.contains(above)) return false;

    final left = TileSlot(layer: slot.layer, row: slot.row, col: slot.col - 1);
    final right = TileSlot(layer: slot.layer, row: slot.row, col: slot.col + 1);
    return !remaining.contains(left) || !remaining.contains(right);
  }

  static List<TileSlot> freeSlots(Set<TileSlot> remaining) {
    return [
      for (final slot in remaining)
        if (isFree(slot, remaining)) slot,
    ];
  }

  /// Pairs of free tiles that share a face — every move available right now.
  static List<(TileSlot, TileSlot)> availableMoves(
    Set<TileSlot> remaining,
    Map<TileSlot, TileFace> faces,
  ) {
    final free = freeSlots(remaining);
    final moves = <(TileSlot, TileSlot)>[];
    for (var i = 0; i < free.length; i++) {
      for (var j = i + 1; j < free.length; j++) {
        if (faces[free[i]] == faces[free[j]]) moves.add((free[i], free[j]));
      }
    }
    return moves;
  }

  /// Whether the board can still be cleared from [remaining].
  ///
  /// Note what "solvable" means for this genre: a clearing sequence exists
  /// from the starting position. Because a face appears on more than two
  /// tiles, a player can still pick a pair that strands the rest — that
  /// risk *is* the game. What the generator guarantees is that a way
  /// through exists, not that every path works.
  ///
  /// Returns null when the search ran past [nodeBudget] without deciding,
  /// so a caller can tell "too hard to verify" from "proven unsolvable"
  /// instead of shipping a board on the strength of a timeout.
  static bool? isSolvable(
    Set<TileSlot> remaining,
    Map<TileSlot, TileFace> faces, {
    int nodeBudget = 300000,
  }) {
    if (remaining.isEmpty) return true;
    return _Search(remaining, faces, nodeBudget).run();
  }
}

/// Bitmask clearing search.
///
/// The board is re-expressed as indices into a fixed slot list so a
/// position is two 62-bit words rather than a Set. That matters: the memo
/// sees hundreds of thousands of positions, and hashing a set of objects
/// (or a string built from one) per node is what makes the naive version
/// too slow to run over a whole bank.
class _Search {
  _Search(Set<TileSlot> remaining, Map<TileSlot, TileFace> faces, this._budget)
      : _slots = remaining.toList() {
    if (_slots.length > _wordBits * 2) {
      throw ArgumentError(
        'Boards above ${_wordBits * 2} tiles need a wider state word.',
      );
    }
    final indexOf = <TileSlot, int>{
      for (var i = 0; i < _slots.length; i++) _slots[i]: i,
    };

    for (var i = 0; i < _slots.length; i++) {
      final slot = _slots[i];
      _faceOf.add(faces[slot]!.id);
      _above.add(indexOf[TileSlot(
            layer: slot.layer + 1,
            row: slot.row,
            col: slot.col,
          )] ??
          -1);
      _left.add(indexOf[TileSlot(
            layer: slot.layer,
            row: slot.row,
            col: slot.col - 1,
          )] ??
          -1);
      _right.add(indexOf[TileSlot(
            layer: slot.layer,
            row: slot.row,
            col: slot.col + 1,
          )] ??
          -1);
    }
  }

  /// Bits per word. 62 keeps every mask comfortably positive.
  static const int _wordBits = 62;

  final List<TileSlot> _slots;
  final List<int> _faceOf = [];
  final List<int> _above = [];
  final List<int> _left = [];
  final List<int> _right = [];

  /// Visited positions, indexed by the low word so the pair of words is
  /// compared exactly. Folding both words into one integer key would be
  /// faster but not collision-free: together they carry more than 64 bits
  /// of state, and a collision here would silently prune a live branch and
  /// report a solvable board as unsolvable.
  final Map<int, Set<int>> _seen = <int, Set<int>>{};
  int _budget;
  bool _exhausted = false;

  bool? run() {
    var lo = 0;
    var hi = 0;
    for (var i = 0; i < _slots.length; i++) {
      if (i < _wordBits) {
        lo |= 1 << i;
      } else {
        hi |= 1 << (i - _wordBits);
      }
    }
    final result = _search(lo, hi, _slots.length);
    return _exhausted ? null : result;
  }

  bool _present(int lo, int hi, int index) {
    if (index < 0) return false;
    return index < _wordBits
        ? lo & (1 << index) != 0
        : hi & (1 << (index - _wordBits)) != 0;
  }

  bool _isFree(int lo, int hi, int index) {
    if (_present(lo, hi, _above[index])) return false;
    return !_present(lo, hi, _left[index]) || !_present(lo, hi, _right[index]);
  }

  bool? _search(int lo, int hi, int count) {
    if (count == 0) return true;
    if (_budget-- <= 0) {
      _exhausted = true;
      return null;
    }
    if (!(_seen[lo] ??= <int>{}).add(hi)) return false;

    final free = <int>[];
    for (var i = 0; i < _slots.length; i++) {
      if (!_present(lo, hi, i)) continue;
      if (_isFree(lo, hi, i)) free.add(i);
    }

    // How many tiles of each face are left, so forced moves can be spotted.
    final remainingPerFace = <int, int>{};
    for (var i = 0; i < _slots.length; i++) {
      if (!_present(lo, hi, i)) continue;
      remainingPerFace[_faceOf[i]] = (remainingPerFace[_faceOf[i]] ?? 0) + 1;
    }

    final moves = <(int, int)>[];
    for (var a = 0; a < free.length; a++) {
      for (var b = a + 1; b < free.length; b++) {
        if (_faceOf[free[a]] == _faceOf[free[b]]) moves.add((free[a], free[b]));
      }
    }
    if (moves.isEmpty) return false;

    // A face down to its last two tiles, both free, has exactly one way it
    // can ever be cleared — taking it now can never be the wrong choice.
    // Trying those first collapses most of the tree before any real
    // branching happens.
    moves.sort((a, b) {
      final aForced = remainingPerFace[_faceOf[a.$1]] == 2 ? 0 : 1;
      final bForced = remainingPerFace[_faceOf[b.$1]] == 2 ? 0 : 1;
      return aForced.compareTo(bForced);
    });

    for (final move in moves) {
      var nextLo = lo;
      var nextHi = hi;
      for (final index in [move.$1, move.$2]) {
        if (index < _wordBits) {
          nextLo &= ~(1 << index);
        } else {
          nextHi &= ~(1 << (index - _wordBits));
        }
      }
      final result = _search(nextLo, nextHi, count - 2);
      if (result == true) return true;
      if (result == null) return null;
    }
    return false;
  }
}
