"""
Steply Mobility Data Preprocessing Script
Processes GPS stay-point data from Blogwatcher to generate pre-computed
analytics JSON for the Flutter app.

Usage:
    python3 scripts/precompute_mobility.py

Input:  Preproccessed2022-2023/*.csv (monthly stay-point CSVs)
Output: assets/data/mobility_computed.json
"""

import pandas as pd
import numpy as np
import json
from pathlib import Path
from collections import defaultdict

# Configuration
DATA_DIR = Path(__file__).parent.parent / "Preproccessed2022-2023"
OUTPUT_FILE = Path(__file__).parent.parent / "assets" / "data" / "mobility_computed.json"

# Nagoya area bounds
LAT_MIN, LAT_MAX = 35.05, 35.25
LNG_MIN, LNG_MAX = 136.80, 137.05

# Use 2022-2023 data (skip 2020)
YEARS = [2022, 2023]

# Sampling: with 210M rows, process a random subset for speed
MAX_ROWS_PER_FILE = 50000  # Sample to keep processing manageable


def load_all_data() -> pd.DataFrame:
    """Load monthly CSVs with sampling for large files."""
    dfs = []
    for year in YEARS:
        for month in range(1, 13):
            file = DATA_DIR / f"preprocessed{year}_{month:02d}.csv"
            if not file.exists():
                continue
            try:
                # Count rows first to determine if sampling needed
                with open(file, 'r') as f:
                    total_rows = sum(1 for _ in f) - 1  # minus header

                if total_rows > MAX_ROWS_PER_FILE:
                    # Random sampling
                    skip_ratio = 1.0 - (MAX_ROWS_PER_FILE / total_rows)
                    df = pd.read_csv(
                        file,
                        skiprows=lambda i: i > 0 and np.random.random() < skip_ratio,
                        nrows=MAX_ROWS_PER_FILE * 2,  # over-read then trim
                    )
                    df = df.head(MAX_ROWS_PER_FILE)
                else:
                    df = pd.read_csv(file)

                df['year'] = year
                df['month'] = month
                dfs.append(df)
                print(f"  Loaded {file.name}: {len(df)} records (of {total_rows})")
            except Exception as e:
                print(f"  Error loading {file.name}: {e}")

    if not dfs:
        raise RuntimeError("No CSV files found!")

    combined = pd.concat(dfs, ignore_index=True)

    # Parse timestamps
    combined['start_time'] = pd.to_datetime(combined['start_time'], errors='coerce')
    combined['hour'] = combined['start_time'].dt.hour

    day_map = {
        'Monday': 0, 'Tuesday': 1, 'Wednesday': 2, 'Thursday': 3,
        'Friday': 4, 'Saturday': 5, 'Sunday': 6
    }
    combined['day_num'] = combined['day_of_week'].map(day_map)

    # Filter to Nagoya bounds
    combined = combined[
        (combined['latitude'] >= LAT_MIN) & (combined['latitude'] <= LAT_MAX) &
        (combined['longitude'] >= LNG_MIN) & (combined['longitude'] <= LNG_MAX)
    ].dropna(subset=['hour', 'day_num'])

    print(f"\nTotal records after filtering: {len(combined)}")
    return combined


def compute_heatmap(df: pd.DataFrame, grid_size: float = 0.002) -> list:
    """Create density heatmap using grid cells (~200m)."""
    lat_bins = np.arange(LAT_MIN, LAT_MAX, grid_size)
    lng_bins = np.arange(LNG_MIN, LNG_MAX, grid_size)

    df = df.copy()
    df['lat_bin'] = pd.cut(df['latitude'], bins=lat_bins, labels=False)
    df['lng_bin'] = pd.cut(df['longitude'], bins=lng_bins, labels=False)

    grid = df.groupby(['lat_bin', 'lng_bin']).agg(
        total_dwell=('elapsed_time', 'sum'),
        visit_count=('latitude', 'count')
    ).reset_index()

    # Intensity = weighted combination of visits and dwell time
    grid['raw_intensity'] = grid['visit_count'] * 0.5 + grid['total_dwell'] * 0.001
    max_intensity = grid['raw_intensity'].max()
    if max_intensity > 0:
        grid['intensity'] = grid['raw_intensity'] / max_intensity
    else:
        grid['intensity'] = 0

    heatmap = []
    for _, row in grid.iterrows():
        if pd.notna(row['lat_bin']) and pd.notna(row['lng_bin']):
            lat = LAT_MIN + (row['lat_bin'] + 0.5) * grid_size
            lng = LNG_MIN + (row['lng_bin'] + 0.5) * grid_size
            if row['intensity'] > 0.05:  # filter noise
                heatmap.append({
                    'lat': round(lat, 6),
                    'lng': round(lng, 6),
                    'intensity': round(float(row['intensity']), 4)
                })

    return sorted(heatmap, key=lambda x: -x['intensity'])


def compute_popular_areas(df: pd.DataFrame, grid_size: float = 0.005) -> list:
    """Grid-based clustering to find popular areas."""
    df = df.copy()
    df['grid_lat'] = (df['latitude'] / grid_size).astype(int) * grid_size
    df['grid_lng'] = (df['longitude'] / grid_size).astype(int) * grid_size

    groups = df.groupby(['grid_lat', 'grid_lng'])

    areas = []
    for (glat, glng), group in groups:
        visit_count = len(group)
        if visit_count < 20:  # minimum threshold
            continue

        avg_dwell = float(group['elapsed_time'].mean())
        total_dwell = float(group['elapsed_time'].sum())

        # Peak day
        peak_day = group['day_of_week'].mode()
        peak_day = peak_day.iloc[0] if len(peak_day) > 0 else 'Unknown'

        # Peak hour
        peak_hour = group['hour'].mode()
        peak_hour = int(peak_hour.iloc[0]) if len(peak_hour) > 0 else 12

        areas.append({
            'id': f'area_{len(areas):03d}',
            'lat': round(float(glat + grid_size / 2), 6),
            'lng': round(float(glng + grid_size / 2), 6),
            'visitCount': int(visit_count),
            'avgDwellTime': round(avg_dwell, 1),
            'totalDwellHours': round(total_dwell / 60, 1),
            'peakDay': peak_day,
            'peakHour': peak_hour,
        })

    # Sort by visits, take top 50
    areas = sorted(areas, key=lambda x: -x['visitCount'])[:50]

    # Known Nagoya landmarks — label nearby areas
    landmarks = [
        ('Nagoya Castle', 35.1856, 136.8990),
        ('Oasis 21', 35.1709, 136.9084),
        ('Atsuta Shrine', 35.1283, 136.9087),
        ('Nagoya Station', 35.1709, 136.8815),
        ('Sakae District', 35.1681, 136.9089),
        ('Hisaya Odori Park', 35.1720, 136.9090),
        ('Nagoya TV Tower', 35.1745, 136.9088),
        ('Tokugawa Art Museum', 35.1869, 136.9347),
        ('Meitetsu Department Store', 35.1705, 136.8830),
        ('Nagoya Dome', 35.1861, 136.9473),
        ('Port of Nagoya', 35.0888, 136.8840),
    ]

    for area in areas:
        best_name = None
        best_dist = 0.01  # ~1km threshold
        for name, lat, lng in landmarks:
            dist = ((area['lat'] - lat) ** 2 + (area['lng'] - lng) ** 2) ** 0.5
            if dist < best_dist:
                best_dist = dist
                best_name = name
        area['name'] = best_name or f"Area near ({area['lat']:.3f}, {area['lng']:.3f})"

    return areas


def compute_temporal_analysis(df: pd.DataFrame) -> dict:
    """Compute hourly, daily, and 7x24 heatmap distributions."""
    # Hourly (24 values)
    hourly = df.groupby('hour').size()
    hourly = hourly.reindex(range(24), fill_value=0)
    hourly_sum = hourly.sum()
    hourly_norm = (hourly / hourly_sum).tolist() if hourly_sum > 0 else [0] * 24

    # Daily (7 values)
    daily = df.groupby('day_num').size()
    daily = daily.reindex(range(7), fill_value=0)
    daily_sum = daily.sum()
    daily_norm = (daily / daily_sum).tolist() if daily_sum > 0 else [0] * 7

    # 7x24 heatmap
    heatmap = df.groupby(['day_num', 'hour']).size().unstack(fill_value=0)
    heatmap = heatmap.reindex(index=range(7), columns=range(24), fill_value=0)
    heatmap_max = heatmap.values.max()
    heatmap_norm = (heatmap / heatmap_max).values.tolist() if heatmap_max > 0 else [[0]*24]*7

    # Peaks
    busiest_hour = int(hourly.idxmax()) if hourly_sum > 0 else 12
    quietest_hour = int(hourly.idxmin()) if hourly_sum > 0 else 4
    busiest_day = int(daily.idxmax()) if daily_sum > 0 else 5
    quietest_day = int(daily.idxmin()) if daily_sum > 0 else 1

    day_names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday',
                 'Friday', 'Saturday', 'Sunday']

    return {
        'hourly': [round(v, 4) for v in hourly_norm],
        'daily': [round(v, 4) for v in daily_norm],
        'heatmap': [[round(float(v), 4) for v in row] for row in heatmap_norm],
        'busiestHour': busiest_hour,
        'quietestHour': quietest_hour,
        'busiestDay': day_names[busiest_day],
        'quietestDay': day_names[quietest_day],
    }


def compute_monthly_trends(df: pd.DataFrame) -> list:
    """Compute monthly aggregates for trend analysis."""
    monthly = df.groupby(['year', 'month']).agg(
        visits=('latitude', 'count'),
        avg_dwell=('elapsed_time', 'mean'),
    ).reset_index()

    max_visits = monthly['visits'].max() if len(monthly) > 0 else 1

    return [{
        'year': int(row['year']),
        'month': int(row['month']),
        'visits': int(row['visits']),
        'avgDwell': round(float(row['avg_dwell']), 1),
        'mobilityIndex': round(float(row['visits'] / max_visits), 4),
    } for _, row in monthly.iterrows()]


def main():
    print("=" * 60)
    print("Steply Mobility Data Preprocessor")
    print("=" * 60)

    print(f"\nLoading data from {DATA_DIR}...")
    df = load_all_data()

    print("\nComputing heatmap...")
    heatmap = compute_heatmap(df)
    print(f"  Heatmap points: {len(heatmap)}")

    print("Computing popular areas...")
    areas = compute_popular_areas(df)
    print(f"  Popular areas: {len(areas)}")

    print("Computing temporal analysis...")
    temporal = compute_temporal_analysis(df)

    print("Computing monthly trends...")
    monthly = compute_monthly_trends(df)

    # Build output
    output = {
        'metadata': {
            'totalRecords': len(df),
            'years': YEARS,
            'sampledPerFile': MAX_ROWS_PER_FILE,
            'generatedAt': pd.Timestamp.now().isoformat(),
        },
        'heatmap': heatmap,
        'popularAreas': areas,
        'temporalAnalysis': temporal,
        'monthlyTrends': monthly,
    }

    # Write JSON
    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_FILE, 'w') as f:
        json.dump(output, f)

    file_size = OUTPUT_FILE.stat().st_size / 1024
    print(f"\nOutput: {OUTPUT_FILE}")
    print(f"Size: {file_size:.1f} KB")
    print("Done!")


if __name__ == '__main__':
    main()
