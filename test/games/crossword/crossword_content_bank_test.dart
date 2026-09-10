import 'package:flutter_test/flutter_test.dart';
import 'package:allways_games/games/crossword/domain/crossword_puzzle.dart';
import 'package:allways_games/games/crossword/generation/crossword_content_bank.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('puzzlesOfDifficulty partitions the real shipped bank correctly',
      () async {
    final bank = await CrosswordContentBank.load();

    var total = 0;
    for (final difficulty in CrosswordDifficulty.values) {
      final pool = bank.puzzlesOfDifficulty(difficulty);
      // Free play depends on there being real choice within a tier, not
      // just one puzzle wearing a label.
      expect(pool.length, greaterThan(100), reason: difficulty.name);
      total += pool.length;
    }

    // The bank ships exactly two grid shapes (6 and 8 black squares), so
    // this really is a two-way split, not three artificial tiers.
    expect(total, bank.puzzles.length);
  });

  test('easy grids have more black squares than hard grids', () async {
    final bank = await CrosswordContentBank.load();
    final easy = bank.puzzlesOfDifficulty(CrosswordDifficulty.easy);
    final hard = bank.puzzlesOfDifficulty(CrosswordDifficulty.hard);

    final minEasyBlocked = easy
        .map((p) => p.blocked.where((b) => b).length)
        .reduce((a, b) => a < b ? a : b);
    final maxHardBlocked = hard
        .map((p) => p.blocked.where((b) => b).length)
        .reduce((a, b) => a > b ? a : b);

    expect(minEasyBlocked, greaterThan(maxHardBlocked));
  });
}
