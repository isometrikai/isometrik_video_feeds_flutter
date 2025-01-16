import 'package:ism_video_reel_player/ism_video_reel_player_platform_interface.dart';

class IsmVideoReelPlayer {
  Future<String?> getPlatformVersion() => IsmVideoReelPlayerPlatform.instance.getPlatformVersion();
}
