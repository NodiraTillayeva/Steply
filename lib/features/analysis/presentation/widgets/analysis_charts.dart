import 'package:flutter/material.dart';
import 'package:steply/core/constants/app_constants.dart';
import 'package:steply/features/analysis/domain/entities/temporal_analysis.dart';
import 'package:steply/features/analysis/domain/entities/weather_data.dart';

// ─── Hourly Bar Chart (24 bars, rounded, gradient) ───

class HourlyBarChart extends StatelessWidget {
  final Map<int, int> hourlyDistribution;
  final int busiestHour;
  final int quietestHour;

  const HourlyBarChart({
    super.key,
    required this.hourlyDistribution,
    required this.busiestHour,
    required this.quietestHour,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: CustomPaint(
        size: Size.infinite,
        painter: _HourlyBarPainter(
          hourlyDistribution: hourlyDistribution,
          busiestHour: busiestHour,
          quietestHour: quietestHour,
        ),
      ),
    );
  }
}

class _HourlyBarPainter extends CustomPainter {
  final Map<int, int> hourlyDistribution;
  final int busiestHour;
  final int quietestHour;

  _HourlyBarPainter({
    required this.hourlyDistribution,
    required this.busiestHour,
    required this.quietestHour,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = hourlyDistribution.values.fold(0, (a, b) => a > b ? a : b);
    if (maxVal == 0) return;

    final barWidth = (size.width - 8) / 24;
    final chartHeight = size.height - 20;

    for (int h = 0; h < 24; h++) {
      final value = hourlyDistribution[h] ?? 0;
      final barHeight = (value / maxVal) * (chartHeight - 4);
      final x = h * barWidth + 1;

      Color barColor = AppColors.primary.withOpacity(0.4);
      if (h == busiestHour) barColor = AppColors.accent;
      if (h == quietestHour) barColor = AppColors.emerald;

      final paint = Paint()..color = barColor;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x + 1, chartHeight - barHeight, barWidth - 3, barHeight),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        ),
        paint,
      );

      // Hour labels (every 4 hours)
      if (h % 4 == 0) {
        final tp = TextPainter(
          text: TextSpan(
            text: '${h}h',
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
            canvas, Offset(x + barWidth / 2 - tp.width / 2, chartHeight + 4));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HourlyBarPainter oldDelegate) => true;
}

// ─── Day of Week Chart (7 horizontal bars, premium) ───

class DayOfWeekChart extends StatelessWidget {
  final Map<int, int> dayOfWeekDistribution;

  const DayOfWeekChart({
    super.key,
    required this.dayOfWeekDistribution,
  });

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final maxVal =
        dayOfWeekDistribution.values.fold(0, (a, b) => a > b ? a : b);

    return Column(
      children: List.generate(7, (d) {
        final value = dayOfWeekDistribution[d] ?? 0;
        final fraction = maxVal > 0 ? value / maxVal : 0.0;
        final isWeekend = d >= 5;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  _dayLabels[d],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isWeekend ? FontWeight.w700 : FontWeight.w500,
                    color:
                        isWeekend ? AppColors.accent : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: fraction,
                    backgroundColor: Colors.grey.shade100,
                    color: isWeekend
                        ? AppColors.accent.withOpacity(0.7)
                        : AppColors.primary.withOpacity(0.5),
                    minHeight: 10,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 32,
                child: Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Temporal Heatmap Grid (7 days x 24 hours) ───

class TemporalHeatmapGrid extends StatelessWidget {
  final List<List<int>> temporalHeatmap;

  const TemporalHeatmapGrid({super.key, required this.temporalHeatmap});

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    int maxVal = 0;
    for (final row in temporalHeatmap) {
      for (final v in row) {
        if (v > maxVal) maxVal = v;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hour labels row
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Row(
            children: List.generate(24, (h) {
              return Expanded(
                child: h % 6 == 0
                    ? Text('${h}h',
                        style: TextStyle(
                            fontSize: 8,
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center)
                    : const SizedBox.shrink(),
              );
            }),
          ),
        ),
        const SizedBox(height: 4),
        // Grid rows
        ...List.generate(7, (d) {
          return Row(
            children: [
              SizedBox(
                width: 16,
                child: Text(
                  _dayLabels[d],
                  style: TextStyle(
                    fontSize: 9,
                    color: d >= 5 ? AppColors.accent : AppColors.textTertiary,
                    fontWeight: d >= 5 ? FontWeight.w700 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 4),
              ...List.generate(24, (h) {
                final value = temporalHeatmap[d][h];
                final intensity = maxVal > 0 ? value / maxVal : 0.0;
                return Expanded(
                  child: Container(
                    height: 16,
                    margin: const EdgeInsets.all(0.5),
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        Colors.grey.shade50,
                        AppColors.primary,
                        intensity * 0.85,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ],
          );
        }),
        const SizedBox(height: 8),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Less',
                style: TextStyle(
                    fontSize: 9, color: AppColors.textTertiary)),
            const SizedBox(width: 6),
            ...List.generate(5, (i) {
              return Container(
                width: 14,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: Color.lerp(
                    Colors.grey.shade50,
                    AppColors.primary,
                    i / 4 * 0.85,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
            const SizedBox(width: 6),
            Text('More',
                style: TextStyle(
                    fontSize: 9, color: AppColors.textTertiary)),
          ],
        ),
      ],
    );
  }
}

// ─── Weather Correlation (inline, no wrapper card) ───

class WeatherCorrelationCard extends StatelessWidget {
  final List<HourlyWeather> weatherData;
  final TemporalAnalysis temporalAnalysis;

  const WeatherCorrelationCard({
    super.key,
    required this.weatherData,
    required this.temporalAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    int sunnyHours = 0;
    int rainyHours = 0;
    int cloudyHours = 0;

    for (final w in weatherData) {
      switch (w.condition) {
        case WeatherCondition.sunny:
          sunnyHours++;
          break;
        case WeatherCondition.rainy:
        case WeatherCondition.stormy:
          rainyHours++;
          break;
        case WeatherCondition.cloudy:
          cloudyHours++;
          break;
        default:
          break;
      }
    }

    final total = sunnyHours + rainyHours + cloudyHours;
    if (total == 0) return const SizedBox.shrink();

    return Column(
      children: [
        _WeatherBar(
          label: 'Sunny',
          count: sunnyHours,
          total: total,
          color: AppColors.weatherSunny,
          icon: Icons.wb_sunny_outlined,
        ),
        const SizedBox(height: 10),
        _WeatherBar(
          label: 'Cloudy',
          count: cloudyHours,
          total: total,
          color: AppColors.weatherCloudy,
          icon: Icons.cloud_outlined,
        ),
        const SizedBox(height: 10),
        _WeatherBar(
          label: 'Rainy',
          count: rainyHours,
          total: total,
          color: AppColors.weatherRainy,
          icon: Icons.water_drop_outlined,
        ),
      ],
    );
  }
}

class _WeatherBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  final IconData icon;

  const _WeatherBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        SizedBox(
            width: 44,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary))),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: count / total,
              backgroundColor: Colors.grey.shade100,
              color: color.withOpacity(0.6),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 32,
          child: Text(
            '${(count / total * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// ─── Current Weather Card (inline, compact) ───

class CurrentWeatherCard extends StatelessWidget {
  final HourlyWeather currentWeather;

  const CurrentWeatherCard({super.key, required this.currentWeather});

  IconData _conditionIcon(WeatherCondition c) {
    switch (c) {
      case WeatherCondition.sunny:
        return Icons.wb_sunny;
      case WeatherCondition.cloudy:
        return Icons.cloud;
      case WeatherCondition.rainy:
        return Icons.water_drop;
      case WeatherCondition.snowy:
        return Icons.ac_unit;
      case WeatherCondition.stormy:
        return Icons.flash_on;
      case WeatherCondition.foggy:
        return Icons.cloud_queue;
    }
  }

  Color _conditionColor(WeatherCondition c) {
    switch (c) {
      case WeatherCondition.sunny:
        return AppColors.weatherSunny;
      case WeatherCondition.cloudy:
        return AppColors.weatherCloudy;
      case WeatherCondition.rainy:
        return AppColors.weatherRainy;
      case WeatherCondition.snowy:
        return AppColors.weatherSnowy;
      case WeatherCondition.stormy:
        return AppColors.weatherStormy;
      case WeatherCondition.foggy:
        return AppColors.weatherFoggy;
    }
  }

  String _conditionLabel(WeatherCondition c) {
    switch (c) {
      case WeatherCondition.sunny:
        return 'Sunny';
      case WeatherCondition.cloudy:
        return 'Cloudy';
      case WeatherCondition.rainy:
        return 'Rainy';
      case WeatherCondition.snowy:
        return 'Snowy';
      case WeatherCondition.stormy:
        return 'Stormy';
      case WeatherCondition.foggy:
        return 'Foggy';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _conditionColor(currentWeather.condition);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weather',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${currentWeather.temperature.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '°C',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              _conditionIcon(currentWeather.condition),
              size: 16,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              _conditionLabel(currentWeather.condition),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
