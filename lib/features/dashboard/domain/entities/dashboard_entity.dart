import 'package:equatable/equatable.dart';

class DashboardSummary extends Equatable {
  const DashboardSummary({
    required this.activeCourseTitle,
    required this.activeCourseProgress,
    required this.activeInternshipTitle,
    required this.internshipProgress,
    required this.dailyTasks,
    required this.upcomingDeadlines,
    required this.aiRecommendations,
    required this.engineeringScore,
  });

  final String activeCourseTitle;
  final double activeCourseProgress; // 0.0 - 1.0
  final String activeInternshipTitle;
  final double internshipProgress;
  final List<TaskItem> dailyTasks;
  final List<DeadlineItem> upcomingDeadlines;
  final List<String> aiRecommendations;
  final int engineeringScore;

  @override
  List<Object?> get props => [
        activeCourseTitle,
        activeCourseProgress,
        activeInternshipTitle,
        internshipProgress,
        dailyTasks,
        upcomingDeadlines,
        aiRecommendations,
        engineeringScore,
      ];
}

class TaskItem extends Equatable {
  const TaskItem({required this.id, required this.title, required this.done});
  final String id;
  final String title;
  final bool done;

  TaskItem copyWith({bool? done}) => TaskItem(id: id, title: title, done: done ?? this.done);

  @override
  List<Object?> get props => [id, title, done];
}

class DeadlineItem extends Equatable {
  const DeadlineItem({required this.id, required this.title, required this.dueAt});
  final String id;
  final String title;
  final DateTime dueAt;

  @override
  List<Object?> get props => [id, title, dueAt];
}
