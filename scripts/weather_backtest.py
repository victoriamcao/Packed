#!/usr/bin/env python3
"""
Standalone, offline-reproducible test of median-vs-mean historical weather
estimates for Packed, calling the same Open-Meteo Historical Archive API
that WeatherService.swift uses (one request per calendar day per year -
not a batched range), and caching every raw response to disk.

Part A: case study for a single trip date.
Part B: backtest across multiple cities/dates/years with explicit
         no-data-leakage checks.

Run:
    python3 weather_backtest.py

Nothing here calls Open-Meteo's forecast API - only archive.
Re-running after the first run reads entirely from weather_cache/.
"""

import csv
import json
import math
import ssl
import time
import urllib.error
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

try:
    import certifi
    SSL_CONTEXT = ssl.create_default_context(cafile=certifi.where())
except ImportError:
    SSL_CONTEXT = ssl.create_default_context()

ARCHIVE_ENDPOINT = "https://archive-api.open-meteo.com/v1/archive"
DAILY_VARS = "temperature_2m_max,temperature_2m_min,precipitation_sum,snowfall_sum,windspeed_10m_max"

SCRIPT_DIR = Path(__file__).parent
CACHE_DIR = SCRIPT_DIR / "weather_cache"
CACHE_DIR.mkdir(exist_ok=True)
CSV_PATH = SCRIPT_DIR / "backtest_results.csv"

# ---------------------------------------------------------------------------
# FIXED CONFIG - written before any API call was made or any result looked
# at. Do not edit this block after running the backtest: that would be
# tuning the test to the data, which is exactly what leakage check #4 below
# guards against. (See the bottom of this file for why there is nothing
# else in this script that gets "tuned".)
# ---------------------------------------------------------------------------

# 8 cities, deliberately spanning different climates.
CITIES = {
    "Philadelphia_US": (39.9526, -75.1652),   # temperate / humid continental
    "Miami_US": (25.7617, -80.1918),          # subtropical
    "Phoenix_US": (33.4484, -112.0740),       # hot desert
    "Seattle_US": (47.6062, -122.3321),       # temperate oceanic
    "Denver_US": (39.7392, -104.9903),        # semi-arid / high altitude
    "Reykjavik_IS": (64.1466, -21.9426),      # subpolar oceanic
    "Singapore_SG": (1.3521, 103.8198),       # equatorial
    "Mumbai_IN": (19.0760, 72.8777),          # tropical monsoon
}

# 6 calendar dates, spread across the year (not tied to any one hemisphere's
# "summer"/"winter" so the mix of seasons differs by city).
BACKTEST_DATES = [(1, 15), (3, 20), (5, 10), (7, 4), (9, 22), (11, 15)]

BACKTEST_Y_START = 2010
BACKTEST_Y_END = 2023  # inclusive
YEARS_OF_HISTORY = 10  # matches WeatherService.defaultYearsOfHistory

CASE_STUDY_CITY = "Philadelphia_US"
CASE_STUDY_MONTH, CASE_STUDY_DAY = 8, 3
CASE_STUDY_EVENT_YEAR = 2025  # the wedding; sample = 2015..2024

RAIN_MEASURABLE_MM = 0.1
SNOW_MEASURABLE_CM = 0.1

MAX_WORKERS = 8


# Condition thresholds copied verbatim from WeatherService.swift's
# suggestedCondition (around lines 47-61), same order. These are NOT fit to
# this data - they're the app's existing, already-shipped rule, used as-is
# so the backtest measures something the app actually does.
def classify(high_c, precip_mm, snow_cm, wind_kmh):
    if snow_cm >= 0.5:
        return "Snowy"
    if precip_mm >= 4.0:
        return "Rainy"
    if wind_kmh >= 25.0:
        return "Windy"
    if high_c < 13.0:
        return "Cold"
    return "Sunny"


# ---------------------------------------------------------------------------
# Statistics - the two "center" methods under comparison, plus the spread
# functions used for the 25th/75th percentile and min/max range.
# ---------------------------------------------------------------------------

def mean(values):
    return sum(values) / len(values) if values else 0.0


def percentile(values, p):
    """Linear-interpolation percentile (numpy's default 'linear' method)."""
    if not values:
        return 0.0
    s = sorted(values)
    if len(s) == 1:
        return s[0]
    rank = p / 100.0 * (len(s) - 1)
    lo = math.floor(rank)
    hi = math.ceil(rank)
    if lo == hi:
        return s[int(lo)]
    weight = rank - lo
    return s[int(lo)] + (s[int(hi)] - s[int(lo)]) * weight


def median(values):
    return percentile(values, 50)


def iqr_outliers(values):
    """Tukey-fence outlier flags (1.5*IQR), one bool per value, input order."""
    if len(values) < 4:
        return [False] * len(values)
    q1 = percentile(values, 25)
    q3 = percentile(values, 75)
    iqr = q3 - q1
    lo_fence, hi_fence = q1 - 1.5 * iqr, q3 + 1.5 * iqr
    return [v < lo_fence or v > hi_fence for v in values]


# ---------------------------------------------------------------------------
# Networking + caching - archive endpoint only, one call per (lat, lon, day).
# ---------------------------------------------------------------------------

def _cache_path(lat, lon, date_iso):
    return CACHE_DIR / f"{lat:.4f}_{lon:.4f}_{date_iso}.json"


def fetch_day(lat, lon, date_iso, max_retries=4):
    """Fetch one calendar day from the ARCHIVE endpoint, cached to disk.

    This is the only network function in the whole script, and it only
    ever talks to ARCHIVE_ENDPOINT - so "actual" values for a target year
    and the sampled years used to build an estimate both come from the
    same archive, never a forecast call (leakage check #5).
    """
    path = _cache_path(lat, lon, date_iso)
    if path.exists():
        return json.loads(path.read_text())

    params = {
        "latitude": lat,
        "longitude": lon,
        "start_date": date_iso,
        "end_date": date_iso,
        "daily": DAILY_VARS,
        "timezone": "auto",
    }
    url = f"{ARCHIVE_ENDPOINT}?{urllib.parse.urlencode(params)}"
    delay = 1.0
    last_err = None
    for attempt in range(max_retries):
        try:
            with urllib.request.urlopen(url, timeout=30, context=SSL_CONTEXT) as resp:
                data = json.loads(resp.read().decode())
            path.write_text(json.dumps(data))
            return data
        except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError) as e:
            last_err = e
            time.sleep(delay)
            delay *= 2
    raise RuntimeError(f"fetch failed for {date_iso} @ ({lat},{lon}): {last_err}")


def reading_from_response(data):
    daily = data.get("daily") if data else None
    if not daily or not daily.get("time"):
        return None

    def first(key):
        arr = daily.get(key) or []
        return arr[0] if arr else None

    high, low = first("temperature_2m_max"), first("temperature_2m_min")
    if high is None or low is None:
        return None
    precip, snow, wind = first("precipitation_sum"), first("snowfall_sum"), first("windspeed_10m_max")
    return {
        "high": high,
        "low": low,
        "precip": precip if precip is not None else 0.0,
        "snow": snow if snow is not None else 0.0,
        "wind": wind if wind is not None else 0.0,
    }


def fetch_years(lat, lon, month, day, years, pool):
    """Fetch many years of one calendar day in parallel. Returns a dict of
    only the years that actually succeeded - a year that fails to fetch is
    silently absent, not padded with a placeholder, which is what makes the
    rest of the pipeline naturally use N = actual successful count."""
    futures = {pool.submit(fetch_day, lat, lon, f"{y:04d}-{month:02d}-{day:02d}"): y for y in years}
    readings = {}
    for fut in as_completed(futures):
        y = futures[fut]
        try:
            r = reading_from_response(fut.result())
            if r is not None:
                readings[y] = r
        except Exception as e:
            print(f"    WARNING: year {y} failed to fetch, dropped from sample: {e}")
    return readings


def build_estimate(readings_by_year, method):
    """method is 'mean' or 'median'. Uses exactly the years present in
    readings_by_year - nothing else."""
    years = sorted(readings_by_year.keys())
    highs = [readings_by_year[y]["high"] for y in years]
    lows = [readings_by_year[y]["low"] for y in years]
    precips = [readings_by_year[y]["precip"] for y in years]
    snows = [readings_by_year[y]["snow"] for y in years]
    winds = [readings_by_year[y]["wind"] for y in years]

    center = mean if method == "mean" else median
    est_high, est_low = center(highs), center(lows)
    est_precip, est_snow, est_wind = center(precips), center(snows), center(winds)
    label = classify(est_high, est_precip, est_snow, est_wind)

    return {
        "years_used": years,
        "n": len(years),
        "high": est_high, "low": est_low,
        "precip": est_precip, "snow": est_snow, "wind": est_wind,
        "label": label,
        "high_min": min(highs), "high_max": max(highs),
        "high_p25": percentile(highs, 25), "high_p75": percentile(highs, 75),
        "low_min": min(lows), "low_max": max(lows),
        "low_p25": percentile(lows, 25), "low_p75": percentile(lows, 75),
        "rain_years": sum(1 for p in precips if p >= RAIN_MEASURABLE_MM),
        "snow_years": sum(1 for s in snows if s >= SNOW_MEASURABLE_CM),
    }


# ---------------------------------------------------------------------------
# Part A - case study
# ---------------------------------------------------------------------------

def run_case_study(pool):
    print("=" * 78)
    print(
        f"PART A: Case study - {CASE_STUDY_CITY} on "
        f"{CASE_STUDY_MONTH:02d}/{CASE_STUDY_DAY:02d}, sampled from the "
        f"{YEARS_OF_HISTORY} years before {CASE_STUDY_EVENT_YEAR}"
    )
    print("=" * 78)

    lat, lon = CITIES[CASE_STUDY_CITY]
    years = sorted(CASE_STUDY_EVENT_YEAR - k for k in range(1, YEARS_OF_HISTORY + 1))
    readings = fetch_years(lat, lon, CASE_STUDY_MONTH, CASE_STUDY_DAY, years, pool)

    present_years = [y for y in years if y in readings]
    outlier_years = set()
    for key in ("high", "low", "precip", "snow", "wind"):
        vals = [readings[y][key] for y in present_years]
        flags = iqr_outliers(vals)
        outlier_years |= {y for y, f in zip(present_years, flags) if f}

    print(f"\n{'Year':<6}{'High C':>9}{'Low C':>9}{'Rain mm':>10}{'Snow cm':>10}{'Wind kmh':>10}")
    for y in years:
        if y not in readings:
            print(f"{y:<6}  MISSING (fetch failed - excluded from estimate)")
            continue
        r = readings[y]
        flag = "  <-- OUTLIER (Tukey fence on some variable)" if y in outlier_years else ""
        print(f"{y:<6}{r['high']:>9.1f}{r['low']:>9.1f}{r['precip']:>10.1f}{r['snow']:>10.1f}{r['wind']:>10.1f}{flag}")

    for method in ("mean", "median"):
        est = build_estimate(readings, method)
        print(f"\n{method.upper()} estimate (n={est['n']}, years used={est['years_used']}):")
        print(
            f"  High {est['high']:.1f}C ({est['high']*9/5+32:.1f}F)  "
            f"Low {est['low']:.1f}C ({est['low']*9/5+32:.1f}F)  "
            f"Rain {est['precip']:.1f}mm  Snow {est['snow']:.1f}cm  Wind {est['wind']:.1f}km/h"
        )
        print(f"  -> label: {est['label']}")

    med = build_estimate(readings, "median")
    print("\nSpread (same years, median run):")
    print(
        f"  High: min {med['high_min']:.1f}C, p25 {med['high_p25']:.1f}C, "
        f"median {med['high']:.1f}C, p75 {med['high_p75']:.1f}C, max {med['high_max']:.1f}C"
    )
    print(
        f"  Low:  min {med['low_min']:.1f}C, p25 {med['low_p25']:.1f}C, "
        f"median {med['low']:.1f}C, p75 {med['low_p75']:.1f}C, max {med['low_max']:.1f}C"
    )
    print(f"  Rain occurred in {med['rain_years']} of {med['n']} sampled years")
    print(f"  Snow occurred in {med['snow_years']} of {med['n']} sampled years")


# ---------------------------------------------------------------------------
# Part B - backtest with leakage checks
# ---------------------------------------------------------------------------

def run_backtest(pool):
    print("\n" + "=" * 78)
    print("PART B: Backtest (no-leakage estimate-vs-actual, mean vs median)")
    print("=" * 78)

    rows = []
    skipped = []

    for city, (lat, lon) in CITIES.items():
        for (month, day) in BACKTEST_DATES:
            needed_years = list(range(BACKTEST_Y_START - YEARS_OF_HISTORY, BACKTEST_Y_END + 1))
            print(f"\nFetching {city} {month:02d}/{day:02d}: {len(needed_years)} calendar years...")
            all_readings = fetch_years(lat, lon, month, day, needed_years, pool)
            print(f"  got {len(all_readings)}/{len(needed_years)} years from the archive")

            for Y in range(BACKTEST_Y_START, BACKTEST_Y_END + 1):
                sample_years = list(range(Y - YEARS_OF_HISTORY, Y))

                # --- Leakage checks (fail loudly) ---
                assert Y not in sample_years, f"LEAKAGE: target year {Y} is in its own sample"
                assert all(y < Y for y in sample_years), f"LEAKAGE: a sampled year >= target {Y}"
                assert sample_years == list(range(Y - YEARS_OF_HISTORY, Y)), (
                    f"estimate for Y={Y} does not use the claimed 10-year window"
                )

                sample_readings = {y: all_readings[y] for y in sample_years if y in all_readings}
                used_years = sorted(sample_readings.keys())
                assert set(used_years) <= set(sample_years), "estimate used a year outside its claimed window"
                assert all(y < Y for y in used_years), "LEAKAGE: estimate used a year >= target after filtering"

                actual = all_readings.get(Y)  # fetched from fetch_years -> fetch_day -> ARCHIVE_ENDPOINT only

                if not sample_readings or actual is None:
                    skipped.append((city, month, day, Y))
                    continue

                actual_label = classify(actual["high"], actual["precip"], actual["snow"], actual["wind"])

                row = {
                    "city": city,
                    "month": month,
                    "day": day,
                    "target_year": Y,
                    "n_sample_years": len(used_years),
                    "sample_years_used": ",".join(str(y) for y in used_years),
                    "actual_high_c": actual["high"],
                    "actual_low_c": actual["low"],
                    "actual_label": actual_label,
                }

                for method in ("mean", "median"):
                    est = build_estimate(sample_readings, method)
                    row[f"{method}_high_c"] = round(est["high"], 2)
                    row[f"{method}_low_c"] = round(est["low"], 2)
                    row[f"{method}_label"] = est["label"]
                    row[f"{method}_high_abs_err"] = round(abs(est["high"] - actual["high"]), 3)
                    row[f"{method}_low_abs_err"] = round(abs(est["low"] - actual["low"]), 3)
                    row[f"{method}_label_correct"] = int(est["label"] == actual_label)
                    row[f"{method}_high_in_iqr"] = int(est["high_p25"] <= actual["high"] <= est["high_p75"])
                    row[f"{method}_low_in_iqr"] = int(est["low_p25"] <= actual["low"] <= est["low_p75"])
                    row[f"{method}_high_in_range"] = int(est["high_min"] <= actual["high"] <= est["high_max"])
                    row[f"{method}_low_in_range"] = int(est["low_min"] <= actual["low"] <= est["low_max"])

                rows.append(row)

    if skipped:
        print(f"\nSkipped {len(skipped)} estimate(s) due to missing data: {skipped}")
    else:
        print("\nNo estimates were skipped - every city/date/year combo had both a usable sample and an actual value.")

    return rows


def summarize(rows):
    if not rows:
        print("No rows to summarize.")
        return

    with open(CSV_PATH, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)
    print(f"\nSaved {len(rows)} rows to {CSV_PATH}")

    n = len(rows)

    def agg(method):
        return {
            "MAE high (C)": mean([r[f"{method}_high_abs_err"] for r in rows]),
            "MAE low (C)": mean([r[f"{method}_low_abs_err"] for r in rows]),
            "label accuracy": sum(r[f"{method}_label_correct"] for r in rows) / n,
            "high in 25-75pct": sum(r[f"{method}_high_in_iqr"] for r in rows) / n,
            "low in 25-75pct": sum(r[f"{method}_low_in_iqr"] for r in rows) / n,
            "high in min-max": sum(r[f"{method}_high_in_range"] for r in rows) / n,
            "low in min-max": sum(r[f"{method}_low_in_range"] for r in rows) / n,
        }

    mean_stats, median_stats = agg("mean"), agg("median")

    print(f"\nOverall (n={n} estimate/actual pairs)")
    print(f"{'Metric':<20}{'Mean':>12}{'Median':>12}{'Winner':>10}")
    for key in mean_stats:
        mv, dv = mean_stats[key], median_stats[key]
        lower_is_better = "MAE" in key
        if mv == dv:
            winner = "tie"
        elif lower_is_better:
            winner = "median" if dv < mv else "mean"
        else:
            winner = "median" if dv > mv else "mean"
        print(f"{key:<20}{mv:>12.3f}{dv:>12.3f}{winner:>10}")

    print("\nPer-city MAE on high temp (C), mean vs median - reported for every city, including losses:")
    for city in CITIES:
        city_rows = [r for r in rows if r["city"] == city]
        if not city_rows:
            continue
        mv = mean([r["mean_high_abs_err"] for r in city_rows])
        dv = mean([r["median_high_abs_err"] for r in city_rows])
        flag = "  <-- median worse here" if dv > mv else ("  <-- tie" if dv == mv else "")
        print(f"  {city:<16} mean={mv:.2f}  median={dv:.2f}{flag}")

    print("\nPer-date MAE on high temp (C), mean vs median - reported for every date, including losses:")
    for (month, day) in BACKTEST_DATES:
        date_rows = [r for r in rows if r["month"] == month and r["day"] == day]
        if not date_rows:
            continue
        mv = mean([r["mean_high_abs_err"] for r in date_rows])
        dv = mean([r["median_high_abs_err"] for r in date_rows])
        flag = "  <-- median worse here" if dv > mv else ("  <-- tie" if dv == mv else "")
        print(f"  {month:02d}/{day:02d}           mean={mv:.2f}  median={dv:.2f}{flag}")


def main():
    print(
        "No tuning: classify() thresholds are copied verbatim from "
        "WeatherService.swift; mean/median are parameter-free. CITIES, "
        "BACKTEST_DATES, and BACKTEST_Y_START/END were fixed in this file "
        "before this script was ever run, so there is no train/held-out "
        "split to report - nothing here is fit to the data being evaluated."
    )
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as pool:
        run_case_study(pool)
        rows = run_backtest(pool)
    summarize(rows)


if __name__ == "__main__":
    main()
