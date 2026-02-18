import 'package:steply/features/analysis/domain/entities/itinerary.dart';

abstract class ItineraryRepository {
  Future<void> createItinerary(Itinerary itinerary);
  Future<List<Itinerary>> getItineraries();
  Future<void> deleteItinerary(String id);
}
