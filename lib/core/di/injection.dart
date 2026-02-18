import 'package:get_it/get_it.dart';
import 'package:steply/features/analysis/data/datasources/mobility_local_datasource.dart';
import 'package:steply/features/analysis/data/datasources/weather_remote_datasource.dart';
import 'package:steply/features/analysis/data/repositories/itinerary_repository_impl.dart';
import 'package:steply/features/analysis/data/repositories/mobility_repository_impl.dart';
import 'package:steply/features/analysis/data/repositories/weather_repository_impl.dart';
import 'package:steply/features/analysis/domain/repositories/itinerary_repository.dart';
import 'package:steply/features/analysis/domain/repositories/mobility_repository.dart';
import 'package:steply/features/analysis/domain/repositories/weather_repository.dart';
import 'package:steply/features/analysis/domain/usecases/calculate_comfort_index.dart';
import 'package:steply/features/analysis/domain/usecases/create_itinerary.dart';
import 'package:steply/features/analysis/domain/usecases/get_mobility_data.dart';
import 'package:steply/features/analysis/domain/usecases/get_popular_areas.dart';
import 'package:steply/features/analysis/domain/usecases/get_recommendations.dart';
import 'package:steply/features/analysis/domain/usecases/get_temporal_analysis.dart';
import 'package:steply/features/analysis/domain/usecases/get_weather_data.dart';
import 'package:steply/features/analysis/presentation/bloc/comfort_bloc.dart';
import 'package:steply/features/analysis/presentation/bloc/itinerary_bloc.dart';
import 'package:steply/features/map_view/data/repositories/location_repository_impl.dart';
import 'package:steply/features/map_view/domain/repositories/location_repository.dart';
import 'package:steply/features/map_view/domain/usecases/get_heatmap_data.dart';
import 'package:steply/features/map_view/domain/usecases/get_pois.dart';
import 'package:steply/features/map_view/presentation/bloc/map_bloc.dart';
import 'package:steply/features/wishlist/data/datasources/openai_remote_datasource.dart';
import 'package:steply/features/wishlist/data/repositories/wishlist_repository_impl.dart';
import 'package:steply/features/wishlist/domain/repositories/wishlist_repository.dart';
import 'package:steply/features/wishlist/domain/usecases/add_wishlist_place.dart';
import 'package:steply/features/wishlist/domain/usecases/extract_places_from_image.dart';
import 'package:steply/features/wishlist/domain/usecases/extract_places_from_url.dart';
import 'package:steply/features/wishlist/domain/usecases/get_wishlist_places.dart';
import 'package:steply/features/wishlist/domain/usecases/remove_wishlist_place.dart';
import 'package:steply/features/wishlist/presentation/bloc/wishlist_bloc.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Datasources
  getIt.registerLazySingleton<MobilityLocalDatasource>(
    () => MobilityLocalDatasourceImpl(),
  );

  getIt.registerLazySingleton<WeatherRemoteDatasource>(
    () => WeatherRemoteDatasource(),
  );

  // Repositories
  getIt.registerLazySingleton<MobilityRepository>(
    () => MobilityRepositoryImpl(datasource: getIt()),
  );

  getIt.registerLazySingleton<WeatherRepository>(
    () => WeatherRepositoryImpl(datasource: getIt()),
  );

  getIt.registerLazySingleton<ItineraryRepository>(
    () => ItineraryRepositoryImpl(),
  );

  getIt.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(mobilityDatasource: getIt()),
  );

  // Use cases
  getIt.registerLazySingleton(
    () => GetMobilityData(repository: getIt()),
  );

  getIt.registerLazySingleton(
    () => CalculateComfortIndex(repository: getIt()),
  );

  getIt.registerLazySingleton(
    () => CreateItinerary(repository: getIt()),
  );

  getIt.registerLazySingleton(
    () => GetPopularAreas(repository: getIt()),
  );

  getIt.registerLazySingleton(
    () => GetPois(repository: getIt()),
  );

  getIt.registerLazySingleton(
    () => GetHeatmapData(repository: getIt()),
  );

  getIt.registerLazySingleton(
    () => GetTemporalAnalysis(repository: getIt<MobilityRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetWeatherData(repository: getIt()),
  );

  getIt.registerLazySingleton(
    () => GetRecommendations(repository: getIt<MobilityRepository>()),
  );

  // BLoCs
  getIt.registerFactory(
    () => MapBloc(
      getPois: getIt(),
      getHeatmapData: getIt(),
    ),
  );

  getIt.registerFactory(
    () => ItineraryBloc(
      createItinerary: getIt(),
      getPois: getIt(),
      mobilityRepository: getIt(),
    ),
  );

  getIt.registerFactory(
    () => ComfortBloc(
      calculateComfortIndex: getIt(),
      getPopularAreas: getIt(),
      getMobilityData: getIt(),
      getTemporalAnalysis: getIt(),
      getWeatherData: getIt(),
      getRecommendations: getIt(),
    ),
  );

  // Wishlist feature
  getIt.registerLazySingleton<OpenAiRemoteDatasource>(
    () => OpenAiRemoteDatasourceImpl(),
  );

  getIt.registerLazySingleton<WishlistRepository>(
    () => WishlistRepositoryImpl(datasource: getIt()),
  );

  getIt.registerLazySingleton(
    () => GetWishlistPlaces(repository: getIt()),
  );

  getIt.registerLazySingleton(
    () => AddWishlistPlace(repository: getIt()),
  );

  getIt.registerLazySingleton(
    () => RemoveWishlistPlace(repository: getIt()),
  );

  getIt.registerLazySingleton(
    () => ExtractPlacesFromUrl(repository: getIt()),
  );

  getIt.registerLazySingleton(
    () => ExtractPlacesFromImage(repository: getIt()),
  );

  getIt.registerFactory(
    () => WishlistBloc(
      getWishlistPlaces: getIt(),
      extractPlacesFromUrl: getIt(),
      extractPlacesFromImage: getIt(),
      removeWishlistPlace: getIt(),
    ),
  );
}
