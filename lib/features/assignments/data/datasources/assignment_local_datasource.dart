import 'package:hive/hive.dart';
import '../models/assignment_model.dart';

class AssignmentLocalDataSource {
  static const box = 'assignments_cache_box';

  static Future<void> openBox() async {
    await Hive.openBox(box);
  }

  Box get _box => Hive.box(box);

  Future<void> cacheAssignments(List<AssignmentModel> assignments) async {
    await _box.put('all', assignments.map(_assignmentToJson).toList());
  }

  List<AssignmentModel> getCachedAssignments() {
    final raw = _box.get('all') as List? ?? [];
    return raw.map((e) => _assignmentFromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<void> cacheSubmissions(String assignmentId, List<SubmissionModel> submissions) async {
    await _box.put('submissions_$assignmentId', submissions.map((s) => s.toJson()).toList());
  }

  List<SubmissionModel> getCachedSubmissions(String assignmentId) {
    final raw = _box.get('submissions_$assignmentId') as List? ?? [];
    return raw.map((e) => SubmissionModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<void> addLocalSubmission(String assignmentId, SubmissionModel submission) async {
    final existing = getCachedSubmissions(assignmentId);
    existing.insert(0, submission);
    await cacheSubmissions(assignmentId, existing);
  }

  Future<void> markSubmissionSynced(String assignmentId, String submissionId) async {
    final existing = getCachedSubmissions(assignmentId);
    final updated = existing
        .map((s) => s.id == submissionId
            ? SubmissionModel(
                id: s.id,
                assignmentId: s.assignmentId,
                filePath: s.filePath,
                githubLink: s.githubLink,
                submittedAt: s.submittedAt,
                synced: true,
              )
            : s)
        .toList();
    await cacheSubmissions(assignmentId, updated);
  }

  Map<String, dynamic> _assignmentToJson(AssignmentModel a) => {
        'id': a.id,
        'title': a.title,
        'description': a.description,
        'due_at': a.dueAt.toIso8601String(),
        'status': a.status.name,
        'evaluation_score': a.evaluationScore,
      };

  AssignmentModel _assignmentFromJson(Map<String, dynamic> json) => AssignmentModel.fromJson(json);
}
