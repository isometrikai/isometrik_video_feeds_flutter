import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ism_video_reel_player/ism_video_reel_player_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var platform = MethodChannelIsmVideoReelPlayer();
  const channel = MethodChannel('ism_video_reel_player');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async => '42',
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
