import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:steply/core/constants/app_constants.dart';
import 'package:steply/features/analysis/domain/entities/comfort_index.dart';
import 'package:steply/features/analysis/presentation/bloc/comfort_bloc.dart';
import 'package:steply/features/analysis/presentation/widgets/analysis_charts.dart';
import 'package:steply/features/analysis/presentation/widgets/recommendation_card.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    context.read<ComfortBloc>().add(LoadEnhancedAnalysis());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Color _comfortColor(ComfortLevel level) {
    switch (level) {
      case ComfortLevel.low:
        return AppColors.lowComfort;
      case ComfortLevel.medium:
        return AppColors.mediumComfort;
      case ComfortLevel.high:
        return AppColors.highComfort;
    }
  }

  String _comfortLabel(ComfortLevel level) {
    switch (level) {
      case ComfortLevel.low:
        return AppStrings.comfortLow;
      case ComfortLevel.medium:
        return AppStrings.comfortMedium;
      case ComfortLevel.high:
        return AppStrings.comfortHigh;
    }
  }

  Widget _shimmerBlock({double height = 80}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade100,
      highlightColor: Colors.grey.shade50,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
      ),
    );
  }

  // ─── Section Header (Storytelling style) ───

  Widget _sectionHeader({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md + 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle,
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textTertiary,
                              ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Premium Card Wrapper ───

  Widget _premiumCard({
    required Widget child,
    EdgeInsets? padding,
    LinearGradient? gradient,
  }) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: gradient == null ? AppColors.surfaceLight : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: gradient == null
            ? Border.all(color: Colors.black.withOpacity(0.04))
            : null,
        boxShadow: AppShadows.sm,
      ),
      child: child,
    );
  }

  // ─── Microcopy explanation ───

  Widget _microcopy(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
              fontStyle: FontStyle.italic,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ComfortBloc, ComfortState>(
        builder: (context, state) {
          if (state is ComfortLoading || state is ComfortInitial) {
            return Container(
              decoration: const BoxDecoration(
                gradient: AppColors.surfaceGradient,
              ),
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          if (state is ComfortError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.insights_outlined,
                        size: 48, color: AppColors.textTertiary),
                    const SizedBox(height: AppSpacing.md),
                    Text(state.message),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      onPressed: () => context
                          .read<ComfortBloc>()
                          .add(LoadEnhancedAnalysis()),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text(AppStrings.retry),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is ComfortLoaded) {
            _fadeController.forward();

            return FadeTransition(
              opacity: CurvedAnimation(
                parent: _fadeController,
                curve: Curves.easeOut,
              ),
              child: CustomScrollView(
                slivers: [
                  // ─── Header ───
                  SliverAppBar(
                    expandedHeight: 140,
                    floating: false,
                    pinned: true,
                    backgroundColor: AppColors.bgLight,
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(
                          left: AppSpacing.lg, bottom: 16),
                      title: Text(
                        AppStrings.insightsTitle,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontSize: 18),
                      ),
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: AppColors.warmBgGradient,
                        ),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).padding.top + 12,
                              right: AppSpacing.lg,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
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
                                    'AI-Powered',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ─── Narrative Summary ───
                        _premiumCard(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.05),
                              AppColors.accent.withOpacity(0.03),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      gradient:
                                          AppColors.accentGradient,
                                      borderRadius:
                                          BorderRadius.circular(
                                              AppRadius.sm),
                                    ),
                                    child: const Icon(
                                        Icons.auto_awesome,
                                        size: 16,
                                        color: Colors.white),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    AppStrings.movementIntelligence,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accent,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              RichText(
                                text: TextSpan(
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: AppColors.textPrimary,
                                        height: 1.7,
                                      ),
                                  children: [
                                    const TextSpan(
                                        text: 'Based on '),
                                    TextSpan(
                                      text: _formatNumber(state
                                          .mobilityData.length),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                    const TextSpan(
                                        text:
                                            ' movement records, we identified '),
                                    TextSpan(
                                      text:
                                          '${state.popularAreas.length} hotspots',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.coral,
                                      ),
                                    ),
                                    const TextSpan(
                                        text:
                                            ' across Nagoya — revealing patterns in how the city moves.'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // ─── Current Conditions ───
                        if (state.currentWeather != null ||
                            state.comfortIndex != null) ...[
                          Row(
                            children: [
                              if (state.currentWeather != null)
                                Expanded(
                                  child: _premiumCard(
                                    padding: const EdgeInsets.all(
                                        AppSpacing.md),
                                    child: CurrentWeatherCard(
                                        currentWeather:
                                            state.currentWeather!),
                                  ),
                                ),
                              if (state.currentWeather != null &&
                                  state.comfortIndex != null)
                                const SizedBox(
                                    width: AppSpacing.sm + 4),
                              if (state.comfortIndex != null)
                                Expanded(
                                  child: _premiumCard(
                                    padding: const EdgeInsets.all(
                                        AppSpacing.md),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppStrings.crowdPulse,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight:
                                                FontWeight.w700,
                                            color: _comfortColor(
                                                state.comfortIndex!
                                                    .level),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .end,
                                          children: [
                                            Text(
                                              '${(state.comfortIndex!.value * 100).toStringAsFixed(0)}',
                                              style: Theme.of(
                                                      context)
                                                  .textTheme
                                                  .headlineLarge
                                                  ?.copyWith(
                                                    fontWeight:
                                                        FontWeight
                                                            .w800,
                                                    color: _comfortColor(
                                                        state
                                                            .comfortIndex!
                                                            .level),
                                                  ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets
                                                      .only(
                                                      bottom: 4),
                                              child: Text(
                                                '%',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight:
                                                      FontWeight
                                                          .w600,
                                                  color: _comfortColor(
                                                      state
                                                          .comfortIndex!
                                                          .level),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  AppRadius.full),
                                          child:
                                              LinearProgressIndicator(
                                            value: state
                                                .comfortIndex!
                                                .value,
                                            backgroundColor:
                                                Colors
                                                    .grey.shade100,
                                            color: _comfortColor(
                                                state.comfortIndex!
                                                    .level),
                                            minHeight: 6,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _comfortLabel(state
                                              .comfortIndex!.level),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                  color: AppColors
                                                      .textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (state.isWeatherLoading &&
                              state.currentWeather == null)
                            _shimmerBlock(height: 100),
                          const SizedBox(height: AppSpacing.xxl),
                        ],

                        // ══════════════════════════════════
                        // BLOCK 1: CROWD INTELLIGENCE
                        // ══════════════════════════════════
                        _sectionHeader(
                          icon: Icons.people_outline,
                          color: AppColors.coral,
                          title: AppStrings.crowdIntelligence,
                          subtitle: 'Understanding movement patterns',
                        ),

                        // Hotspots
                        ...state.popularAreas.take(5).map((area) {
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm + 2),
                            child: _premiumCard(
                              padding:
                                  const EdgeInsets.all(AppSpacing.md),
                              child: InkWell(
                                onTap: () {
                                  context.read<ComfortBloc>().add(
                                        CalculateComfortForLocation(
                                            area.latitude,
                                            area.longitude),
                                      );
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      padding:
                                          const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        gradient: AppColors
                                            .coralGradient,
                                        borderRadius:
                                            BorderRadius.circular(
                                                AppRadius.md),
                                      ),
                                      child: const Icon(
                                          Icons
                                              .local_fire_department,
                                          color: Colors.white,
                                          size: 20),
                                    ),
                                    const SizedBox(
                                        width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            area.name,
                                            style:
                                                Theme.of(context)
                                                    .textTheme
                                                    .titleSmall,
                                          ),
                                          const SizedBox(
                                              height: 2),
                                          Text(
                                            '${area.visitCount} visits  ·  Peak: ${area.peakDay} ${area.peakHour}:00',
                                            style:
                                                Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: AppColors
                                                          .textTertiary,
                                                    ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${area.avgElapsedTime.toStringAsFixed(0)}m',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.chevron_right,
                                        size: 16,
                                        color:
                                            AppColors.textTertiary),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),

                        _microcopy(
                            'Hotspots are ranked by visit frequency and average time spent.'),

                        const SizedBox(height: AppSpacing.xxl),

                        // ══════════════════════════════════
                        // BLOCK 2: TEMPORAL PATTERNS
                        // ══════════════════════════════════
                        if (state.temporalAnalysis != null) ...[
                          _sectionHeader(
                            icon: Icons.timeline,
                            color: AppColors.primary,
                            title: AppStrings.temporalPatterns,
                            subtitle: 'When the city moves',
                          ),

                          // Weekday vs Weekend
                          _premiumCard(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _statBlock(
                                    label: 'Weekday',
                                    value: _formatNumber(state
                                        .temporalAnalysis!
                                        .weekdayCount),
                                    color: AppColors.primary,
                                    icon: Icons.work_outline,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 48,
                                  color: Colors.black
                                      .withOpacity(0.06),
                                ),
                                Expanded(
                                  child: _statBlock(
                                    label: 'Weekend',
                                    value: _formatNumber(state
                                        .temporalAnalysis!
                                        .weekendCount),
                                    color: AppColors.accent,
                                    icon: Icons.weekend_outlined,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          _microcopy(
                              'Movement volume comparison between work days and rest days.'),

                          const SizedBox(height: AppSpacing.lg),

                          // Hourly flow
                          _premiumCard(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.hourlyFlow,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                          fontWeight:
                                              FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                RichText(
                                  text: TextSpan(
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppColors
                                                .textTertiary),
                                    children: [
                                      const TextSpan(
                                          text: 'Busiest at '),
                                      TextSpan(
                                        text:
                                            '${state.temporalAnalysis!.busiestHour}:00',
                                        style: TextStyle(
                                          fontWeight:
                                              FontWeight.w700,
                                          color: AppColors.coral,
                                        ),
                                      ),
                                      const TextSpan(
                                          text:
                                              '  ·  Quietest at '),
                                      TextSpan(
                                        text:
                                            '${state.temporalAnalysis!.quietestHour}:00',
                                        style: TextStyle(
                                          fontWeight:
                                              FontWeight.w700,
                                          color: AppColors.emerald,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                    height: AppSpacing.md),
                                HourlyBarChart(
                                  hourlyDistribution: state
                                      .temporalAnalysis!
                                      .hourlyDistribution,
                                  busiestHour: state
                                      .temporalAnalysis!
                                      .busiestHour,
                                  quietestHour: state
                                      .temporalAnalysis!
                                      .quietestHour,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // Weekly rhythm
                          _premiumCard(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.weeklyRhythm,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                          fontWeight:
                                              FontWeight.w600),
                                ),
                                const SizedBox(
                                    height: AppSpacing.md),
                                DayOfWeekChart(
                                  dayOfWeekDistribution: state
                                      .temporalAnalysis!
                                      .dayOfWeekDistribution,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // Activity heatmap
                          _premiumCard(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.activityHeatmap,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                          fontWeight:
                                              FontWeight.w600),
                                ),
                                _microcopy(
                                    'A 7-day x 24-hour view of movement intensity across Nagoya.'),
                                const SizedBox(
                                    height: AppSpacing.md),
                                TemporalHeatmapGrid(
                                  temporalHeatmap: state
                                      .temporalAnalysis!
                                      .temporalHeatmap,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSpacing.xxl),
                        ],

                        // ══════════════════════════════════
                        // BLOCK 3: WEATHER CORRELATION
                        // ══════════════════════════════════
                        if (state.weatherData != null &&
                            state.temporalAnalysis != null) ...[
                          _sectionHeader(
                            icon: Icons.cloud_outlined,
                            color: AppColors.weatherRainy,
                            title: AppStrings.weatherCorrelation,
                            subtitle:
                                'How weather shapes the city',
                          ),
                          _premiumCard(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                WeatherCorrelationCard(
                                  weatherData:
                                      state.weatherData!,
                                  temporalAnalysis:
                                      state.temporalAnalysis!,
                                ),
                                _microcopy(
                                    'Weather conditions influence crowd patterns and optimal visit times.'),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                        ] else if (state.isWeatherLoading) ...[
                          _shimmerBlock(height: 120),
                          const SizedBox(height: AppSpacing.xxl),
                        ],

                        if (state.weatherError != null &&
                            state.weatherData == null)
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppSpacing.lg),
                            child: _premiumCard(
                              padding: const EdgeInsets.all(
                                  AppSpacing.md),
                              child: Row(
                                children: [
                                  Container(
                                    padding:
                                        const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.amber
                                          .withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.cloud_off,
                                        size: 16,
                                        color: AppColors.amber),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      AppStrings
                                          .analysisWeatherUnavailable,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: AppColors
                                                  .textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // ─── Smart Recommendations ───
                        _sectionHeader(
                          icon: Icons.auto_awesome,
                          color: AppColors.accent,
                          title: AppStrings.smartRecommendations,
                          subtitle: 'Personalized for you',
                        ),

                        if (state.recommendations != null)
                          ...state.recommendations!.map(
                            (rec) => Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm + 4),
                              child:
                                  RecommendationCard(recommendation: rec),
                            ),
                          )
                        else if (state.isWeatherLoading) ...[
                          _shimmerBlock(height: 100),
                          const SizedBox(height: AppSpacing.sm),
                          _shimmerBlock(height: 100),
                        ],

                        const SizedBox(height: AppSpacing.xxl),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _statBlock({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      final formatted = (n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1);
      return '${formatted}k';
    }
    return n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]},');
  }
}
