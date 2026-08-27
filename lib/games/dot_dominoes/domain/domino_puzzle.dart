import 'domino_board.dart';

/// Where one domino sits: two adjacent cells and the pips on each.
class DominoPlacement {
  const DominoPlacement({
    required this.cellA,
    required this.cellB,
    required this.pipsA,
    required this.pipsB,
  });

  final int cellA;
  final int cellB;
  final int pipsA;
  final int pipsB;

  Domino get domino => Domino.of(pipsA, pipsB);

  factory DominoPlacement.fromJson(List<dynamic> json) => DominoPlacement(
        cellA: json[0] as int,
        cellB: json[1] as int,
        pipsA: json[2] as int,
        pipsB: json[3] as int,
      );

  List<int> toJson() => [cellA, cellB, pipsA, pipsB];
}

class DominoPuzzle {
  DominoPuzzle({
    required this.present,
    required this.regions,
    required this.tray,
    required this.solution,
  });

  /// Which of the [dominoCellCount] grid cells are part of this board.
  final List<bool> present;

  final List<DominoRegion> regions;

  /// The dominoes supplied, each to be used exactly once.
  final List<Domino> tray;

  /// One valid arrangement — and, because the generator only ships
  /// puzzles with a unique solution, the only one.
  final List<DominoPlacement> solution;

  List<int> get cells => [
        for (var i = 0; i < dominoCellCount; i++)
          if (present[i]) i,
      ];

  /// Cell to the region containing it.
  Map<int, int> get regionOfCell => {
        for (var r = 0; r < regions.length; r++)
          for (final cell in regions[r].cells) cell: r,
      };

  factory DominoPuzzle.fromJson(Map<String, dynamic> json) => DominoPuzzle(
        present: (json['present'] as String).split('').map((c) => c == '1').toList(),
        regions: (json['regions'] as List)
            .cast<Map<String, dynamic>>()
            .map(DominoRegion.fromJson)
            .toList(),
        tray: [
          for (final pair in (json['tray'] as List).cast<List<dynamic>>())
            Domino(pair[0] as int, pair[1] as int),
        ],
        solution: [
          for (final p in (json['solution'] as List).cast<List<dynamic>>())
            DominoPlacement.fromJson(p),
        ],
      );

  Map<String, dynamic> toJson() => {
        'present': present.map((p) => p ? '1' : '0').join(),
        'regions': regions.map((r) => r.toJson()).toList(),
        'tray': tray.map((d) => [d.low, d.high]).toList(),
        'solution': solution.map((p) => p.toJson()).toList(),
      };
}
