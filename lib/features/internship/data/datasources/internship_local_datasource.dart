import 'package:hive/hive.dart';
import '../models/internship_model.dart';

class InternshipLocalDataSource {
  static const box = 'internship_cache_box';

  static Future<void> openBox() async {
    await Hive.openBox(box);
  }

  Box get _box => Hive.box(box);

  Future<void> cacheTasks(List<InternshipTaskModel> tasks) async {
    await _box.put('tasks', tasks.map((t) => t.toJson()).toList());
  }

  List<InternshipTaskModel> getCachedTasks() {
    final raw = _box.get('tasks') as List? ?? [];
    return raw
        .map((e) => InternshipTaskModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> setTaskDone(String taskId, bool done) async {
    final tasks = getCachedTasks();
    final updated = tasks
        .map((t) => t.id == taskId ? InternshipTaskModel(id: t.id, title: t.title, done: done, dayLabel: t.dayLabel) : t)
        .toList();
    await cacheTasks(updated);
  }

  Future<void> cacheReports(List<WeeklyReportModel> reports) async {
    await _box.put('reports', reports.map((r) => r.toJson()).toList());
  }

  List<WeeklyReportModel> getCachedReports() {
    final raw = _box.get('reports') as List? ?? [];
    return raw
        .map((e) => WeeklyReportModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> addLocalReport(WeeklyReportModel report) async {
    final reports = getCachedReports();
    reports.insert(0, report);
    await cacheReports(reports);
  }

  Future<void> markReportSynced(String reportId) async {
    final reports = getCachedReports();
    final updated = reports
        .map((r) => r.id == reportId
            ? WeeklyReportModel(
                id: r.id,
                weekNumber: r.weekNumber,
                summary: r.summary,
                githubLink: r.githubLink,
                submittedAt: r.submittedAt,
                synced: true,
              )
            : r)
        .toList();
    await cacheReports(updated);
  }
}
