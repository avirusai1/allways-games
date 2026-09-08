import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:allways_games/core/stats/free_play_stats.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('an untouched difficulty reports zero solved and no best time', () async {
    final prefs = await SharedPreferences.getInstance();
    final stats = FreePlayStats('sudoku', prefs);

    final tier = stats.forDifficulty('easy');
    expect(tier.solved, 0);
    expect(tier.bestSeconds, isNull);
  });

  test('recording a solve increments the count and sets the best time', () async {
    final prefs = await SharedPreferences.getInstance();
    final stats = FreePlayStats('sudoku', prefs);

    await stats.recordSolve('easy', 120);
    final tier = stats.forDifficulty('easy');
    expect(tier.solved, 1);
    expect(tier.bestSeconds, 120);
  });

  test('best time only improves, never regresses', () async {
    final prefs = await SharedPreferences.getInstance();
    final stats = FreePlayStats('sudoku', prefs);

    await stats.recordSolve('easy', 120);
    await stats.recordSolve('easy', 200); // slower — must not replace best
    final afterSlower = stats.forDifficulty('easy');
    expect(afterSlower.solved, 2);
    expect(afterSlower.bestSeconds, 120);

    await stats.recordSolve('easy', 90); // faster — must replace best
    final afterFaster = stats.forDifficulty('easy');
    expect(afterFaster.solved, 3);
    expect(afterFaster.bestSeconds, 90);
  });

  test('difficulties and games are tracked independently', () async {
    final prefs = await SharedPreferences.getInstance();
    final sudoku = FreePlayStats('sudoku', prefs);
    final dominoes = FreePlayStats('dot_dominoes', prefs);

    await sudoku.recordSolve('easy', 100);
    await sudoku.recordSolve('hard', 500);
    await dominoes.recordSolve('easy', 999); // same difficulty key, other game

    expect(sudoku.forDifficulty('easy').solved, 1);
    expect(sudoku.forDifficulty('easy').bestSeconds, 100);
    expect(sudoku.forDifficulty('hard').solved, 1);
    expect(sudoku.forDifficulty('hard').bestSeconds, 500);
    // The other game's "easy" must not see sudoku's solve, and vice versa.
    expect(dominoes.forDifficulty('easy').solved, 1);
    expect(dominoes.forDifficulty('easy').bestSeconds, 999);
  });
}
