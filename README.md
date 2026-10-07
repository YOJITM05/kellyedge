# KellyEdge

A Kelly Criterion position-sizing calculator. It is a Flutter/Dart app that turns the classic Kelly formula into a risk-classified staking decision.

## What it does

Given an estimated win probability, a win/loss ratio and a bankroll, KellyEdge computes the optimal fraction to stake, `f* = W - (1 - W) / R`, and converts it into a concrete suggested stake. A four-tier risk classification sits between the raw number and the recommendation: do not invest (no edge), conservative (up to 10%), moderate (10% to 25%) and aggressive (above 25%). Inputs are validated before any calculation (valid numbers, 0 < W < 1, R > 0, bankroll > 0).

## Architecture

Three layers. The UI is `lib/kelly_home_page.dart`. The calculation engine and the decision layer are in `lib/calculation_engine.dart`: the Kelly formula, the four risk bands and the suggested-stake rule. The screen imports these functions, so the code the tests exercise is the code the app runs. Firebase Authentication handles sign-in.

## Tests

```
flutter test
```

12 tests in total.

- `test/kelly_test.dart`: four cases (aggressive, moderate, zero edge, negative edge).
- `test/risk_bands_test.dart`: the exact band boundaries at 10% and 25%, extra formula cases (certain win, break-even probability) and the suggested-stake rule.

## KellyLab: the research behind the formula

The calculator gives you a number. [`kellylab/`](kellylab/) asks the harder questions on simulated data: where the formula comes from, how risky it is, and what happens when your estimate of the odds is wrong.

- Derivation of `f*` and the growth curve.
- 10,000 simulated bankrolls at full, half and quarter Kelly: growth, worst drawdown and ruin.
- Estimation error: with a weak edge, betting the full estimated Kelly after 100 trades loses money in the long run, and the best fraction is about 0.3 of Kelly.
- Model risk and the continuous version `f* = mu / sigma^2`.

Read [`kellylab/README.md`](kellylab/README.md) or open the notebook `kellylab/KellyLab.ipynb`. Tests: `cd kellylab && python -m pytest`.

## Limits

The app uses the simple binary-bet formula. It assumes you know the win probability and the win/loss ratio exactly, that bets are independent, and that there are no costs. KellyLab shows why those assumptions matter. It is a learning project, not trading advice.

## Stack

Flutter, Dart, Firebase Authentication. KellyLab: Python, NumPy, Matplotlib.

## Run the app

```
flutter pub get
flutter run
```
