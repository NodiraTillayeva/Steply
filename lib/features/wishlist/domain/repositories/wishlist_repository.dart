import 'package:steply/features/wishlist/domain/entities/wishlist_place.dart';

abstract class WishlistRepository {
  Future<List<WishlistPlace>> getWishlistPlaces();
  Future<void> addWishlistPlace(WishlistPlace place);
  Future<void> removeWishlistPlace(String id);
  Future<List<WishlistPlace>> extractPlacesFromUrl(String url);
  Future<List<WishlistPlace>> extractPlacesFromImage(String base64Image);
}
