import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:steply/core/constants/app_constants.dart';
import 'package:steply/features/wishlist/domain/entities/wishlist_place.dart';
import 'package:steply/features/wishlist/presentation/bloc/wishlist_bloc.dart';
import 'package:steply/features/analysis/presentation/bloc/itinerary_bloc.dart';
import 'package:steply/features/wishlist/presentation/widgets/place_analysis_sheet.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final wishlistState = context.read<WishlistBloc>().state;
    if (wishlistState is! WishlistLoaded) {
      context.read<WishlistBloc>().add(LoadWishlist());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Premium header
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.bgLight,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: AppSpacing.lg, bottom: 16),
              title: Text(
                AppStrings.profileTitle,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontSize: 18),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.warmBgGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 60),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.glow(AppColors.primary),
                          ),
                          child: const Icon(Icons.person_outline,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Explorer',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Nagoya, Japan',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
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
          ),

          // Tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textTertiary,
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w400),
                tabs: const [
                  Tab(text: 'Saved'),
                  Tab(text: 'Preferences'),
                  Tab(text: 'Settings'),
                ],
              ),
            ),
          ),

          // Tab content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SavedPlacesTab(),
                _PreferencesTab(),
                _SettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Saved Places Tab ───

class _SavedPlacesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WishlistBloc, WishlistState>(
      builder: (context, state) {
        if (state is WishlistLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final places =
            state is WishlistLoaded ? state.places : <WishlistPlace>[];

        if (places.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.saved.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.bookmark_outline,
                        size: 36, color: AppColors.saved),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'No saved places yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Places you save from the map will appear here.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: places.length,
          itemBuilder: (context, index) {
            final place = places[index];
            return _SavedPlaceCard(place: place);
          },
        );
      },
    );
  }
}

class _SavedPlaceCard extends StatelessWidget {
  final WishlistPlace place;

  const _SavedPlaceCard({required this.place});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: AppShadows.sm,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => PlaceAnalysisSheet(
                name: place.name,
                lat: place.latitude,
                lng: place.longitude,
                description: place.description,
                localTips: place.localTips,
                sourceUrl: place.sourceUrl,
                rawSourceContent: place.rawSourceContent,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Image or placeholder
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.saved.withOpacity(0.1),
                          AppColors.primary.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: place.imageUrl != null &&
                            place.imageUrl!.isNotEmpty
                        ? Image.network(place.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                                Icons.place,
                                color: AppColors.saved,
                                size: 24))
                        : Icon(Icons.place,
                            color: AppColors.saved, size: 24),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        place.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Actions
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      size: 18, color: AppColors.textTertiary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'add_trip',
                      child: Row(
                        children: [
                          Icon(Icons.add_circle_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Add to Trip'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'analyze',
                      child: Row(
                        children: [
                          Icon(Icons.analytics_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Analyze'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 18, color: AppColors.error),
                          const SizedBox(width: 8),
                          Text('Remove',
                              style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'add_trip') {
                      context.read<ItineraryBloc>().add(
                            AddStopByDetails(
                              name: place.name,
                              lat: place.latitude,
                              lng: place.longitude,
                            ),
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${place.name} added to trip'),
                          backgroundColor: AppColors.emerald,
                        ),
                      );
                    } else if (value == 'analyze') {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => PlaceAnalysisSheet(
                          name: place.name,
                          lat: place.latitude,
                          lng: place.longitude,
                          description: place.description,
                          localTips: place.localTips,
                          sourceUrl: place.sourceUrl,
                          rawSourceContent: place.rawSourceContent,
                        ),
                      );
                    } else if (value == 'remove') {
                      context
                          .read<WishlistBloc>()
                          .add(RemovePlace(place.id));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Preferences Tab ───

class _PreferencesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _PreferenceSection(
          title: 'Travel Style',
          children: [
            _PreferenceChip(label: 'Cultural', icon: Icons.museum, selected: true),
            _PreferenceChip(label: 'Foodie', icon: Icons.restaurant),
            _PreferenceChip(label: 'Nature', icon: Icons.park),
            _PreferenceChip(label: 'Shopping', icon: Icons.shopping_bag),
            _PreferenceChip(label: 'Nightlife', icon: Icons.nightlife),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _PreferenceSection(
          title: 'Crowd Preference',
          children: [
            _PreferenceChip(
                label: 'Avoid Crowds', icon: Icons.people_outline, selected: true),
            _PreferenceChip(label: 'Don\'t Mind', icon: Icons.groups),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _PreferenceSection(
          title: 'Pace',
          children: [
            _PreferenceChip(label: 'Relaxed', icon: Icons.spa),
            _PreferenceChip(
                label: 'Balanced', icon: Icons.balance, selected: true),
            _PreferenceChip(label: 'Active', icon: Icons.directions_run),
          ],
        ),
      ],
    );
  }
}

class _PreferenceSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _PreferenceSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm + 4),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: children,
        ),
      ],
    );
  }
}

class _PreferenceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;

  const _PreferenceChip({
    required this.label,
    required this.icon,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppConstants.shortAnimation,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: selected ? AppColors.primary : Colors.black.withOpacity(0.06),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 16,
              color: selected ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings Tab ───

class _SettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _SettingsCard(
          children: [
            _SettingsTile(
              icon: Icons.map_outlined,
              title: 'Map Style',
              subtitle: 'Satellite',
              color: AppColors.primary,
            ),
            _SettingsDivider(),
            _SettingsTile(
              icon: Icons.palette_outlined,
              title: 'Appearance',
              subtitle: 'System',
              color: AppColors.accent,
            ),
            _SettingsDivider(),
            _SettingsTile(
              icon: Icons.language,
              title: 'Language',
              subtitle: 'English',
              color: AppColors.emerald,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _SettingsCard(
          children: [
            _SettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Smart alerts',
              color: AppColors.amber,
            ),
            _SettingsDivider(),
            _SettingsTile(
              icon: Icons.location_on_outlined,
              title: 'Location',
              subtitle: 'While using',
              color: AppColors.coral,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _SettingsCard(
          children: [
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'About STEPLY',
              subtitle: 'v1.0.0',
              color: AppColors.textSecondary,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Column(
            children: [
              Text(
                'STEPLY',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.appTagline,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: AppShadows.sm,
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
          Text(
            subtitle,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right,
              size: 16, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Divider(
        height: 1,
        color: Colors.black.withOpacity(0.04),
      ),
    );
  }
}

// ─── Tab Bar Delegate ───

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.bgLight,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
