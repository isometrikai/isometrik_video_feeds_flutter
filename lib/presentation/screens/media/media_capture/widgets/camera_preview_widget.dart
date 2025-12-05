import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:video_player/video_player.dart';

class CameraPreviewWidget extends StatefulWidget {
  const CameraPreviewWidget({
    super.key,
    required this.cameraBloc,
    required this.state,
  });

  final CameraBloc cameraBloc;
  final CameraState state;

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  double _baseScale = 1.0;

  @override
  Widget build(BuildContext context) {
    if (widget.state is CameraRecordingReadyState) {
      return _buildVideoPreview(widget.state as CameraRecordingReadyState);
    }
    return _buildCameraPreview(widget.state);
  }

  Widget _buildCameraPreview(CameraState state) {
    if (widget.cameraBloc.recordedVideoPath != null ||
        widget.cameraBloc.capturedPhotoPath != null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (state is CameraLoadingState) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    CameraController? controller;
    var maxZoom = 4.0;

    if (state is CameraInitializedState) {
      controller = state.cameraController;
      maxZoom = state.maxZoom;
    } else if (state is CameraSwitchedState) {
      controller = state.cameraController;
      maxZoom = state.maxZoom;
    } else {
      controller = widget.cameraBloc.cameraController;
    }

    if (controller != null) {
      try {
        final size = MediaQuery.of(context).size;
        final scale = size.aspectRatio * controller.value.aspectRatio;
        final value = controller.value;
        if (!value.hasError &&
            value.isInitialized &&
            mounted &&
            context.mounted) {
          return GestureDetector(
            onScaleStart: (details) {
              _baseScale = widget.cameraBloc.currentZoom;
            },
            onScaleUpdate: (details) {
              if (controller == null ||
                  !controller.value.isInitialized ||
                  controller.value.hasError) {
                return;
              }

              final newScale = (_baseScale * details.scale).clamp(
                1.0,
                maxZoom,
              );

              if ((newScale - widget.cameraBloc.currentZoom).abs() > 0.1) {
                widget.cameraBloc.add(CameraSetZoomEvent(zoomLevel: newScale));
              }
            },
            child: Transform.scale(
              scale: scale < 1 ? 1 / scale : scale,
              child: Center(
                child: CameraPreview(
                  controller,
                ),
              ),
            ),
          );
        }
      } catch (_) {}
    }

    if (mounted) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildVideoPreview(CameraRecordingReadyState state) {
    try {
      final controller = state.videoController;
      final value = controller.value;

      if (!value.isInitialized) {
        return Container(
          color: IsrColors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (controller.value.isInitialized && !controller.value.isPlaying) {
            controller.play();
          }
        } catch (_) {
          // Controller was disposed, ignore
        }
      });

      return VideoPlayer(controller);
    } catch (e) {
      return Container(
        color: IsrColors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
  }
}
