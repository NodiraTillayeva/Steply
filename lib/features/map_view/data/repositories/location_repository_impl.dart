import 'package:steply/features/analysis/data/datasources/mobility_local_datasource.dart';
import 'package:steply/features/map_view/domain/entities/heatmap_point.dart';
import 'package:steply/features/map_view/domain/entities/poi.dart';
import 'package:steply/features/map_view/domain/repositories/location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  final MobilityLocalDatasource mobilityDatasource;

  LocationRepositoryImpl({required this.mobilityDatasource});

  @override
  Future<List<Poi>> getPois() async {
    return const [
      Poi(
        id: '1',
        name: 'Nagoya Castle',
        latitude: 35.1856,
        longitude: 136.8990,
        category: PoiCategory.attraction,
        description:
            'Iconic castle built in 1612, famous for its golden shachihoko.',
      ),
      Poi(
        id: '2',
        name: 'Oasis 21',
        latitude: 35.1709,
        longitude: 136.9084,
        category: PoiCategory.shopping,
        description:
            'Futuristic glass structure with shops and a bus terminal.',
      ),
      Poi(
        id: '3',
        name: 'Atsuta Shrine',
        latitude: 35.1283,
        longitude: 136.9087,
        category: PoiCategory.attraction,
        description:
            'One of Japan\'s most important Shinto shrines, over 1900 years old.',
      ),
      Poi(
        id: '4',
        name: 'Nagoya Station',
        latitude: 35.1709,
        longitude: 136.8815,
        category: PoiCategory.transport,
        description:
            'Major railway hub and one of the largest station buildings in the world.',
      ),
      Poi(
        id: '5',
        name: 'Sakae District',
        latitude: 35.1681,
        longitude: 136.9089,
        category: PoiCategory.shopping,
        description:
            'Central shopping and entertainment district with department stores.',
      ),
      Poi(
        id: '6',
        name: 'Hisaya Odori Park',
        latitude: 35.1720,
        longitude: 136.9090,
        category: PoiCategory.attraction,
        description:
            'A lush green park stretching through the city center.',
      ),
      Poi(
        id: '7',
        name: 'Nagoya TV Tower',
        latitude: 35.1745,
        longitude: 136.9088,
        category: PoiCategory.attraction,
        description:
            'Japan\'s oldest TV tower, now a hotel and observation deck.',
      ),
      Poi(
        id: '8',
        name: 'Yabaton Miso Katsu',
        latitude: 35.1695,
        longitude: 136.9072,
        category: PoiCategory.restaurant,
        description:
            'Famous for Nagoya-style miso katsu, a local specialty.',
      ),
      Poi(
        id: '9',
        name: 'Tokugawa Art Museum',
        latitude: 35.1869,
        longitude: 136.9347,
        category: PoiCategory.attraction,
        description:
            'Houses treasures from the Owari branch of the Tokugawa family.',
      ),
      Poi(
        id: '10',
        name: 'Meitetsu Department Store',
        latitude: 35.1705,
        longitude: 136.8830,
        category: PoiCategory.shopping,
        description:
            'Major department store directly connected to Nagoya Station.',
      ),
    ];
  }

  @override
  Future<List<HeatmapPoint>> getHeatmapData() async {
    final data = await mobilityDatasource.getMobilityData();

    // Aggregate into grid cells for heatmap
    final Map<String, List<double>> grid = {};
    for (final point in data) {
      final gridLat = (point.latitude / 0.002).floor() * 0.002;
      final gridLng = (point.longitude / 0.002).floor() * 0.002;
      final key = '${gridLat.toStringAsFixed(4)},${gridLng.toStringAsFixed(4)}';
      grid.putIfAbsent(key, () => [0, 0, 0]); // lat, lng, count
      grid[key]![0] = gridLat + 0.001;
      grid[key]![1] = gridLng + 0.001;
      grid[key]![2] = grid[key]![2] + 1;
    }

    if (grid.isEmpty) return [];

    final maxCount =
        grid.values.map((v) => v[2]).reduce((a, b) => a > b ? a : b);

    return grid.values.map((v) {
      return HeatmapPoint(
        latitude: v[0],
        longitude: v[1],
        intensity: (v[2] / maxCount).clamp(0.0, 1.0),
      );
    }).toList();
  }
}
