import 'package:flutter_test/flutter_test.dart';
import 'package:allways_games/games/five/generation/five_content_bank.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('puzzlesOfDifficulty partitions the real shipped bank correctly',
      () async {
    final bank = await FiveContentBank.load();

    var total = 0;
    for (final difficulty in FiveDifficulty.values) {
      final pool = bank.puzzlesOfDifficulty(difficulty);
      // Free play depends on there being real choice within a tier, not
      // just one puzzle wearing a label.
      expect(pool.length, greaterThan(100), reason: difficulty.name);
      total += pool.length;
    }

    // Every answer in the bank must land in exactly one tier.
    expect(total, bank.puzzles.length);
  });

  test('every tier answer is a valid guess too', () async {
    // The difficulty split only reorders the answers list — it must never
    // drop a word or let one sneak in that the guess validator wouldn't
    // otherwise accept.
    final bank = await FiveContentBank.load();
    for (final difficulty in FiveDifficulty.values) {
      for (final answer in bank.puzzlesOfDifficulty(difficulty)) {
        expect(bank.isValidGuess(answer), isTrue, reason: answer);
      }
    }
  });
}
