import 'dart:async';
import 'dart:io';

import 'package:deepar_flutter_plus/deepar_flutter_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:ism_video_reel_player/domain/models/ar_filter_config.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_capture/engines/camera_capture_engine.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// DeepAR-backed capture engine used when [ArFilterConfig.isEffectivelyEnabled].
///
/// iOS note: [DeepArControllerPlus.initialize] only partially initializes —
/// `textureId` is set when [DeepArPreviewPlus] mounts. Do not wait for
/// [DeepArControllerPlus.isInitialized] before building the preview.
class DeepArCameraEngine implements CameraCaptureEngine {
  DeepArControllerPlus? _controller;
  bool _sessionStarted = false;
  bool _iosViewReady = false;
  bool _flashOn = false;

  DeepArControllerPlus? get controller => _controller;

  /// True once native init returned success and the controller can build a preview.
  /// On iOS this is true before the platform view creates a textureId.
  bool get canBuildPreview => _sessionStarted && _controller != null;

  @override
  bool get isInitialized {
    if (!canBuildPreview) return false;
    if (Platform.isIOS) return _iosViewReady;
    return _controller?.isInitialized ?? false;
  }

  @override
  bool get isRecording => _controller?.isRecording ?? false;

  @override
  bool get isFlashOn => _flashOn;

  @override
  bool get isFlashAvailable => true;

  Resolution _mapResolution(ArResolution resolution) {
    switch (resolution) {
      case ArResolution.low:
        return Resolution.low;
      case ArResolution.medium:
        return Resolution.medium;
      case ArResolution.high:
        return Resolution.high;
      case ArResolution.veryHigh:
        return Resolution.veryHigh;
    }
  }

  @override
  Widget buildPreview({VoidCallback? onIosViewCreated}) {
    final controller = _controller;
    if (controller == null || !canBuildPreview) {
      return const SizedBox.shrink();
    }
    return DeepArPreviewPlus(
      controller,
      onViewCreated: () {
        _iosViewReady = true;
        onIosViewCreated?.call();
      },
    );
  }

  @override
  Future<CameraEngineInitResult> initialize(ArFilterConfig config) async {
    await dispose();
    final controller = DeepArControllerPlus();
    _controller = controller;

    try {
      final result = await controller.initialize(
        androidLicenseKey: config.androidLicenseKey,
        iosLicenseKey: config.iosLicenseKey,
        resolution: _mapResolution(config.resolution),
      );

      if (!result.success) {
        await dispose();
        return CameraEngineInitResult(
          success: false,
          message: result.message.isNotEmpty
              ? result.message
              : 'DeepAR initialization failed',
        );
      }

      // iOS completes when DeepArPreviewPlus mounts (onPlatformViewCreated).
      // Waiting here deadlocks: preview is only built after we report success.
      if (Platform.isAndroid && !controller.isInitialized) {
        await dispose();
        return const CameraEngineInitResult(
          success: false,
          message: 'DeepAR Android camera did not start',
        );
      }

      _sessionStarted = true;
      _iosViewReady = Platform.isAndroid;
      _flashOn = controller.flashState;
      return CameraEngineInitResult(
        success: true,
        message: result.message,
      );
    } catch (e, st) {
      AppLog.error('DeepArCameraEngine.initialize: $e\n$st');
      await dispose();
      return CameraEngineInitResult(
        success: false,
        message: 'DeepAR initialization error: $e',
      );
    }
  }

  @override
  Future<void> dispose() async {
    final controller = _controller;
    _controller = null;
    _sessionStarted = false;
    _iosViewReady = false;
    _flashOn = false;
    if (controller == null) return;
    try {
      await controller.destroy();
    } catch (e) {
      AppLog.error('DeepArCameraEngine.dispose: $e');
    }
  }

  @override
  Future<void> flipCamera() async {
    final controller = _controller;
    if (controller == null || !isInitialized) return;
    await controller.flipCamera();
  }

  @override
  Future<bool> toggleFlash() async {
    final controller = _controller;
    if (controller == null || !isInitialized) return _flashOn;
    _flashOn = await controller.toggleFlash();
    return _flashOn;
  }

  @override
  Future<void> switchEffect(String? pathOrUrl) async {
    final controller = _controller;
    if (controller == null || !isInitialized) return;
    final path = pathOrUrl?.trim() ?? '';
    if (path.isEmpty) {
      // DeepAR clears the slot when path ends with "none" (Android plugin).
      // Do not call switchEffect('') — that resolves to flutter_assets/ and crashes.
      await controller.switchEffectWithSlot(slot: 'effect', path: 'none');
      return;
    }
    await controller.switchEffect(path);
  }

  @override
  Future<File> takePhoto() async {
    final controller = _controller;
    if (controller == null || !isInitialized) {
      throw StateError('DeepAR camera is not ready for photo capture');
    }
    return controller.takeScreenshot();
  }

  @override
  Future<void> startVideoRecording() async {
    final controller = _controller;
    if (controller == null || !isInitialized) {
      throw StateError('DeepAR camera is not ready for video recording');
    }
    if (controller.isRecording) return;
    await controller.startVideoRecording();
  }

  @override
  Future<File> stopVideoRecording() async {
    final controller = _controller;
    if (controller == null || !isInitialized) {
      throw StateError('DeepAR camera is not ready to stop recording');
    }
    return controller.stopVideoRecording();
  }
}
