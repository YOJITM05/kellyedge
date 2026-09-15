import 'package:flutter_test/flutter_test.dart';
import 'package:kellyedge/calculation_engine.dart';

void main() {
  group('Kelly Criterion Business Logic Verification (50% Milestone)', () {
    test('Case 1: W=0.55, R=2.0 -> f* = 0.325 (32.50%)', () {
      final fStar = calculateKellyFraction(0.55, 2.0);
      expect(fStar, closeTo(0.325, 0.0001));
      expect(getRiskInterpretation(fStar * 100), contains('Aggressive'));
    });

    test('Case 2: W=0.40, R=3.0 -> f* = 0.200 (20.00%)', () {
      final fStar = calculateKellyFraction(0.40, 3.0);
      expect(fStar, closeTo(0.200, 0.0001));
      expect(getRiskInterpretation(fStar * 100), contains('Moderate'));
    });

    test('Case 3: W=0.50, R=1.0 -> f* = 0.000 (0.00% / No Edge)', () {
      final fStar = calculateKellyFraction(0.50, 1.0);
      expect(fStar, closeTo(0.0, 0.0001));
      expect(getRiskInterpretation(fStar * 100), contains('DO NOT INVEST'));
    });

    test('Case 4: W=0.30, R=1.0 -> f* = -0.400 (Negative Edge)', () {
      final fStar = calculateKellyFraction(0.30, 1.0);
      expect(fStar, closeTo(-0.400, 0.0001));
      expect(getRiskInterpretation(fStar * 100), contains('DO NOT INVEST'));
    });
  });
}
