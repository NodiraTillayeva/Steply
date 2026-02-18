import 'package:equatable/equatable.dart';

class WishlistPlace extends Equatable {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String description;
  final DateTime? eventDate;
  final DateTime? eventEndDate;
  final String sourceUrl;
  final DateTime addedAt;
  final List<String> localTips;
  final String? rawSourceContent;
  final String? imageUrl;

  const WishlistPlace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.description,
    this.eventDate,
    this.eventEndDate,
    required this.sourceUrl,
    required this.addedAt,
    this.localTips = const [],
    this.rawSourceContent,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        latitude,
        longitude,
        description,
        eventDate,
        eventEndDate,
        sourceUrl,
        addedAt,
        localTips,
        rawSourceContent,
        imageUrl,
      ];
}
