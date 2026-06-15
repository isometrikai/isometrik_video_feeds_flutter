import 'package:flutter_test/flutter_test.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';

void main() {
  test('CreateStoryRequest matches stories API media + optional fields', () {
    final request = CreateStoryRequest(
      mediaUrl: 'https://example.com/image.jpg',
      mediaType: 'image',
      caption: 'Having a great day! 🌟',
      mediaPosition: 1,
      assetId: 'image_123',
      description: 'This is a description of the image',
      extraData: const {
        'location': 'New York, NY',
        'weather': 'sunny',
      },
      privacy: 'followers',
      soundId: 'sound_123',
      soundSnapshot: const {
        'end_time': 45,
        'fade_in': 1,
        'fade_out': 2,
        'loop': false,
        'segment_duration': 30,
        'start_time': 15,
        'volume': 0.8,
      },
      tags: const {
        'hashtags': [
          {
            'position': {'end': 58, 'start': 51},
            'tag': 'Travel',
          },
        ],
        'mentions': [
          {
            'position': {'end': 79, 'start': 68},
            'user_id': 'user_456',
            'username': '@friendname',
          },
        ],
        'places': <dynamic>[],
        'products': <dynamic>[],
      },
      textFormatting: const {
        'background': {
          'text_color': '#FFFFFF',
          'type': 'gradient',
          'value': 'blue_purple',
        },
        'font_family': 'Roboto',
        'font_size': 16,
        'font_style': 'normal',
        'text_align': 'left',
      },
      expiresInHours: 24,
    );

    final json = request.toJson();
    final media = json['media'] as Map<String, dynamic>?;
    expect(media, isNotNull);
    expect(media!['url'], 'https://example.com/image.jpg');
    expect(media['media_type'], 'image');
    expect(media['position'], 1);
    expect(media['asset_id'], 'image_123');
    expect(media['description'], 'This is a description of the image');
    expect(json['caption'], 'Having a great day! 🌟');
    expect(json['extra_data'], isA<Map<String, dynamic>>());
    expect(json['privacy'], 'followers');
    expect(json['sound_id'], 'sound_123');
    expect(json['sound_snapshot'], isA<Map<String, dynamic>>());
    expect(json['tags'], isA<Map<String, dynamic>>());
    expect(json['text_formatting'], isA<Map<String, dynamic>>());
    expect(json['expires_in_hours'], 24);
  });

  test('CreateStoryRequest minimal body uses media.url and position', () {
    final request = CreateStoryRequest(
      mediaUrl: 'https://example.com/a.jpg',
      mediaType: 'image',
      mediaPosition: 1,
      caption: 'hello',
    );
    final json = request.toJson();
    final media = json['media'] as Map<String, dynamic>?;
    expect(media!['url'], 'https://example.com/a.jpg');
    expect(media['media_type'], 'image');
    expect(media['position'], 1);
    expect(json['caption'], 'hello');
    expect(json.containsKey('expires_in_hours'), isFalse);
  });

  test('CreateStoryHighlightRequest maps API body keys correctly', () {
    final request = CreateStoryHighlightRequest(
      title: 'My Highlight',
      coverUrl: 'https://cdn.example.com/highlight.jpg',
      sortOrder: 2,
      storyIds: const ['story_1', 'story_2'],
    );

    final json = request.toJson();
    expect(json['title'], 'My Highlight');
    expect(json['cover_url'], 'https://cdn.example.com/highlight.jpg');
    expect(json['sort_order'], 2);
    expect(json['story_ids'], ['story_1', 'story_2']);
  });

  test('CreateStoryRequest video body matches VideoMedia schema', () {
    final request = CreateStoryRequest(
      mediaUrl: 'https://example.com/video.mp4',
      mediaType: 'video',
      mediaPosition: 1,
      caption: 'video',
      videoDurationSeconds: 12,
    );
    final json = request.toJson();
    final media = json['media'] as Map<String, dynamic>?;
    expect(media!['media_type'], 'video');
    expect(media['duration'], 12.0);
    expect(media.containsKey('preview_url'), isFalse);
    expect(media.containsKey('video'), isFalse);
  });

  test('CreateStoryRequest video includes preview_url when set', () {
    final request = CreateStoryRequest(
      mediaUrl: 'https://example.com/video.mp4',
      mediaType: 'video',
      mediaPosition: 1,
      videoDurationSeconds: 8,
      previewUrl: 'https://example.com/video_thumb.jpg',
    );
    final media = request.toJson()['media'] as Map<String, dynamic>?;
    expect(media!['preview_url'], 'https://example.com/video_thumb.jpg');
    expect(media['duration'], 8.0);
  });
}
