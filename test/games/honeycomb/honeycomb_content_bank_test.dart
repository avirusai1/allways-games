import 'package:flutter_test/flutter_test.dart';
import 'package:allways_games/games/honeycomb/domain/honeycomb_puzzle.dart';
import 'package:allways_games/games/honeycomb/generation/honeycomb_content_bank.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('puzzlesOfDifficulty partitions the real shipped bank by answer count',
      () async {
    final bank = await HoneycombContentBank.load();

    var total = 0;
    int? previousMaxAnswers;
    // Hard (fewest answers) first, Easy (most) last.
    for (final difficulty in [
      HoneycombDifficulty.hard,
      HoneycombDifficulty.medium,
      HoneycombDifficulty.easy,
    ]) {
      final pool = bank.puzzlesOfDifficulty(difficulty);
      expect(pool.length, greaterThan(100), reason: difficulty.name);

      final maxInTier =
          pool.map((p) => p.answers.length).reduce((a, b) => a > b ? a : b);
      final minInTier =
          pool.map((p) => p.answers.length).reduce((a, b) => a < b ? a : b);
      if (previousMaxAnswers != null) {
        expect(minInTier, greaterThanOrEqualTo(previousMaxAnswers));
      }
      previousMaxAnswers = maxInTier;
      total += pool.length;
    }

    expect(total, bank.puzzles.length);
  });
}
