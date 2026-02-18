import 'dart:math';

import 'package:steply/features/analysis/data/datasources/mobility_local_datasource.dart';
import 'package:steply/features/analysis/domain/entities/comfort_index.dart';
import 'package:steply/features/analysis/domain/entities/local_temporal_analysis.dart';
import 'package:steply/features/analysis/domain/entities/mobility_data_point.dart';
import 'package:steply/features/analysis/domain/entities/popular_area.dart';
import 'package:steply/features/analysis/domain/entities/recommendation.dart';
import 'package:steply/features/analysis/domain/entities/temporal_analysis.dart';
import 'package:steply/features/analysis/domain/entities/weather_data.dart';
import 'package:steply/features/analysis/domain/repositories/mobility_repository.dart';

class MobilityRepositoryImpl implements MobilityRepository {
  final MobilityLocalDatasource datasource;

  MobilityRepositoryImpl({required this.datasource});

  @override
  Future<List<MobilityDataPoint>> getMobilityData() {
    return datasource.getMobilityData();
  }

  @override
  Future<ComfortIndex> calculateComfortIndex(double lat, double lng) async {
    final data = await datasource.getMobilityData();

    // Find nearby data points within ~500m radius (~0.005 degrees)
    const radius = 0.005;
    final nearby = data.where((p) {
      final dLat = p.latitude - lat;
      final dLng = p.longitude - lng;
      return sqrt(dLat * dLat + dLng * dLng) <= radius;
    }).toList();

    final count = nearby.length;

    // Density-based comfort: fewer people = more comfortable
    // Normalize against max expected density
    final density = count / max(data.length * 0.01, 1);
    final value = (1.0 - min(density, 1.0)).clamp(0.0, 1.0);

    ComfortLevel level;
    if (value < 0.3) {
      level = ComfortLevel.low;
    } else if (value < 0.7) {
      level = ComfortLevel.medium;
    } else {
      level = ComfortLevel.high;
    }

    return ComfortIndex(
      value: value,
      level: level,
      areaLatitude: lat,
      areaLongitude: lng,
      dataPointCount: count,
    );
  }

  // Known landmarks for labelling hotspots
  static const _landmarks = [
    {'name': 'Nagoya Castle', 'lat': 35.1856, 'lng': 136.8990},
    {'name': 'Oasis 21', 'lat': 35.1709, 'lng': 136.9084},
    {'name': 'Atsuta Shrine', 'lat': 35.1283, 'lng': 136.9087},
    {'name': 'Nagoya Station', 'lat': 35.1709, 'lng': 136.8815},
    {'name': 'Sakae District', 'lat': 35.1681, 'lng': 136.9089},
    {'name': 'Hisaya Odori Park', 'lat': 35.1720, 'lng': 136.9090},
    {'name': 'Nagoya TV Tower', 'lat': 35.1745, 'lng': 136.9088},
    {'name': 'Tokugawa Art Museum', 'lat': 35.1869, 'lng': 136.9347},
    {'name': 'Meitetsu Dept Store', 'lat': 35.1705, 'lng': 136.8830},
  ];

  String _nearestLandmarkName(double lat, double lng, int index) {
    String bestName = '';
    double bestDist = double.infinity;
    for (final lm in _landmarks) {
      final dLat = (lm['lat'] as double) - lat;
      final dLng = (lm['lng'] as double) - lng;
      final dist = sqrt(dLat * dLat + dLng * dLng);
      if (dist < bestDist) {
        bestDist = dist;
        bestName = lm['name'] as String;
      }
    }
    // ~0.005 degrees ≈ 500m — if within that, use the name directly
    if (bestDist <= 0.005) return bestName;
    // Otherwise label relative to nearest landmark
    return 'Near $bestName';
  }

  @override
  Future<List<PopularArea>> getPopularAreas() async {
    final data = await datasource.getMobilityData();

    // Grid-cell clustering: group by 0.005-degree grid cells
    final Map<String, List<MobilityDataPoint>> grid = {};
    for (final point in data) {
      final gridLat = (point.latitude / 0.005).floor() * 0.005;
      final gridLng = (point.longitude / 0.005).floor() * 0.005;
      final key = '${gridLat.toStringAsFixed(4)},${gridLng.toStringAsFixed(4)}';
      grid.putIfAbsent(key, () => []).add(point);
    }

    // Sort by visit count and take top 10
    final sortedCells = grid.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    final usedNames = <String>{};
    int index = 0;

    return sortedCells.take(10).map((entry) {
      final points = entry.value;
      final parts = entry.key.split(',');
      final lat = double.parse(parts[0]) + 0.0025; // center of cell
      final lng = double.parse(parts[1]) + 0.0025;

      var name = _nearestLandmarkName(lat, lng, index);
      // Avoid duplicate names
      if (usedNames.contains(name)) {
        name = '$name #${index + 1}';
      }
      usedNames.add(name);
      index++;

      final avgElapsed =
          points.map((p) => p.elapsedTime).reduce((a, b) => a + b) /
              points.length;

      // Find peak day
      final dayCount = <String, int>{};
      for (final p in points) {
        dayCount[p.dayOfWeek] = (dayCount[p.dayOfWeek] ?? 0) + 1;
      }
      final peakDay =
          dayCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;

      // Find peak hour from start_time
      final hourCount = <int, int>{};
      for (final p in points) {
        final hourMatch = RegExp(r'(\d{2}):(\d{2}):').firstMatch(p.startTime);
        if (hourMatch != null) {
          final hour = int.parse(hourMatch.group(1)!);
          hourCount[hour] = (hourCount[hour] ?? 0) + 1;
        }
      }
      final peakHour = hourCount.isEmpty
          ? 12
          : hourCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;

      return PopularArea(
        name: name,
        latitude: lat,
        longitude: lng,
        visitCount: points.length,
        avgElapsedTime: avgElapsed,
        peakDay: peakDay,
        peakHour: peakHour,
      );
    }).toList();
  }

  static const _dayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  int _dayIndex(String dayOfWeek) {
    final idx = _dayNames.indexWhere(
        (d) => d.toLowerCase() == dayOfWeek.toLowerCase());
    return idx >= 0 ? idx : 0;
  }

  int _parseHour(String startTime) {
    final match = RegExp(r'(\d{2}):').firstMatch(startTime);
    return match != null ? int.parse(match.group(1)!) : 12;
  }

  @override
  Future<TemporalAnalysis> getTemporalAnalysis() async {
    final data = await datasource.getMobilityData();

    // Hourly distribution (0-23)
    final hourlyDist = <int, int>{};
    for (int h = 0; h < 24; h++) {
      hourlyDist[h] = 0;
    }

    // Day of week distribution (0=Mon, 6=Sun)
    final dayDist = <int, int>{};
    for (int d = 0; d < 7; d++) {
      dayDist[d] = 0;
    }

    // 7x24 heatmap
    final heatmap = List.generate(7, (_) => List.filled(24, 0));

    // Dwell time by area grid cell
    final dwellTimeSum = <String, double>{};
    final dwellTimeCount = <String, int>{};

    int weekdayCount = 0;
    int weekendCount = 0;

    for (final p in data) {
      final hour = _parseHour(p.startTime);
      final dayIdx = _dayIndex(p.dayOfWeek);

      hourlyDist[hour] = (hourlyDist[hour] ?? 0) + 1;
      dayDist[dayIdx] = (dayDist[dayIdx] ?? 0) + 1;
      heatmap[dayIdx][hour]++;

      if (dayIdx < 5) {
        weekdayCount++;
      } else {
        weekendCount++;
      }

      // Area key for dwell time
      final gridLat = (p.latitude / 0.005).floor() * 0.005;
      final gridLng = (p.longitude / 0.005).floor() * 0.005;
      final areaKey = '${gridLat.toStringAsFixed(4)},${gridLng.toStringAsFixed(4)}';
      dwellTimeSum[areaKey] = (dwellTimeSum[areaKey] ?? 0) + p.elapsedTime;
      dwellTimeCount[areaKey] = (dwellTimeCount[areaKey] ?? 0) + 1;
    }

    final dwellTimeByArea = <String, double>{};
    for (final key in dwellTimeSum.keys) {
      dwellTimeByArea[key] = dwellTimeSum[key]! / dwellTimeCount[key]!;
    }

    // Find busiest/quietest hour
    int busiestHour = 0;
    int quietestHour = 0;
    int maxHourly = 0;
    int minHourly = data.length + 1;
    for (final entry in hourlyDist.entries) {
      if (entry.value > maxHourly) {
        maxHourly = entry.value;
        busiestHour = entry.key;
      }
      if (entry.value < minHourly) {
        minHourly = entry.value;
        quietestHour = entry.key;
      }
    }

    // Find busiest/quietest day
    int busiestDay = 0;
    int quietestDay = 0;
    int maxDaily = 0;
    int minDaily = data.length + 1;
    for (final entry in dayDist.entries) {
      if (entry.value > maxDaily) {
        maxDaily = entry.value;
        busiestDay = entry.key;
      }
      if (entry.value < minDaily) {
        minDaily = entry.value;
        quietestDay = entry.key;
      }
    }

    return TemporalAnalysis(
      hourlyDistribution: hourlyDist,
      dayOfWeekDistribution: dayDist,
      temporalHeatmap: heatmap,
      dwellTimeByArea: dwellTimeByArea,
      weekdayCount: weekdayCount,
      weekendCount: weekendCount,
      busiestHour: busiestHour,
      quietestHour: quietestHour,
      busiestDay: busiestDay,
      quietestDay: quietestDay,
    );
  }

  @override
  Future<List<Recommendation>> getRecommendations(
      List<HourlyWeather> weatherData) async {
    final data = await datasource.getMobilityData();
    final recommendations = <Recommendation>[];

    // Build hourly crowd map: hour -> count
    final hourlyCrowd = <int, int>{};
    for (final p in data) {
      final hour = _parseHour(p.startTime);
      hourlyCrowd[hour] = (hourlyCrowd[hour] ?? 0) + 1;
    }

    final maxCrowd = hourlyCrowd.values.fold(0, max);

    // Build weather map: hour -> avg weather score
    // sunny=1.0, cloudy=0.8, foggy=0.5, rainy=0.3, snowy=0.2, stormy=0.1
    double weatherScore(WeatherCondition c) {
      switch (c) {
        case WeatherCondition.sunny:
          return 1.0;
        case WeatherCondition.cloudy:
          return 0.8;
        case WeatherCondition.foggy:
          return 0.5;
        case WeatherCondition.rainy:
          return 0.3;
        case WeatherCondition.snowy:
          return 0.2;
        case WeatherCondition.stormy:
          return 0.1;
      }
    }

    // Average weather score per hour of day across the year
    final hourlyWeatherScore = <int, double>{};
    final hourlyWeatherCount = <int, int>{};
    final hourlyTemp = <int, double>{};

    for (final w in weatherData) {
      final h = w.time.hour;
      hourlyWeatherScore[h] =
          (hourlyWeatherScore[h] ?? 0) + weatherScore(w.condition);
      hourlyWeatherCount[h] = (hourlyWeatherCount[h] ?? 0) + 1;
      hourlyTemp[h] = (hourlyTemp[h] ?? 0) + w.temperature;
    }

    // Compute combined score per hour: (1-crowd)*0.6 + weather*0.4
    final hourlyScores = <int, double>{};
    for (int h = 0; h < 24; h++) {
      final crowd = (hourlyCrowd[h] ?? 0) / max(maxCrowd, 1);
      final wCount = hourlyWeatherCount[h] ?? 1;
      final wScore = (hourlyWeatherScore[h] ?? 0.5) / wCount;
      final avgTemp = (hourlyTemp[h] ?? 15.0) / wCount;

      // Temperature filter: prefer 10-28°C
      double tempBonus = 1.0;
      if (avgTemp < 10 || avgTemp > 28) {
        tempBonus = 0.5;
      }

      hourlyScores[h] = ((1.0 - crowd) * 0.6 + wScore * 0.4) * tempBonus;
    }

    // Best time recommendation
    final bestHour = hourlyScores.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    recommendations.add(Recommendation(
      type: RecommendationType.bestTime,
      title: 'Best time to explore',
      description:
          '${bestHour.key}:00 offers the best combination of low crowds and good weather.',
      suggestedHour: bestHour.key,
      confidenceScore: bestHour.value.clamp(0.0, 1.0),
    ));

    // Quietest area recommendation
    final areaCrowdCounts = <String, int>{};
    for (final p in data) {
      final gridLat = (p.latitude / 0.005).floor() * 0.005;
      final gridLng = (p.longitude / 0.005).floor() * 0.005;
      final key = '${gridLat.toStringAsFixed(4)},${gridLng.toStringAsFixed(4)}';
      areaCrowdCounts[key] = (areaCrowdCounts[key] ?? 0) + 1;
    }
    if (areaCrowdCounts.isNotEmpty) {
      final quietestArea = areaCrowdCounts.entries
          .reduce((a, b) => a.value < b.value ? a : b);
      final parts = quietestArea.key.split(',');
      final aLat = double.parse(parts[0]) + 0.0025;
      final aLng = double.parse(parts[1]) + 0.0025;
      recommendations.add(Recommendation(
        type: RecommendationType.quietArea,
        title: 'Quiet area to visit',
        description:
            'This area has the fewest visitors (${quietestArea.value} records). Great for a peaceful experience.',
        lat: aLat,
        lng: aLng,
        confidenceScore: 0.8,
      ));
    }

    // Weather-optimal recommendation
    // Find hours with good weather AND low crowd
    final weatherOptimalHours = hourlyScores.entries
        .where((e) => e.value > 0.6)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (weatherOptimalHours.length >= 2) {
      final topHours = weatherOptimalHours.take(3).map((e) => '${e.key}:00').join(', ');
      recommendations.add(Recommendation(
        type: RecommendationType.weatherOptimal,
        title: 'Weather-optimal hours',
        description:
            'Best weather with low crowds at: $topHours. Ideal for outdoor activities.',
        confidenceScore: weatherOptimalHours.first.value.clamp(0.0, 1.0),
      ));
    }

    // Avoid crowd recommendation
    final worstHour = hourlyScores.entries
        .reduce((a, b) => a.value < b.value ? a : b);
    recommendations.add(Recommendation(
      type: RecommendationType.avoidCrowd,
      title: 'Avoid peak crowds',
      description:
          'Avoid visiting around ${worstHour.key}:00 — this is the most crowded time with the worst crowd-weather combination.',
      suggestedHour: worstHour.key,
      confidenceScore: (1.0 - worstHour.value).clamp(0.0, 1.0),
    ));

    // Sort by confidence
    recommendations.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));

    return recommendations;
  }

  @override
  Future<LocalTemporalAnalysis> getLocalTemporalAnalysis(
      double lat, double lng) async {
    final data = await datasource.getMobilityData();

    // Filter to ~500m radius (reuse radius from calculateComfortIndex)
    const radius = 0.005;
    final nearby = data.where((p) {
      final dLat = p.latitude - lat;
      final dLng = p.longitude - lng;
      return sqrt(dLat * dLat + dLng * dLng) <= radius;
    }).toList();

    final totalRecords = nearby.length;

    // Hourly distribution (0-23)
    final hourlyDist = <int, int>{};
    for (int h = 0; h < 24; h++) {
      hourlyDist[h] = 0;
    }

    // Day of week distribution (0=Mon, 6=Sun)
    final dayDist = <int, int>{};
    for (int d = 0; d < 7; d++) {
      dayDist[d] = 0;
    }

    // 7x24 heatmap
    final heatmap = List.generate(7, (_) => List.filled(24, 0));

    double totalElapsed = 0;

    for (final p in nearby) {
      final hour = _parseHour(p.startTime);
      final dayIdx = _dayIndex(p.dayOfWeek);

      hourlyDist[hour] = (hourlyDist[hour] ?? 0) + 1;
      dayDist[dayIdx] = (dayDist[dayIdx] ?? 0) + 1;
      heatmap[dayIdx][hour]++;
      totalElapsed += p.elapsedTime;
    }

    final avgDwell = totalRecords > 0 ? totalElapsed / totalRecords : 0.0;

    // Find busiest/quietest hour
    int busiestHour = 0;
    int quietestHour = 0;
    int maxH = 0;
    int minH = totalRecords + 1;
    for (final entry in hourlyDist.entries) {
      if (entry.value > maxH) {
        maxH = entry.value;
        busiestHour = entry.key;
      }
      if (entry.value < minH) {
        minH = entry.value;
        quietestHour = entry.key;
      }
    }

    // Find busiest/quietest day
    int busiestDay = 0;
    int quietestDay = 0;
    int maxD = 0;
    int minD = totalRecords + 1;
    for (final entry in dayDist.entries) {
      if (entry.value > maxD) {
        maxD = entry.value;
        busiestDay = entry.key;
      }
      if (entry.value < minD) {
        minD = entry.value;
        quietestDay = entry.key;
      }
    }

    // Compute median crowd across all heatmap cells
    final allCells = <int>[];
    for (int d = 0; d < 7; d++) {
      for (int h = 0; h < 24; h++) {
        allCells.add(heatmap[d][h]);
      }
    }
    allCells.sort();
    final median = allCells.isNotEmpty
        ? allCells[allCells.length ~/ 2].toDouble()
        : 0.0;

    // Determine currentStatus from current hour/day
    final now = DateTime.now();
    final currentDayIdx = (now.weekday - 1); // DateTime weekday: 1=Mon
    final currentHour = now.hour;
    final currentCrowd = heatmap[currentDayIdx][currentHour];

    String currentStatus;
    if (currentCrowd <= median * 0.5) {
      currentStatus = 'quiet';
    } else if (currentCrowd <= median * 1.5) {
      currentStatus = 'moderate';
    } else {
      currentStatus = 'busy';
    }

    // Find nextQuietWeekendHour: next Sat/Sun hour below median
    DateTime? nextQuietWeekend;
    final searchStart = now.add(const Duration(hours: 1));
    for (int offset = 0; offset < 7 * 24; offset++) {
      final candidate = searchStart.add(Duration(hours: offset));
      final candidateDayIdx = candidate.weekday - 1;
      // Saturday=5, Sunday=6
      if (candidateDayIdx == 5 || candidateDayIdx == 6) {
        if (heatmap[candidateDayIdx][candidate.hour] < median) {
          nextQuietWeekend = DateTime(
            candidate.year,
            candidate.month,
            candidate.day,
            candidate.hour,
          );
          break;
        }
      }
    }

    // Build bestTimeSlots from lowest-crowd heatmap cells
    final cellScores = <_CellScore>[];
    final maxCellValue =
        allCells.isNotEmpty ? allCells.last.toDouble() : 1.0;
    for (int d = 0; d < 7; d++) {
      for (int h = 0; h < 24; h++) {
        cellScores.add(_CellScore(
          day: d,
          hour: h,
          score: maxCellValue > 0
              ? heatmap[d][h] / maxCellValue
              : 0.0,
        ));
      }
    }
    cellScores.sort((a, b) => a.score.compareTo(b.score));

    // Merge adjacent hours on same day into slots, take top 3
    final bestSlots = <TimeSlot>[];
    final used = <String>{};
    for (final cell in cellScores) {
      final key = '${cell.day}_${cell.hour}';
      if (used.contains(key)) continue;
      if (bestSlots.length >= 3) break;

      // Expand to adjacent quiet hours
      int startH = cell.hour;
      int endH = cell.hour;
      while (startH > 0 &&
          !used.contains('${cell.day}_${startH - 1}') &&
          heatmap[cell.day][startH - 1] <= median) {
        startH--;
      }
      while (endH < 23 &&
          !used.contains('${cell.day}_${endH + 1}') &&
          heatmap[cell.day][endH + 1] <= median) {
        endH++;
      }

      for (int h = startH; h <= endH; h++) {
        used.add('${cell.day}_$h');
      }

      bestSlots.add(TimeSlot(
        dayOfWeek: cell.day,
        startHour: startH,
        endHour: endH + 1, // exclusive end
        crowdScore: cell.score,
      ));
    }

    return LocalTemporalAnalysis(
      hourlyDistribution: hourlyDist,
      dayOfWeekDistribution: dayDist,
      temporalHeatmap: heatmap,
      busiestHour: busiestHour,
      quietestHour: quietestHour,
      busiestDay: busiestDay,
      quietestDay: quietestDay,
      totalNearbyRecords: totalRecords,
      avgDwellTime: avgDwell,
      currentStatus: currentStatus,
      nextQuietWeekendHour: nextQuietWeekend,
      bestTimeSlots: bestSlots,
    );
  }
}

class _CellScore {
  final int day;
  final int hour;
  final double score;
  _CellScore({required this.day, required this.hour, required this.score});
}
