"""KellyLab: small, tested helpers for studying Kelly-criterion bet sizing.

Conventions (same as KellyEdge):
    p  win probability, 0 < p < 1
    b  net odds: a win pays b per 1 staked, a loss costs the 1 staked (b is KellyEdge's R)
    f  fraction of the CURRENT bankroll staked on each bet
All data in this project are simulated.
"""
import numpy as np


def kelly_fraction(p, b):
    """Full-Kelly stake fraction f* = p - (1 - p) / b. Negative means no edge."""
    return p - (1.0 - p) / b


def log_growth(f, p, b):
    """Expected log-growth of wealth per bet: g(f) = p ln(1 + b f) + (1 - p) ln(1 - f).

    Valid for 0 <= f < 1. Returns -inf when f >= 1 would risk the whole bankroll.
    """
    f = np.asarray(f, dtype=float)
    with np.errstate(divide="ignore", invalid="ignore"):
        g = p * np.log1p(b * f) + (1.0 - p) * np.log1p(-f)
    return np.where(f >= 1.0, -np.inf, g)


def gaussian_kelly(mu, var):
    """Continuous-time / small-return Kelly leverage f* = mu / var (excess return mean over variance)."""
    return mu / var


def simulate_paths(p, b, f, n_paths, n_bets, seed=0, w0=1.0):
    """Simulate bankroll paths with a fixed fraction f of current wealth staked each bet.

    Returns an array of shape (n_paths, n_bets + 1) of wealth including the start w0.
    Outcomes are independent across bets and across paths.
    """
    if not 0.0 <= f < 1.0:
        raise ValueError("f must satisfy 0 <= f < 1; f >= 1 can wipe out (or flip the sign of) wealth in one loss")
    rng = np.random.default_rng(seed)
    wins = rng.random((n_paths, n_bets)) < p
    step = np.where(wins, 1.0 + b * f, 1.0 - f)
    w = np.empty((n_paths, n_bets + 1))
    w[:, 0] = w0
    np.cumprod(step, axis=1, out=w[:, 1:])
    w[:, 1:] *= w0
    return w


def path_stats(w, ruin_level=0.01, drawdown=0.5):
    """Summaries of simulated wealth paths (start wealth is column 0).

    ruin: wealth ever falls below ruin_level x starting wealth.
    dd:   at some point wealth is at least `drawdown` below its running peak.
    """
    w0 = w[:, 0]
    final = w[:, -1]
    n_bets = w.shape[1] - 1
    peak = np.maximum.accumulate(w, axis=1)
    max_dd = (1.0 - w / peak).max(axis=1)
    with np.errstate(divide="ignore"):
        growth = np.log(final / w0) / n_bets
    return {
        "median_final": float(np.median(final / w0)),
        "mean_final": float(np.mean(final / w0)),
        "p05_final": float(np.percentile(final / w0, 5)),
        "p95_final": float(np.percentile(final / w0, 95)),
        "median_growth_per_bet": float(np.median(growth)),
        "prob_below_start": float(np.mean(final < w0)),
        "prob_drawdown": float(np.mean(max_dd >= drawdown)),
        "median_max_drawdown": float(np.median(max_dd)),
        "p90_max_drawdown": float(np.percentile(max_dd, 90)),
        "prob_ruin": float(np.mean((w < ruin_level * w0[:, None]).any(axis=1))),
    }


def estimated_fraction(p_hat, b, k=1.0, cap=0.99):
    """Stake fraction a trader would use after estimating win probability as p_hat.

    k scales full Kelly (k = 0.5 is half-Kelly). Negative edge means no bet. cap < 1 keeps log-growth finite.
    """
    f = k * kelly_fraction(np.asarray(p_hat, dtype=float), b)
    return np.clip(f, 0.0, cap)


def estimation_error_experiment(p_true, b, n_trades, k, n_draws=40000, seed=0):
    """Trader estimates p from n_trades past outcomes, then bets estimated Kelly times k.

    Returns the mean TRUE log-growth per bet, the share of the true optimum achieved,
    and the share of draws where the stake exceeds twice the true Kelly (negative true growth).
    """
    rng = np.random.default_rng(seed)
    p_hat = rng.binomial(n_trades, p_true, size=n_draws) / n_trades
    f = estimated_fraction(p_hat, b, k)
    g = log_growth(f, p_true, b)
    g_star = float(log_growth(kelly_fraction(p_true, b), p_true, b))
    return {
        "mean_growth": float(np.mean(g)),
        "share_of_optimum": float(np.mean(g) / g_star),
        "prob_overbet_2x": float(np.mean(f > 2.0 * kelly_fraction(p_true, b))),
    }


def shrinkage_fraction(p, b, n_trades):
    """Rule-of-thumb fraction of Kelly to bet when p is estimated from n_trades outcomes.

    Small-edge approximation: edge mu = p*b - (1-p) per unit staked; the estimate of mu has standard
    deviation s = (b + 1) * sqrt(p (1-p) / n). Maximising expected log-growth over k gives k = mu^2 / (mu^2 + s^2).
    Ignores the no-short clipping and the curvature of the exact growth curve, so treat it as a guide.
    """
    mu = p * b - (1.0 - p)
    s = (b + 1.0) * np.sqrt(p * (1.0 - p) / n_trades)
    return float(mu**2 / (mu**2 + s**2))


def breakeven_true_p(f, b, lo=0.0, hi=1.0, iters=80):
    """True win probability at which a fixed stake fraction f has zero expected log-growth (bisection)."""
    g = lambda p: float(log_growth(f, p, b))
    if g(hi) <= 0:
        return hi
    for _ in range(iters):
        mid = 0.5 * (lo + hi)
        if g(mid) > 0:
            hi = mid
        else:
            lo = mid
    return 0.5 * (lo + hi)
