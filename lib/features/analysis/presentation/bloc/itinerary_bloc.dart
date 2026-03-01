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

class ResetTrip extends ItineraryEvent {}

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
    on<ResetTrip>(_onResetTrip);
    on<OrganizeItinerary>(_onOrganizeItinerary);
  }

  Future<void> _onLoadPois(
      LoadPois event, Emitter<ItineraryState> emit) async {
    // Preserve existing stops if already editing
    final currentState = state;
    final existingStops = currentState is ItineraryEditing
        ? currentState.stops
        : const <ItineraryStop>[];
    final existingStartDate =
        currentState is ItineraryEditing ? currentState.startDate : null;
    final existingEndDate =
        currentState is ItineraryEditing ? currentState.endDate : null;
    final existingIsOrganized =
        currentState is ItineraryEditing ? currentState.isOrganized : false;

    emit(ItineraryLoading());
    try {
      final pois = await getPois();
      emit(ItineraryEditing(
        availablePois: pois,
        stops: existingStops,
        startDate: existingStartDate,
        endDate: existingEndDate,
        isOrganized: existingIsOrganized,
      ));
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

  Future<void> _onResetTrip(
      ResetTrip event, Emitter<ItineraryState> emit) async {
    try {
      final pois = await getPois();
      emit(ItineraryEditing(availablePois: pois, stops: const []));
    } catch (e) {
      emit(ItineraryError(e.toString()));
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
      final now = DateTime.now();

      // Build list of available (day, hour) time slots across the trip
      final availableSlots = <({DateTime date, int hour})>[];
      var tripDay = startDate;
      while (!tripDay.isAfter(endDate)) {
        final isToday = tripDay.year == now.year &&
            tripDay.month == now.month &&
            tripDay.day == now.day;
        // Only consider hours that haven't passed yet
        final earliestHour = isToday ? max(now.hour + 1, 8) : 8;
        for (int hour = earliestHour; hour <= 20; hour++) {
          availableSlots.add((date: tripDay, hour: hour));
        }
        tripDay = tripDay.add(const Duration(days: 1));
      }

      // Collect crowd scores for each stop at each available slot
      final stopSlotScores =
          <int, Map<int, double>>{}; // stopIdx -> {slotIdx -> score}

      for (int i = 0; i < savedState.stops.length; i++) {
        final stop = savedState.stops[i];
        final analysis = await mobilityRepository.getLocalTemporalAnalysis(
          stop.latitude,
          stop.longitude,
        );

        final slotScores = <int, double>{};
        for (int s = 0; s < availableSlots.length; s++) {
          final slot = availableSlots[s];
          final dayIdx = (slot.date.weekday - 1) % 7;
          slotScores[s] = analysis.temporalHeatmap[dayIdx][slot.hour].toDouble();
        }
        stopSlotScores[i] = slotScores;
      }

      // Greedy assignment: assign each stop to the best available slot
      final stopIndices = List.generate(savedState.stops.length, (i) => i);

      // Sort by most constrained first (smallest range between best and worst)
      stopIndices.sort((a, b) {
        final aScores = stopSlotScores[a]!.values.toList()..sort();
        final bScores = stopSlotScores[b]!.values.toList()..sort();
        final aRange = aScores.isEmpty ? 0.0 : aScores.last - aScores.first;
        final bRange = bScores.isEmpty ? 0.0 : bScores.last - bScores.first;
        return aRange.compareTo(bRange);
      });

      final usedSlots = <int>{};
      final organizedStops = List<ItineraryStop>.from(savedState.stops);

      for (final idx in stopIndices) {
        final scores = stopSlotScores[idx]!;
        // Find best available slot (lowest crowd)
        int bestSlotIdx = 0;
        double bestScore = double.infinity;

        for (final entry in scores.entries) {
          if (!usedSlots.contains(entry.key) && entry.value < bestScore) {
            bestScore = entry.value;
            bestSlotIdx = entry.key;
          }
        }

        usedSlots.add(bestSlotIdx);

        final bestSlot = availableSlots[bestSlotIdx];
        final visitTime = DateTime(
          bestSlot.date.year,
          bestSlot.date.month,
          bestSlot.date.day,
          bestSlot.hour,
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
