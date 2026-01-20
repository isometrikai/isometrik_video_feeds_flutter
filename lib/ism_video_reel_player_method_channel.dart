import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ism_video_reel_player/ism_video_reel_player_platform_interface.dart';

/// Default [IsmVideoReelPlayerPlatform] implementation using a [MethodChannel].
///
/// This is used by the plugin unless a platform overrides
/// [IsmVideoReelPlayerPlatform.instance] with its own implementation.
class MethodChannelIsmVideoReelPlayer extends IsmVideoReelPlayerPlatform {
  /// The method channel used to interact with the native platform.
  ///
  /// Exposed for tests so a fake channel can be injected.
  @visibleForTesting
  final methodChannel = const MethodChannel('ism_video_reel_player');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
