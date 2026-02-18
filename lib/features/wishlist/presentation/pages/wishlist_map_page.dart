import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:steply/core/constants/app_constants.dart';
import 'package:steply/features/analysis/presentation/bloc/itinerary_bloc.dart';
import 'package:steply/features/wishlist/domain/entities/wishlist_place.dart';
import 'package:steply/features/wishlist/presentation/bloc/wishlist_bloc.dart';
import 'package:steply/features/wishlist/presentation/widgets/place_analysis_sheet.dart';
import 'package:intl/intl.dart';

class WishlistMapPage extends StatelessWidget {
  const WishlistMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WishlistBloc, WishlistState>(
      builder: (context, state) {
        final places =
            state is WishlistLoaded ? state.places : <WishlistPlace>[];
        final selectedPlace =
            state is WishlistLoaded ? state.selectedPlace : null;

        LatLng center = AppConstants.nagoyaCenter;
        double zoom = AppConstants.defaultZoom;

        if (places.isNotEmpty) {
          final avgLat =
              places.map((p) => p.latitude).reduce((a, b) => a + b) /
                  places.length;
          final avgLng =
              places.map((p) => p.longitude).reduce((a, b) => a + b) /
                  places.length;
          center = LatLng(avgLat, avgLng);
        }

        if (selectedPlace != null) {
          center = LatLng(selectedPlace.latitude, selectedPlace.longitude);
          zoom = 15.0;
        }

        return Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: zoom,
                minZoom: 3.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: AppConstants.osmTileUrl,
                  userAgentPackageName: 'com.steply.app',
                ),
                MarkerLayer(
                  markers: places.map((place) {
                    final isSelected = selectedPlace?.id == place.id;
                    return Marker(
                      point: LatLng(place.latitude, place.longitude),
                      width: isSelected ? 52 : 44,
                      height: isSelected ? 52 : 44,
                      child: GestureDetector(
                        onTap: () {
                          context
                              .read<WishlistBloc>()
                              .add(SelectWishlistPlace(place));
                        },
                        child: AnimatedContainer(
                          duration: AppConstants.mediumAnimation,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.wishlistMarker,
                              width: isSelected ? 3 : 2,
                            ),
                            boxShadow: isSelected
                                ? AppShadows.glow(AppColors.wishlistMarker)
                                : AppShadows.sm,
                          ),
                          child: Icon(
                            Icons.favorite,
                            color: AppColors.wishlistMarker,
                            size: isSelected ? 24 : 18,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            if (selectedPlace != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _PlaceDetailCard(
                  place: selectedPlace,
                  onClose: () {
                    context
                        .read<WishlistBloc>()
                        .add(const SelectWishlistPlace(null));
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PlaceDetailCard extends StatelessWidget {
  final WishlistPlace place;
  final VoidCallback onClose;

  const _PlaceDetailCard({required this.place, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppShadows.lg,
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image preview
          if (place.imageUrl != null && place.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xxl)),
              child: Image.network(
                place.imageUrl!,
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite,
                        color: AppColors.wishlistMarker, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        place.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    GestureDetector(
                      onTap: onClose,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close,
                            size: 16, color: AppColors.textTertiary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  place.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                ),
                if (place.eventDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.event,
                          size: 13, color: AppColors.amber),
                      const SizedBox(width: 4),
                      Text(
                        place.eventEndDate != null
                            ? '${dateFormat.format(place.eventDate!)} – ${dateFormat.format(place.eventEndDate!)}'
                            : dateFormat.format(place.eventDate!),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.amber,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.sm + 4),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => PlaceAnalysisSheet(
                              name: place.name,
                              lat: place.latitude,
                              lng: place.longitude,
                              sourceUrl: place.sourceUrl,
                              description: place.description,
                              localTips: place.localTips,
                              rawSourceContent: place.rawSourceContent,
                            ),
                          );
                        },
                        icon: const Icon(Icons.insights_outlined, size: 16),
                        label: const Text('Analyze'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          context.read<ItineraryBloc>().add(
                                AddStopByDetails(
                                  name: place.name,
                                  lat: place.latitude,
                                  lng: place.longitude,
                                ),
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Added to itinerary'),
                              backgroundColor: AppColors.emerald,
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_location_alt, size: 16),
                        label: const Text('Add to Trip'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
