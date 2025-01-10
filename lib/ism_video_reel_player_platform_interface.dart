import 'package:ism_video_reel_player/ism_video_reel_player_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class IsmVideoReelPlayerPlatform extends PlatformInterface {
  /// Constructs a IsmVideoReelPlayerPlatform.
  IsmVideoReelPlayerPlatform() : super(token: _token);

  static final Object _token = Object();

  static IsmVideoReelPlayerPlatform _instance = MethodChannelIsmVideoReelPlayer();

  /// The default instance of [IsmVideoReelPlayerPlatform] to use.
  ///
  /// Defaults to [MethodChannelIsmVideoReelPlayer].
  static IsmVideoReelPlayerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [IsmVideoReelPlayerPlatform] when
  /// they register themselves.
  static set instance(IsmVideoReelPlayerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
