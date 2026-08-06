import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:ism_video_reel_player/domain/models/ar_filter_config.dart';

/// Result of attempting to initialize a capture engine.
class CameraEngineInitResult {
  const CameraEngineInitResult({
    required this.success,
    this.message = '',
  });

  final bool success;
  final String message;
}

/// Abstraction over standard camera vs DeepAR capture backends.
abstract class CameraCaptureEngine {
  bool get isInitialized;

  bool get isRecording;

  bool get isFlashOn;

  bool get isFlashAvailable;

  /// Builds the live preview widget (DeepAR platform view or camera preview).
  Widget buildPreview({VoidCallback? onIosViewCreated});

  Future<CameraEngineInitResult> initialize(ArFilterConfig config);

  Future<void> dispose();

  Future<void> flipCamera();

  Future<bool> toggleFlash();

  /// Clears the current effect when [pathOrUrl] is null or empty.
  Future<void> switchEffect(String? pathOrUrl);

  Future<File> takePhoto();

  Future<void> startVideoRecording();

  Future<File> stopVideoRecording();
}
