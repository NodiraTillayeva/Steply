import 'package:steply/features/analysis/domain/entities/comfort_index.dart';
import 'package:steply/features/analysis/domain/entities/local_temporal_analysis.dart';
import 'package:steply/features/analysis/domain/entities/mobility_data_point.dart';
import 'package:steply/features/analysis/domain/entities/popular_area.dart';
import 'package:steply/features/analysis/domain/entities/recommendation.dart';
import 'package:steply/features/analysis/domain/entities/temporal_analysis.dart';
import 'package:steply/features/analysis/domain/entities/weather_data.dart';

abstract class MobilityRepository {
  Future<List<MobilityDataPoint>> getMobilityData();
  Future<ComfortIndex> calculateComfortIndex(double lat, double lng);
  Future<List<PopularArea>> getPopularAreas();
  Future<TemporalAnalysis> getTemporalAnalysis();
  Future<List<Recommendation>> getRecommendations(List<HourlyWeather> weatherData);
  Future<LocalTemporalAnalysis> getLocalTemporalAnalysis(double lat, double lng);
}
