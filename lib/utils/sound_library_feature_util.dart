import 'package:ism_video_reel_player/isr_video_reel_config.dart';

/// Dub / add-sound flows use the live sounds API only when enabled in config.
abstract final class SoundLibraryFeatureUtil {
  static bool get isDubOrAddSoundEnabled =>
      IsrVideoReelConfig.postConfig.enableDubWithAudio ||
      IsrVideoReelConfig.createEditPostConfig.enableAddSoundOnCamera;

  static bool get useSoundsApi => isDubOrAddSoundEnabled;
}
