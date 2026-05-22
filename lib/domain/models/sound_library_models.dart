/// Reel sound library: category row and track cards (API-ready plain models).
class SoundCategory {
  const SoundCategory({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
  });

  final String id;
  final String title;
  final String thumbnailUrl;
}

class SoundTrack {
  const SoundTrack({
    required this.id,
    required this.thumbnailUrl,
    required this.trackUrl,
    required this.title,
    required this.author,
    required this.duration,
    this.lyricsSnippet,
    this.categoryIds = const [],
  });

  final String id;
  final String thumbnailUrl;
  /// Preview / stream URL when available from your backend.
  final String trackUrl;
  final String title;
  final String author;
  final Duration duration;
  /// Optional text matched when user searches "lyrics".
  final String? lyricsSnippet;
  final List<String> categoryIds;
}
