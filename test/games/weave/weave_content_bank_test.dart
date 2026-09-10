import 'package:flutter_test/flutter_test.dart';
import 'package:allways_games/games/weave/domain/weave_puzzle.dart';
import 'package:allways_games/games/weave/generation/weave_content_bank.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('puzzlesOfDifficulty partitions the real shipped bank by bonus count',
      () async {
    final bank = await WeaveContentBank.load();

    var total = 0;
    int? previousMaxBonus;
    // Hard (fewest bonus words) first, Easy (most) last.
    for (final difficulty in [
      WeaveDifficulty.hard,
      WeaveDifficulty.medium,
      WeaveDifficulty.easy,
    ]) {
      final pool = bank.puzzlesOfDifficulty(difficulty);
      expect(pool.length, greaterThan(100), reason: difficulty.name);

      final maxInTier =
          pool.map((p) => p.bonusWords.length).reduce((a, b) => a > b ? a : b);
      final minInTier =
          pool.map((p) => p.bonusWords.length).reduce((a, b) => a < b ? a : b);
      if (previousMaxBonus != null) {
        expect(minInTier, greaterThanOrEqualTo(previousMaxBonus));
      }
      previousMaxBonus = maxInTier;
      total += pool.length;
    }

    expect(total, bank.puzzles.length);
  });
}
