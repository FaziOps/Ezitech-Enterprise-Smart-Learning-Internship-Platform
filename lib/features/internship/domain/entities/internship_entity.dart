import 'package:equatable/equatable.dart';

class CaseStudyEntity extends Equatable {
  const CaseStudyEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.durationWeeks,
    required this.currentWeek,
  });

  final String id;
  final String title;
  final String description;
  final int durationWeeks;
  final int currentWeek;

  @override
  List<Object?> get props => [id, title, description, durationWeeks, currentWeek];
}

class InternshipTaskEntity extends Equatable {
  const InternshipTaskEntity({
    required this.id,
    required this.title,
    required this.done,
    required this.dayLabel,
  });

  final String id;
  final String title;
  final bool done;
  final String dayLabel;

  InternshipTaskEntity copyWith({bool? done}) => InternshipTaskEntity(
        id: id,
        title: title,
        done: done ?? this.done,
        dayLabel: dayLabel,
      );

  @override
  List<Object?> get props => [id, title, done, dayLabel];
}

class MentorFeedbackEntity extends Equatable {
  const MentorFeedbackEntity({
    required this.id,
    required this.mentorName,
    required this.message,
    required this.givenAt,
    required this.rating,
  });

  final String id;
  final String mentorName;
  final String message;
  final DateTime givenAt;
  final int rating; // 1-5

  @override
  List<Object?> get props => [id, mentorName, message, givenAt, rating];
}

/// A weekly report the student submits — goes through the offline
/// outbox on submit (see InternshipRepositoryImpl.submitWeeklyReport).
class WeeklyReportEntity extends Equatable {
  const WeeklyReportEntity({
    required this.id,
    required this.weekNumber,
    required this.summary,
    required this.githubLink,
    required this.submittedAt,
    this.synced = false,
  });

  final String id;
  final int weekNumber;
  final String summary;
  final String? githubLink;
  final DateTime submittedAt;
  final bool synced;

  @override
  List<Object?> get props => [id, weekNumber, summary, githubLink, submittedAt, synced];
}
