import 'package:equatable/equatable.dart';

enum ComfortLevel { low, medium, high }

class ComfortIndex extends Equatable {
  final double value;
  final ComfortLevel level;
  final double areaLatitude;
  final double areaLongitude;
  final int dataPointCount;

  const ComfortIndex({
    required this.value,
    required this.level,
    required this.areaLatitude,
    required this.areaLongitude,
    required this.dataPointCount,
  });

  @override
  List<Object?> get props =>
      [value, level, areaLatitude, areaLongitude, dataPointCount];
}
