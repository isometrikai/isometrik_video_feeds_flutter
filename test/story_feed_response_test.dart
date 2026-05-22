import 'package:flutter_test/flutter_test.dart';
import 'package:ism_video_reel_player/domain/models/response/story_response.dart';

void main() {
  test('StoryGroup.allStoriesViewed follows segment flags', () {
    final mixed = StoryGroup(
      stories: [
        StoryData(id: '1', isViewed: true),
        StoryData(id: '2', isViewed: false),
      ],
    );
    expect(mixed.allStoriesViewed, isFalse);
    final done = StoryGroup(
      stories: [
        StoryData(id: '1', isViewed: true),
        StoryData(id: '2', isViewed: true),
      ],
    );
    expect(done.allStoriesViewed, isTrue);
    final empty = StoryGroup(isViewed: true, stories: const []);
    expect(empty.allStoriesViewed, isTrue);
    final emptyNot = StoryGroup(isViewed: false, stories: const []);
    expect(emptyNot.allStoriesViewed, isFalse);
  });

  test('StoryFeedResponse parses data.stories flat list into groups', () {
    final feed = StoryFeedResponse.fromMap({
      'stories': [
        {
          'id': 's1',
          'user_id': 'u1',
          'media_url': 'https://x.com/a.jpg',
          'media_type': 'image',
        },
        {
          'id': 's2',
          'user_id': 'u1',
          'url': 'https://x.com/b.jpg',
          'media_type': 'image',
        },
      ],
      'next_cursor': 'c1',
    });
    expect(feed.unViewed.length, 1);
    expect(feed.unViewed.first.userId, 'u1');
    expect(feed.unViewed.first.stories.length, 2);
    expect(feed.nextCursor, 'c1');
  });

  test('StoryData parses engagement_metrics.view_count', () {
    final story = StoryData.fromMap({
      'id': 'story_da9a6443f399',
      'user_id': 'd196903f-33e1-4ef3-bc69-ad6483e8e516',
      'caption': 'lo',
      'media': {
        'media_type': 'image',
        'url':
            'https://assets.dubly.xyz/stories/image_picker_08669E62.jpg',
      },
      'engagement_metrics': {
        'view_count': 2,
        'reaction_types': {'love': 1},
      },
    });
    expect(story.viewCount, 2);
    expect(story.caption, 'lo');
  });

  test('StoryFeedResponse parses grouped stories rings', () {
    final feed = StoryFeedResponse.fromMap({
      'stories': [
        {
          'user_id': 'u9',
          'username': 'n',
          'stories': [
            {'id': 'a', 'media_url': 'https://m.jpg'},
          ],
        },
      ],
    });
    expect(feed.unViewed.length, 1);
    expect(feed.unViewed.first.stories.length, 1);
    expect(feed.unViewed.first.stories.first.id, 'a');
  });

  test('StoryFeedResponse preserves view_count in grouped feed payload', () {
    final feed = StoryFeedResponse.fromMap({
      'stories': [
        {
          'user_id': 'd196903f-33e1-4ef3-bc69-ad6483e8e516',
          'is_viewed': true,
          'stories': [
            {
              'id': 'story_da9a6443f399',
              'caption': 'lo',
              'media': {
                'media_type': 'image',
                'url': 'https://assets.dubly.xyz/stories/a.jpg',
              },
              'engagement_metrics': {'view_count': 2},
            },
          ],
        },
      ],
    });
    expect(feed.unViewed.first.stories.first.viewCount, 2);
    expect(feed.unViewed.first.stories.first.caption, 'lo');
  });
}
