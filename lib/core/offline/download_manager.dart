import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// Handles the "Downloads" module's core job: fetching a remote asset
/// (lesson video, lesson PDF) once and keeping a local copy so
/// [VideoPlayerSection]/[PdfReaderSection] can play from disk instead of
/// the network. This is what makes "Download for Offline" on the course
/// detail screen do something real instead of just caching JSON metadata
/// (which is all Week 2's `downloadForOffline` actually did).
///
/// Files are keyed by a stable id (lesson id + asset type) so repeated
/// downloads overwrite rather than duplicate, and [isDownloaded] can be
/// checked cheaply before choosing network vs. file playback.
class DownloadManager {
  Future<Directory> get _downloadsDir async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/ezitech_downloads');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String> _pathFor(String key, String extension) async {
    final dir = await _downloadsDir;
    return '${dir.path}/$key.$extension';
  }

  Future<bool> isDownloaded(String key, String extension) async {
    final path = await _pathFor(key, extension);
    return File(path).exists();
  }

  Future<String?> localPathIfExists(String key, String extension) async {
    final path = await _pathFor(key, extension);
    return await File(path).exists() ? path : null;
  }

  /// Downloads [url] to local storage under [key].[extension], reporting
  /// progress via [onProgress] (0.0–1.0) for a download progress UI.
  /// Returns the local file path on success.
  Future<String> download({
    required String url,
    required String key,
    required String extension,
    void Function(double progress)? onProgress,
  }) async {
    final path = await _pathFor(key, extension);
    final dio = Dio();
    await dio.download(
      url,
      path,
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress?.call(received / total);
      },
    );
    return path;
  }

  Future<void> deleteDownload(String key, String extension) async {
    final path = await _pathFor(key, extension);
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  /// Approximate total size of everything downloaded — surfaced in a
  /// future Settings/storage-management screen.
  Future<int> totalCachedBytes() async {
    final dir = await _downloadsDir;
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list()) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }
}
