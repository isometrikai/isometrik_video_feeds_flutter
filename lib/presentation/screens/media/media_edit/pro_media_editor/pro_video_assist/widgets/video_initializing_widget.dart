import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// A widget that displays a initializing screen when the video editor startup.
class VideoInitializingWidget extends StatelessWidget {
  /// Creates a [VideoInitializingWidget] widget.
  const VideoInitializingWidget({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          color: Colors.white.withValues(alpha: 0.5),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 30,
              children: [
                const Icon(
                  Icons.video_camera_back_rounded,
                  size: 80,
                  color: Colors.black,
                ),
                const Text(
                  'Initializing Video-Editor...',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Utility.loaderWidget(isAdaptive: false),
                ),
              ],
            ),
          ),
        ),
      );
}
