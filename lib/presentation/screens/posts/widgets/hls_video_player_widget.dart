import 'package:flutter/material.dart';
import 'package:flutter_hls_video_player/flutter_hls_video_player/controller/flutter_hls_video_controls.dart';
import 'package:flutter_hls_video_player/flutter_hls_video_player/controller/flutter_hls_video_player_controller.dart';
import 'package:flutter_hls_video_player/flutter_hls_video_player/view/flutter_hls_video_player.dart';

class HlsVideoPlayerWidget extends StatefulWidget {
  const HlsVideoPlayerWidget({super.key, required this.videoUrl});
  final String videoUrl;

  @override
  State<HlsVideoPlayerWidget> createState() => _HlsVideoPlayerWidgetState();
}

class _HlsVideoPlayerWidgetState extends State<HlsVideoPlayerWidget> {
  late FlutterHLSVideoPlayerController controller;
  bool isReady = false;

  @override
  void initState() {
    super.initState();
    controller = FlutterHLSVideoPlayerController();

    init();
  }

  Future<void> init() async {
    await controller.loadHlsVideo(widget.videoUrl);

    // controller.addListener(() {
    //   debugPrint("State: ${controller.playerState}");
    //   debugPrint("Position: ${controller.position}");
    //   debugPrint("Duration: ${controller.duration}");
    // });

    setState(() => isReady = true);

    /// Don't play immediately — wait 100–200ms
    Future.delayed(const Duration(milliseconds: 200), () {
      controller.play();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isReady) {
      return const Center(child: CircularProgressIndicator());
    }

    return FlutterHLSVideoPlayer(
      controller: controller,
      controls: FlutterHLSVideoPlayerControls(
        hideBackArrowWidget: true,
      ),
    );
  }
}
