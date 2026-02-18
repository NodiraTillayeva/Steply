import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:steply/features/wishlist/domain/entities/wishlist_place.dart';
import 'package:steply/features/wishlist/domain/usecases/extract_places_from_image.dart';
import 'package:steply/features/wishlist/domain/usecases/extract_places_from_url.dart';
import 'package:steply/features/wishlist/domain/usecases/get_wishlist_places.dart';
import 'package:steply/features/wishlist/domain/usecases/remove_wishlist_place.dart';

// Events
abstract class WishlistEvent extends Equatable {
  const WishlistEvent();
  @override
  List<Object?> get props => [];
}

class LoadWishlist extends WishlistEvent {}

class ExtractFromUrl extends WishlistEvent {
  final String url;
  const ExtractFromUrl({required this.url});
  @override
  List<Object?> get props => [url];
}

class ExtractFromImage extends WishlistEvent {
  final List<int> imageBytes;
  const ExtractFromImage({required this.imageBytes});
  @override
  List<Object?> get props => [imageBytes];
}

class RemovePlace extends WishlistEvent {
  final String id;
  const RemovePlace(this.id);
  @override
  List<Object?> get props => [id];
}

class SelectWishlistPlace extends WishlistEvent {
  final WishlistPlace? place;
  const SelectWishlistPlace(this.place);
  @override
  List<Object?> get props => [place];
}

// States
abstract class WishlistState extends Equatable {
  const WishlistState();
  @override
  List<Object?> get props => [];
}

class WishlistInitial extends WishlistState {}

class WishlistLoading extends WishlistState {}

class WishlistLoaded extends WishlistState {
  final List<WishlistPlace> places;
  final WishlistPlace? selectedPlace;
  final bool isExtracting;

  const WishlistLoaded({
    required this.places,
    this.selectedPlace,
    this.isExtracting = false,
  });

  @override
  List<Object?> get props => [places, selectedPlace, isExtracting];

  WishlistLoaded copyWith({
    List<WishlistPlace>? places,
    WishlistPlace? selectedPlace,
    bool clearSelectedPlace = false,
    bool? isExtracting,
  }) {
    return WishlistLoaded(
      places: places ?? this.places,
      selectedPlace:
          clearSelectedPlace ? null : (selectedPlace ?? this.selectedPlace),
      isExtracting: isExtracting ?? this.isExtracting,
    );
  }
}

class WishlistError extends WishlistState {
  final String message;
  const WishlistError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class WishlistBloc extends Bloc<WishlistEvent, WishlistState> {
  final GetWishlistPlaces getWishlistPlaces;
  final ExtractPlacesFromUrl extractPlacesFromUrl;
  final ExtractPlacesFromImage extractPlacesFromImage;
  final RemoveWishlistPlace removeWishlistPlace;

  WishlistBloc({
    required this.getWishlistPlaces,
    required this.extractPlacesFromUrl,
    required this.extractPlacesFromImage,
    required this.removeWishlistPlace,
  }) : super(WishlistInitial()) {
    on<LoadWishlist>(_onLoadWishlist);
    on<ExtractFromUrl>(_onExtractFromUrl);
    on<ExtractFromImage>(_onExtractFromImage);
    on<RemovePlace>(_onRemovePlace);
    on<SelectWishlistPlace>(_onSelectPlace);
  }

  Future<void> _onLoadWishlist(
      LoadWishlist event, Emitter<WishlistState> emit) async {
    emit(WishlistLoading());
    try {
      final places = await getWishlistPlaces();
      emit(WishlistLoaded(places: places));
    } catch (e) {
      emit(WishlistError(e.toString()));
    }
  }

  Future<void> _onExtractFromUrl(
      ExtractFromUrl event, Emitter<WishlistState> emit) async {
    final currentState = state;

    if (currentState is WishlistLoaded) {
      emit(currentState.copyWith(isExtracting: true));
    } else {
      emit(const WishlistLoaded(places: [], isExtracting: true));
    }

    try {
      await extractPlacesFromUrl(event.url);
      final places = await getWishlistPlaces();
      emit(WishlistLoaded(places: places));
    } catch (e) {
      final places = currentState is WishlistLoaded
          ? currentState.places
          : <WishlistPlace>[];
      emit(WishlistLoaded(places: places));
      emit(WishlistError(e.toString()));
    }
  }

  Future<void> _onExtractFromImage(
      ExtractFromImage event, Emitter<WishlistState> emit) async {
    final currentState = state;

    if (currentState is WishlistLoaded) {
      emit(currentState.copyWith(isExtracting: true));
    } else {
      emit(const WishlistLoaded(places: [], isExtracting: true));
    }

    try {
      final base64Image = base64Encode(event.imageBytes);
      await extractPlacesFromImage(base64Image);
      final places = await getWishlistPlaces();
      emit(WishlistLoaded(places: places));
    } catch (e) {
      final places = currentState is WishlistLoaded
          ? currentState.places
          : <WishlistPlace>[];
      emit(WishlistLoaded(places: places));
      emit(WishlistError(e.toString()));
    }
  }

  Future<void> _onRemovePlace(
      RemovePlace event, Emitter<WishlistState> emit) async {
    try {
      await removeWishlistPlace(event.id);
      final places = await getWishlistPlaces();
      emit(WishlistLoaded(places: places));
    } catch (e) {
      emit(WishlistError(e.toString()));
    }
  }

  void _onSelectPlace(
      SelectWishlistPlace event, Emitter<WishlistState> emit) {
    final currentState = state;
    if (currentState is WishlistLoaded) {
      emit(currentState.copyWith(
        selectedPlace: event.place,
        clearSelectedPlace: event.place == null,
      ));
    }
  }
}
