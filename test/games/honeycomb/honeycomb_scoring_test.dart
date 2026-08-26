import 'package:allways_games/games/honeycomb/domain/honeycomb_scoring.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('honeycombScoreFor', () {
    test('the shortest allowed word is worth one point', () {
      expect(honeycombScoreFor('ABCD', isPangram: false), 1);
      expect(honeycombMinWordLength, 4);
    });

    test('longer words score their length', () {
      expect(honeycombScoreFor('ABCDE', isPangram: false), 5);
      expect(honeycombScoreFor('ABCDEFGHI', isPangram: false), 9);
    });

    test('a pangram takes its length plus the bonus', () {
      expect(
        honeycombScoreFor('ABCDEFG', isPangram: true),
        7 + honeycombPangramBonus,
      );
      // Even a four-letter word, if it somehow were a pangram, keeps the
      // one-point base rather than jumping to four.
      expect(
        honeycombScoreFor('ABCD', isPangram: true),
        1 + honeycombPangramBonus,
      );
    });

    test('a word under the minimum scores nothing', () {
      expect(honeycombScoreFor('ABC', isPangram: false), 0);
      expect(honeycombScoreFor('', isPangram: true), 0);
    });

    test('reaching for length always beats piling up short words', () {
      // Two four-letter words score 2; one eight-letter word scores 8.
      final short = 2 * honeycombScoreFor('ABCD', isPangram: false);
      final long = honeycombScoreFor('ABCDEFGH', isPangram: false);
      expect(long, greaterThan(short));
    });
  });

  group('rank ladder', () {
    test('runs from zero to a hundred percent without gaps', () {
      expect(honeycombRanks.first.percentOfMax, 0);
      expect(honeycombRanks.last.percentOfMax, 100);
      for (var i = 1; i < honeycombRanks.length; i++) {
        expect(
          honeycombRanks[i].percentOfMax,
          greaterThan(honeycombRanks[i - 1].percentOfMax),
          reason: 'ranks must strictly increase',
        );
      }
    });

    test('rank names are distinct', () {
      final names = honeycombRanks.map((r) => r.name).toSet();
      expect(names, hasLength(honeycombRanks.length));
    });

    test('a fresh board sits at the bottom rung', () {
      expect(honeycombRankFor(0, 100).name, honeycombRanks.first.name);
    });

    test('a perfect board reaches the top rung', () {
      expect(honeycombRankFor(100, 100).name, honeycombRanks.last.name);
      expect(honeycombRankFor(240, 240).name, honeycombRanks.last.name);
    });

    test('rank climbs monotonically with score', () {
      var lastPercent = -1;
      for (var score = 0; score <= 200; score++) {
        final rank = honeycombRankFor(score, 200);
        expect(rank.percentOfMax, greaterThanOrEqualTo(lastPercent));
        lastPercent = rank.percentOfMax;
      }
    });

    test('an empty board does not divide by zero', () {
      expect(honeycombRankFor(0, 0).name, honeycombRanks.first.name);
      expect(honeycombRankFor(5, 0).name, honeycombRanks.first.name);
    });

    test('the score shown for a rank actually earns that rank', () {
      // Rounding down here would show a target one point short of the rank,
      // which reads as a bug to anyone who hits it exactly.
      for (final maxScore in [37, 100, 146, 289]) {
        for (final rank in honeycombRanks) {
          final target = honeycombScoreForRank(rank, maxScore);
          expect(
            honeycombRankFor(target, maxScore).percentOfMax,
            greaterThanOrEqualTo(rank.percentOfMax),
            reason: 'scoring $target on a $maxScore board should reach '
                '${rank.name}',
          );
        }
      }
    });

    test('the top rank needs every single point', () {
      const maxScore = 146;
      final top = honeycombRanks.last;
      expect(honeycombScoreForRank(top, maxScore), maxScore);
      expect(honeycombRankFor(maxScore - 1, maxScore).name, isNot(top.name));
    });
  });
}
