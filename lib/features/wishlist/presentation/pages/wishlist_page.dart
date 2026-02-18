import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:steply/core/constants/app_constants.dart';
import 'package:steply/features/analysis/presentation/bloc/itinerary_bloc.dart';
import 'package:steply/features/wishlist/presentation/bloc/wishlist_bloc.dart';
import 'package:steply/features/wishlist/presentation/pages/wishlist_map_page.dart';
import 'package:steply/features/wishlist/presentation/widgets/place_analysis_sheet.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    context.read<WishlistBloc>().add(LoadWishlist());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.navWishlist),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _showMap
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: IconButton(
              icon: Icon(
                _showMap ? Icons.list_rounded : Icons.map_outlined,
                color: _showMap ? AppColors.primary : AppColors.textSecondary,
              ),
              tooltip: _showMap ? 'Show List' : 'Show Map',
              onPressed: () => setState(() => _showMap = !_showMap),
            ),
          ),
        ],
      ),
      body: BlocConsumer<WishlistBloc, WishlistState>(
        listener: (context, state) {
          if (state is WishlistError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
            context.read<WishlistBloc>().add(LoadWishlist());
          }
        },
        builder: (context, state) {
          if (state is WishlistLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is WishlistLoaded) {
            return Stack(
              children: [
                AnimatedSwitcher(
                  duration: AppConstants.mediumAnimation,
                  child: _showMap
                      ? const WishlistMapPage()
                      : _buildListView(context, state),
                ),
                if (state.isExtracting)
                  Container(
                    color: Colors.black38,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius:
                              BorderRadius.circular(AppRadius.xxl),
                          boxShadow: AppShadows.lg,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Discovering places...',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                      color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }

          // Default empty / error
          return _buildEmptyState(context);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.wishlistMarker.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.favorite_outline,
                  size: 40, color: AppColors.wishlistMarker),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Start Your Wishlist',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Save places from anywhere on the web.\nPaste a URL or snap a screenshot.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () =>
                  context.read<WishlistBloc>().add(LoadWishlist()),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(BuildContext context, WishlistLoaded state) {
    if (state.places.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.wishlistMarker.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.favorite_outline,
                    size: 40, color: AppColors.wishlistMarker),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Your wishlist is empty',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tap + to add places from URLs\nor screenshots',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    final dateFormat = DateFormat('MMM d, yyyy');

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 80),
      itemCount: state.places.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final place = state.places[index];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: Colors.black.withOpacity(0.04)),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image header
              if (place.imageUrl != null && place.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xl)),
                  child: Image.network(
                    place.imageUrl!,
                    width: double.infinity,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (place.imageUrl == null ||
                            place.imageUrl!.isEmpty)
                          Padding(
                            padding:
                                const EdgeInsets.only(right: 8),
                            child: Icon(Icons.favorite,
                                size: 18,
                                color: AppColors.wishlistMarker),
                          ),
                        Expanded(
                          child: Text(
                            place.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall,
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              context
                                  .read<WishlistBloc>()
                                  .add(RemovePlace(place.id));
                            }
                          },
                          icon: Icon(Icons.more_horiz,
                              size: 20,
                              color: AppColors.textTertiary),
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline,
                                      color: AppColors.error,
                                      size: 18),
                                  const SizedBox(width: 8),
                                  const Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                    ),
                    if (place.eventDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.amber.withOpacity(0.08),
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event,
                                  size: 13, color: AppColors.amber),
                              const SizedBox(width: 4),
                              Text(
                                place.eventEndDate != null
                                    ? '${dateFormat.format(place.eventDate!)} – ${dateFormat.format(place.eventEndDate!)}'
                                    : dateFormat
                                        .format(place.eventDate!),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm + 4),
                    // Action buttons
                    Row(
                      children: [
                        _ActionChip(
                          icon: Icons.insights_outlined,
                          label: 'Analyze',
                          onTap: () {
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
                                rawSourceContent:
                                    place.rawSourceContent,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _ActionChip(
                          icon: Icons.add_location_alt_outlined,
                          label: 'Add to Trip',
                          onTap: () {
                            context.read<ItineraryBloc>().add(
                                  AddStopByDetails(
                                    name: place.name,
                                    lat: place.latitude,
                                    lng: place.longitude,
                                  ),
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                    'Added to itinerary'),
                                backgroundColor: AppColors.emerald,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xxl)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 12, AppSpacing.lg, AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Add Places',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Discover new places to visit',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Two option cards
                  Row(
                    children: [
                      Expanded(
                        child: _AddOptionCard(
                          icon: Icons.link,
                          title: 'Paste URL',
                          subtitle: 'From any website',
                          gradient: AppColors.primaryGradient,
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _showUrlDialog(context);
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm + 4),
                      Expanded(
                        child: _AddOptionCard(
                          icon: Icons.image_outlined,
                          title: 'Screenshot',
                          subtitle: 'TikTok, Reels, etc.',
                          gradient: AppColors.coralGradient,
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _pickImage(context);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showUrlDialog(BuildContext context) {
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final isSocial = _isSocialMediaUrl(urlController.text);
            return AlertDialog(
              title: const Text('Paste URL'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      labelText: 'URL',
                      hintText: 'https://...',
                    ),
                    keyboardType: TextInputType.url,
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  if (isSocial) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'We\'ll extract captions & metadata automatically.',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(AppStrings.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    final url = urlController.text.trim();
                    if (url.isNotEmpty) {
                      Navigator.pop(dialogContext);
                      context.read<WishlistBloc>().add(
                            ExtractFromUrl(url: url),
                          );
                    }
                  },
                  child: const Text('Extract'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final bytes = await image.readAsBytes();

    if (!context.mounted) return;
    context.read<WishlistBloc>().add(
          ExtractFromImage(imageBytes: bytes),
        );
  }

  bool _isSocialMediaUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('tiktok.com') ||
        lower.contains('instagram.com') ||
        lower.contains('twitter.com') ||
        lower.contains('x.com') ||
        lower.contains('facebook.com') ||
        lower.contains('threads.net') ||
        lower.contains('youtube.com') ||
        lower.contains('youtu.be');
  }
}

// ─── Action Chip Button ───

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.bgLight,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Option Card ───

class _AddOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _AddOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: Colors.black.withOpacity(0.04)),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: AppShadows.glow(gradient.colors.first),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: AppSpacing.sm + 4),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
