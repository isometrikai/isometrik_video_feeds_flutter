import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:video_player/video_player.dart';

class StoryViewerMediaContent extends StatelessWidget {
  const StoryViewerMediaContent({
    super.key,
    required this.story,
    required this.isVideo,
    required this.videoController,
  });

  final StoryData? story;
  final bool Function(StoryData story) isVideo;
  final VideoPlayerController? videoController;

  @override
  Widget build(BuildContext context) {
    final current = story;
    if (current == null) return const SizedBox.shrink();
    final isVideoStory = isVideo(current);
    if (isVideoStory && videoController?.value.isInitialized == true) {
      final controller = videoController!;
      return Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio == 0
              ? 1
              : controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      );
    }
    if (isVideoStory) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return Center(
      child: AppImage.network(
        current.mediaUrl,
        fit: BoxFit.contain,
      ),
    );
  }
}
