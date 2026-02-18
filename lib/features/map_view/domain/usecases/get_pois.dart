import 'package:steply/features/map_view/domain/entities/poi.dart';
import 'package:steply/features/map_view/domain/repositories/location_repository.dart';

class GetPois {
  final LocationRepository repository;

  GetPois({required this.repository});

  Future<List<Poi>> call() {
    return repository.getPois();
  }
}
