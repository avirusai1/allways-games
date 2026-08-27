/// Board geometry and the constraint vocabulary for Dot Dominoes.
///
/// Pure Dart, no Flutter imports, so the generator, the solver and the
/// unit tests all share the rules the app draws.
///
/// The rules are this app's own design. A domino covers two adjacent
/// cells; every cell belongs to a region; each region states something
/// that must be true of the pips inside it. That is enough to make a
/// deduction puzzle without borrowing any specific published ruleset.
library;

const int dominoMaxPips = 6;
const int dominoBoardCols = 5;
const int dominoBoardRows = 5;
const int dominoCellCount = dominoBoardCols * dominoBoardRows;

int dominoRowOf(int index) => index ~/ dominoBoardCols;
int dominoColOf(int index) => index % dominoBoardCols;
int dominoIndexAt(int row, int col) => row * dominoBoardCols + col;

/// Orthogonal neighbours only: a domino is a straight two-cell tile.
List<int> dominoNeighbours(int index) {
  final row = dominoRowOf(index);
  final col = dominoColOf(index);
  return [
    if (row > 0) dominoIndexAt(row - 1, col),
    if (row < dominoBoardRows - 1) dominoIndexAt(row + 1, col),
    if (col > 0) dominoIndexAt(row, col - 1),
    if (col < dominoBoardCols - 1) dominoIndexAt(row, col + 1),
  ];
}

final List<List<int>> dominoAdjacency = List.generate(
  dominoCellCount,
  dominoNeighbours,
  growable: false,
);

/// What a region says about the pips inside it.
enum DominoRule {
  /// The pips add up to exactly the region's value.
  sum,

  /// Every pip in the region is the same.
  same,

  /// No two pips in the region are equal.
  allDifferent,

  /// Every pip is strictly less than the region's value.
  lessThan,

  /// Every pip is strictly greater than the region's value.
  greaterThan,
}

extension DominoRuleLabel on DominoRule {
  /// How the rule is written on the board.
  String badge(int value) => switch (this) {
        DominoRule.sum => '$value',
        DominoRule.same => '=',
        DominoRule.allDifferent => '≠',
        DominoRule.lessThan => '<$value',
        DominoRule.greaterThan => '>$value',
      };

  String describe(int value) => switch (this) {
        DominoRule.sum => 'adds up to $value',
        DominoRule.same => 'all the same',
        DominoRule.allDifferent => 'all different',
        DominoRule.lessThan => 'every pip under $value',
        DominoRule.greaterThan => 'every pip over $value',
      };
}

/// A group of cells and the rule they must satisfy together.
class DominoRegion {
  const DominoRegion({
    required this.cells,
    required this.rule,
    required this.value,
  });

  final List<int> cells;
  final DominoRule rule;

  /// Meaningless for [DominoRule.same] and [DominoRule.allDifferent].
  final int value;

  factory DominoRegion.fromJson(Map<String, dynamic> json) => DominoRegion(
        cells: (json['c'] as List).cast<int>(),
        rule: DominoRule.values[json['r'] as int],
        value: json['v'] as int,
      );

  Map<String, dynamic> toJson() => {
        'c': cells,
        'r': rule.index,
        'v': value,
      };

  /// Whether the pips placed so far can still satisfy this region.
  ///
  /// Called on every partial placement, so it has to judge an incomplete
  /// region: reject only what is already impossible, and demand the full
  /// condition only once every cell is filled. Checking solely on
  /// completion would explore far more of the tree.
  bool isSatisfiable(List<int?> pips) {
    final placed = <int>[];
    var filled = 0;
    for (final cell in cells) {
      final pip = pips[cell];
      if (pip == null) continue;
      placed.add(pip);
      filled++;
    }
    final complete = filled == cells.length;

    switch (rule) {
      case DominoRule.sum:
        final total = placed.fold<int>(0, (a, b) => a + b);
        if (total > value) return false;
        // The unfilled cells can each contribute at most the maximum.
        final headroom = (cells.length - filled) * dominoMaxPips;
        if (total + headroom < value) return false;
        return complete ? total == value : true;
      case DominoRule.same:
        return placed.every((p) => p == placed.first);
      case DominoRule.allDifferent:
        return placed.toSet().length == placed.length;
      case DominoRule.lessThan:
        return placed.every((p) => p < value);
      case DominoRule.greaterThan:
        return placed.every((p) => p > value);
    }
  }

  bool isSatisfiedBy(List<int> pips) =>
      isSatisfiable(pips.map<int?>((p) => p).toList());
}

/// One domino from the double-six set, written low pip first.
class Domino {
  const Domino(this.low, this.high);

  factory Domino.of(int a, int b) => a <= b ? Domino(a, b) : Domino(b, a);

  final int low;
  final int high;

  bool get isDouble => low == high;

  @override
  bool operator ==(Object other) =>
      other is Domino && other.low == low && other.high == high;

  @override
  int get hashCode => Object.hash(low, high);

  @override
  String toString() => '$low|$high';
}

/// The full double-six set, 28 tiles.
List<Domino> fullDominoSet() => [
      for (var low = 0; low <= dominoMaxPips; low++)
        for (var high = low; high <= dominoMaxPips; high++) Domino(low, high),
    ];
