import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/ism_video_reel_player_platform_interface.dart';

final GlobalKey<NavigatorState> kNavigatorKey = GlobalKey<NavigatorState>();

class IsmVideoReelPlayer {
  Future<String?> getPlatformVersion() => IsmVideoReelPlayerPlatform.instance.getPlatformVersion();
}
