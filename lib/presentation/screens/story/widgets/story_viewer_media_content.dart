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
      final size = controller.value.size;
      final ar = controller.value.aspectRatio == 0 ? 1.0 : controller.value.aspectRatio;
      return ColoredBox(
        color: Colors.black,
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: size.width > 0 ? size.width : ar,
            height: size.height > 0 ? size.height : 1,
            child: VideoPlayer(controller),
          ),
        ),
      );
    }
    if (isVideoStory) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => ColoredBox(
        color: Colors.black,
        child: AppImage.network(
          current.mediaUrl,
          fit: BoxFit.cover,
          width: constraints.maxWidth,
          height: constraints.maxHeight,
        ),
      ),
    );
  }
}
