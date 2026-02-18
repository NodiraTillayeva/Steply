import 'package:steply/features/analysis/domain/entities/weather_data.dart';
import 'package:steply/features/analysis/domain/repositories/weather_repository.dart';

class GetWeatherData {
  final WeatherRepository repository;

  GetWeatherData({required this.repository});

  Future<List<HourlyWeather>> call() {
    return repository.getHistoricalWeather();
  }

  Future<HourlyWeather> callCurrent() {
    return repository.getCurrentWeather();
  }
}
