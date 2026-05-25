import 'package:flutter_test/flutter_test.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/model/media_edit_audio_model.dart';
import 'package:ism_video_reel_player/utils/post_sound_util.dart';

void main() {
  test('buildSoundSnapshot caps clip length and omits title/artist', () {
    final sound = MediaEditSoundItem(
      soundId: 'snd_test',
      soundDuration: '268',
      soundArtist: 'Artist',
      soundMetadata: {'title': 'Song'},
    );

    final snapshot = PostSoundUtil.buildSoundSnapshot(
      sound: sound,
      videoDurationSeconds: 268,
    );

    expect(snapshot.containsKey('title'), isFalse);
    expect(snapshot.containsKey('artist'), isFalse);
    expect(snapshot['start_time'], 0);
    expect(snapshot['segment_duration'], 60);
    expect(snapshot['end_time'], 60);
    expect(snapshot['fade_in'], 0);
    expect(snapshot['fade_out'], 0);
    expect(snapshot['loop'], isFalse);
    expect(snapshot['captured_at'], isA<String>());
  });

  test('buildSoundSnapshot uses shorter video when under 60s', () {
    final sound = MediaEditSoundItem(
      soundId: 'snd_test',
      soundDuration: '120',
    );

    final snapshot = PostSoundUtil.buildSoundSnapshot(
      sound: sound,
      videoDurationSeconds: 15,
    );

    expect(snapshot['segment_duration'], 15);
    expect(snapshot['end_time'], 15);
  });

  test('buildSoundSnapshot includes original_status from metadata', () {
    final sound = MediaEditSoundItem(
      soundId: 'snd_test',
      soundDuration: '30',
      soundMetadata: const {'original_status': 'approved'},
    );

    final snapshot = PostSoundUtil.buildSoundSnapshot(sound: sound);

    expect(snapshot['original_status'], 'approved');
  });
}
