import os, sys
import numpy as np
import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import kellylab as kl


def test_kelly_matches_kellyedge_cases():
    # Same four cases as KellyEdge's test/kelly_test.dart
    assert kl.kelly_fraction(0.55, 2.0) == pytest.approx(0.325)
    assert kl.kelly_fraction(0.40, 3.0) == pytest.approx(0.200)
    assert kl.kelly_fraction(0.50, 1.0) == pytest.approx(0.0)
    assert kl.kelly_fraction(0.30, 1.0) == pytest.approx(-0.400)


def test_growth_is_maximised_at_kelly():
    p, b = 0.55, 2.0
    f = kl.kelly_fraction(p, b)
    grid = np.linspace(0.0, 0.95, 1901)
    best = grid[np.argmax(kl.log_growth(grid, p, b))]
    assert best == pytest.approx(f, abs=1e-3)
    assert kl.log_growth(f, p, b) > kl.log_growth(f - 0.05, p, b)
    assert kl.log_growth(f, p, b) > kl.log_growth(f + 0.05, p, b)


def test_growth_at_zero_stake_is_zero_and_full_stake_is_minus_inf():
    assert kl.log_growth(0.0, 0.55, 2.0) == pytest.approx(0.0)
    assert np.isneginf(kl.log_growth(1.0, 0.55, 2.0))


def test_twice_kelly_has_roughly_zero_growth_for_small_edge():
    p, b = 0.505, 1.0              # tiny edge, f* = 0.01
    f = kl.kelly_fraction(p, b)
    assert kl.log_growth(2 * f, p, b) == pytest.approx(0.0, abs=2e-6)


def test_half_kelly_keeps_about_three_quarters_of_growth_for_small_edge():
    p, b = 0.505, 1.0
    f = kl.kelly_fraction(p, b)
    ratio = kl.log_growth(0.5 * f, p, b) / kl.log_growth(f, p, b)
    assert ratio == pytest.approx(0.75, abs=0.01)
    ratio_q = kl.log_growth(0.25 * f, p, b) / kl.log_growth(f, p, b)
    assert ratio_q == pytest.approx(0.4375, abs=0.01)


def test_gaussian_kelly():
    assert kl.gaussian_kelly(0.08, 0.04) == pytest.approx(2.0)


def test_simulation_shape_start_and_reproducibility():
    w1 = kl.simulate_paths(0.55, 2.0, 0.2, n_paths=50, n_bets=30, seed=7)
    w2 = kl.simulate_paths(0.55, 2.0, 0.2, n_paths=50, n_bets=30, seed=7)
    assert w1.shape == (50, 31)
    assert np.all(w1[:, 0] == 1.0)
    assert np.array_equal(w1, w2)
    assert np.all(w1 > 0)


def test_zero_stake_keeps_wealth_constant():
    w = kl.simulate_paths(0.55, 2.0, 0.0, n_paths=10, n_bets=20, seed=1)
    assert np.allclose(w, 1.0)


def test_stake_of_one_or_more_is_rejected():
    with pytest.raises(ValueError):
        kl.simulate_paths(0.55, 2.0, 1.0, 10, 10)


def test_simulated_median_growth_matches_theory():
    p, b = 0.55, 2.0
    f = kl.kelly_fraction(p, b)
    w = kl.simulate_paths(p, b, f, n_paths=20000, n_bets=400, seed=11)
    stats = kl.path_stats(w)
    assert stats["median_growth_per_bet"] == pytest.approx(float(kl.log_growth(f, p, b)), rel=0.03)


def test_risk_rises_with_stake_fraction():
    p, b = 0.55, 2.0
    f = kl.kelly_fraction(p, b)
    dd = []
    for k in (0.25, 0.5, 1.0, 1.8):
        w = kl.simulate_paths(p, b, k * f, 8000, 300, seed=5)
        dd.append(kl.path_stats(w)["prob_drawdown"])
    assert dd == sorted(dd)
    assert all(0.0 <= x <= 1.0 for x in dd)


def test_estimation_error_hurts_full_kelly_more_with_fewer_trades():
    few = kl.estimation_error_experiment(0.55, 2.0, n_trades=20, k=1.0, seed=3)
    many = kl.estimation_error_experiment(0.55, 2.0, n_trades=2000, k=1.0, seed=3)
    assert few["share_of_optimum"] < many["share_of_optimum"] <= 1.0001


def test_half_kelly_beats_full_when_edge_is_weak_and_estimate_is_noisy():
    full = kl.estimation_error_experiment(0.52, 1.0, n_trades=100, k=1.0, seed=3)
    half = kl.estimation_error_experiment(0.52, 1.0, n_trades=100, k=0.5, seed=3)
    assert half["prob_overbet_2x"] <= full["prob_overbet_2x"]
    assert half["share_of_optimum"] > full["share_of_optimum"]


def test_full_kelly_is_fine_when_edge_is_strong_and_data_plentiful():
    full = kl.estimation_error_experiment(0.55, 2.0, n_trades=2000, k=1.0, seed=3)
    half = kl.estimation_error_experiment(0.55, 2.0, n_trades=2000, k=0.5, seed=3)
    assert full["share_of_optimum"] > half["share_of_optimum"]


def test_shrinkage_fraction_rises_with_data_and_stays_in_unit_interval():
    ks = [kl.shrinkage_fraction(0.52, 1.0, n) for n in (10, 100, 1000, 10000)]
    assert ks == sorted(ks)
    assert all(0.0 < k < 1.0 for k in ks)


def test_shrinkage_fraction_tracks_simulated_best_fraction_for_strong_edge():
    grid = np.linspace(0.1, 1.2, 23)
    for n in (20, 50):
        shares = [kl.estimation_error_experiment(0.55, 2.0, n, k, n_draws=40000, seed=4)["share_of_optimum"] for k in grid]
        best = grid[int(np.argmax(shares))]
        assert best == pytest.approx(kl.shrinkage_fraction(0.55, 2.0, n), abs=0.15)


def test_breakeven_true_p_for_full_kelly_stake():
    p_assumed, b = 0.55, 2.0
    f = kl.kelly_fraction(p_assumed, b)
    be = kl.breakeven_true_p(f, b)
    assert 0.2 < be < p_assumed
    assert float(kl.log_growth(f, be, b)) == pytest.approx(0.0, abs=1e-9)
    assert float(kl.log_growth(f, be + 0.02, b)) > 0
    assert float(kl.log_growth(f, be - 0.02, b)) < 0


def test_median_worst_drawdown_rises_with_stake_and_is_a_share():
    p, b = 0.55, 2.0
    f = kl.kelly_fraction(p, b)
    med = [kl.path_stats(kl.simulate_paths(p, b, k * f, 6000, 300, seed=9))["median_max_drawdown"] for k in (0.25, 0.5, 1.0, 1.5)]
    assert med == sorted(med)
    assert all(0.0 < x < 1.0 for x in med)
