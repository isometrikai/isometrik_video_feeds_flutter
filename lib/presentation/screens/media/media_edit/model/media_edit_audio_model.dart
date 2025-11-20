class MediaEditSoundItem {
  MediaEditSoundItem({
    this.soundId,
    this.soundUrl,
    this.soundImage,
    this.soundArtist,
    this.soundDuration,
    this.soundMetadata,
    this.soundAlbum,
  });

  // Factory constructor to create from JSON
  factory MediaEditSoundItem.fromJson(Map<String, dynamic> json) =>
      MediaEditSoundItem(
        soundId: json['soundId'] as String?,
        soundUrl: json['soundUrl'] as String?,
        soundImage: json['soundImage'] as String?,
        soundArtist: json['soundArtist'] as String?,
        soundDuration: json['soundDuration'] as String?,
        soundAlbum: json['soundAlbum'] as String?,
        soundMetadata: json['soundMetadata'] as Map<String, dynamic>?,
      );
  String? soundId;
  String? soundUrl;
  String? soundImage;
  String? soundArtist;
  String? soundDuration;
  String? soundAlbum;
  Map<String, dynamic>? soundMetadata;

  // Convert to JSON
  Map<String, dynamic> toJson() => {
        'soundId': soundId,
        'soundUrl': soundUrl,
        'soundImage': soundImage,
        'soundArtist': soundArtist,
        'soundDuration': soundDuration,
        'soundAlbum': soundAlbum,
        'soundMetadata': soundMetadata,
      };
}
