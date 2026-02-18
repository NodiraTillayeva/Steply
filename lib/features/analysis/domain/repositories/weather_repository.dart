import 'package:steply/features/analysis/domain/entities/monthly_weather_summary.dart';
import 'package:steply/features/analysis/domain/entities/weather_data.dart';

abstract class WeatherRepository {
  Future<List<HourlyWeather>> getHistoricalWeather();
  Future<HourlyWeather> getCurrentWeather();
  Future<HourlyWeather> getCurrentWeatherAt(double lat, double lng);
  Future<List<MonthlyWeatherSummary>> getMonthlyWeatherSummaries();
}
