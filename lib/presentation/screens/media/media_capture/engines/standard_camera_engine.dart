import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:ism_video_reel_player/domain/models/ar_filter_config.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_capture/engines/camera_capture_engine.dart';

/// Marker / documentation engine for the existing `camera` plugin path.
///
/// The live standard-camera implementation remains inside CameraBloc to
/// preserve segment recording, mic re-init, and framing-music behavior.
/// DeepAR uses DeepArCameraEngine; this class documents the dual-engine
/// contract for hosts and future extraction.
class StandardCameraEngine implements CameraCaptureEngine {
  StandardCameraEngine(this._controller);

  final CameraController _controller;

  @override
  bool get isInitialized =>
      _controller.value.isInitialized && !_controller.value.hasError;

  @override
  bool get isRecording => _controller.value.isRecordingVideo;

  @override
  bool get isFlashOn => _controller.value.flashMode != FlashMode.off;

  @override
  bool get isFlashAvailable =>
      _controller.description.lensDirection == CameraLensDirection.back;

  @override
  Widget buildPreview({VoidCallback? onIosViewCreated}) =>
      CameraPreview(_controller);

  @override
  Future<CameraEngineInitResult> initialize(ArFilterConfig config) async =>
      CameraEngineInitResult(
        success: isInitialized,
        message: isInitialized
            ? 'Standard camera already initialized'
            : 'Standard camera not initialized',
      );

  @override
  Future<void> dispose() async {
    await _controller.dispose();
  }

  @override
  Future<void> flipCamera() async {
    // Handled by CameraBloc (rebuilds CameraController with opposite lens).
  }

  @override
  Future<bool> toggleFlash() async {
    final next = !isFlashOn;
    await _controller.setFlashMode(next ? FlashMode.always : FlashMode.off);
    return next;
  }

  @override
  Future<void> switchEffect(String? pathOrUrl) async {
    // Standard camera has no live AR effects.
  }

  @override
  Future<File> takePhoto() async {
    final file = await _controller.takePicture();
    return File(file.path);
  }

  @override
  Future<void> startVideoRecording() => _controller.startVideoRecording();

  @override
  Future<File> stopVideoRecording() async {
    final file = await _controller.stopVideoRecording();
    return File(file.path);
  }
}
