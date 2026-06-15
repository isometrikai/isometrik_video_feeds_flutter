import 'package:flutter_test/flutter_test.dart';
import 'package:ism_video_reel_player/domain/models/response/posts_by_sound_response.dart';

void main() {
  test('PostsBySoundResponse.fromMap parses posts-by-sound envelope', () {
    const raw = '''
{
  "status": "success",
  "message": "ok",
  "status_code": 200,
  "code": "2000",
  "data": [
    {
      "id": "post_1",
      "type": "reel",
      "caption": "test",
      "user_id": "u1",
      "sound_id": "snd_1",
      "sound": {
        "id": "snd_1",
        "title": "Track",
        "artist": "Artist",
        "usage_count": 12
      },
      "media": [
        {
          "media_type": "video",
          "url": "https://example.com/v.mp4",
          "preview_url": "https://example.com/thumb.jpg"
        }
      ],
      "is_liked": false,
      "is_saved": false
    }
  ],
  "total": 12,
  "page": 1,
  "page_size": 20,
  "total_pages": 1,
  "has_next": false,
  "has_previous": false
}
''';

    final response = postsBySoundResponseFromJson(raw);

    expect(response.status, 'success');
    expect(response.statusCode, 200);
    expect(response.total, 12);
    expect(response.hasNext, isFalse);
    expect(response.data, hasLength(1));
    expect(response.data!.first.id, 'post_1');
    expect(response.data!.first.sound?.title, 'Track');
    expect(response.data!.first.sound?.usageCount, 12);
  });
}
