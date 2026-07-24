import '../../domain/entities/analytics_entity.dart';

class AnalyticsRepository {
  /// Returns seeded analytics data — wired to real API endpoint
  /// when backend is ready (replace body with Dio call).
  Future<LearningAnalyticsEntity> getAnalytics() async {
    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 400));

    return const LearningAnalyticsEntity(
      totalLearningHours: 47.5,
      weeklyActivity: [
        WeeklyActivityPoint(day: 'Mon', minutes: 90),
        WeeklyActivityPoint(day: 'Tue', minutes: 120),
        WeeklyActivityPoint(day: 'Wed', minutes: 45),
        WeeklyActivityPoint(day: 'Thu', minutes: 180),
        WeeklyActivityPoint(day: 'Fri', minutes: 75),
        WeeklyActivityPoint(day: 'Sat', minutes: 210),
        WeeklyActivityPoint(day: 'Sun', minutes: 60),
      ],
      courseCompletionRate: 68.0,
      internshipPerformanceScore: 82.0,
      assignmentSuccessRate: 91.0,
      skillGrowth: [
        SkillGrowthPoint(skill: 'Flutter', level: 4, previousLevel: 2),
        SkillGrowthPoint(skill: 'Dart', level: 4, previousLevel: 3),
        SkillGrowthPoint(skill: 'Clean Arch', level: 3, previousLevel: 1),
        SkillGrowthPoint(skill: 'Riverpod', level: 3, previousLevel: 1),
        SkillGrowthPoint(skill: 'Firebase', level: 2, previousLevel: 1),
        SkillGrowthPoint(skill: 'GoRouter', level: 3, previousLevel: 2),
      ],
      currentStreak: 7,
      longestStreak: 12,
    );
  }
}
