import 'package:equatable/equatable.dart';

class TimeSlot extends Equatable {
  final int dayOfWeek; // 0=Mon, 6=Sun
  final int startHour;
  final int endHour;
  final double crowdScore; // 0.0 = empty, 1.0 = max crowd

  const TimeSlot({
    required this.dayOfWeek,
    required this.startHour,
    required this.endHour,
    required this.crowdScore,
  });

  @override
  List<Object?> get props => [dayOfWeek, startHour, endHour, crowdScore];
}

class LocalTemporalAnalysis extends Equatable {
  final Map<int, int> hourlyDistribution; // hour (0-23) -> count
  final Map<int, int> dayOfWeekDistribution; // day (0-6) -> count
  final List<List<int>> temporalHeatmap; // 7 days x 24 hours
  final int busiestHour;
  final int quietestHour;
  final int busiestDay;
  final int quietestDay;
  final int totalNearbyRecords;
  final double avgDwellTime;
  final String currentStatus; // "quiet", "moderate", "busy"
  final DateTime? nextQuietWeekendHour;
  final List<TimeSlot> bestTimeSlots; // top 3 quiet slots

  const LocalTemporalAnalysis({
    required this.hourlyDistribution,
    required this.dayOfWeekDistribution,
    required this.temporalHeatmap,
    required this.busiestHour,
    required this.quietestHour,
    required this.busiestDay,
    required this.quietestDay,
    required this.totalNearbyRecords,
    required this.avgDwellTime,
    required this.currentStatus,
    this.nextQuietWeekendHour,
    required this.bestTimeSlots,
  });

  @override
  List<Object?> get props => [
        hourlyDistribution,
        dayOfWeekDistribution,
        temporalHeatmap,
        busiestHour,
        quietestHour,
        busiestDay,
        quietestDay,
        totalNearbyRecords,
        avgDwellTime,
        currentStatus,
        nextQuietWeekendHour,
        bestTimeSlots,
      ];
}
