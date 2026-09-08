import 'package:flutter_test/flutter_test.dart';
import 'package:allways_games/games/dot_dominoes/domain/domino_board.dart';
import 'package:allways_games/games/dot_dominoes/generation/domino_content_bank.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('puzzlesOfSize partitions the real shipped bank correctly', () async {
    final bank = await DominoContentBank.load();

    var total = 0;
    for (final size in dominoDifficultyTiers) {
      final pool = bank.puzzlesOfSize(size);
      // Free play depends on there being real choice within a tier, not
      // just one puzzle wearing a label.
      expect(pool.length, greaterThan(100), reason: 'size $size');
      expect(pool.every((p) => p.tray.length == size), isTrue);
      total += pool.length;
    }

    // Every puzzle in the bank must land in exactly one tier.
    expect(total, bank.puzzles.length);
  });

  test('dominoDifficultyLabel names every shipped tier', () {
    expect(dominoDifficultyLabel(3), 'Easy');
    expect(dominoDifficultyLabel(4), 'Medium');
    expect(dominoDifficultyLabel(5), 'Hard');
  });
}
