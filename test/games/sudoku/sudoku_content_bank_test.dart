import 'package:flutter_test/flutter_test.dart';
import 'package:allways_games/games/sudoku/domain/sudoku_board.dart';
import 'package:allways_games/games/sudoku/generation/sudoku_content_bank.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('puzzlesOfDifficulty partitions the real shipped bank correctly', () async {
    final bank = await SudokuContentBank.load();

    var total = 0;
    for (final difficulty in SudokuDifficulty.values) {
      final pool = bank.puzzlesOfDifficulty(difficulty);
      // Free play depends on there being real choice within a tier, not
      // just one puzzle wearing a label.
      expect(pool.length, greaterThan(100), reason: difficulty.name);
      expect(pool.every((p) => p.difficulty == difficulty), isTrue);
      total += pool.length;
    }

    // Every puzzle in the bank must land in exactly one tier.
    expect(total, bank.puzzles.length);
  });
}
