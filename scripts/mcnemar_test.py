#!/usr/bin/env python3
"""
McNemar's test on the paired label-correctness results from
backtest_results.csv (produced by weather_backtest.py).

Each row is one (city, date, target_year) estimate where BOTH the mean
estimate and the median estimate were evaluated against the same actual
outcome - so mean_label_correct and median_label_correct are paired
(matched) binary outcomes, which is exactly what McNemar's test is for:
it only looks at the pairs where the two methods disagreed, and asks
whether disagreements favor one method more than chance (50/50) would.

No stdlib scipy/statsmodels dependency - computes both:
  - the exact binomial form of McNemar's test (appropriate here, since
    the discordant count is well under the ~25 where the chi-square
    approximation is usually considered safe)
  - the continuity-corrected chi-square form, for reference/comparison
"""

import csv
import math
from pathlib import Path

CSV_PATH = Path(__file__).parent / "backtest_results.csv"


def mcnemar_exact_p(b, c):
    """Two-sided exact McNemar p-value: 2 * P(X <= min(b,c)) under
    X ~ Binomial(b+c, 0.5), capped at 1.0."""
    n = b + c
    if n == 0:
        return 1.0
    k = min(b, c)
    tail = sum(math.comb(n, i) for i in range(0, k + 1)) * (0.5 ** n)
    return min(1.0, 2 * tail)


def mcnemar_chi2_p(b, c):
    """Continuity-corrected chi-square McNemar p-value (1 dof)."""
    n = b + c
    if n == 0:
        return 1.0
    stat = ((abs(b - c) - 1) ** 2) / n
    # For 1 dof, chi2 = Z^2, so P(chi2 > x) = erfc(sqrt(x/2)).
    return math.erfc(math.sqrt(stat / 2))


def main():
    with open(CSV_PATH, newline="") as f:
        rows = list(csv.DictReader(f))

    n = len(rows)
    both_correct = both_wrong = mean_only = median_only = 0
    for r in rows:
        m = int(r["mean_label_correct"])
        d = int(r["median_label_correct"])
        if m == 1 and d == 1:
            both_correct += 1
        elif m == 0 and d == 0:
            both_wrong += 1
        elif m == 1 and d == 0:
            mean_only += 1
        else:
            median_only += 1

    print(f"n = {n} paired estimates\n")
    print("2x2 contingency table (rows=mean, cols=median):")
    print(f"{'':>18}{'median correct':>16}{'median wrong':>16}")
    print(f"{'mean correct':>18}{both_correct:>16}{mean_only:>16}")
    print(f"{'mean wrong':>18}{median_only:>16}{both_wrong:>16}")

    b, c = mean_only, median_only  # discordant pairs
    print(f"\nConcordant pairs (both right or both wrong): {both_correct + both_wrong}")
    print(f"Discordant pairs: {b + c}  "
          f"(mean right/median wrong: {b}, mean wrong/median right: {c})")

    if b + c == 0:
        print("\nNo discordant pairs - the two methods never disagreed on a label. "
              "McNemar's test is undefined (nothing to test).")
        return

    exact_p = mcnemar_exact_p(b, c)
    chi2_p = mcnemar_chi2_p(b, c)
    stat = ((abs(b - c) - 1) ** 2) / (b + c)

    print(f"\nMcNemar's test (two-sided):")
    print(f"  exact binomial p-value:              {exact_p:.4f}")
    print(f"  continuity-corrected chi2 statistic:  {stat:.3f}  (1 df)")
    print(f"  continuity-corrected chi2 p-value:    {chi2_p:.4f}")

    direction = "median" if c > b else ("mean" if b > c else "neither")
    print(f"\nOf the {b + c} disagreements, {'median' if c > b else 'mean'} won "
          f"{max(b, c)} to {min(b, c)}.")
    if exact_p < 0.05:
        print(f"That's a statistically significant difference (p < 0.05): "
              f"{direction} is the more reliable labeler on this sample.")
    else:
        print("That is NOT statistically significant at p < 0.05 - with this "
              "many discordant pairs, a split this lopsided is still "
              "plausible under pure chance.")


if __name__ == "__main__":
    main()
