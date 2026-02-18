import 'package:equatable/equatable.dart';

class HeatmapPoint extends Equatable {
  final double latitude;
  final double longitude;
  final double intensity;

  const HeatmapPoint({
    required this.latitude,
    required this.longitude,
    required this.intensity,
  });

  @override
  List<Object?> get props => [latitude, longitude, intensity];
}
