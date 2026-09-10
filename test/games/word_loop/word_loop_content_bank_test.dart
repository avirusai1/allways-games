import 'package:flutter_test/flutter_test.dart';
import 'package:allways_games/games/word_loop/domain/word_loop_puzzle.dart';
import 'package:allways_games/games/word_loop/generation/word_loop_content_bank.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('puzzlesOfDifficulty partitions the real shipped bank by word count',
      () async {
    final bank = await WordLoopContentBank.load();

    var total = 0;
    int? previousMaxWordCount;
    // Hard (fewest playable words) first, Easy (most) last: every puzzle
    // in a later tier must have at least as many playable words as every
    // puzzle in the tier before it, or the buckets aren't real bands.
    for (final difficulty in [
      WordLoopDifficulty.hard,
      WordLoopDifficulty.medium,
      WordLoopDifficulty.easy,
    ]) {
      final pool = bank.puzzlesOfDifficulty(difficulty);
      expect(pool.length, greaterThan(100), reason: difficulty.name);

      final maxInTier =
          pool.map((p) => p.playableWordCount).reduce((a, b) => a > b ? a : b);
      final minInTier =
          pool.map((p) => p.playableWordCount).reduce((a, b) => a < b ? a : b);
      if (previousMaxWordCount != null) {
        expect(minInTier, greaterThanOrEqualTo(previousMaxWordCount));
      }
      previousMaxWordCount = maxInTier;
      total += pool.length;
    }

    // Every puzzle in the bank must land in exactly one tier.
    expect(total, bank.puzzles.length);
  });
}
