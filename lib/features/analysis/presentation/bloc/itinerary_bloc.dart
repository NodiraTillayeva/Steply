import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:steply/features/analysis/domain/entities/itinerary.dart';
import 'package:steply/features/analysis/domain/repositories/mobility_repository.dart';
import 'package:steply/features/analysis/domain/usecases/create_itinerary.dart';
import 'package:steply/features/map_view/domain/entities/poi.dart';
import 'package:steply/features/map_view/domain/usecases/get_pois.dart';

// Events
abstract class ItineraryEvent extends Equatable {
  const ItineraryEvent();

  @override
  List<Object?> get props => [];
}

class LoadPois extends ItineraryEvent {}

class AddStop extends ItineraryEvent {
  final Poi poi;

  const AddStop(this.poi);

  @override
  List<Object?> get props => [poi];
}

class RemoveStop extends ItineraryEvent {
  final int index;

  const RemoveStop(this.index);

  @override
  List<Object?> get props => [index];
}

class AddStopByDetails extends ItineraryEvent {
  final String name;
  final double lat;
  final double lng;

  const AddStopByDetails({
    required this.name,
    required this.lat,
    required this.lng,
  });

  @override
  List<Object?> get props => [name, lat, lng];
}

class SaveItinerary extends ItineraryEvent {
  final String name;

  const SaveItinerary(this.name);

  @override
  List<Object?> get props => [name];
}

class SelectTripDates extends ItineraryEvent {
  final DateTime startDate;
  final DateTime endDate;

  const SelectTripDates({required this.startDate, required this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

class OrganizeItinerary extends ItineraryEvent {}

// States
abstract class ItineraryState extends Equatable {
  const ItineraryState();

  @override
  List<Object?> get props => [];
}

class ItineraryInitial extends ItineraryState {}

class ItineraryLoading extends ItineraryState {}

class ItineraryOrganizing extends ItineraryState {}

class ItineraryEditing extends ItineraryState {
  final List<Poi> availablePois;
  final List<ItineraryStop> stops;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isOrganized;

  const ItineraryEditing({
    required this.availablePois,
    required this.stops,
    this.startDate,
    this.endDate,
    this.isOrganized = false,
  });

  @override
  List<Object?> get props =>
      [availablePois, stops, startDate, endDate, isOrganized];

  ItineraryEditing copyWith({
    List<Poi>? availablePois,
    List<ItineraryStop>? stops,
    DateTime? startDate,
    DateTime? endDate,
    bool? isOrganized,
  }) {
    return ItineraryEditing(
      availablePois: availablePois ?? this.availablePois,
      stops: stops ?? this.stops,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isOrganized: isOrganized ?? this.isOrganized,
    );
  }
}

class ItinerarySaved extends ItineraryState {}

class ItineraryError extends ItineraryState {
  final String message;

  const ItineraryError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ItineraryBloc extends Bloc<ItineraryEvent, ItineraryState> {
  final CreateItinerary createItinerary;
  final GetPois getPois;
  final MobilityRepository mobilityRepository;

  ItineraryBloc({
    required this.createItinerary,
    required this.getPois,
    required this.mobilityRepository,
  }) : super(ItineraryInitial()) {
    on<LoadPois>(_onLoadPois);
    on<AddStop>(_onAddStop);
    on<AddStopByDetails>(_onAddStopByDetails);
    on<RemoveStop>(_onRemoveStop);
    on<SaveItinerary>(_onSaveItinerary);
    on<SelectTripDates>(_onSelectTripDates);
    on<OrganizeItinerary>(_onOrganizeItinerary);
  }

  Future<void> _onLoadPois(
      LoadPois event, Emitter<ItineraryState> emit) async {
    emit(ItineraryLoading());
    try {
      final pois = await getPois();
      emit(ItineraryEditing(availablePois: pois, stops: const []));
    } catch (e) {
      emit(ItineraryError(e.toString()));
    }
  }

  Future<void> _onAddStopByDetails(
      AddStopByDetails event, Emitter<ItineraryState> emit) async {
    final newStop = ItineraryStop(
      name: event.name,
      latitude: event.lat,
      longitude: event.lng,
      duration: const Duration(hours: 1),
    );

    final currentState = state;
    if (currentState is ItineraryEditing) {
      emit(currentState.copyWith(
        stops: [...currentState.stops, newStop],
        isOrganized: false,
      ));
    } else {
      try {
        final pois = await getPois();
        emit(ItineraryEditing(availablePois: pois, stops: [newStop]));
      } catch (e) {
        emit(ItineraryError(e.toString()));
      }
    }
  }

  void _onAddStop(AddStop event, Emitter<ItineraryState> emit) {
    final currentState = state;
    if (currentState is ItineraryEditing) {
      final newStop = ItineraryStop(
        name: event.poi.name,
        latitude: event.poi.latitude,
        longitude: event.poi.longitude,
        duration: const Duration(hours: 1),
      );
      emit(currentState.copyWith(
        stops: [...currentState.stops, newStop],
        isOrganized: false,
      ));
    }
  }

  void _onRemoveStop(RemoveStop event, Emitter<ItineraryState> emit) {
    final currentState = state;
    if (currentState is ItineraryEditing) {
      final newStops = List<ItineraryStop>.from(currentState.stops)
        ..removeAt(event.index);
      emit(currentState.copyWith(stops: newStops, isOrganized: false));
    }
  }

  Future<void> _onSaveItinerary(
      SaveItinerary event, Emitter<ItineraryState> emit) async {
    final currentState = state;
    if (currentState is ItineraryEditing && currentState.stops.isNotEmpty) {
      try {
        final totalDuration = currentState.stops.fold<Duration>(
          Duration.zero,
          (sum, stop) => sum + stop.duration,
        );

        final itinerary = Itinerary(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: event.name,
          stops: currentState.stops,
          totalDuration: totalDuration,
          startDate: currentState.startDate,
          endDate: currentState.endDate,
        );

        await createItinerary(itinerary);
        emit(ItinerarySaved());

        // Reload to editing state
        final pois = await getPois();
        emit(ItineraryEditing(availablePois: pois, stops: const []));
      } catch (e) {
        emit(ItineraryError(e.toString()));
      }
    }
  }

  void _onSelectTripDates(
      SelectTripDates event, Emitter<ItineraryState> emit) {
    final currentState = state;
    if (currentState is ItineraryEditing) {
      emit(currentState.copyWith(
        startDate: event.startDate,
        endDate: event.endDate,
        isOrganized: false,
      ));
    }
  }

  Future<void> _onOrganizeItinerary(
      OrganizeItinerary event, Emitter<ItineraryState> emit) async {
    final currentState = state;
    if (currentState is! ItineraryEditing ||
        currentState.stops.isEmpty ||
        currentState.startDate == null) {
      return;
    }

    // Save state so we can restore after organizing
    final savedState = currentState;
    emit(ItineraryOrganizing());

    try {
      final startDate = savedState.startDate!;
      final endDate = savedState.endDate!;

      // Collect crowd scores for each stop at each available hour
      final stopScores = <int, Map<int, double>>{}; // stopIdx -> {hour -> score}

      for (int i = 0; i < savedState.stops.length; i++) {
        final stop = savedState.stops[i];
        final analysis = await mobilityRepository.getLocalTemporalAnalysis(
          stop.latitude,
          stop.longitude,
        );

        // Get the heatmap for the trip's day(s) of week
        // Average crowd across all trip days for each hour
        final hourScores = <int, double>{};
        final tripDays = <int>[];

        var day = startDate;
        while (!day.isAfter(endDate)) {
          tripDays.add((day.weekday - 1) % 7); // Convert to 0=Mon
          day = day.add(const Duration(days: 1));
        }

        final uniqueDays = tripDays.toSet();
        for (int hour = 8; hour <= 20; hour++) {
          // Reasonable visiting hours: 8am-8pm
          double totalCrowd = 0;
          for (final d in uniqueDays) {
            totalCrowd += analysis.temporalHeatmap[d][hour];
          }
          // Lower crowd = better score
          hourScores[hour] = totalCrowd / uniqueDays.length;
        }

        stopScores[i] = hourScores;
      }

      // Greedy assignment: assign each stop to the best available hour
      // Sort stops by how constrained they are (fewer good hours = assign first)
      final stopIndices = List.generate(savedState.stops.length, (i) => i);

      // Find the max crowd across all stops/hours for normalization
      double maxCrowd = 1;
      for (final scores in stopScores.values) {
        for (final v in scores.values) {
          maxCrowd = max(maxCrowd, v);
        }
      }

      // Sort by best-to-worst ratio (most constrained first)
      stopIndices.sort((a, b) {
        final aScores = stopScores[a]!.values.toList()..sort();
        final bScores = stopScores[b]!.values.toList()..sort();
        // Ratio of best vs worst — lower ratio = more constrained
        final aRange = aScores.isEmpty ? 0 : aScores.last - aScores.first;
        final bRange = bScores.isEmpty ? 0 : bScores.last - bScores.first;
        return aRange.compareTo(bRange);
      });

      final usedHours = <int>{};
      final organizedStops = List<ItineraryStop>.from(savedState.stops);

      for (final idx in stopIndices) {
        final scores = stopScores[idx]!;
        // Find best available hour (lowest crowd)
        int bestHour = 10; // default fallback
        double bestScore = double.infinity;

        for (final entry in scores.entries) {
          if (!usedHours.contains(entry.key) && entry.value < bestScore) {
            bestScore = entry.value;
            bestHour = entry.key;
          }
        }

        usedHours.add(bestHour);

        // Assign visit time on the start date at the best hour
        final visitTime = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          bestHour,
        );

        organizedStops[idx] = organizedStops[idx].copyWith(
          visitTime: visitTime,
          duration: const Duration(hours: 1),
        );
      }

      // Sort stops chronologically by visit time
      organizedStops.sort((a, b) {
        if (a.visitTime == null && b.visitTime == null) return 0;
        if (a.visitTime == null) return 1;
        if (b.visitTime == null) return -1;
        return a.visitTime!.compareTo(b.visitTime!);
      });

      emit(savedState.copyWith(
        stops: organizedStops,
        isOrganized: true,
      ));
    } catch (e) {
      emit(savedState.copyWith(isOrganized: false));
      emit(ItineraryError('Failed to organize: $e'));
    }
  }
}
