import 'package:flutter/material.dart';
import 'package:steply/core/constants/app_constants.dart';
import 'package:steply/features/analysis/domain/entities/recommendation.dart';

class RecommendationCard extends StatelessWidget {
  final Recommendation recommendation;

  const RecommendationCard({super.key, required this.recommendation});

  IconData _typeIcon(RecommendationType type) {
    switch (type) {
      case RecommendationType.bestTime:
        return Icons.schedule;
      case RecommendationType.quietArea:
        return Icons.explore;
      case RecommendationType.weatherOptimal:
        return Icons.wb_sunny_outlined;
      case RecommendationType.avoidCrowd:
        return Icons.groups_outlined;
    }
  }

  Color _typeColor(RecommendationType type) {
    switch (type) {
      case RecommendationType.bestTime:
        return AppColors.recBestTime;
      case RecommendationType.quietArea:
        return AppColors.recQuietArea;
      case RecommendationType.weatherOptimal:
        return AppColors.recWeatherOptimal;
      case RecommendationType.avoidCrowd:
        return AppColors.recAvoidCrowd;
    }
  }

  String _typeLabel(RecommendationType type) {
    switch (type) {
      case RecommendationType.bestTime:
        return 'BEST TIME';
      case RecommendationType.quietArea:
        return 'QUIET AREA';
      case RecommendationType.weatherOptimal:
        return 'WEATHER';
      case RecommendationType.avoidCrowd:
        return 'HEADS UP';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(recommendation.type);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              _typeIcon(recommendation.type),
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type label
                Text(
                  _typeLabel(recommendation.type),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recommendation.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  recommendation.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                ),
                const SizedBox(height: 10),
                // Confidence bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                        child: LinearProgressIndicator(
                          value: recommendation.confidenceScore,
                          backgroundColor: Colors.grey.shade100,
                          color: color.withOpacity(0.6),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${(recommendation.confidenceScore * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (recommendation.areaName != null &&
                    recommendation.areaName!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.place_outlined,
                          size: 12, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        recommendation.areaName!,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
