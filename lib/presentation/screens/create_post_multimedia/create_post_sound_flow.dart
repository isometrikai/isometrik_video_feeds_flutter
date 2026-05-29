import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/models/camera_capture_result.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/media_edit.dart' as me;
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/model/media_edit_audio_model.dart';
import 'package:ism_video_reel_player/presentation/screens/media/sound_selection/sound_library_picker_screen.dart';
import 'package:ism_video_reel_player/utils/post_sound_util.dart';
import 'package:ism_video_reel_player/utils/sound_library_feature_util.dart';

/// Helpers for create-post flows that use the sound library.
abstract final class CreatePostSoundFlow {
  static bool get isEnabled => SoundLibraryFeatureUtil.isDubOrAddSoundEnabled;

  static Future<MediaEditSoundItem?> pickSound(BuildContext context) =>
      SoundLibraryPickerScreen.show(context);

  static Future<me.MediaEditItem> buildEditItemFromCapture({
    required String videoPath,
    required int? durationSeconds,
    required String? thumbnailPath,
    MediaEditSoundItem? sound,
    bool soundAlreadyAppliedToVideo = false,
  }) async {
    var path = videoPath;
    if (!soundAlreadyAppliedToVideo &&
        sound != null &&
        sound.soundUrl?.isNotEmpty == true) {
      path = await PostSoundUtil.muxVideoWithSound(
        videoPath: path,
        sound: sound,
      );
    }
    return me.MediaEditItem(
      originalPath: path,
      editedPath: path,
      mediaType: me.EditMediaType.video,
      width: 0,
      height: 0,
      duration: durationSeconds,
      thumbnailPath: thumbnailPath,
      sound: sound,
    );
  }

  static MediaEditSoundItem? soundFromCaptureResult(dynamic result) {
    if (result is CameraCaptureResult) return result.sound;
    return null;
  }

  static String pathFromCaptureResult(dynamic result) {
    if (result is CameraCaptureResult) return result.mediaPath;
    if (result is String) return result;
    return '';
  }

  static Future<MediaEditSoundItem?> onSelectSoundForMediaEdit(
    BuildContext context,
    MediaEditSoundItem? current,
    me.MediaEditItem item,
  ) async {
    if (!isEnabled) return current;
    return pickSound(context);
  }

  static me.MediaEditItem buildEditItemFromPhotoCapture({
    required String imagePath,
    MediaEditSoundItem? sound,
  }) =>
      me.MediaEditItem(
        originalPath: imagePath,
        editedPath: imagePath,
        mediaType: me.EditMediaType.image,
        width: 0,
        height: 0,
        thumbnailPath: imagePath,
        sound: sound,
      );
}
