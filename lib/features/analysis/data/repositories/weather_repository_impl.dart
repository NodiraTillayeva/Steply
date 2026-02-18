import 'dart:math';

import 'package:steply/features/analysis/data/datasources/weather_remote_datasource.dart';
import 'package:steply/features/analysis/domain/entities/monthly_weather_summary.dart';
import 'package:steply/features/analysis/domain/entities/weather_data.dart';
import 'package:steply/features/analysis/domain/repositories/weather_repository.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherRemoteDatasource datasource;

  WeatherRepositoryImpl({required this.datasource});

  @override
  Future<List<HourlyWeather>> getHistoricalWeather() {
    return datasource.getHistoricalWeather();
  }

  @override
  Future<HourlyWeather> getCurrentWeather() {
    return datasource.getCurrentWeather();
  }

  @override
  Future<HourlyWeather> getCurrentWeatherAt(double lat, double lng) {
    return datasource.getCurrentWeatherAt(lat, lng);
  }

  @override
  Future<List<MonthlyWeatherSummary>> getMonthlyWeatherSummaries() async {
    final historical = await datasource.getHistoricalWeather();

    // Group by month
    final byMonth = <int, List<HourlyWeather>>{};
    for (final h in historical) {
      byMonth.putIfAbsent(h.time.month, () => []).add(h);
    }

    final summaries = <MonthlyWeatherSummary>[];
    for (int m = 1; m <= 12; m++) {
      final records = byMonth[m] ?? [];
      if (records.isEmpty) continue;

      final avgTemp =
          records.map((r) => r.temperature).reduce((a, b) => a + b) /
              records.length;
      final totalPrecip =
          records.map((r) => r.precipitation).reduce((a, b) => a + b);
      final avgWind =
          records.map((r) => r.windSpeed).reduce((a, b) => a + b) /
              records.length;

      // Count conditions
      final conditionCount = <WeatherCondition, int>{};
      for (final r in records) {
        conditionCount[r.condition] =
            (conditionCount[r.condition] ?? 0) + 1;
      }
      final dominant = conditionCount.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      // Count sunny/rainy days (group by day, check dominant condition)
      final dayConditions = <int, Map<WeatherCondition, int>>{};
      for (final r in records) {
        final day = r.time.day;
        dayConditions.putIfAbsent(day, () => {});
        dayConditions[day]![r.condition] =
            (dayConditions[day]![r.condition] ?? 0) + 1;
      }

      int sunnyDays = 0;
      int rainyDays = 0;
      for (final dayConds in dayConditions.values) {
        final dayDominant =
            dayConds.entries.reduce((a, b) => a.value > b.value ? a : b).key;
        if (dayDominant == WeatherCondition.sunny) sunnyDays++;
        if (dayDominant == WeatherCondition.rainy ||
            dayDominant == WeatherCondition.stormy) {
          rainyDays++;
        }
      }

      final totalDays = dayConditions.length;

      // Visitability score:
      // temp component (0-1): how close to ideal 15-25°C range
      double tempScore;
      if (avgTemp >= 15 && avgTemp <= 25) {
        tempScore = 1.0;
      } else {
        final dist = avgTemp < 15 ? 15 - avgTemp : avgTemp - 25;
        tempScore = max(0.0, 1.0 - dist / 20.0);
      }

      // Precipitation component (0-1): less is better
      const monthlyPrecipMax = 300.0; // rough upper bound for Nagoya
      final precipScore =
          max(0.0, 1.0 - totalPrecip / monthlyPrecipMax);

      // Sunny ratio component
      final sunnyRatio = totalDays > 0 ? sunnyDays / totalDays : 0.0;

      final visitability =
          (tempScore * 0.4 + precipScore * 0.3 + sunnyRatio * 0.3)
              .clamp(0.0, 1.0);

      summaries.add(MonthlyWeatherSummary(
        month: m,
        avgTemperature: avgTemp,
        totalPrecipitation: totalPrecip,
        avgWindSpeed: avgWind,
        dominantCondition: dominant,
        sunnyDays: sunnyDays,
        rainyDays: rainyDays,
        visitabilityScore: visitability,
      ));
    }

    return summaries;
  }
}
