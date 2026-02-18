import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:steply/features/analysis/domain/entities/mobility_data_point.dart';

abstract class MobilityLocalDatasource {
  Future<List<MobilityDataPoint>> getMobilityData();
}

class MobilityLocalDatasourceImpl implements MobilityLocalDatasource {
  List<MobilityDataPoint>? _cache;

  @override
  Future<List<MobilityDataPoint>> getMobilityData() async {
    if (_cache != null) return _cache!;

    final csvString =
        await rootBundle.loadString('assets/data/nagoya_mobility.csv');
    final rows = const CsvToListConverter().convert(csvString, eol: '\n');

    // Skip header row
    _cache = rows.skip(1).where((row) => row.length >= 6).map((row) {
      return MobilityDataPoint(
        index: (row[0] is int) ? row[0] : int.tryParse(row[0].toString()) ?? 0,
        latitude: (row[1] is double)
            ? row[1]
            : double.tryParse(row[1].toString()) ?? 0.0,
        longitude: (row[2] is double)
            ? row[2]
            : double.tryParse(row[2].toString()) ?? 0.0,
        elapsedTime: (row[3] is double)
            ? row[3]
            : double.tryParse(row[3].toString()) ?? 0.0,
        dayOfWeek: row[4].toString(),
        startTime: row[5].toString(),
      );
    }).toList();

    return _cache!;
  }
}
