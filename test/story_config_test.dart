import 'package:flutter_test/flutter_test.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';

void main() {
  test('StoryConfig is applied through setUpConfig', () {
    IsrVideoReelConfig.setUpConfig(storyConfig: null);
    expect(IsrVideoReelConfig.storyConfig, isNull);

    const config = StoryConfig();
    IsrVideoReelConfig.setUpConfig(storyConfig: config);
    expect(IsrVideoReelConfig.storyConfig, isNotNull);
    expect(IsrVideoReelConfig.storyConfig!.storyUiConfig.showHighlight, isFalse);
  });

  test('showHighlight can be enabled via StoryUiConfig', () {
    const config = StoryConfig(
      storyUiConfig: StoryUiConfig(showHighlight: true),
    );
    expect(config.storyUiConfig.showHighlight, isTrue);
  });
}
