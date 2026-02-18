import 'package:steply/features/map_view/domain/entities/heatmap_point.dart';
import 'package:steply/features/map_view/domain/entities/poi.dart';

abstract class LocationRepository {
  Future<List<Poi>> getPois();
  Future<List<HeatmapPoint>> getHeatmapData();
}
