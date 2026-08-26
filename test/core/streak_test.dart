import 'package:flutter_test/flutter_test.dart';
import 'package:allways_games/core/persistence/streak.dart';

void main() {
  group('StreakCalculator.current', () {
    test('counts consecutive days ending today', () {
      final won = {98, 99, 100};
      expect(StreakCalculator.current(won, 100), 3);
    });

    test('still counts a streak that ended yesterday', () {
      final won = {97, 98, 99};
      expect(StreakCalculator.current(won, 100), 3);
    });

    test('breaks on a gap', () {
      final won = {95, 98, 99, 100};
      expect(StreakCalculator.current(won, 100), 3);
    });

    test('zero when nothing won recently', () {
      expect(StreakCalculator.current({50}, 100), 0);
    });
  });

  group('StreakCalculator.longest', () {
    test('finds the longest run anywhere in history', () {
      final won = {1, 2, 3, 4, 10, 11, 20};
      expect(StreakCalculator.longest(won), 4);
    });

    test('empty set is zero', () {
      expect(StreakCalculator.longest({}), 0);
    });
  });
}
