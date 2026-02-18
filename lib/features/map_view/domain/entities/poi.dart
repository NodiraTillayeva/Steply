import 'package:equatable/equatable.dart';

enum PoiCategory { attraction, restaurant, shopping, transport }

class Poi extends Equatable {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final PoiCategory category;
  final String description;

  const Poi({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.description,
  });

  @override
  List<Object?> get props =>
      [id, name, latitude, longitude, category, description];
}
