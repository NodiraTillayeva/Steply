import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:steply/core/constants/app_constants.dart';
import 'package:steply/core/di/injection.dart';
import 'package:steply/features/analysis/domain/entities/comfort_index.dart';
import 'package:steply/features/analysis/domain/entities/local_temporal_analysis.dart';
import 'package:steply/features/analysis/domain/entities/monthly_weather_summary.dart';
import 'package:steply/features/analysis/domain/entities/place_insights.dart';
import 'package:steply/features/analysis/domain/entities/weather_data.dart';
import 'package:steply/features/analysis/domain/repositories/mobility_repository.dart';
import 'package:steply/features/analysis/domain/repositories/weather_repository.dart';
import 'package:steply/features/wishlist/data/datasources/openai_remote_datasource.dart';

class PlaceAnalysisSheet extends StatefulWidget {
  final String name;
  final double lat;
  final double lng;
  final String? sourceUrl;
  final String? description;
  final List<String> localTips;
  final String? rawSourceContent;

  const PlaceAnalysisSheet({
    super.key,
    required this.name,
    required this.lat,
    required this.lng,
    this.sourceUrl,
    this.description,
    this.localTips = const [],
    this.rawSourceContent,
  });

  @override
  State<PlaceAnalysisSheet> createState() => _PlaceAnalysisSheetState();
}

class _PlaceAnalysisSheetState extends State<PlaceAnalysisSheet> {
  late final Future<_AnalysisResult> _analysisFuture;
  Future<PlaceInsights>? _insightsFuture;

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _analysisFuture = _loadAnalysis();
  }

  Future<_AnalysisResult> _loadAnalysis() async {
    final results = await Future.wait([
      getIt<MobilityRepository>().calculateComfortIndex(widget.lat, widget.lng),
      getIt<WeatherRepository>().getCurrentWeatherAt(widget.lat, widget.lng),
      getIt<MobilityRepository>().getLocalTemporalAnalysis(widget.lat, widget.lng),
      getIt<WeatherRepository>().getMonthlyWeatherSummaries(),
    ]);
    return _AnalysisResult(
      comfort: results[0] as ComfortIndex,
      weather: results[1] as HourlyWeather,
      temporal: results[2] as LocalTemporalAnalysis,
      monthlySummaries: results[3] as List<MonthlyWeatherSummary>,
    );
  }

  void _loadInsights() {
    setState(() {
      _insightsFuture = getIt<OpenAiRemoteDatasource>().getPlaceInsights(
        placeName: widget.name,
        sourceUrl: widget.sourceUrl,
        rawContent: widget.rawSourceContent,
        description: widget.description,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Header
                Text(
                  widget.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.lat.toStringAsFixed(4)}, ${widget.lng.toStringAsFixed(4)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                if (widget.description != null && widget.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.description!,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 20),
                // Main content
                FutureBuilder<_AnalysisResult>(
                  future: _analysisFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError) {
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: Colors.red),
                              const SizedBox(height: 8),
                              Text('Failed to load analysis',
                                  style: theme.textTheme.bodyMedium),
                              const SizedBox(height: 4),
                              Text(
                                snapshot.error.toString(),
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final result = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: Right Now
                        _buildSectionHeader(
                            context, Icons.access_time, AppStrings.analysisRightNow),
                        const SizedBox(height: 8),
                        _buildRightNowSection(context, result),
                        const SizedBox(height: 24),
                        // Section 2: Best Times to Visit
                        _buildSectionHeader(
                            context, Icons.schedule, AppStrings.analysisBestTimes),
                        const SizedBox(height: 8),
                        _buildBestTimesSection(context, result.temporal),
                        const SizedBox(height: 24),
                        // Section 3: Seasonal Weather Guide
                        _buildSectionHeader(context, Icons.calendar_month,
                            AppStrings.analysisSeasonalGuide),
                        const SizedBox(height: 8),
                        _buildSeasonalSection(context, result.monthlySummaries),
                        const SizedBox(height: 24),
                        // Section 4: Local Tips & Insights
                        _buildSectionHeader(context, Icons.lightbulb_outline,
                            AppStrings.analysisLocalTips),
                        const SizedBox(height: 8),
                        _buildInsightsSection(context),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, IconData icon, String title) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // Section 1: Right Now
  // ──────────────────────────────────────────────
  Widget _buildRightNowSection(BuildContext context, _AnalysisResult result) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildComfortCard(context, result.comfort)),
            const SizedBox(width: 8),
            _buildStatusBadge(context, result.temporal.currentStatus),
          ],
        ),
        const SizedBox(height: 12),
        _buildWeatherCard(context, result.weather),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color color;
    String label;
    IconData icon;
    switch (status) {
      case 'quiet':
        color = AppColors.statusQuiet;
        label = '${AppStrings.statusQuiet} now';
        icon = Icons.sentiment_very_satisfied;
      case 'busy':
        color = AppColors.statusBusy;
        label = '${AppStrings.statusBusy} now';
        icon = Icons.sentiment_very_dissatisfied;
      default:
        color = AppColors.statusModerate;
        label = '${AppStrings.statusModerate} now';
        icon = Icons.sentiment_neutral;
    }

    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComfortCard(BuildContext context, ComfortIndex comfort) {
    final theme = Theme.of(context);

    Color levelColor;
    String levelLabel;
    switch (comfort.level) {
      case ComfortLevel.high:
        levelColor = Colors.green;
        levelLabel = AppStrings.comfortHigh;
      case ComfortLevel.medium:
        levelColor = Colors.orange;
        levelLabel = AppStrings.comfortMedium;
      case ComfortLevel.low:
        levelColor = Colors.red;
        levelLabel = AppStrings.comfortLow;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comfort', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        levelLabel,
                        style: TextStyle(
                          color: levelColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: comfort.value,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(levelColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(comfort.value * 100).toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: levelColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${comfort.dataPointCount} records nearby',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard(BuildContext context, HourlyWeather weather) {
    final theme = Theme.of(context);

    IconData weatherIcon;
    String conditionLabel;
    switch (weather.condition) {
      case WeatherCondition.sunny:
        weatherIcon = Icons.wb_sunny;
        conditionLabel = 'Sunny';
      case WeatherCondition.cloudy:
        weatherIcon = Icons.cloud;
        conditionLabel = 'Cloudy';
      case WeatherCondition.rainy:
        weatherIcon = Icons.grain;
        conditionLabel = 'Rainy';
      case WeatherCondition.snowy:
        weatherIcon = Icons.ac_unit;
        conditionLabel = 'Snowy';
      case WeatherCondition.stormy:
        weatherIcon = Icons.thunderstorm;
        conditionLabel = 'Stormy';
      case WeatherCondition.foggy:
        weatherIcon = Icons.foggy;
        conditionLabel = 'Foggy';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(weatherIcon, size: 32, color: Colors.blueGrey),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(conditionLabel,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text('${weather.temperature.toStringAsFixed(1)}°C',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _weatherChip(Icons.air,
                    '${weather.windSpeed.toStringAsFixed(1)} km/h'),
                const SizedBox(height: 4),
                _weatherChip(Icons.water_drop,
                    '${weather.precipitation.toStringAsFixed(1)} mm'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _weatherChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // Section 2: Best Times to Visit
  // ──────────────────────────────────────────────
  Widget _buildBestTimesSection(
      BuildContext context, LocalTemporalAnalysis temporal) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Best time slots
        if (temporal.bestTimeSlots.isNotEmpty) ...[
          Text('Quietest time slots',
              style: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ...temporal.bestTimeSlots.map((slot) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      size: 16, color: AppColors.statusQuiet),
                  const SizedBox(width: 6),
                  Text(
                    '${_dayNames[slot.dayOfWeek]} ${slot.startHour}:00–${slot.endHour}:00',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  _crowdIndicator(slot.crowdScore),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
        ],

        // Next quiet weekend
        if (temporal.nextQuietWeekendHour != null) ...[
          Card(
            color: AppColors.statusQuiet.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.weekend,
                      color: AppColors.statusQuiet, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.nextQuietWeekend,
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.statusQuiet)),
                        Text(
                          DateFormat('EEE, MMM d – HH:00')
                              .format(temporal.nextQuietWeekendHour!),
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Hourly bar chart
        Text('Hourly crowd at this location',
            style: theme.textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _buildHourlyBarChart(context, temporal.hourlyDistribution),
        const SizedBox(height: 16),

        // 7x24 Heatmap
        Text('Weekly heatmap',
            style: theme.textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _buildHeatmap(context, temporal.temporalHeatmap),
      ],
    );
  }

  Widget _crowdIndicator(double score) {
    Color color;
    String label;
    if (score < 0.3) {
      color = AppColors.statusQuiet;
      label = 'Quiet';
    } else if (score < 0.6) {
      color = AppColors.statusModerate;
      label = 'Moderate';
    } else {
      color = AppColors.statusBusy;
      label = 'Busy';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildHourlyBarChart(
      BuildContext context, Map<int, int> hourlyDist) {
    final maxVal = hourlyDist.values.fold(0, (a, b) => a > b ? a : b);
    const barMaxHeight = 60.0;

    return SizedBox(
      height: barMaxHeight + 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(24, (h) {
          final val = hourlyDist[h] ?? 0;
          final ratio = maxVal > 0 ? val / maxVal : 0.0;
          final barH = ratio * barMaxHeight;

          Color barColor;
          if (ratio < 0.3) {
            barColor = AppColors.statusQuiet;
          } else if (ratio < 0.6) {
            barColor = AppColors.statusModerate;
          } else {
            barColor = AppColors.statusBusy;
          }

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: barH.clamp(2.0, barMaxHeight),
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (h % 6 == 0)
                    Text('${h}h',
                        style: const TextStyle(fontSize: 8, color: Colors.grey))
                  else
                    const SizedBox(height: 10),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeatmap(BuildContext context, List<List<int>> heatmap) {
    // Find max value for normalization
    int maxVal = 0;
    for (final row in heatmap) {
      for (final v in row) {
        if (v > maxVal) maxVal = v;
      }
    }

    return Column(
      children: [
        // Hour labels row
        Row(
          children: [
            const SizedBox(width: 28),
            ...List.generate(24, (h) {
              if (h % 6 == 0) {
                return Expanded(
                  child: Text('${h}h',
                      style: const TextStyle(fontSize: 8, color: Colors.grey)),
                );
              }
              return const Expanded(child: SizedBox());
            }),
          ],
        ),
        // Heatmap grid
        ...List.generate(7, (d) {
          return Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(_dayNames[d],
                    style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ),
              ...List.generate(24, (h) {
                final val = heatmap[d][h];
                final ratio = maxVal > 0 ? val / maxVal : 0.0;
                return Expanded(
                  child: Container(
                    height: 14,
                    margin: const EdgeInsets.all(0.5),
                    decoration: BoxDecoration(
                      color: _heatmapColor(ratio),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                );
              }),
            ],
          );
        }),
        // Legend
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text('Less', style: TextStyle(fontSize: 9, color: Colors.grey)),
            const SizedBox(width: 4),
            ...List.generate(5, (i) {
              return Container(
                width: 12,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: _heatmapColor(i / 4),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            }),
            const SizedBox(width: 4),
            const Text('More', style: TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Color _heatmapColor(double ratio) {
    if (ratio <= 0) return Colors.grey.shade100;
    if (ratio < 0.25) return Colors.green.shade100;
    if (ratio < 0.5) return Colors.green.shade300;
    if (ratio < 0.75) return Colors.orange.shade300;
    return Colors.red.shade400;
  }

  // ──────────────────────────────────────────────
  // Section 3: Seasonal Weather Guide
  // ──────────────────────────────────────────────
  Widget _buildSeasonalSection(
      BuildContext context, List<MonthlyWeatherSummary> summaries) {
    final theme = Theme.of(context);

    if (summaries.isEmpty) {
      return const Text('No seasonal data available');
    }

    // Find best months
    final sorted = [...summaries]
      ..sort((a, b) => b.visitabilityScore.compareTo(a.visitabilityScore));
    final bestMonths = sorted.take(3).map((s) => _monthNames[s.month - 1]).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Best months highlight
        Card(
          color: AppColors.seasonalBest.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.star, color: AppColors.seasonalBest, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.bestMonths,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: AppColors.seasonalBest)),
                      Text(
                        bestMonths.join(', '),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Monthly grid
        ...summaries.map((s) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    _monthNames[s.month - 1],
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ),
                Icon(_weatherConditionIcon(s.dominantCondition),
                    size: 14, color: Colors.blueGrey),
                const SizedBox(width: 4),
                SizedBox(
                  width: 36,
                  child: Text('${s.avgTemperature.toStringAsFixed(0)}°C',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: s.visitabilityScore,
                      minHeight: 7,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(
                        _visitabilityColor(s.visitabilityScore),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 24,
                  child: Text(
                    '${(s.visitabilityScore * 100).toInt()}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      color: _visitabilityColor(s.visitabilityScore),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  IconData _weatherConditionIcon(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return Icons.wb_sunny;
      case WeatherCondition.cloudy:
        return Icons.cloud;
      case WeatherCondition.rainy:
        return Icons.grain;
      case WeatherCondition.snowy:
        return Icons.ac_unit;
      case WeatherCondition.stormy:
        return Icons.thunderstorm;
      case WeatherCondition.foggy:
        return Icons.foggy;
    }
  }

  Color _visitabilityColor(double score) {
    if (score >= 0.7) return AppColors.seasonalBest;
    if (score >= 0.4) return AppColors.statusModerate;
    return AppColors.seasonalWorst;
  }

  // ──────────────────────────────────────────────
  // Section 4: Local Tips & Insights
  // ──────────────────────────────────────────────
  Widget _buildInsightsSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show existing local tips as chips
        if (widget.localTips.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: widget.localTips.map((tip) {
              return Chip(
                avatar: const Icon(Icons.tips_and_updates,
                    size: 16, color: AppColors.insightTip),
                label: Text(tip, style: const TextStyle(fontSize: 12)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],

        // AI Insights
        if (_insightsFuture == null)
          Center(
            child: FilledButton.tonalIcon(
              onPressed: _loadInsights,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text(AppStrings.getAiInsights),
            ),
          )
        else
          FutureBuilder<PlaceInsights>(
            future: _insightsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Getting AI insights...',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Failed to load insights: ${snapshot.error}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final insights = snapshot.data!;
              return _buildInsightsContent(context, insights);
            },
          ),
      ],
    );
  }

  Widget _buildInsightsContent(BuildContext context, PlaceInsights insights) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vibe
        if (insights.vibe.isNotEmpty) ...[
          Card(
            color: AppColors.insightVibe.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.mood,
                      color: AppColors.insightVibe, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vibe',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: AppColors.insightVibe)),
                        Text(insights.vibe, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Best Season
        if (insights.bestSeason.isNotEmpty) ...[
          Card(
            color: AppColors.seasonalBest.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.eco,
                      color: AppColors.seasonalBest, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Best Season',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: AppColors.seasonalBest)),
                        Text(insights.bestSeason,
                            style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Highlights
        if (insights.highlights.isNotEmpty) ...[
          Text('Highlights',
              style: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          ...insights.highlights.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.star,
                        size: 14, color: AppColors.insightHighlight),
                    const SizedBox(width: 6),
                    Expanded(
                        child:
                            Text(h, style: theme.textTheme.bodySmall)),
                  ],
                ),
              )),
          const SizedBox(height: 8),
        ],

        // AI tips
        if (insights.localTips.isNotEmpty) ...[
          Text('Tips',
              style: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: insights.localTips.map((tip) {
              return Chip(
                avatar: const Icon(Icons.tips_and_updates,
                    size: 16, color: AppColors.insightTip),
                label: Text(tip, style: const TextStyle(fontSize: 12)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],

        // Caveat
        if (insights.caveat.isNotEmpty)
          Card(
            color: AppColors.insightCaveat.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber,
                      color: AppColors.insightCaveat, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Heads up',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: AppColors.insightCaveat)),
                        Text(insights.caveat,
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AnalysisResult {
  final ComfortIndex comfort;
  final HourlyWeather weather;
  final LocalTemporalAnalysis temporal;
  final List<MonthlyWeatherSummary> monthlySummaries;

  _AnalysisResult({
    required this.comfort,
    required this.weather,
    required this.temporal,
    required this.monthlySummaries,
  });
}
