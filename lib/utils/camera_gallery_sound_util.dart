import 'dart:io';

import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/utils/media_util.dart';
import 'package:ism_video_reel_player/utils/utility.dart';

/// Result of applying the selected camera sound onto a gallery video.
class GallerySoundApplyResult {
  const GallerySoundApplyResult({
    required this.videoPath,
    required this.soundApplied,
  });

  final String videoPath;
  final bool soundApplied;
}

/// Muxes the camera's selected sound onto a gallery (or file) video path.
abstract final class CameraGallerySoundUtil {
  static Future<GallerySoundApplyResult> applySelectedSoundToVideo({
    required CameraBloc cameraBloc,
    required String videoPath,
    bool showLoader = true,
    bool notifyOnFailure = true,
  }) async {
    if (!cameraBloc.hasMusicSelected) {
      return GallerySoundApplyResult(videoPath: videoPath, soundApplied: false);
    }

    final musicPath = cameraBloc.selectedMusicPreviewUrl;
    if (musicPath == null || musicPath.isEmpty) {
      return GallerySoundApplyResult(videoPath: videoPath, soundApplied: false);
    }

    if (showLoader) await Utility.showLoader();
    try {
      final muxed = await MediaUtil.muxVideoWithMusicFromUrl(
        videoPath: videoPath,
        musicUrlOrPath: musicPath,
      );
      if (muxed != null &&
          muxed != videoPath &&
          await File(muxed).exists() &&
          await File(muxed).length() > 64) {
        try {
          await File(videoPath).delete();
        } catch (_) {}
        return GallerySoundApplyResult(videoPath: muxed, soundApplied: true);
      }
      if (notifyOnFailure) {
        Utility.showToastMessage(
          'Could not apply sound to video. Try another clip or sound.',
        );
      }
      return GallerySoundApplyResult(videoPath: videoPath, soundApplied: false);
    } finally {
      if (showLoader) Utility.closeProgressDialog();
    }
  }
}
