import 'package:steply/features/analysis/domain/entities/temporal_analysis.dart';
import 'package:steply/features/analysis/domain/repositories/mobility_repository.dart';

class GetTemporalAnalysis {
  final MobilityRepository repository;

  GetTemporalAnalysis({required this.repository});

  Future<TemporalAnalysis> call() {
    return repository.getTemporalAnalysis();
  }
}
