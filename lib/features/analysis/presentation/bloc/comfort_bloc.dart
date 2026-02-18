import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:steply/features/analysis/domain/entities/comfort_index.dart';
import 'package:steply/features/analysis/domain/entities/mobility_data_point.dart';
import 'package:steply/features/analysis/domain/entities/popular_area.dart';
import 'package:steply/features/analysis/domain/entities/recommendation.dart';
import 'package:steply/features/analysis/domain/entities/temporal_analysis.dart';
import 'package:steply/features/analysis/domain/entities/weather_data.dart';
import 'package:steply/features/analysis/domain/usecases/calculate_comfort_index.dart';
import 'package:steply/features/analysis/domain/usecases/get_mobility_data.dart';
import 'package:steply/features/analysis/domain/usecases/get_popular_areas.dart';
import 'package:steply/features/analysis/domain/usecases/get_recommendations.dart';
import 'package:steply/features/analysis/domain/usecases/get_temporal_analysis.dart';
import 'package:steply/features/analysis/domain/usecases/get_weather_data.dart';

// Events
abstract class ComfortEvent extends Equatable {
  const ComfortEvent();

  @override
  List<Object?> get props => [];
}

class LoadAnalysis extends ComfortEvent {}

class LoadEnhancedAnalysis extends ComfortEvent {}

class CalculateComfortForLocation extends ComfortEvent {
  final double lat;
  final double lng;

  const CalculateComfortForLocation(this.lat, this.lng);

  @override
  List<Object?> get props => [lat, lng];
}

// States
abstract class ComfortState extends Equatable {
  const ComfortState();

  @override
  List<Object?> get props => [];
}

class ComfortInitial extends ComfortState {}

class ComfortLoading extends ComfortState {}

class ComfortLoaded extends ComfortState {
  final List<MobilityDataPoint> mobilityData;
  final List<PopularArea> popularAreas;
  final ComfortIndex? comfortIndex;
  final TemporalAnalysis? temporalAnalysis;
  final List<HourlyWeather>? weatherData;
  final HourlyWeather? currentWeather;
  final List<Recommendation>? recommendations;
  final bool isWeatherLoading;
  final String? weatherError;

  const ComfortLoaded({
    required this.mobilityData,
    required this.popularAreas,
    this.comfortIndex,
    this.temporalAnalysis,
    this.weatherData,
    this.currentWeather,
    this.recommendations,
    this.isWeatherLoading = false,
    this.weatherError,
  });

  @override
  List<Object?> get props => [
        mobilityData,
        popularAreas,
        comfortIndex,
        temporalAnalysis,
        weatherData,
        currentWeather,
        recommendations,
        isWeatherLoading,
        weatherError,
      ];

  ComfortLoaded copyWith({
    List<MobilityDataPoint>? mobilityData,
    List<PopularArea>? popularAreas,
    ComfortIndex? comfortIndex,
    TemporalAnalysis? temporalAnalysis,
    List<HourlyWeather>? weatherData,
    HourlyWeather? currentWeather,
    List<Recommendation>? recommendations,
    bool? isWeatherLoading,
    String? weatherError,
    bool clearWeatherError = false,
  }) {
    return ComfortLoaded(
      mobilityData: mobilityData ?? this.mobilityData,
      popularAreas: popularAreas ?? this.popularAreas,
      comfortIndex: comfortIndex ?? this.comfortIndex,
      temporalAnalysis: temporalAnalysis ?? this.temporalAnalysis,
      weatherData: weatherData ?? this.weatherData,
      currentWeather: currentWeather ?? this.currentWeather,
      recommendations: recommendations ?? this.recommendations,
      isWeatherLoading: isWeatherLoading ?? this.isWeatherLoading,
      weatherError: clearWeatherError ? null : (weatherError ?? this.weatherError),
    );
  }
}

class ComfortError extends ComfortState {
  final String message;

  const ComfortError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ComfortBloc extends Bloc<ComfortEvent, ComfortState> {
  final CalculateComfortIndex calculateComfortIndex;
  final GetPopularAreas getPopularAreas;
  final GetMobilityData getMobilityData;
  final GetTemporalAnalysis getTemporalAnalysis;
  final GetWeatherData getWeatherData;
  final GetRecommendations getRecommendations;

  ComfortBloc({
    required this.calculateComfortIndex,
    required this.getPopularAreas,
    required this.getMobilityData,
    required this.getTemporalAnalysis,
    required this.getWeatherData,
    required this.getRecommendations,
  }) : super(ComfortInitial()) {
    on<LoadAnalysis>(_onLoadAnalysis);
    on<LoadEnhancedAnalysis>(_onLoadEnhancedAnalysis);
    on<CalculateComfortForLocation>(_onCalculateComfort);
  }

  Future<void> _onLoadAnalysis(
      LoadAnalysis event, Emitter<ComfortState> emit) async {
    emit(ComfortLoading());
    try {
      final mobilityData = await getMobilityData();
      final popularAreas = await getPopularAreas();
      emit(ComfortLoaded(
        mobilityData: mobilityData,
        popularAreas: popularAreas,
      ));
    } catch (e) {
      emit(ComfortError(e.toString()));
    }
  }

  Future<void> _onLoadEnhancedAnalysis(
      LoadEnhancedAnalysis event, Emitter<ComfortState> emit) async {
    emit(ComfortLoading());
    try {
      // Phase 1: Load local data instantly
      final mobilityData = await getMobilityData();
      final popularAreas = await getPopularAreas();
      final temporalAnalysis = await getTemporalAnalysis();

      emit(ComfortLoaded(
        mobilityData: mobilityData,
        popularAreas: popularAreas,
        temporalAnalysis: temporalAnalysis,
        isWeatherLoading: true,
      ));

      // Phase 2: Fetch weather data in background
      try {
        final weatherData = await getWeatherData();
        HourlyWeather? currentWeather;
        try {
          currentWeather = await getWeatherData.callCurrent();
        } catch (_) {
          // Current weather is optional
        }

        final recommendations = await getRecommendations(weatherData);

        emit(ComfortLoaded(
          mobilityData: mobilityData,
          popularAreas: popularAreas,
          temporalAnalysis: temporalAnalysis,
          weatherData: weatherData,
          currentWeather: currentWeather,
          recommendations: recommendations,
          isWeatherLoading: false,
        ));
      } catch (e) {
        // Weather failure is non-fatal
        emit(ComfortLoaded(
          mobilityData: mobilityData,
          popularAreas: popularAreas,
          temporalAnalysis: temporalAnalysis,
          isWeatherLoading: false,
          weatherError: e.toString(),
        ));
      }
    } catch (e) {
      emit(ComfortError(e.toString()));
    }
  }

  Future<void> _onCalculateComfort(
      CalculateComfortForLocation event, Emitter<ComfortState> emit) async {
    final currentState = state;
    if (currentState is ComfortLoaded) {
      try {
        final comfort = await calculateComfortIndex(event.lat, event.lng);
        emit(currentState.copyWith(comfortIndex: comfort));
      } catch (e) {
        emit(ComfortError(e.toString()));
      }
    }
  }
}
