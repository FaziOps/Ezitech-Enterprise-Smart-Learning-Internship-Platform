import '../../../courses/domain/entities/course_entity.dart';
import '../../../assignments/domain/entities/assignment_entity.dart';
import '../../../internship/domain/entities/internship_entity.dart';

class StudentContextEntity {
  const StudentContextEntity({
    this.courses = const [],
    this.assignments = const [],
    this.caseStudy,
    this.tasks = const [],
  });

  final List<CourseEntity> courses;
  final List<AssignmentEntity> assignments;
  final CaseStudyEntity? caseStudy;
  final List<InternshipTaskEntity> tasks;

  String toFormattedPrompt() {
    final buffer = StringBuffer();
    buffer.writeln('CURRENT USER LEARNING & INTERNSHIP CONTEXT:');

    if (courses.isNotEmpty) {
      buffer.writeln('\n📚 Enrolled Courses:');
      for (final c in courses) {
        final pct = (c.progress * 100).toStringAsFixed(0);
        buffer.writeln('- ${c.title} (${c.category}): $pct% completed (${c.completedLessons}/${c.totalLessons} lessons)');
      }
    } else {
      buffer.writeln('\n📚 Enrolled Courses: None found');
    }

    if (assignments.isNotEmpty) {
      buffer.writeln('\n📝 Assignments & Deadlines:');
      for (final a in assignments) {
        final daysLeft = a.dueAt.difference(DateTime.now()).inDays;
        final dueStr = '${a.dueAt.year}-${a.dueAt.month.toString().padLeft(2, '0')}-${a.dueAt.day.toString().padLeft(2, '0')}';
        final statusStr = a.status == AssignmentStatus.submitted ? 'Submitted' : (daysLeft < 0 ? 'OVERDUE' : 'Pending ($daysLeft days left)');
        buffer.writeln('- "${a.title}": Due on $dueStr | Status: $statusStr');
      }
    } else {
      buffer.writeln('\n📝 Assignments: No active assignments');
    }

    if (caseStudy != null) {
      buffer.writeln('\n💼 Internship Project:');
      buffer.writeln('- Case Study: "${caseStudy!.title}" (Week ${caseStudy!.currentWeek} of ${caseStudy!.durationWeeks})');
      buffer.writeln('  Description: ${caseStudy!.description}');
    }

    if (tasks.isNotEmpty) {
      buffer.writeln('\n📋 Internship Tasks:');
      for (final t in tasks) {
        buffer.writeln('- [${t.done ? 'x' : ' '}] ${t.title} (${t.dayLabel})');
      }
    }

    return buffer.toString();
  }
}
