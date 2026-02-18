import 'package:steply/features/wishlist/data/datasources/openai_remote_datasource.dart';
import 'package:steply/features/wishlist/domain/entities/wishlist_place.dart';
import 'package:steply/features/wishlist/domain/repositories/wishlist_repository.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  final OpenAiRemoteDatasource datasource;
  final List<WishlistPlace> _places = [];

  WishlistRepositoryImpl({required this.datasource});

  @override
  Future<List<WishlistPlace>> getWishlistPlaces() async {
    return List.unmodifiable(_places);
  }

  @override
  Future<void> addWishlistPlace(WishlistPlace place) async {
    _places.add(place);
  }

  @override
  Future<void> removeWishlistPlace(String id) async {
    _places.removeWhere((p) => p.id == id);
  }

  @override
  Future<List<WishlistPlace>> extractPlacesFromUrl(String url) async {
    final extracted = await datasource.extractPlacesFromUrl(url);
    _places.addAll(extracted);
    return extracted;
  }

  @override
  Future<List<WishlistPlace>> extractPlacesFromImage(
      String base64Image) async {
    final extracted = await datasource.extractPlacesFromImage(base64Image);
    _places.addAll(extracted);
    return extracted;
  }
}
