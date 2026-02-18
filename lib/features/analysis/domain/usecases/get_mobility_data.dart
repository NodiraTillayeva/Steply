import 'package:steply/features/analysis/domain/entities/mobility_data_point.dart';
import 'package:steply/features/analysis/domain/repositories/mobility_repository.dart';

class GetMobilityData {
  final MobilityRepository repository;

  GetMobilityData({required this.repository});

  Future<List<MobilityDataPoint>> call() {
    return repository.getMobilityData();
  }
}
