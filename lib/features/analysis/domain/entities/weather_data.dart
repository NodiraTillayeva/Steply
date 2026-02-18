import 'package:equatable/equatable.dart';

enum WeatherCondition { sunny, cloudy, rainy, snowy, stormy, foggy }

class HourlyWeather extends Equatable {
  final DateTime time;
  final double temperature;
  final double precipitation;
  final int weatherCode;
  final double windSpeed;
  final WeatherCondition condition;

  const HourlyWeather({
    required this.time,
    required this.temperature,
    required this.precipitation,
    required this.weatherCode,
    required this.windSpeed,
    required this.condition,
  });

  @override
  List<Object?> get props =>
      [time, temperature, precipitation, weatherCode, windSpeed, condition];
}

class WeatherSummary extends Equatable {
  final double avgTemp;
  final double totalPrecip;
  final WeatherCondition dominantCondition;
  final double avgWind;

  const WeatherSummary({
    required this.avgTemp,
    required this.totalPrecip,
    required this.dominantCondition,
    required this.avgWind,
  });

  @override
  List<Object?> get props => [avgTemp, totalPrecip, dominantCondition, avgWind];
}
