import 'package:equatable/equatable.dart';

class WeeklyActivityPoint extends Equatable {
  const WeeklyActivityPoint({required this.day, required this.minutes});
  final String day;
  final int minutes;

  @override
  List<Object?> get props => [day, minutes];
}

class SkillGrowthPoint extends Equatable {
  const SkillGrowthPoint({required this.skill, required this.level, required this.previousLevel});
  final String skill;
  final int level; // 1–5
  final int previousLevel;

  @override
  List<Object?> get props => [skill, level, previousLevel];
}

class LearningAnalyticsEntity extends Equatable {
  const LearningAnalyticsEntity({
    required this.totalLearningHours,
    required this.weeklyActivity,
    required this.courseCompletionRate,
    required this.internshipPerformanceScore,
    required this.assignmentSuccessRate,
    required this.skillGrowth,
    required this.currentStreak,
    required this.longestStreak,
  });

  final double totalLearningHours;
  final List<WeeklyActivityPoint> weeklyActivity;
  final double courseCompletionRate;   // 0–100
  final double internshipPerformanceScore; // 0–100
  final double assignmentSuccessRate;  // 0–100
  final List<SkillGrowthPoint> skillGrowth;
  final int currentStreak;  // days
  final int longestStreak;  // days

  @override
  List<Object?> get props => [
        totalLearningHours,
        weeklyActivity,
        courseCompletionRate,
        internshipPerformanceScore,
        assignmentSuccessRate,
        skillGrowth,
        currentStreak,
        longestStreak,
      ];
}
