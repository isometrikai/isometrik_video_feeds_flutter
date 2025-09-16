import 'package:ism_video_reel_player_example/presentation/presentation.dart';

class MusicService {
  const MusicService._();
  static final getDummyTracks = [
    const MusicTrack(
      id: '1',
      title: 'Summer Vibes',
      artist: 'Artist One',
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      duration: Duration(minutes: 6, seconds: 12),
    ),
    const MusicTrack(
      id: '2',
      title: 'Electronic Beat',
      artist: 'Artist Two',
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      duration: Duration(minutes: 7, seconds: 5),
    ),
    const MusicTrack(
      id: '3',
      title: 'Chill Hop',
      artist: 'Artist Three',
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      duration: Duration(minutes: 5, seconds: 44),
    ),
    const MusicTrack(
      id: '4',
      title: 'Pop Energy',
      artist: 'Artist Four',
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
      duration: Duration(minutes: 5, seconds: 2),
    ),
    const MusicTrack(
      id: '5',
      title: 'Acoustic Melody',
      artist: 'Artist Five',
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
      duration: Duration(minutes: 5, seconds: 53),
    ),
  ];
}
