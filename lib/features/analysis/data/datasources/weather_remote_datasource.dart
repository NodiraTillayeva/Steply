import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:steply/features/analysis/domain/entities/weather_data.dart';

class WeatherRemoteDatasource {
  static const double _nagoyaLat = 35.1815;
  static const double _nagoyaLng = 136.9066;

  List<HourlyWeather>? _cachedHistorical;

  WeatherCondition _mapWmoCode(int code) {
    // WMO Weather interpretation codes
    // https://open-meteo.com/en/docs
    if (code == 0 || code == 1) return WeatherCondition.sunny;
    if (code == 2 || code == 3) return WeatherCondition.cloudy;
    if (code == 45 || code == 48) return WeatherCondition.foggy;
    if (code >= 51 && code <= 67) return WeatherCondition.rainy;
    if (code >= 71 && code <= 77) return WeatherCondition.snowy;
    if (code >= 80 && code <= 82) return WeatherCondition.rainy;
    if (code >= 85 && code <= 86) return WeatherCondition.snowy;
    if (code >= 95 && code <= 99) return WeatherCondition.stormy;
    return WeatherCondition.cloudy;
  }

  Future<List<HourlyWeather>> getHistoricalWeather() async {
    if (_cachedHistorical != null) return _cachedHistorical!;

    final uri = Uri.parse(
      'https://archive-api.open-meteo.com/v1/archive'
      '?latitude=$_nagoyaLat'
      '&longitude=$_nagoyaLng'
      '&start_date=2023-01-01'
      '&end_date=2023-12-31'
      '&hourly=temperature_2m,precipitation,weather_code,wind_speed_10m'
      '&timezone=Asia%2FTokyo',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch historical weather: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final hourly = json['hourly'] as Map<String, dynamic>;

    final times = (hourly['time'] as List).cast<String>();
    final temps = (hourly['temperature_2m'] as List);
    final precips = (hourly['precipitation'] as List);
    final codes = (hourly['weather_code'] as List);
    final winds = (hourly['wind_speed_10m'] as List);

    final result = <HourlyWeather>[];
    for (int i = 0; i < times.length; i++) {
      final code = (codes[i] as num?)?.toInt() ?? 0;
      result.add(HourlyWeather(
        time: DateTime.parse(times[i]),
        temperature: (temps[i] as num?)?.toDouble() ?? 0.0,
        precipitation: (precips[i] as num?)?.toDouble() ?? 0.0,
        weatherCode: code,
        windSpeed: (winds[i] as num?)?.toDouble() ?? 0.0,
        condition: _mapWmoCode(code),
      ));
    }

    _cachedHistorical = result;
    return result;
  }

  Future<HourlyWeather> getCurrentWeather() async {
    return getCurrentWeatherAt(_nagoyaLat, _nagoyaLng);
  }

  Future<HourlyWeather> getCurrentWeatherAt(double lat, double lng) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat'
      '&longitude=$lng'
      '&current=temperature_2m,precipitation,weather_code,wind_speed_10m'
      '&timezone=Asia%2FTokyo',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch current weather: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final current = json['current'] as Map<String, dynamic>;

    final code = (current['weather_code'] as num?)?.toInt() ?? 0;

    return HourlyWeather(
      time: DateTime.parse(current['time'] as String),
      temperature: (current['temperature_2m'] as num?)?.toDouble() ?? 0.0,
      precipitation: (current['precipitation'] as num?)?.toDouble() ?? 0.0,
      weatherCode: code,
      windSpeed: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
      condition: _mapWmoCode(code),
    );
  }
}
