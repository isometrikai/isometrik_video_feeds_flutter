/// Public entrypoint for the Isometrik Video Reel Player SDK.
///
/// This library re-exports the SDK modules (core/data/di/domain/presentation/etc.)
/// and exposes a minimal top-level API via [IsmVideoReelPlayer].
///
/// Importing [IsrVideoReelConfig] ensures DartDoc references are resolvable.
import 'package:ism_video_reel_player/ism_video_reel_player_platform_interface.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';

/// Core exports.
export 'core/core.dart';
/// Data exports.
export 'data/data.dart';
/// Dependency-injection exports.
export 'di/di.dart';
/// Domain exports.
export 'domain/domain.dart';
export 'domain/models/user_info_class.dart';
/// SDK configuration exports.
export 'isr_video_reel_config.dart';
/// Presentation exports.
export 'presentation/presentation.dart';
/// Remote/API exports.
export 'remote/remote.dart';
/// SDK enums.
export 'utils/enums.dart';
/// Navigation helpers.
export 'utils/navigator/navigator.dart';

/// High-level SDK API.
///
/// Prefer using [IsrVideoReelConfig.initializeSdk] to initialize the SDK.
class IsmVideoReelPlayer {
  /// Returns the native platform version, if available.
  ///
  /// This is primarily useful for debugging and smoke-testing the plugin
  /// installation across platforms.
  Future<String?> getPlatformVersion() =>
      IsmVideoReelPlayerPlatform.instance.getPlatformVersion();
}
