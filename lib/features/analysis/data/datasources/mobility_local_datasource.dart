import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:steply/features/analysis/domain/entities/mobility_data_point.dart';
import 'package:steply/features/analysis/domain/entities/popular_area.dart';
import 'package:steply/features/analysis/domain/entities/temporal_analysis.dart';
import 'package:steply/features/map_view/domain/entities/heatmap_point.dart';

abstract class MobilityLocalDatasource {
  Future<List<MobilityDataPoint>> getMobilityData();
  Future<List<HeatmapPoint>> getPrecomputedHeatmap();
  Future<List<PopularArea>> getPrecomputedPopularAreas();
  Future<TemporalAnalysis> getPrecomputedTemporalAnalysis();
  Future<List<Map<String, dynamic>>> getPrecomputedMonthlyTrends();
}

class MobilityLocalDatasourceImpl implements MobilityLocalDatasource {
  Map<String, dynamic>? _jsonCache;

  Future<Map<String, dynamic>> _loadJson() async {
    if (_jsonCache != null) return _jsonCache!;

    final jsonString =
        await rootBundle.loadString('assets/data/mobility_computed.json');
    _jsonCache = json.decode(jsonString) as Map<String, dynamic>;
    return _jsonCache!;
  }

  @override
  Future<List<MobilityDataPoint>> getMobilityData() async {
    // Raw data is no longer bundled (210M rows too large).
    // All analytics come from pre-computed JSON.
    return [];
  }

  @override
  Future<List<HeatmapPoint>> getPrecomputedHeatmap() async {
    final data = await _loadJson();
    final heatmap = data['heatmap'] as List<dynamic>;
    return heatmap.map((point) {
      final p = point as Map<String, dynamic>;
      return HeatmapPoint(
        latitude: (p['lat'] as num).toDouble(),
        longitude: (p['lng'] as num).toDouble(),
        intensity: (p['intensity'] as num).toDouble(),
      );
    }).toList();
  }

  @override
  Future<List<PopularArea>> getPrecomputedPopularAreas() async {
    final data = await _loadJson();
    final areas = data['popularAreas'] as List<dynamic>;
    return areas.map((a) {
      final area = a as Map<String, dynamic>;
      return PopularArea(
        name: area['name'] as String,
        latitude: (area['lat'] as num).toDouble(),
        longitude: (area['lng'] as num).toDouble(),
        visitCount: area['visitCount'] as int,
        avgElapsedTime: (area['avgDwellTime'] as num).toDouble(),
        peakDay: area['peakDay'] as String,
        peakHour: area['peakHour'] as int,
      );
    }).toList();
  }

  @override
  Future<TemporalAnalysis> getPrecomputedTemporalAnalysis() async {
    final data = await _loadJson();
    final t = data['temporalAnalysis'] as Map<String, dynamic>;

    final hourlyList = (t['hourly'] as List<dynamic>).cast<num>();
    final dailyList = (t['daily'] as List<dynamic>).cast<num>();
    final heatmapList = (t['heatmap'] as List<dynamic>)
        .map((row) =>
            (row as List<dynamic>).map((v) => (v as num).toDouble()).toList())
        .toList();

    // Convert normalized distributions to integer counts (scale by 1000)
    final hourlyDist = <int, int>{};
    for (int h = 0; h < 24; h++) {
      hourlyDist[h] = (hourlyList[h].toDouble() * 1000).round();
    }
    final dayDist = <int, int>{};
    for (int d = 0; d < 7; d++) {
      dayDist[d] = (dailyList[d].toDouble() * 1000).round();
    }

    // Convert heatmap to int grid
    final intHeatmap = heatmapList
        .map((row) => row.map((v) => (v * 1000).round()).toList())
        .toList();

    // Compute weekday/weekend counts from daily distribution
    int weekdayCount = 0;
    int weekendCount = 0;
    for (int d = 0; d < 7; d++) {
      if (d < 5) {
        weekdayCount += dayDist[d]!;
      } else {
        weekendCount += dayDist[d]!;
      }
    }

    return TemporalAnalysis(
      hourlyDistribution: hourlyDist,
      dayOfWeekDistribution: dayDist,
      temporalHeatmap: intHeatmap,
      dwellTimeByArea: const {},
      weekdayCount: weekdayCount,
      weekendCount: weekendCount,
      busiestHour: t['busiestHour'] as int,
      quietestHour: t['quietestHour'] as int,
      busiestDay: _dayNameToIndex(t['busiestDay'] as String),
      quietestDay: _dayNameToIndex(t['quietestDay'] as String),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getPrecomputedMonthlyTrends() async {
    final data = await _loadJson();
    return (data['monthlyTrends'] as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static int _dayNameToIndex(String name) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    final idx = days.indexOf(name);
    return idx >= 0 ? idx : 0;
  }
}
