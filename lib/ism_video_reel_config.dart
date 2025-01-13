// sdk_config.dart
import 'package:injectable/injectable.dart';
import 'package:ism_video_reel_player/export.dart';

@lazySingleton
class IsmVideoReelConfig {
  IsmVideoReelConfig({
    required this.baseUrl,
  });

  final String? baseUrl;

  static Future<void> initializeSdk({
    String? baseUrl,
  }) async {
    AppUrl.appBaseUrl = baseUrl ?? AppUrl.appBaseUrl;
  }
}
