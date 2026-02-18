import 'package:equatable/equatable.dart';

class PlaceInsights extends Equatable {
  final List<String> localTips;
  final String bestSeason;
  final String vibe;
  final List<String> highlights;
  final String caveat;

  const PlaceInsights({
    required this.localTips,
    required this.bestSeason,
    required this.vibe,
    required this.highlights,
    required this.caveat,
  });

  @override
  List<Object?> get props => [localTips, bestSeason, vibe, highlights, caveat];
}
