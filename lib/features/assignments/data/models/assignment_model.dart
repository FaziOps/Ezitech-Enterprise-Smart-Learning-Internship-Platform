import '../../domain/entities/assignment_entity.dart';

class AssignmentModel extends AssignmentEntity {
  const AssignmentModel({
    required super.id,
    required super.title,
    required super.description,
    required super.dueAt,
    required super.status,
    required super.evaluationScore,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) => AssignmentModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        dueAt: DateTime.parse(json['due_at'] as String),
        status: _statusFromString(json['status'] as String? ?? 'pending'),
        evaluationScore: (json['evaluation_score'] as num?)?.toInt(),
      );

  static AssignmentStatus _statusFromString(String value) {
    switch (value) {
      case 'submitted':
        return AssignmentStatus.submitted;
      case 'evaluated':
        return AssignmentStatus.evaluated;
      default:
        return AssignmentStatus.pending;
    }
  }
}

class SubmissionModel extends SubmissionEntity {
  const SubmissionModel({
    required super.id,
    required super.assignmentId,
    required super.filePath,
    required super.githubLink,
    required super.submittedAt,
    required super.synced,
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> json) => SubmissionModel(
        id: json['id'] as String,
        assignmentId: json['assignment_id'] as String,
        filePath: json['file_path'] as String?,
        githubLink: json['github_link'] as String?,
        submittedAt: DateTime.parse(json['submitted_at'] as String),
        synced: json['synced'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'assignment_id': assignmentId,
        'file_path': filePath,
        'github_link': githubLink,
        'submitted_at': submittedAt.toIso8601String(),
        'synced': synced,
      };
}
