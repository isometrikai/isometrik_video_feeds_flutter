import 'package:flutter/material.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

class VideoEditorView extends StatefulWidget {
  const VideoEditorView({super.key, required this.videoPath});
  final String videoPath;

  @override
  State<VideoEditorView> createState() => _VideoEditorViewState();
}

class _VideoEditorViewState extends State<VideoEditorView>
    with VideoEditorMixin {
  @override
  void initState() {
    super.initState();
    initializePlayer();
  }

  @override
  void dispose() {
    videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: proVideoController == null
            ? const VideoInitializingWidget()
            : ProImageEditor.video(
                proVideoController!,
                key: editor,
                callbacks: ProImageEditorCallbacks(
                  onCompleteWithParameters: generateVideo,
                  onCloseEditor: onCloseEditor,
                  videoEditorCallbacks: VideoEditorCallbacks(
                    onPause: videoController.pause,
                    onPlay: videoController.play,
                    onMuteToggle: (isMuted) => videoController.setVolume(
                      isMuted ? 0 : 100,
                    ),
                    onTrimSpanUpdate: (durationSpan) {
                      if (videoController.value.isPlaying) {
                        proVideoController!.pause();
                      }
                    },
                    onTrimSpanEnd: seekToPosition,
                  ),
                ),
                configs: ProImageEditorConfigs(
                  dialogConfigs: DialogConfigs(
                    widgets: DialogWidgets(
                      loadingDialog: (message, configs) => VideoProgressAlert(
                        taskId: taskId,
                      ),
                    ),
                  ),
                  mainEditor: MainEditorConfigs(
                    widgets: MainEditorWidgets(
                      removeLayerArea: (
                        removeAreaKey,
                        editor,
                        rebuildStream,
                        isLayerBeingTransformed,
                      ) =>
                          VideoEditorRemoveArea(
                        removeAreaKey: removeAreaKey,
                        editor: editor,
                        rebuildStream: rebuildStream,
                        isLayerBeingTransformed: isLayerBeingTransformed,
                      ),
                    ),
                  ),
                  paintEditor: const PaintEditorConfigs(
                    enableModePixelate: false,
                    enableModeBlur: false,
                  ),
                  videoEditor: videoConfigs.copyWith(
                    playTimeSmoothingDuration: const Duration(
                      milliseconds: 600,
                    ),
                  ),
                ),
              ),
      );
}
