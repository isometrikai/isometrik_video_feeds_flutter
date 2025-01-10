import 'package:flutter_test/flutter_test.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/ism_video_reel_player_method_channel.dart';
import 'package:ism_video_reel_player/ism_video_reel_player_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockIsmVideoReelPlayerPlatform with MockPlatformInterfaceMixin implements IsmVideoReelPlayerPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final initialPlatform = IsmVideoReelPlayerPlatform.instance;

  test('$MethodChannelIsmVideoReelPlayer is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelIsmVideoReelPlayer>());
  });

  test('getPlatformVersion', () async {
    final ismVideoReelPlayerPlugin = IsmVideoReelPlayer();
    final fakePlatform = MockIsmVideoReelPlayerPlatform();
    IsmVideoReelPlayerPlatform.instance = fakePlatform;

    expect(await ismVideoReelPlayerPlugin.getPlatformVersion(), '42');
  });
}
