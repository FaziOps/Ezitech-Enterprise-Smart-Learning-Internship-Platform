import 'package:flutter_test/flutter_test.dart';
import 'package:ezitech_learning_platform/core/utils/failure.dart';
import 'package:ezitech_learning_platform/features/internship/domain/entities/internship_entity.dart';
import 'package:ezitech_learning_platform/features/internship/domain/repositories/internship_repository.dart';
import 'package:ezitech_learning_platform/features/internship/domain/usecases/submit_weekly_report_usecase.dart';
import 'package:ezitech_learning_platform/features/assignments/domain/entities/assignment_entity.dart';
import 'package:ezitech_learning_platform/features/assignments/domain/repositories/assignment_repository.dart';
import 'package:ezitech_learning_platform/features/assignments/domain/usecases/submit_assignment_usecase.dart';

class _FakeInternshipRepository implements InternshipRepository {
  bool submitCalled = false;

  @override
  Future<void> submitWeeklyReport({
    required int weekNumber,
    required String summary,
    String? githubLink,
  }) async {
    submitCalled = true;
  }

  @override
  Future<Result<CaseStudyEntity>> getAssignedCaseStudy() async => throw UnimplementedError();
  @override
  Future<Result<List<InternshipTaskEntity>>> getDailyTasks() async => throw UnimplementedError();
  @override
  Future<void> toggleTaskDone(String taskId, bool done) async {}
  @override
  Future<Result<List<MentorFeedbackEntity>>> getMentorFeedback() async => throw UnimplementedError();
  @override
  Future<Result<List<WeeklyReportEntity>>> getSubmittedReports() async => const Result.success([]);
}

class _FakeAssignmentRepository implements AssignmentRepository {
  bool submitCalled = false;

  @override
  Future<void> submitAssignment({
    required String assignmentId,
    String? filePath,
    String? githubLink,
  }) async {
    submitCalled = true;
  }

  @override
  Future<Result<List<AssignmentEntity>>> getAssignments() async => const Result.success([]);
  @override
  Future<Result<AssignmentEntity>> getAssignmentDetail(String assignmentId) async =>
      throw UnimplementedError();
  @override
  Future<Result<List<SubmissionEntity>>> getSubmissionHistory(String assignmentId) async =>
      const Result.success([]);
}

void main() {
  group('SubmitWeeklyReportUseCase', () {
    late _FakeInternshipRepository repository;
    late SubmitWeeklyReportUseCase useCase;

    setUp(() {
      repository = _FakeInternshipRepository();
      useCase = SubmitWeeklyReportUseCase(repository);
    });

    test('rejects a summary shorter than 20 characters', () async {
      final result = await useCase(weekNumber: 2, summary: 'too short');
      expect(result.isFailure, isTrue);
      expect(result.failure, isA<ValidationFailure>());
      expect(repository.submitCalled, isFalse);
    });

    test('rejects a github link that is not a github.com URL', () async {
      final result = await useCase(
        weekNumber: 2,
        summary: 'A perfectly reasonable weekly summary of internship progress.',
        githubLink: 'https://gitlab.com/someone/repo',
      );
      expect(result.isFailure, isTrue);
      expect(repository.submitCalled, isFalse);
    });

    test('accepts a valid report and delegates to the repository', () async {
      final result = await useCase(
        weekNumber: 2,
        summary: 'A perfectly reasonable weekly summary of internship progress.',
        githubLink: 'https://github.com/student/repo',
      );
      expect(result.isSuccess, isTrue);
      expect(repository.submitCalled, isTrue);
    });
  });

  group('SubmitAssignmentUseCase', () {
    late _FakeAssignmentRepository repository;
    late SubmitAssignmentUseCase useCase;

    setUp(() {
      repository = _FakeAssignmentRepository();
      useCase = SubmitAssignmentUseCase(repository);
    });

    test('rejects submission with neither a file nor a github link', () async {
      final result = await useCase(assignmentId: 'a1');
      expect(result.isFailure, isTrue);
      expect(repository.submitCalled, isFalse);
    });

    test('accepts a submission with only a file attached', () async {
      final result = await useCase(assignmentId: 'a1', filePath: '/tmp/solution.zip');
      expect(result.isSuccess, isTrue);
      expect(repository.submitCalled, isTrue);
    });
  });
}
