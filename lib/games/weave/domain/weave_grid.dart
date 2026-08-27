/// Grid geometry for Weave: a rectangle of letters through which theme
/// words are traced as unbroken paths.
///
/// Pure Dart, no Flutter imports, so the packing generator, the scanner and
/// the unit tests all share the geometry the app draws.
library;

const int weaveRows = 7;
const int weaveCols = 6;
const int weaveCellCount = weaveRows * weaveCols;

int weaveRowOf(int index) => index ~/ weaveCols;
int weaveColOf(int index) => index % weaveCols;
int weaveIndexAt(int row, int col) => row * weaveCols + col;

bool weaveInBounds(int row, int col) =>
    row >= 0 && row < weaveRows && col >= 0 && col < weaveCols;

/// The eight cells touching [index], including diagonals.
///
/// Weave paths bend in any direction, which is what separates it from a
/// plain word search — a word may double back around itself as long as it
/// never reuses a cell.
List<int> weaveNeighbours(int index) {
  final row = weaveRowOf(index);
  final col = weaveColOf(index);
  final out = <int>[];
  for (var dr = -1; dr <= 1; dr++) {
    for (var dc = -1; dc <= 1; dc++) {
      if (dr == 0 && dc == 0) continue;
      final r = row + dr;
      final c = col + dc;
      if (weaveInBounds(r, c)) out.add(weaveIndexAt(r, c));
    }
  }
  return out;
}

/// Precomputed neighbour lists — the packer and scanner walk these
/// millions of times per bank, so building them per call is wasteful.
final List<List<int>> weaveAdjacency = List.generate(
  weaveCellCount,
  weaveNeighbours,
  growable: false,
);

/// Whether [path] is a legal trace: every step adjacent, no cell reused.
bool isWeavePathConnected(List<int> path) {
  if (path.isEmpty) return false;
  final seen = <int>{};
  for (var i = 0; i < path.length; i++) {
    final cell = path[i];
    if (cell < 0 || cell >= weaveCellCount) return false;
    if (!seen.add(cell)) return false;
    if (i > 0 && !weaveAdjacency[path[i - 1]].contains(cell)) return false;
  }
  return true;
}

/// Whether [path] reaches both the top and bottom rows.
///
/// The theme word that does this is the puzzle's "spanner": it gives away
/// the theme, so it is worth more and is the one hint the player can earn.
bool spansGrid(List<int> path) {
  var touchesTop = false;
  var touchesBottom = false;
  for (final cell in path) {
    final row = weaveRowOf(cell);
    if (row == 0) touchesTop = true;
    if (row == weaveRows - 1) touchesBottom = true;
  }
  return touchesTop && touchesBottom;
}
