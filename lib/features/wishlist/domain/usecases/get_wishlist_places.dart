import 'package:steply/features/wishlist/domain/entities/wishlist_place.dart';
import 'package:steply/features/wishlist/domain/repositories/wishlist_repository.dart';

class GetWishlistPlaces {
  final WishlistRepository repository;

  GetWishlistPlaces({required this.repository});

  Future<List<WishlistPlace>> call() {
    return repository.getWishlistPlaces();
  }
}
