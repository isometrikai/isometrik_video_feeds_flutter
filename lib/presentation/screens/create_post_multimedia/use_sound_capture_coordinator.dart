import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/screens/create_post_multimedia/dub_with_audio_capture_flow.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// Opens the dub camera with a library sound (not extracted from another reel).
abstract final class UseSoundCaptureCoordinator {
  UseSoundCaptureCoordinator._();

  static Future<void> startFromPostSound(
    BuildContext context,
    PostSoundInfo sound,
  ) async {
    if (!sound.hasId) return;

    var track = PostSoundUtil.soundTrackFromPostSound(sound);
    var audioPath = (sound.previewUrl ?? '').trim();

    if (audioPath.isEmpty && SoundLibraryFeatureUtil.useSoundsApi) {
      final result = await IsmInjectionUtils.getUseCase<SoundLibraryUseCase>()
          .getSoundTrackById(isLoading: true, soundId: sound.id);
      final resolved = result.data;
      if (resolved != null) {
        track = resolved;
        audioPath = resolved.trackUrl.trim();
      }
    }

    if (audioPath.isEmpty) {
      Utility.showToastMessage(IsrTranslationFile.soundPreviewUnavailable);
      return;
    }

    if (!context.mounted) return;

    await DubWithAudioCaptureCoordinator.start(
      context,
      CreatePostLaunchConfig.dubWithExtractedAudio(
        dubAudioFilePath: audioPath,
        dubSoundTrack: track,
      ),
    );
  }
}
