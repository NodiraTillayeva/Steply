import 'package:steply/features/wishlist/domain/repositories/wishlist_repository.dart';

class RemoveWishlistPlace {
  final WishlistRepository repository;

  RemoveWishlistPlace({required this.repository});

  Future<void> call(String id) {
    return repository.removeWishlistPlace(id);
  }
}
