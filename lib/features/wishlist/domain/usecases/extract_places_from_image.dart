import 'package:steply/features/wishlist/domain/entities/wishlist_place.dart';
import 'package:steply/features/wishlist/domain/repositories/wishlist_repository.dart';

class ExtractPlacesFromImage {
  final WishlistRepository repository;

  ExtractPlacesFromImage({required this.repository});

  Future<List<WishlistPlace>> call(String base64Image) {
    return repository.extractPlacesFromImage(base64Image);
  }
}
