import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:steply/core/constants/app_constants.dart';
import 'package:steply/features/analysis/domain/entities/itinerary.dart';
import 'package:steply/features/analysis/presentation/bloc/itinerary_bloc.dart';
import 'package:steply/features/map_view/domain/entities/poi.dart';

class ItineraryPage extends StatefulWidget {
  const ItineraryPage({super.key});

  @override
  State<ItineraryPage> createState() => _ItineraryPageState();
}

class _ItineraryPageState extends State<ItineraryPage> {
  @override
  void initState() {
    super.initState();
    context.read<ItineraryBloc>().add(LoadPois());
  }

  void _showAddStopSheet(BuildContext context, List<Poi> pois) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xxl)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Choose a Place',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: pois.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (ctx, index) {
                  final poi = pois[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border:
                          Border.all(color: Colors.black.withOpacity(0.04)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              _categoryColor(poi.category).withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(
                          _categoryIcon(poi.category),
                          color: _categoryColor(poi.category),
                          size: 20,
                        ),
                      ),
                      title: Text(poi.name,
                          style: Theme.of(context).textTheme.titleSmall),
                      subtitle: Text(
                        poi.category.name,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textTertiary),
                      ),
                      trailing: Icon(Icons.add_circle_outline,
                          color: AppColors.primary, size: 22),
                      onTap: () {
                        context.read<ItineraryBloc>().add(AddStop(poi));
                        Navigator.pop(ctx);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showDateSelectionSheet(BuildContext context) {
    final now = DateTime.now();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xxl)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 12, AppSpacing.lg, AppSpacing.xl),
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
                AppStrings.whenAreYouGoing,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'We\'ll optimize your schedule based on crowd data.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textTertiary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  _DateChip(
                    label: AppStrings.today,
                    icon: Icons.today,
                    onTap: () {
                      final today =
                          DateTime(now.year, now.month, now.day);
                      context.read<ItineraryBloc>().add(SelectTripDates(
                            startDate: today,
                            endDate: today,
                          ));
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _DateChip(
                    label: AppStrings.thisWeekend,
                    icon: Icons.weekend_outlined,
                    onTap: () {
                      final daysUntilSaturday =
                          (DateTime.saturday - now.weekday) % 7;
                      final saturday = DateTime(now.year, now.month,
                          now.day + daysUntilSaturday);
                      final sunday =
                          saturday.add(const Duration(days: 1));
                      context.read<ItineraryBloc>().add(SelectTripDates(
                            startDate: saturday,
                            endDate: sunday,
                          ));
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _DateChip(
                    label: AppStrings.thisMonth,
                    icon: Icons.calendar_month_outlined,
                    onTap: () {
                      final firstDay =
                          DateTime(now.year, now.month, 1);
                      final lastDay =
                          DateTime(now.year, now.month + 1, 0);
                      context.read<ItineraryBloc>().add(SelectTripDates(
                            startDate: firstDay,
                            endDate: lastDay,
                          ));
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 365)),
                      initialDateRange: DateTimeRange(
                        start: now,
                        end: now.add(const Duration(days: 2)),
                      ),
                    );
                    if (picked != null && context.mounted) {
                      context.read<ItineraryBloc>().add(SelectTripDates(
                            startDate: picked.start,
                            endDate: picked.end,
                          ));
                    }
                  },
                  icon: const Icon(Icons.date_range, size: 18),
                  label: const Text(AppStrings.chooseADate),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSaveDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.itineraryCreate),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'My Nagoya Adventure',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.isNotEmpty
                  ? controller.text
                  : 'My Itinerary';
              context.read<ItineraryBloc>().add(SaveItinerary(name));
              Navigator.pop(ctx);
            },
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
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

  String _formatDateRange(DateTime start, DateTime end) {
    final fmt = DateFormat('MMM d');
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return fmt.format(start);
    }
    return '${fmt.format(start)} – ${fmt.format(end)}';
  }

  String _formatVisitTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  // ─── Empty State: Plan a Trip ───

  Widget _buildPlanATripEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon cluster
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: AppShadows.glow(AppColors.primary),
              ),
              child: const Icon(Icons.flight_takeoff,
                  size: 44, color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              AppStrings.planATrip,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Pick your travel dates and we\'ll help you\nbuild the perfect day in Nagoya.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => _showDateSelectionSheet(context),
              icon: const Icon(Icons.calendar_today, size: 18),
              label: const Text('Get Started'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 16),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Date Banner ───

  Widget _buildDateBanner(BuildContext context, ItineraryEditing state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today,
              size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(
            _formatDateRange(state.startDate!, state.endDate!),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showDateSelectionSheet(context),
            child: Text(
              'Change',
              style: TextStyle(
                color: AppColors.primary.withOpacity(0.7),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stop Card ───

  Widget _buildStopCard(
      BuildContext context, ItineraryStop stop, int index, bool isOrganized) {
    return Container(
      key: ValueKey('$index-${stop.name}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: AppShadows.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
        child: Row(
          children: [
            // Number circle
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: isOrganized
                    ? AppColors.emeraldGradient
                    : AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  if (stop.visitTime != null)
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 13, color: AppColors.emerald),
                        const SizedBox(width: 4),
                        Text(
                          _formatVisitTime(stop.visitTime!),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.emerald,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '  ·  ${stop.duration.inMinutes} min',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      '${stop.duration.inMinutes} min',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
            // Delete
            IconButton(
              icon: Icon(Icons.remove_circle_outline,
                  color: AppColors.textTertiary, size: 20),
              onPressed: () =>
                  context.read<ItineraryBloc>().add(RemoveStop(index)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.itineraryTitle),
      ),
      body: BlocConsumer<ItineraryBloc, ItineraryState>(
        listener: (context, state) {
          if (state is ItinerarySaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Journey saved!'),
                backgroundColor: AppColors.emerald,
              ),
            );
          }
          if (state is ItineraryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is ItineraryLoading || state is ItineraryInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ItineraryOrganizing) {
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
                        gradient: AppColors.emeraldGradient,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.glow(AppColors.emerald),
                      ),
                      child: const Icon(Icons.auto_awesome,
                          size: 36, color: Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      AppStrings.organizing,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: 120,
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                        child: const LinearProgressIndicator(minHeight: 4),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is ItineraryEditing) {
            final hasDates =
                state.startDate != null && state.endDate != null;

            if (!hasDates) {
              return _buildPlanATripEmpty(context);
            }

            // Dates selected, no stops
            if (state.stops.isEmpty) {
              return Column(
                children: [
                  _buildDateBanner(context, state),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.route,
                                size: 48,
                                color: AppColors.textTertiary),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              AppStrings.itineraryEmpty,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              AppStrings.itineraryEmptySub,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: AppColors.textTertiary),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            FilledButton.icon(
                              onPressed: () => _showAddStopSheet(
                                  context, state.availablePois),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text(AppStrings.itineraryAdd),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            // Dates + stops
            return Column(
              children: [
                _buildDateBanner(context, state),
                // Organized banner
                if (state.isOrganized)
                  Container(
                    margin: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 16, color: AppColors.emerald),
                        const SizedBox(width: 8),
                        Text(
                          'Optimized for low crowds',
                          style: TextStyle(
                            color: AppColors.emerald,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    itemCount: state.stops.length,
                    onReorder: (oldIndex, newIndex) {},
                    proxyDecorator: (child, index, animation) {
                      return Material(
                        color: Colors.transparent,
                        elevation: 8,
                        borderRadius:
                            BorderRadius.circular(AppRadius.xl),
                        child: child,
                      );
                    },
                    itemBuilder: (context, index) {
                      final stop = state.stops[index];
                      return _buildStopCard(
                          context, stop, index, state.isOrganized);
                    },
                  ),
                ),
                // Bottom buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                  child: Column(
                    children: [
                      if (!state.isOrganized)
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: AppColors.emeraldGradient,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              boxShadow:
                                  AppShadows.glow(AppColors.emerald),
                            ),
                            child: FilledButton.icon(
                              onPressed: () => context
                                  .read<ItineraryBloc>()
                                  .add(OrganizeItinerary()),
                              icon: const Icon(Icons.auto_awesome,
                                  size: 18),
                              label: const Text(
                                  AppStrings.organizeWithAi),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                              ),
                            ),
                          ),
                        ),
                      if (state.isOrganized) ...[
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => _showSaveDialog(context),
                            icon: const Icon(Icons.save_outlined,
                                size: 18),
                            label: const Text('Save Journey'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton:
          BlocBuilder<ItineraryBloc, ItineraryState>(
        builder: (context, state) {
          if (state is ItineraryEditing &&
              state.startDate != null &&
              state.stops.isNotEmpty) {
            return FloatingActionButton(
              onPressed: () =>
                  _showAddStopSheet(context, state.availablePois),
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ─── Date Selection Chip ───

class _DateChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DateChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
