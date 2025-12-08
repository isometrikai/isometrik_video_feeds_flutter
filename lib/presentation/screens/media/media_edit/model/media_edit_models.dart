import 'package:ism_video_reel_player/presentation/screens/media/media_edit/model/media_edit_audio_model.dart';

enum EditMediaType {
  image,
  video;

  static EditMediaType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'image':
        return EditMediaType.image;
      case 'video':
        return EditMediaType.video;
      default:
        throw ArgumentError('Invalid MediaType: $value');
    }
  }

  String toJson() => name;
}

// Media editing models
class MediaEditItem {
  MediaEditItem({
    required this.originalPath,
    this.editedPath,
    required this.mediaType,
    required this.width,
    required this.height,
    this.duration,
    this.thumbnailPath,
    this.sound,
    this.metaData,
  });

  factory MediaEditItem.fromJson(Map<String, dynamic> json) => MediaEditItem(
      originalPath: json['originalPath'] as String? ?? '',
      editedPath: json['editedPath'] as String?,
      mediaType: json['mediaType'] != null
          ? EditMediaType.fromString(json['mediaType'] as String)
          : EditMediaType.image,
      width: (json['width'] as num? ?? 0).toDouble(),
      height: (json['height'] as num? ?? 0).toDouble(),
      duration: json['duration'] as int?,
      thumbnailPath: json['thumbnailPath'] as String?,
      sound: json['sound'] != null
          ? MediaEditSoundItem.fromJson(json['sound'] as Map<String, dynamic>)
          : null,
      metaData: json['metaData'] as Map<String, dynamic>?);
  final String originalPath;
  String? editedPath;
  final EditMediaType mediaType; // 'image' or 'video'
  final double width;
  final double height;
  final int? duration; // for videos
  String? thumbnailPath;
  MediaEditSoundItem? sound;
  Map<String, dynamic>? metaData;

  MediaEditItem copyWith({
    String? originalPath,
    String? editedPath,
    EditMediaType? mediaType,
    double? width,
    double? height,
    int? duration,
    String? thumbnailPath,
    MediaEditSoundItem? sound,
    Map<String, dynamic>? metaData,
  }) =>
      MediaEditItem(
          originalPath: originalPath ?? this.originalPath,
          editedPath: editedPath ?? this.editedPath,
          mediaType: mediaType ?? this.mediaType,
          width: width ?? this.width,
          height: height ?? this.height,
          duration: duration ?? this.duration,
          thumbnailPath: thumbnailPath ?? this.thumbnailPath,
          sound: sound ?? this.sound,
          metaData: metaData ?? this.metaData);

  Map<String, dynamic> toJson() => {
        'originalPath': originalPath,
        'editedPath': editedPath,
        'mediaType': mediaType.toJson(),
        'width': width,
        'height': height,
        'duration': duration,
        'thumbnailPath': thumbnailPath,
        'sound': sound?.toJson(),
        'metaData': metaData
      };
}
