import 'package:steply/features/analysis/domain/entities/comfort_index.dart';
import 'package:steply/features/analysis/domain/repositories/mobility_repository.dart';

class CalculateComfortIndex {
  final MobilityRepository repository;

  CalculateComfortIndex({required this.repository});

  Future<ComfortIndex> call(double lat, double lng) {
    return repository.calculateComfortIndex(lat, lng);
  }
}
