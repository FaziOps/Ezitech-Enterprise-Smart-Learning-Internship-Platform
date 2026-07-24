import 'package:equatable/equatable.dart';

class AssignmentEntity extends Equatable {
  const AssignmentEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.dueAt,
    required this.status,
    required this.evaluationScore,
  });

  final String id;
  final String title;
  final String description;
  final DateTime dueAt;
  final AssignmentStatus status;
  final int? evaluationScore; // null until evaluated

  bool get isOverdue => DateTime.now().isAfter(dueAt) && status != AssignmentStatus.submitted;

  @override
  List<Object?> get props => [id, title, description, dueAt, status, evaluationScore];
}

enum AssignmentStatus { pending, submitted, evaluated }

class SubmissionEntity extends Equatable {
  const SubmissionEntity({
    required this.id,
    required this.assignmentId,
    required this.filePath,
    required this.githubLink,
    required this.submittedAt,
    required this.synced,
  });

  final String id;
  final String assignmentId;
  final String? filePath;
  final String? githubLink;
  final DateTime submittedAt;
  final bool synced;

  @override
  List<Object?> get props => [id, assignmentId, filePath, githubLink, submittedAt, synced];
}
