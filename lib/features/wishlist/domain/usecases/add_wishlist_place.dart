import 'package:steply/features/wishlist/domain/entities/wishlist_place.dart';
import 'package:steply/features/wishlist/domain/repositories/wishlist_repository.dart';

class AddWishlistPlace {
  final WishlistRepository repository;

  AddWishlistPlace({required this.repository});

  Future<void> call(WishlistPlace place) {
    return repository.addWishlistPlace(place);
  }
}
