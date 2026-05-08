import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ism_video_reel_player/domain/models/response/story_response.dart';
import 'package:ism_video_reel_player/utils/navigator/highlight_viewer_resolver.dart';
import 'package:ism_video_reel_player/utils/navigator/isr_app_navigator.dart';

void main() {
  group('HighlightViewerResolver', () {
    test('story id normalization trims and deduplicates ids', () {
      final ids = HighlightViewerResolver.normalizedStoryIds(
        ['  story_1 ', 'story_1', '', ' story_2  '],
      );
      expect(ids, ['story_1', 'story_2']);
    });

    test('empty feed returns empty resolved list', () {
      final resolved = HighlightViewerResolver.resolveStoriesByIds(
        stories: const [],
        storyIds: const ['story_1'],
      );
      expect(resolved, isEmpty);
    });

    test('story ids empty resolves empty list', () {
      final resolved = HighlightViewerResolver.resolveStoriesByIds(
        stories: [
          StoryData(id: 'story_1', userId: 'user_1', mediaUrl: 'https://x.jpg'),
        ],
        storyIds: const [],
      );
      expect(resolved, isEmpty);
    });

    test('highlight ids present but no active stories returns empty', () {
      final stories = [
        StoryData(
          id: 'story_1',
          userId: 'user_1',
          mediaUrl: '',
        ),
      ];
      final resolved = HighlightViewerResolver.resolveStoriesByIds(
        stories: stories,
        storyIds: const ['story_1'],
      );
      expect(resolved, isEmpty);
    });

    test('feed empty but detail fetch list can resolve stories', () {
      final fetchedStory = StoryData(
        id: 'story_2',
        userId: 'user_2',
        mediaUrl: 'https://assets/story_2.jpg',
      );
      final resolved = HighlightViewerResolver.resolveStoriesByIds(
        stories: [fetchedStory],
        storyIds: const [' story_2 '],
      );
      expect(resolved.length, 1);
      expect(resolved.first.id, 'story_2');
    });
  });

  testWidgets('cubit missing from context is detected', (tester) async {
    late bool hasCubit;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            hasCubit = IsrAppNavigator.hasStoryCubitInContext(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(hasCubit, isFalse);
  });
}

