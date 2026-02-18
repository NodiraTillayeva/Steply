import 'package:steply/features/analysis/domain/entities/itinerary.dart';
import 'package:steply/features/analysis/domain/repositories/itinerary_repository.dart';

class CreateItinerary {
  final ItineraryRepository repository;

  CreateItinerary({required this.repository});

  Future<void> call(Itinerary itinerary) {
    return repository.createItinerary(itinerary);
  }
}
