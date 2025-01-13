// sdk_config.dart
import 'package:injectable/injectable.dart';
import 'package:ism_video_reel_player/export.dart';

@lazySingleton
class IsmVideoReelConfig {
  static Future<void> initializeSdk({
    required String baseUrl,
  }) async {
    AppUrl.appBaseUrl = baseUrl;
  }
}
