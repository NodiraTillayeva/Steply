import 'package:steply/features/map_view/domain/entities/heatmap_point.dart';
import 'package:steply/features/map_view/domain/repositories/location_repository.dart';

class GetHeatmapData {
  final LocationRepository repository;

  GetHeatmapData({required this.repository});

  Future<List<HeatmapPoint>> call() {
    return repository.getHeatmapData();
  }
}
