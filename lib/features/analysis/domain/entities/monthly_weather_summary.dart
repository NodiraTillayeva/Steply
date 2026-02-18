import 'package:equatable/equatable.dart';
import 'package:steply/features/analysis/domain/entities/weather_data.dart';

class MonthlyWeatherSummary extends Equatable {
  final int month; // 1-12
  final double avgTemperature;
  final double totalPrecipitation;
  final double avgWindSpeed;
  final WeatherCondition dominantCondition;
  final int sunnyDays;
  final int rainyDays;
  final double visitabilityScore; // 0.0 - 1.0

  const MonthlyWeatherSummary({
    required this.month,
    required this.avgTemperature,
    required this.totalPrecipitation,
    required this.avgWindSpeed,
    required this.dominantCondition,
    required this.sunnyDays,
    required this.rainyDays,
    required this.visitabilityScore,
  });

  @override
  List<Object?> get props => [
        month,
        avgTemperature,
        totalPrecipitation,
        avgWindSpeed,
        dominantCondition,
        sunnyDays,
        rainyDays,
        visitabilityScore,
      ];
}
