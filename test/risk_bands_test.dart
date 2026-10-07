import 'package:flutter_test/flutter_test.dart';
import 'package:kellyedge/calculation_engine.dart';

void main() {
  group('Risk band boundaries (fractions)', () {
    test('zero and negative fractions mean no edge', () {
      expect(getRiskCategory(0), startsWith('No Edge'));
      expect(getRiskCategory(-0.01), startsWith('No Edge'));
    });

    test('exactly 10% is conservative; just above is moderate', () {
      expect(getRiskCategory(0.10), startsWith('Conservative'));
      expect(getRiskCategory(0.1000001), startsWith('Moderate'));
    });

    test('exactly 25% is moderate; just above is aggressive', () {
      expect(getRiskCategory(0.25), startsWith('Moderate'));
      expect(getRiskCategory(0.2500001), startsWith('Aggressive'));
    });
  });

  group('Kelly fraction extra cases', () {
    test('W=0.6, R=1 gives 0.2', () {
      expect(calculateKellyFraction(0.6, 1.0), closeTo(0.2, 1e-12));
    });

    test('a certain win stakes the whole bankroll', () {
      expect(calculateKellyFraction(1.0, 2.0), closeTo(1.0, 1e-12));
    });

    test('break-even win probability 1 / (1 + R) gives zero', () {
      for (final r in [0.5, 1.0, 2.0, 3.0, 10.0]) {
        expect(calculateKellyFraction(1 / (1 + r), r), closeTo(0.0, 1e-12));
      }
    });
  });

  group('Suggested stake', () {
    test('no edge means no stake', () {
      expect(calculateSuggestedStake(0.0, 1000), 0);
      expect(calculateSuggestedStake(-0.4, 1000), 0);
    });

    test('stake is fraction times bankroll', () {
      expect(calculateSuggestedStake(0.325, 1000), closeTo(325, 1e-9));
      expect(calculateSuggestedStake(0.1, 250), closeTo(25, 1e-9));
    });
  });
}
