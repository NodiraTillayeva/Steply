import 'package:steply/features/wishlist/domain/entities/wishlist_place.dart';
import 'package:steply/features/wishlist/domain/repositories/wishlist_repository.dart';

class ExtractPlacesFromUrl {
  final WishlistRepository repository;

  ExtractPlacesFromUrl({required this.repository});

  Future<List<WishlistPlace>> call(String url) {
    return repository.extractPlacesFromUrl(url);
  }
}
