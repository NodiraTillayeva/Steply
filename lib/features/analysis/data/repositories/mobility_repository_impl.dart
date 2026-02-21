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
import 'package:steply/features/map_view/domain/entities/heatmap_point.dart';

class MobilityRepositoryImpl implements MobilityRepository {
  final MobilityLocalDatasource datasource;

  MobilityRepositoryImpl({required this.datasource});

  // Cache pre-computed data
  List<HeatmapPoint>? _heatmapCache;
  List<PopularArea>? _areasCache;

  @override
  Future<List<MobilityDataPoint>> getMobilityData() {
    return datasource.getMobilityData();
  }

  @override
  Future<ComfortIndex> calculateComfortIndex(double lat, double lng) async {
    // Use pre-computed heatmap to approximate comfort
    _heatmapCache ??= await datasource.getPrecomputedHeatmap();

    // Find nearest heatmap points within ~500m radius (~0.005 degrees)
    const radius = 0.005;
    double maxNearbyIntensity = 0;
    int nearbyCount = 0;

    for (final point in _heatmapCache!) {
      final dLat = point.latitude - lat;
      final dLng = point.longitude - lng;
      final dist = sqrt(dLat * dLat + dLng * dLng);
      if (dist <= radius) {
        nearbyCount++;
        if (point.intensity > maxNearbyIntensity) {
          maxNearbyIntensity = point.intensity;
        }
      }
    }

    // Comfort = inverse of crowd intensity
    final value = (1.0 - maxNearbyIntensity).clamp(0.0, 1.0);

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
      dataPointCount: nearbyCount,
    );
  }

  @override
  Future<List<PopularArea>> getPopularAreas() async {
    _areasCache ??= await datasource.getPrecomputedPopularAreas();
    return _areasCache!;
  }

  @override
  Future<TemporalAnalysis> getTemporalAnalysis() async {
    return datasource.getPrecomputedTemporalAnalysis();
  }

  @override
  Future<List<Recommendation>> getRecommendations(
      List<HourlyWeather> weatherData) async {
    final temporal = await datasource.getPrecomputedTemporalAnalysis();
    final recommendations = <Recommendation>[];

    // Build hourly crowd from pre-computed temporal analysis
    final hourlyCrowd = temporal.hourlyDistribution;
    final maxCrowd = hourlyCrowd.values.fold(0, max);

    // Weather scoring
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

    // Combined score per hour
    final hourlyScores = <int, double>{};
    for (int h = 0; h < 24; h++) {
      final crowd = (hourlyCrowd[h] ?? 0) / max(maxCrowd, 1);
      final wCount = hourlyWeatherCount[h] ?? 1;
      final wScore = (hourlyWeatherScore[h] ?? 0.5) / wCount;
      final avgTemp = (hourlyTemp[h] ?? 15.0) / wCount;

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

    // Quietest area from pre-computed popular areas
    final areas = await getPopularAreas();
    if (areas.isNotEmpty) {
      final quietest = areas.reduce(
          (a, b) => a.visitCount < b.visitCount ? a : b);
      recommendations.add(Recommendation(
        type: RecommendationType.quietArea,
        title: 'Quiet area to visit',
        description:
            '${quietest.name} has relatively fewer visitors. Great for a peaceful experience.',
        areaName: quietest.name,
        lat: quietest.latitude,
        lng: quietest.longitude,
        confidenceScore: 0.8,
      ));
    }

    // Weather-optimal
    final weatherOptimalHours = hourlyScores.entries
        .where((e) => e.value > 0.6)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (weatherOptimalHours.length >= 2) {
      final topHours =
          weatherOptimalHours.take(3).map((e) => '${e.key}:00').join(', ');
      recommendations.add(Recommendation(
        type: RecommendationType.weatherOptimal,
        title: 'Weather-optimal hours',
        description:
            'Best weather with low crowds at: $topHours. Ideal for outdoor activities.',
        confidenceScore: weatherOptimalHours.first.value.clamp(0.0, 1.0),
      ));
    }

    // Avoid crowd
    final worstHour = hourlyScores.entries
        .reduce((a, b) => a.value < b.value ? a : b);
    recommendations.add(Recommendation(
      type: RecommendationType.avoidCrowd,
      title: 'Avoid peak crowds',
      description:
          'Avoid visiting around ${worstHour.key}:00 — this is the most crowded time.',
      suggestedHour: worstHour.key,
      confidenceScore: (1.0 - worstHour.value).clamp(0.0, 1.0),
    ));

    recommendations.sort(
        (a, b) => b.confidenceScore.compareTo(a.confidenceScore));
    return recommendations;
  }

  @override
  Future<LocalTemporalAnalysis> getLocalTemporalAnalysis(
      double lat, double lng) async {
    // Use pre-computed data to approximate local patterns
    final temporal = await datasource.getPrecomputedTemporalAnalysis();
    _heatmapCache ??= await datasource.getPrecomputedHeatmap();

    // Find nearby heatmap intensity for this location
    const radius = 0.005;
    double localIntensity = 0;
    for (final point in _heatmapCache!) {
      final dLat = point.latitude - lat;
      final dLng = point.longitude - lng;
      if (sqrt(dLat * dLat + dLng * dLng) <= radius) {
        if (point.intensity > localIntensity) {
          localIntensity = point.intensity;
        }
      }
    }

    // Use global temporal patterns scaled by local intensity
    final heatmap = temporal.temporalHeatmap;
    final scaledHeatmap = heatmap
        .map((row) => row.map((v) => (v * localIntensity).round()).toList())
        .toList();

    // Compute median
    final allCells = <int>[];
    for (final row in scaledHeatmap) {
      allCells.addAll(row);
    }
    allCells.sort();
    final median =
        allCells.isNotEmpty ? allCells[allCells.length ~/ 2].toDouble() : 0.0;

    // Current status
    final now = DateTime.now();
    final currentDayIdx = now.weekday - 1;
    final currentHour = now.hour;
    final currentCrowd = scaledHeatmap[currentDayIdx][currentHour];

    String currentStatus;
    if (currentCrowd <= median * 0.5) {
      currentStatus = 'quiet';
    } else if (currentCrowd <= median * 1.5) {
      currentStatus = 'moderate';
    } else {
      currentStatus = 'busy';
    }

    // Next quiet weekend
    DateTime? nextQuietWeekend;
    final searchStart = now.add(const Duration(hours: 1));
    for (int offset = 0; offset < 7 * 24; offset++) {
      final candidate = searchStart.add(Duration(hours: offset));
      final candidateDayIdx = candidate.weekday - 1;
      if (candidateDayIdx == 5 || candidateDayIdx == 6) {
        if (scaledHeatmap[candidateDayIdx][candidate.hour] < median) {
          nextQuietWeekend = DateTime(
            candidate.year, candidate.month, candidate.day, candidate.hour);
          break;
        }
      }
    }

    // Best time slots
    final maxCellValue =
        allCells.isNotEmpty ? allCells.last.toDouble() : 1.0;
    final cellScores = <_CellScore>[];
    for (int d = 0; d < 7; d++) {
      for (int h = 0; h < 24; h++) {
        cellScores.add(_CellScore(
          day: d,
          hour: h,
          score:
              maxCellValue > 0 ? scaledHeatmap[d][h] / maxCellValue : 0.0,
        ));
      }
    }
    cellScores.sort((a, b) => a.score.compareTo(b.score));

    final bestSlots = <TimeSlot>[];
    final used = <String>{};
    for (final cell in cellScores) {
      final key = '${cell.day}_${cell.hour}';
      if (used.contains(key)) continue;
      if (bestSlots.length >= 3) break;

      int startH = cell.hour;
      int endH = cell.hour;
      while (startH > 0 &&
          !used.contains('${cell.day}_${startH - 1}') &&
          scaledHeatmap[cell.day][startH - 1] <= median) {
        startH--;
      }
      while (endH < 23 &&
          !used.contains('${cell.day}_${endH + 1}') &&
          scaledHeatmap[cell.day][endH + 1] <= median) {
        endH++;
      }

      for (int h = startH; h <= endH; h++) {
        used.add('${cell.day}_$h');
      }

      bestSlots.add(TimeSlot(
        dayOfWeek: cell.day,
        startHour: startH,
        endHour: endH + 1,
        crowdScore: cell.score,
      ));
    }

    return LocalTemporalAnalysis(
      hourlyDistribution: temporal.hourlyDistribution,
      dayOfWeekDistribution: temporal.dayOfWeekDistribution,
      temporalHeatmap: scaledHeatmap,
      busiestHour: temporal.busiestHour,
      quietestHour: temporal.quietestHour,
      busiestDay: temporal.busiestDay,
      quietestDay: temporal.quietestDay,
      totalNearbyRecords: (localIntensity * 1000).round(),
      avgDwellTime: 30.0, // Default from pre-computed data
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
