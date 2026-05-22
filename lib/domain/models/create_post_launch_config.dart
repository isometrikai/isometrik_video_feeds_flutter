import 'package:ism_video_reel_player/domain/models/sound_library_models.dart';

class CreatePostLaunchConfig {
  const CreatePostLaunchConfig({
    this.dubAudioFilePath,
    this.dubSoundTrack,
  });

  factory CreatePostLaunchConfig.dubWithExtractedAudio({
    required String dubAudioFilePath,
    required SoundTrack dubSoundTrack,
  }) =>
      CreatePostLaunchConfig(
        dubAudioFilePath: dubAudioFilePath,
        dubSoundTrack: dubSoundTrack,
      );

  final String? dubAudioFilePath;
  final SoundTrack? dubSoundTrack;
}
