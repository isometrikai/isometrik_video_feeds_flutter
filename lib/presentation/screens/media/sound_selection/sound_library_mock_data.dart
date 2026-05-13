import 'package:ism_video_reel_player/domain/models/sound_library_models.dart';

/// Placeholder content until a sounds API is wired.
abstract final class SoundLibraryMockData {
  /// Used when a track has no `trackUrl` so preview still works in the SDK UI.
  static const String defaultTrackPreviewUrl =
      'https://codeskulptor-demos.commondatastorage.googleapis.com/GalaxyInvaders/theme_01.mp3';

  static const List<SoundCategory> categories = [
    SoundCategory(
      id: 'cat_pop',
      title: 'Pop',
      thumbnailUrl: 'https://picsum.photos/seed/sndpop/200/200',
    ),
    SoundCategory(
      id: 'cat_hiphop',
      title: 'Hip hop',
      thumbnailUrl: 'https://picsum.photos/seed/sndhh/200/200',
    ),
    SoundCategory(
      id: 'cat_indie',
      title: 'Indie',
      thumbnailUrl: 'https://picsum.photos/seed/sndind/200/200',
    ),
    SoundCategory(
      id: 'cat_electronic',
      title: 'Electronic',
      thumbnailUrl: 'https://picsum.photos/seed/sndel/200/200',
    ),
    SoundCategory(
      id: 'cat_classical',
      title: 'Classical',
      thumbnailUrl: 'https://picsum.photos/seed/sndcl/200/200',
    ),
  ];

  static final List<SoundTrack> recent = [
    SoundTrack(
      id: 'r1',
      thumbnailUrl: 'https://picsum.photos/seed/rc1/300/300',
      trackUrl: defaultTrackPreviewUrl,
      title: 'Midnight Drive',
      author: 'Nova Lane',
      duration: Duration(seconds: 28),
      lyricsSnippet: 'We ride till the city lights fade',
      categoryIds: ['cat_pop', 'cat_electronic'],
    ),
    SoundTrack(
      id: 'r2',
      thumbnailUrl: 'https://picsum.photos/seed/rc2/300/300',
      trackUrl: defaultTrackPreviewUrl,
      title: 'Echo Chamber',
      author: 'The Static',
      duration: Duration(seconds: 42),
      categoryIds: ['cat_indie'],
    ),
    SoundTrack(
      id: 'r3',
      thumbnailUrl: 'https://picsum.photos/seed/rc3/300/300',
      trackUrl: defaultTrackPreviewUrl,
      title: 'Gold Frames',
      author: 'Yuki M',
      duration: Duration(seconds: 19),
      lyricsSnippet: 'Picture perfect moments in gold frames',
      categoryIds: ['cat_pop'],
    ),
  ];

  static final List<SoundTrack> trending = [
    SoundTrack(
      id: 't1',
      thumbnailUrl: 'https://picsum.photos/seed/tr1/300/300',
      trackUrl: defaultTrackPreviewUrl,
      title: 'Run It Back',
      author: 'DJ Kline',
      duration: Duration(seconds: 35),
      categoryIds: ['cat_hiphop', 'cat_electronic'],
    ),
    SoundTrack(
      id: 't2',
      thumbnailUrl: 'https://picsum.photos/seed/tr2/300/300',
      trackUrl: defaultTrackPreviewUrl,
      title: 'Soft Launch',
      author: 'Mara Bloom',
      duration: Duration(seconds: 24),
      lyricsSnippet: 'Quiet love in a loud world',
      categoryIds: ['cat_pop', 'cat_indie'],
    ),
    SoundTrack(
      id: 't3',
      thumbnailUrl: 'https://picsum.photos/seed/tr3/300/300',
      trackUrl: defaultTrackPreviewUrl,
      title: 'Pulse',
      author: '404 Collective',
      duration: Duration(seconds: 58),
      categoryIds: ['cat_electronic'],
    ),
  ];

  static final List<SoundTrack> recommended = [
    SoundTrack(
      id: 'rec1',
      thumbnailUrl: 'https://picsum.photos/seed/re1/300/300',
      trackUrl: defaultTrackPreviewUrl,
      title: 'Paper Boats',
      author: 'Harbor Kids',
      duration: Duration(seconds: 31),
      categoryIds: ['cat_indie'],
    ),
    SoundTrack(
      id: 'rec2',
      thumbnailUrl: 'https://picsum.photos/seed/re2/300/300',
      trackUrl: defaultTrackPreviewUrl,
      title: 'Symphony No. 9 (clip)',
      author: 'City Orchestra',
      duration: Duration(seconds: 45),
      categoryIds: ['cat_classical'],
    ),
    SoundTrack(
      id: 'rec3',
      thumbnailUrl: 'https://picsum.photos/seed/re3/300/300',
      trackUrl: defaultTrackPreviewUrl,
      title: 'Neon Steps',
      author: 'Luma',
      duration: Duration(seconds: 22),
      lyricsSnippet: 'Step on neon follow the beat',
      categoryIds: ['cat_hiphop'],
    ),
  ];

  static final List<SoundTrack> saved = [
    SoundTrack(
      id: 's1',
      thumbnailUrl: 'https://picsum.photos/seed/sv1/300/300',
      trackUrl: defaultTrackPreviewUrl,
      title: 'Saved: Bloom',
      author: 'Aster',
      duration: Duration(seconds: 26),
      categoryIds: ['cat_pop'],
    ),
    SoundTrack(
      id: 's2',
      thumbnailUrl: 'https://picsum.photos/seed/sv2/300/300',
      trackUrl: defaultTrackPreviewUrl,
      title: 'Saved: Low Tide',
      author: 'Coastal',
      duration: Duration(seconds: 33),
      categoryIds: ['cat_indie', 'cat_electronic'],
    ),
  ];
}
