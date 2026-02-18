import 'package:equatable/equatable.dart';

class MobilityDataPoint extends Equatable {
  final int index;
  final double latitude;
  final double longitude;
  final double elapsedTime;
  final String dayOfWeek;
  final String startTime;

  const MobilityDataPoint({
    required this.index,
    required this.latitude,
    required this.longitude,
    required this.elapsedTime,
    required this.dayOfWeek,
    required this.startTime,
  });

  @override
  List<Object?> get props =>
      [index, latitude, longitude, elapsedTime, dayOfWeek, startTime];
}
