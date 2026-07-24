import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';

/// Streams the lesson video and reports playback position upward every
/// few seconds so [CourseDetailScreen] can persist it via
/// `updateLastPosition` — this is the "Smart Video Resume" data path
/// (bonus challenge), even though the UI for jumping back in isn't built
/// until that bonus is prioritized.
class VideoPlayerSection extends StatefulWidget {
  const VideoPlayerSection({
    super.key,
    required this.videoUrl,
    this.localFilePath,
    required this.startPositionSeconds,
    required this.onPositionChanged,
    required this.onCompleted,
  });

  final String videoUrl;
  /// If a downloaded copy exists (see DownloadManager), this is set and
  /// takes priority over [videoUrl] — playback then works with no
  /// network at all, which is the actual point of the Downloads module.
  final String? localFilePath;
  final int startPositionSeconds;
  final ValueChanged<int> onPositionChanged;
  final VoidCallback onCompleted;

  @override
  State<VideoPlayerSection> createState() => _VideoPlayerSectionState();
}

class _VideoPlayerSectionState extends State<VideoPlayerSection> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final controller = widget.localFilePath != null
          ? VideoPlayerController.file(File(widget.localFilePath!))
          : VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await controller.initialize();
      if (widget.startPositionSeconds > 0) {
        await controller.seekTo(Duration(seconds: widget.startPositionSeconds));
      }
      controller.addListener(_onTick);

      if (!mounted) return;
      setState(() {
        _videoController = controller;
        _chewieController = ChewieController(
          videoPlayerController: controller,
          autoPlay: false,
          looping: false,
          materialProgressColors: ChewieProgressColors(
            playedColor: AppColors.primary,
            handleColor: AppColors.primary,
            bufferedColor: AppColors.glassFillStrong,
            backgroundColor: AppColors.glassBorder,
          ),
        );
      });
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _onTick() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;
    final position = controller.value.position;
    widget.onPositionChanged(position.inSeconds);
    if (controller.value.isCompleted) widget.onCompleted();
  }

  @override
  void dispose() {
    _videoController?.removeListener(_onTick);
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.glassFillLight,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Center(
            child: Text('Video unavailable offline', style: TextStyle(color: AppColors.textMuted)),
          ),
        ),
      );
    }

    if (_chewieController == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.glassFillLight,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Chewie(controller: _chewieController!),
      ),
    );
  }
}
