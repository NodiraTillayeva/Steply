import 'package:equatable/equatable.dart';

class TemporalAnalysis extends Equatable {
  final Map<int, int> hourlyDistribution;
  final Map<int, int> dayOfWeekDistribution;
  final List<List<int>> temporalHeatmap; // 7 days x 24 hours
  final Map<String, double> dwellTimeByArea;
  final int weekdayCount;
  final int weekendCount;
  final int busiestHour;
  final int quietestHour;
  final int busiestDay;
  final int quietestDay;

  const TemporalAnalysis({
    required this.hourlyDistribution,
    required this.dayOfWeekDistribution,
    required this.temporalHeatmap,
    required this.dwellTimeByArea,
    required this.weekdayCount,
    required this.weekendCount,
    required this.busiestHour,
    required this.quietestHour,
    required this.busiestDay,
    required this.quietestDay,
  });

  @override
  List<Object?> get props => [
        hourlyDistribution,
        dayOfWeekDistribution,
        temporalHeatmap,
        dwellTimeByArea,
        weekdayCount,
        weekendCount,
        busiestHour,
        quietestHour,
        busiestDay,
        quietestDay,
      ];
}
