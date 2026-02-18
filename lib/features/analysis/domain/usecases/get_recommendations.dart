import 'package:steply/features/analysis/domain/entities/recommendation.dart';
import 'package:steply/features/analysis/domain/entities/weather_data.dart';
import 'package:steply/features/analysis/domain/repositories/mobility_repository.dart';

class GetRecommendations {
  final MobilityRepository repository;

  GetRecommendations({required this.repository});

  Future<List<Recommendation>> call(List<HourlyWeather> weatherData) {
    return repository.getRecommendations(weatherData);
  }
}
