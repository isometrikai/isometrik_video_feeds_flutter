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

  test('StoryFeedResponse parses grouped profile from nested user payload', () {
    final feed = StoryFeedResponse.fromMap({
      'stories': [
        {
          'user': {
            'id': 'u77',
            'display_name': 'Martin Franciss',
            'full_name': 'Martin Franciss',
            'username': 'martinfrancis1038',
            'avatar_url': 'https://x.com/avatar.jpg',
          },
          'stories': [
            {
              'id': 'story_1',
              'user_id': 'u77',
              'media': {
                'media_type': 'image',
                'url': 'https://x.com/story.jpg',
              },
            },
          ],
        },
      ],
    });

    expect(feed.unViewed.first.userId, 'u77');
    expect(feed.unViewed.first.username, 'Martin Franciss');
    expect(feed.unViewed.first.avatarUrl, 'https://x.com/avatar.jpg');
  });

  test('StoriesResponse parses full story list payload', () {
    final response = StoriesResponse.fromMap({
      'status': 'success',
      'message': 'Stories retrieved successfully',
      'status_code': 200,
      'code': '2000',
      'data': [
        {
          'caption': '',
          'tags': {
            'mentions': [],
            'hashtags': [],
            'places': [],
            'products': [],
            'links': [],
          },
          'user_id': '69fdad3ebf81a7aadd61b033',
          'media': {
            'media_type': 'image',
            'asset_id': 'asset_3c3552e25f99',
            'position': 1,
            'url':
                'https://marchecentrale.s3.ap-south-1.amazonaws.com/SoldIsometrik/iOS/streams/1784188462880/69fdad3ebf81a7aadd61b033/1784188462880.jpeg',
            'description': null,
          },
          'sound_id': '',
          'created_at': '2026-07-16T07:54:25.530468+00:00',
          'text_formatting': {},
          'extra_data': {},
          'sound_snapshot': {},
          'id': 'story_f06d739bd806',
          'user': {
            'id': '69fdad3ebf81a7aadd61b033',
            'username': 'martinfrancis1038',
            'full_name': 'Martin Franciss',
            'display_name': 'Martin Franciss',
            'avatar_url':
                'https://s3.ap-south-1.amazonaws.com/marchecentrale/FileData/0/0/1782319943997.jpg',
            'user_metadata': {
              'storeId': '69fdad3ebf81a7aadd61b034',
              'affiliateId': '',
            },
            'verification_status': 'unverified',
            'profile_type': 'Customer',
            'is_private': false,
            'gender': null,
          },
          'engagement_metrics': {
            'view_count': 0,
            'reaction_types': {
              'like': 0,
              'love': 0,
              'haha': 0,
              'wow': 0,
              'sad': 0,
              'angry': 0,
            },
          },
          'is_viewed': false,
        },
      ],
    });

    expect(response.status, 'success');
    expect(response.statusCode, 200);
    expect(response.data?.length, 1);

    final story = response.data!.first;
    expect(story.id, 'story_f06d739bd806');
    expect(story.username, 'martinfrancis1038');
    expect(story.displayName, 'Martin Franciss');
    expect(story.media?.assetId, 'asset_3c3552e25f99');
    expect(story.media?.position, 1);
    expect(story.mediaType, 'image');
    expect(story.tags?.hashtags, isEmpty);
    expect(story.engagementMetrics?.viewCount, 0);
    expect(story.engagementMetrics?.reactionTypes?.love, 0);
    expect(story.isViewed, isFalse);
    expect(story.profileType, 'Customer');
    expect(story.verificationStatus, 'unverified');
  });
}
