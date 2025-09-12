import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ism_video_reel_player/ism_video_reel_player_platform_interface.dart';

/// An implementation of [IsmVideoReelPlayerPlatform] that uses method channels.
class MethodChannelIsmVideoReelPlayer extends IsmVideoReelPlayerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ism_video_reel_player');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
