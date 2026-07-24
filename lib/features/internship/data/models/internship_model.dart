import '../../domain/entities/internship_entity.dart';

class CaseStudyModel extends CaseStudyEntity {
  const CaseStudyModel({
    required super.id,
    required super.title,
    required super.description,
    required super.durationWeeks,
    required super.currentWeek,
  });

  factory CaseStudyModel.fromJson(Map<String, dynamic> json) => CaseStudyModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        durationWeeks: (json['duration_weeks'] as num?)?.toInt() ?? 4,
        currentWeek: (json['current_week'] as num?)?.toInt() ?? 1,
      );
}

class InternshipTaskModel extends InternshipTaskEntity {
  const InternshipTaskModel({
    required super.id,
    required super.title,
    required super.done,
    required super.dayLabel,
  });

  factory InternshipTaskModel.fromJson(Map<String, dynamic> json) => InternshipTaskModel(
        id: json['id'] as String,
        title: json['title'] as String,
        done: json['done'] as bool? ?? false,
        dayLabel: json['day_label'] as String? ?? 'Today',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'done': done,
        'day_label': dayLabel,
      };
}

class MentorFeedbackModel extends MentorFeedbackEntity {
  const MentorFeedbackModel({
    required super.id,
    required super.mentorName,
    required super.message,
    required super.givenAt,
    required super.rating,
  });

  factory MentorFeedbackModel.fromJson(Map<String, dynamic> json) => MentorFeedbackModel(
        id: json['id'] as String,
        mentorName: json['mentor_name'] as String,
        message: json['message'] as String,
        givenAt: DateTime.parse(json['given_at'] as String),
        rating: (json['rating'] as num?)?.toInt() ?? 5,
      );
}

class WeeklyReportModel extends WeeklyReportEntity {
  const WeeklyReportModel({
    required super.id,
    required super.weekNumber,
    required super.summary,
    required super.githubLink,
    required super.submittedAt,
    super.synced,
  });

  factory WeeklyReportModel.fromJson(Map<String, dynamic> json) => WeeklyReportModel(
        id: json['id'] as String,
        weekNumber: (json['week_number'] as num).toInt(),
        summary: json['summary'] as String,
        githubLink: json['github_link'] as String?,
        submittedAt: DateTime.parse(json['submitted_at'] as String),
        synced: json['synced'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'week_number': weekNumber,
        'summary': summary,
        'github_link': githubLink,
        'submitted_at': submittedAt.toIso8601String(),
        'synced': synced,
      };
}
