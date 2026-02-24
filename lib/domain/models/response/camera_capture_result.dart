import 'package:ism_video_reel_player/domain/domain.dart';

/// Result returned when the camera capture view is popped.
/// Contains the captured media path and optional sound selection (no merging).
class CameraCaptureResult {
  const CameraCaptureResult({
    required this.mediaPath,
    this.soundData,
  });

  final String mediaPath;
  final SoundData? soundData;
}
