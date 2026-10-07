/// Calculation and decision layers for KellyEdge. The screen imports these
/// functions so the tested code is the code the app runs.
///
/// Kelly Criterion: f* = W - (1 - W) / R
///   W = probability of a winning trade (0.0 to 1.0)
///   R = win/loss ratio (average win amount / average loss amount)
///   Returns the fraction of capital to stake (0.325 means 32.5%).
double calculateKellyFraction(double W, double R) {
  return W - (1 - W) / R;
}

/// Four-tier risk classification of a Kelly fraction (a fraction, not a percentage).
/// Labels start with the tier name; the screen colours them by that prefix.
String getRiskCategory(double fraction) {
  if (fraction <= 0) {
    return 'No Edge – Avoid Bet';
  } else if (fraction <= 0.10) {
    return 'Conservative – Small Bet';
  } else if (fraction <= 0.25) {
    return 'Moderate – Balanced Bet';
  } else {
    return 'Aggressive – High Bet';
  }
}

/// Suggested stake in currency units. No edge means no stake.
double calculateSuggestedStake(double fraction, double bankroll) {
  if (fraction <= 0) {
    return 0;
  }
  return fraction * bankroll;
}
