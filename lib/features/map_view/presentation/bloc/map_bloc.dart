import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:steply/features/map_view/domain/entities/heatmap_point.dart';
import 'package:steply/features/map_view/domain/entities/poi.dart';
import 'package:steply/features/map_view/domain/usecases/get_heatmap_data.dart';
import 'package:steply/features/map_view/domain/usecases/get_pois.dart';

// Events
abstract class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object?> get props => [];
}

class LoadMap extends MapEvent {}

class SelectPoi extends MapEvent {
  final Poi? poi;

  const SelectPoi(this.poi);

  @override
  List<Object?> get props => [poi];
}

class ToggleSatelliteView extends MapEvent {}

// States
abstract class MapState extends Equatable {
  const MapState();

  @override
  List<Object?> get props => [];
}

class MapInitial extends MapState {}

class MapLoading extends MapState {}

class MapLoaded extends MapState {
  final List<Poi> pois;
  final List<HeatmapPoint> heatmapPoints;
  final Poi? selectedPoi;
  final bool useSatellite;

  const MapLoaded({
    required this.pois,
    required this.heatmapPoints,
    this.selectedPoi,
    this.useSatellite = false,
  });

  @override
  List<Object?> get props => [pois, heatmapPoints, selectedPoi, useSatellite];

  MapLoaded copyWith({
    List<Poi>? pois,
    List<HeatmapPoint>? heatmapPoints,
    Poi? selectedPoi,
    bool clearSelectedPoi = false,
    bool? useSatellite,
  }) {
    return MapLoaded(
      pois: pois ?? this.pois,
      heatmapPoints: heatmapPoints ?? this.heatmapPoints,
      selectedPoi: clearSelectedPoi ? null : (selectedPoi ?? this.selectedPoi),
      useSatellite: useSatellite ?? this.useSatellite,
    );
  }
}

class MapError extends MapState {
  final String message;

  const MapError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class MapBloc extends Bloc<MapEvent, MapState> {
  final GetPois getPois;
  final GetHeatmapData getHeatmapData;

  MapBloc({
    required this.getPois,
    required this.getHeatmapData,
  }) : super(MapInitial()) {
    on<LoadMap>(_onLoadMap);
    on<SelectPoi>(_onSelectPoi);
    on<ToggleSatelliteView>(_onToggleSatellite);
  }

  Future<void> _onLoadMap(LoadMap event, Emitter<MapState> emit) async {
    emit(MapLoading());
    try {
      final pois = await getPois();
      final heatmapPoints = await getHeatmapData();
      emit(MapLoaded(pois: pois, heatmapPoints: heatmapPoints));
    } catch (e) {
      emit(MapError(e.toString()));
    }
  }

  void _onSelectPoi(SelectPoi event, Emitter<MapState> emit) {
    final currentState = state;
    if (currentState is MapLoaded) {
      emit(currentState.copyWith(
        selectedPoi: event.poi,
        clearSelectedPoi: event.poi == null,
      ));
    }
  }

  void _onToggleSatellite(ToggleSatelliteView event, Emitter<MapState> emit) {
    final currentState = state;
    if (currentState is MapLoaded) {
      emit(currentState.copyWith(
        useSatellite: !currentState.useSatellite,
      ));
    }
  }
}
