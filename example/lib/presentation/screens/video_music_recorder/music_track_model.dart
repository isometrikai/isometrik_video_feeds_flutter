class MusicTrack {
  const MusicTrack({
    this.id = '',
    this.title = '',
    this.artist = '',
    this.url = '',
    this.duration = Duration.zero,
  });
  final String id;
  final String title;
  final String artist;
  final String url;
  final Duration duration;
}
