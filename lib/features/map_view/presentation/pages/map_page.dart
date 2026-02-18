import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:steply/core/constants/app_constants.dart';
import 'package:steply/features/map_view/domain/entities/poi.dart';
import 'package:steply/features/map_view/presentation/bloc/map_bloc.dart';
import 'package:steply/features/wishlist/domain/entities/wishlist_place.dart';
import 'package:steply/features/wishlist/presentation/bloc/wishlist_bloc.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    context.read<MapBloc>().add(LoadMap());
    final wishlistState = context.read<WishlistBloc>().state;
    if (wishlistState is! WishlistLoaded) {
      context.read<WishlistBloc>().add(LoadWishlist());
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _categoryColor(PoiCategory category) {
    switch (category) {
      case PoiCategory.attraction:
        return AppColors.poiAttraction;
      case PoiCategory.restaurant:
        return AppColors.poiRestaurant;
      case PoiCategory.shopping:
        return AppColors.poiShopping;
      case PoiCategory.transport:
        return AppColors.poiTransport;
    }
  }

  IconData _categoryIcon(PoiCategory category) {
    switch (category) {
      case PoiCategory.attraction:
        return Icons.museum;
      case PoiCategory.restaurant:
        return Icons.restaurant;
      case PoiCategory.shopping:
        return Icons.shopping_bag;
      case PoiCategory.transport:
        return Icons.train;
    }
  }

  String _categoryLabel(PoiCategory category) {
    switch (category) {
      case PoiCategory.attraction:
        return 'Attraction';
      case PoiCategory.restaurant:
        return 'Restaurant';
      case PoiCategory.shopping:
        return 'Shopping';
      case PoiCategory.transport:
        return 'Transport';
    }
  }

  void _showPoiDetails(BuildContext context, Poi poi) {
    context.read<MapBloc>().add(SelectPoi(poi));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PremiumPoiSheet(
        poi: poi,
        color: _categoryColor(poi.category),
        icon: _categoryIcon(poi.category),
        label: _categoryLabel(poi.category),
      ),
    );
  }

  void _showWishlistPlaceDetails(BuildContext context, WishlistPlace place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PremiumWishlistSheet(place: place),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<MapBloc, MapState>(
        builder: (context, state) {
          if (state is MapLoading || state is MapInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MapError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off,
                        size: 48, color: AppColors.textTertiary),
                    const SizedBox(height: AppSpacing.md),
                    Text(state.message,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      onPressed: () =>
                          context.read<MapBloc>().add(LoadMap()),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text(AppStrings.retry),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is MapLoaded) {
            final tileUrl = state.useSatellite
                ? AppConstants.esriSatelliteTileUrl
                : AppConstants.osmTileUrl;

            return Stack(
              children: [
                // ─── Full-screen Map ───
                BlocBuilder<WishlistBloc, WishlistState>(
                  builder: (context, wishlistState) {
                    final wishlistPlaces = wishlistState is WishlistLoaded
                        ? wishlistState.places
                        : <WishlistPlace>[];

                    return FlutterMap(
                      options: const MapOptions(
                        initialCenter: AppConstants.nagoyaCenter,
                        initialZoom: AppConstants.defaultZoom,
                        minZoom: AppConstants.minZoom,
                        maxZoom: AppConstants.maxZoom,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: tileUrl,
                          userAgentPackageName: 'com.steply.app',
                        ),
                        // Soft animated heatmap layer
                        CircleLayer(
                          circles: state.heatmapPoints.map((hp) {
                            return CircleMarker(
                              point: LatLng(hp.latitude, hp.longitude),
                              radius: AppConstants.heatmapRadius *
                                  hp.intensity *
                                  1.2,
                              color: Color.lerp(
                                AppColors.accent.withOpacity(0.12),
                                AppColors.coral.withOpacity(0.35),
                                hp.intensity,
                              )!,
                              borderStrokeWidth: 0,
                            );
                          }).toList(),
                        ),
                        // Premium POI markers
                        MarkerLayer(
                          markers: state.pois.map((poi) {
                            return Marker(
                              point: LatLng(poi.latitude, poi.longitude),
                              width: 44,
                              height: 44,
                              child: GestureDetector(
                                onTap: () => _showPoiDetails(context, poi),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _categoryColor(poi.category),
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _categoryColor(poi.category)
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                      BoxShadow(
                                        color: _categoryColor(poi.category)
                                            .withOpacity(0.1),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _categoryIcon(poi.category),
                                    color: _categoryColor(poi.category),
                                    size: 20,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        // Wishlist markers
                        if (wishlistPlaces.isNotEmpty)
                          MarkerLayer(
                            markers: wishlistPlaces.map((place) {
                              return Marker(
                                point: LatLng(
                                    place.latitude, place.longitude),
                                width: 46,
                                height: 46,
                                child: GestureDetector(
                                  onTap: () =>
                                      _showWishlistPlaceDetails(
                                          context, place),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.saved,
                                        width: 2.5,
                                      ),
                                      boxShadow:
                                          AppShadows.glow(AppColors.saved),
                                    ),
                                    child: const Icon(
                                      Icons.favorite,
                                      color: AppColors.saved,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    );
                  },
                ),

                // ─── TOP: Logo + Floating glass search bar ───
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  right: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.glassWhite,
                          borderRadius:
                              BorderRadius.circular(AppRadius.xxl),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.5)),
                          boxShadow: AppShadows.md,
                        ),
                        child: Row(
                          children: [
                            // STEPLY logo mark
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Center(
                                child: Text(
                                  'S',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                AppStrings.mapSearch,
                                style: TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome,
                                      size: 12, color: AppColors.accent),
                                  const SizedBox(width: 4),
                                  Text(
                                    'AI',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ─── Satellite toggle ───
                Positioned(
                  top: MediaQuery.of(context).padding.top + 76,
                  right: 16,
                  child: _GlassIconButton(
                    icon: state.useSatellite
                        ? Icons.map_outlined
                        : Icons.satellite_alt,
                    isActive: state.useSatellite,
                    onTap: () => context
                        .read<MapBloc>()
                        .add(ToggleSatelliteView()),
                  ),
                ),

                // ─── AI suggestion chip ───
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                        child: BackdropFilter(
                          filter:
                              ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                              boxShadow: AppShadows.md,
                              border: Border.all(
                                color: AppColors.accent.withOpacity(
                                    0.15 +
                                        _pulseController.value * 0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.accent.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.auto_awesome,
                                      size: 16, color: AppColors.accent),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        AppStrings.smartTiming,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.accent,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Less crowded now. Great time to explore!',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right,
                                    size: 18,
                                    color: AppColors.textTertiary),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ─── Glass Icon Button ───

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _GlassIconButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AnimatedContainer(
            duration: AppConstants.shortAnimation,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary
                  : Colors.white.withOpacity(0.88),
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: AppShadows.sm,
              border: Border.all(
                color: isActive
                    ? AppColors.primary
                    : Colors.white.withOpacity(0.5),
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Premium POI Bottom Sheet ───

class _PremiumPoiSheet extends StatelessWidget {
  final Poi poi;
  final Color color;
  final IconData icon;
  final String label;

  const _PremiumPoiSheet({
    required this.poi,
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppShadows.lg,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poi.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.08),
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          label.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              poi.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

// ─── Premium Wishlist Place Sheet ───

class _PremiumWishlistSheet extends StatelessWidget {
  final WishlistPlace place;

  const _PremiumWishlistSheet({required this.place});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.7,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              if (place.imageUrl != null && place.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xxl)),
                  child: Image.network(
                    place.imageUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderImage(),
                  ),
                )
              else
                _placeholderImage(),

              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.favorite,
                            color: AppColors.saved, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            place.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.saved.withOpacity(0.08),
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        'WISHLIST',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.saved,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      place.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                    ),
                    if (place.localTips.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Tips',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...place.localTips.map(
                        (tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: AppColors.amber.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.lightbulb_outline,
                                    size: 12, color: AppColors.amber),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.saved.withOpacity(0.08),
            AppColors.saved.withOpacity(0.03),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      child: const Center(
        child: Icon(Icons.favorite, size: 40, color: AppColors.saved),
      ),
    );
  }
}
