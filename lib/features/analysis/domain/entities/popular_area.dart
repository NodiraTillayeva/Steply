import 'package:equatable/equatable.dart';

class PopularArea extends Equatable {
  final String name;
  final double latitude;
  final double longitude;
  final int visitCount;
  final double avgElapsedTime;
  final String peakDay;
  final int peakHour;

  const PopularArea({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.visitCount,
    required this.avgElapsedTime,
    required this.peakDay,
    required this.peakHour,
  });

  @override
  List<Object?> get props =>
      [name, latitude, longitude, visitCount, avgElapsedTime, peakDay, peakHour];
}
