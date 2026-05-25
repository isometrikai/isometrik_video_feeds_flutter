import 'package:flutter_test/flutter_test.dart';
import 'package:ism_video_reel_player/domain/models/post_sound_info.dart';

void main() {
  test('PostSoundInfo.fromMap parses post details sound + snapshot', () {
    final sound = PostSoundInfo.fromMap(
      const {
        'id': 'snd_45268d728976',
        'title': 'Channa Mereya',
        'artist': 'Arijit Singh',
        'album': 'Sad & Emotional',
        'type': 'user_upload',
        'usage_count': 1,
      },
      snapshot: const {
        'start_time': 0.0,
        'end_time': 10.0,
        'segment_duration': 10.0,
        'volume': 1.0,
        'fade_in': 0.0,
        'fade_out': 0.0,
        'loop': false,
        'captured_at': '2026-05-25T07:22:23.954086Z',
      },
    );

    expect(sound.id, 'snd_45268d728976');
    expect(sound.title, 'Channa Mereya');
    expect(sound.artist, 'Arijit Singh');
    expect(sound.album, 'Sad & Emotional');
    expect(sound.usageCount, 1);
    expect(sound.displayLabel, 'Channa Mereya • Arijit Singh');
    expect(sound.snapshot, isNotNull);
    expect(sound.snapshot!['segment_duration'], 10.0);
    expect(sound.hasId, isTrue);
  });

  test('PostSoundInfo.displayLabel falls back to artist or default', () {
    expect(
      const PostSoundInfo(id: 'id', artist: 'Adele').displayLabel,
      'Adele',
    );
    expect(
      const PostSoundInfo(id: 'id', title: 'Hello').displayLabel,
      'Hello',
    );
    expect(
      const PostSoundInfo(id: 'id').displayLabel,
      'Original audio',
    );
  });
}
