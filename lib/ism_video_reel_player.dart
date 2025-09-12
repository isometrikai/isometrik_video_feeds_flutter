// Core exports
import 'package:ism_video_reel_player/ism_video_reel_player_platform_interface.dart';

export 'core/core.dart';
// DI exports
export 'di/di.dart';
// Domain exports
export 'domain/domain.dart';
// Config exports
export 'isr_video_reel_config.dart';
// Presentation exports
export 'presentation/presentation.dart';
export 'utils/isr_utils.dart';

class IsmVideoReelPlayer {
  Future<String?> getPlatformVersion() =>
      IsmVideoReelPlayerPlatform.instance.getPlatformVersion();
}
