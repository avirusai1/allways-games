import 'package:flutter_test/flutter_test.dart';
import 'package:allways_games/games/tile_match/domain/tile_layout.dart';
import 'package:allways_games/games/tile_match/generation/tile_match_content_bank.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('puzzlesOfLayout partitions the real shipped bank correctly', () async {
    final bank = await TileMatchContentBank.load();

    var total = 0;
    for (final layoutName in tileMatchDifficultyTiers) {
      final pool = bank.puzzlesOfLayout(layoutName);
      // Free play depends on there being real choice within a tier, not
      // just one puzzle wearing a label.
      expect(pool.length, greaterThan(100), reason: layoutName);
      expect(pool.every((p) => p.layout.name == layoutName), isTrue);
      total += pool.length;
    }

    expect(total, bank.puzzles.length);
  });

  test('tileMatchDifficultyLabel names every shipped tier', () {
    expect(tileMatchDifficultyLabel('Long Hall'), 'Easy');
    expect(tileMatchDifficultyLabel('Spire'), 'Medium');
    expect(tileMatchDifficultyLabel('Terrace'), 'Hard');
  });
}
