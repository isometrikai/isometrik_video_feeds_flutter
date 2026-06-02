import 'package:ism_video_reel_player/presentation/screens/media/media_edit/model/media_edit_audio_model.dart';

/// Result from [CameraCaptureView]: local media path plus optional library sound.
class CameraCaptureResult {
  const CameraCaptureResult({
    required this.mediaPath,
    this.sound,
    this.soundAppliedToVideo = false,
  });

  final String mediaPath;
  final MediaEditSoundItem? sound;
  /// True when gallery/camera output already has the library track muxed in.
  final bool soundAppliedToVideo;
}
