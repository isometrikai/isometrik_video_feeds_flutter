/// Sound attribution surfaced by `/api/v1/posts/*` responses (the `sound`
/// object plus an optional `sound_snapshot` map).
class PostSoundInfo {
  const PostSoundInfo({
    required this.id,
    this.title,
    this.artist,
    this.album,
    this.type,
    this.usageCount,
    this.previewUrl,
    this.thumbnailUrl,
    this.durationSeconds,
    this.snapshot,
  });

  factory PostSoundInfo.fromMap(
    Map<String, dynamic> map, {
    Map<String, dynamic>? snapshot,
  }) {
    final rawDuration = map['duration'] ?? map['duration_seconds'];
    double? duration;
    if (rawDuration is num) {
      duration = rawDuration.toDouble();
    } else if (rawDuration is String) {
      duration = double.tryParse(rawDuration);
    }

    return PostSoundInfo(
      id: (map['id'] ?? map['sound_id'] ?? '').toString(),
      title: (map['title'] as String?)?.trim(),
      artist: (map['artist'] as String?)?.trim(),
      album: (map['album'] as String?)?.trim(),
      type: (map['type'] as String?)?.trim(),
      usageCount: _readInt(map['usage_count']),
      previewUrl: (map['preview_url'] ?? map['url']) as String?,
      thumbnailUrl: (map['thumbnail_url'] ?? map['waveform_url']) as String?,
      durationSeconds: duration,
      snapshot: snapshot,
    );
  }

  final String id;
  final String? title;
  final String? artist;
  final String? album;
  final String? type;
  final int? usageCount;
  final String? previewUrl;
  final String? thumbnailUrl;
  final double? durationSeconds;
  final Map<String, dynamic>? snapshot;

  bool get hasId => id.isNotEmpty;

  /// `“Title” • Artist` (or fallbacks) suitable for the post sound pill.
  String get displayLabel {
    final t = (title ?? '').trim();
    final a = (artist ?? '').trim();
    if (t.isEmpty && a.isEmpty) return 'Original audio';
    if (t.isEmpty) return a;
    if (a.isEmpty) return t;
    return '$t • $a';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        if (title != null) 'title': title,
        if (artist != null) 'artist': artist,
        if (album != null) 'album': album,
        if (type != null) 'type': type,
        if (usageCount != null) 'usage_count': usageCount,
        if (previewUrl != null) 'preview_url': previewUrl,
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
        if (durationSeconds != null) 'duration': durationSeconds,
        if (snapshot != null) 'sound_snapshot': snapshot,
      };

  static int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
