import 'package:equatable/equatable.dart';

enum RecommendationType { bestTime, quietArea, weatherOptimal, avoidCrowd }

class Recommendation extends Equatable {
  final RecommendationType type;
  final String title;
  final String description;
  final String? areaName;
  final double? lat;
  final double? lng;
  final int? suggestedHour;
  final int? suggestedDay;
  final double confidenceScore;

  const Recommendation({
    required this.type,
    required this.title,
    required this.description,
    this.areaName,
    this.lat,
    this.lng,
    this.suggestedHour,
    this.suggestedDay,
    required this.confidenceScore,
  });

  @override
  List<Object?> get props => [
        type,
        title,
        description,
        areaName,
        lat,
        lng,
        suggestedHour,
        suggestedDay,
        confidenceScore,
      ];
}
