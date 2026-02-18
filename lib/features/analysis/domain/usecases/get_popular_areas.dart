import 'package:steply/features/analysis/domain/entities/popular_area.dart';
import 'package:steply/features/analysis/domain/repositories/mobility_repository.dart';

class GetPopularAreas {
  final MobilityRepository repository;

  GetPopularAreas({required this.repository});

  Future<List<PopularArea>> call() {
    return repository.getPopularAreas();
  }
}
