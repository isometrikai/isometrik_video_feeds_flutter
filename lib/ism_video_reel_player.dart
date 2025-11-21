// Core exports
import 'package:ism_video_reel_player/ism_video_reel_player_platform_interface.dart';

export 'core/core.dart';
// Data exports
export 'data/data.dart';
// DI exports
export 'di/di.dart';
// Domain exports
export 'domain/domain.dart';
export 'domain/models/user_info_class.dart';
// Config exports
export 'isr_video_reel_config.dart';
// Presentation exports
export 'presentation/presentation.dart';
//remote
export 'remote/remote.dart';
// page navigator
export 'utils/navigator/navigator.dart';
// enum
export 'utils/enums.dart';


class IsmVideoReelPlayer {
  Future<String?> getPlatformVersion() =>
      IsmVideoReelPlayerPlatform.instance.getPlatformVersion();
}
