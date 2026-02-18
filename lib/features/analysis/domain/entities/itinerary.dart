import 'package:equatable/equatable.dart';

class ItineraryStop extends Equatable {
  final String name;
  final double latitude;
  final double longitude;
  final Duration duration;
  final DateTime? visitTime;

  const ItineraryStop({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.duration,
    this.visitTime,
  });

  ItineraryStop copyWith({
    String? name,
    double? latitude,
    double? longitude,
    Duration? duration,
    DateTime? visitTime,
  }) {
    return ItineraryStop(
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      duration: duration ?? this.duration,
      visitTime: visitTime ?? this.visitTime,
    );
  }

  @override
  List<Object?> get props => [name, latitude, longitude, duration, visitTime];
}

class Itinerary extends Equatable {
  final String id;
  final String name;
  final List<ItineraryStop> stops;
  final Duration totalDuration;
  final DateTime? startDate;
  final DateTime? endDate;

  const Itinerary({
    required this.id,
    required this.name,
    required this.stops,
    required this.totalDuration,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [id, name, stops, totalDuration, startDate, endDate];
}
