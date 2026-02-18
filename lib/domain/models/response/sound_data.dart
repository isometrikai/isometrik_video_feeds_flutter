class SoundData {

  factory SoundData.fromJson(Map<String, dynamic> json) => SoundData(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    artist: json['artist'] as String? ?? '',
    album: json['album'] as String? ?? '',
    duration: json['duration'] as num? ?? 0,
    url: json['url'] as String? ?? '',
    waveformUrl: json['waveform_url'] as String? ?? '',
    previewUrl: json['preview_url'] as String? ?? '',
    type: json['type'] as String? ?? '',
    userId: json['user_id'] as String?,
    status: json['status'] as String? ?? '',
    usageCount: json['usage_count'] as int? ?? 0,
    createdAt: json['created_at'] as String? ?? '',
  );
  SoundData({
    this.id,
    this.title,
    this.artist,
    this.album,
    this.duration,
    this.url,
    this.waveformUrl,
    this.previewUrl,
    this.type,
    this.userId,
    this.status,
    this.usageCount,
    this.createdAt,
  });

  final String? id;
  final String? title;
  final String? artist;
  final String? album;
  final num? duration;
  final String? url;
  final String? waveformUrl;
  final String? previewUrl;
  final String? type;
  final String? userId;
  final String? status;
  final int? usageCount;
  final String? createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'album': album,
    'duration': duration,
    'url': url,
    'waveform_url': waveformUrl,
    'preview_url': previewUrl,
    'type': type,
    'user_id': userId,
    'status': status,
    'usage_count': usageCount,
    'created_at': createdAt,
  };
}
