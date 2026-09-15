/// Calculation Engine Layer for KellyEdge
/// Implements the Kelly Criterion formula: f* = W - (1 - W) / R
///
/// W = Probability of a winning trade (0.0 to 1.0)
/// R = Win/Loss Ratio (avg win amount / avg loss amount)
/// Returns: Optimal fraction of capital to risk (e.g. 0.325 = 32.5%)

double calculateKellyFraction(double W, double R) {
  return W - (1 - W) / R;
}

/// Helper function to classify risk banding for plain-language interpretation
String getRiskInterpretation(double percentage) {
  if (percentage <= 0) {
    return 'DO NOT INVEST / SKIP TRADE';
  } else if (percentage <= 10.0) {
    return 'Conservative Risk Allocation (<= 10%)';
  } else if (percentage <= 25.0) {
    return 'Moderate Risk Allocation (10% - 25%)';
  } else {
    return 'Aggressive Risk Allocation (> 25%)';
  }
}
