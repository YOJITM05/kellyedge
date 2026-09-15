# KellyEdge

A Kelly Criterion position-sizing calculator — Flutter/Dart mobile app that turns the
classic Kelly formula into a practical, risk-classified staking decision.

## What it does

Given a user's estimated win probability, payout ratio, and bankroll, KellyEdge computes
the optimal fraction to stake (f* = W − (1−W)/R) and converts it into a concrete
suggested stake through a 4-tier risk-classification layer, rather than just handing back
a raw number.

## Architecture

Three-layer design: UI → calculation engine → decision layer. The decision layer is what
makes this more than a formula calculator — it classifies the raw Kelly fraction into one
of 4 risk tiers before presenting a recommendation, and includes fail-fast input
validation.

## Testing

Covered by unit tests in `test/kelly_test.dart` across aggressive, moderate,
zero-edge (breakeven), and negative-edge scenarios — not just happy-path inputs.

## Stack

Flutter · Dart · Firebase Authentication

## Try it

[Add a screen-recording GIF or APK/TestFlight link here]
