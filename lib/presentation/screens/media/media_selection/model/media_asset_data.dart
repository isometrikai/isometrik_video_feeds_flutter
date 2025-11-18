import 'dart:io';

enum SelectedMediaType {
  image,
  video;

  static SelectedMediaType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'image':
        return SelectedMediaType.image;
      case 'video':
        return SelectedMediaType.video;
      default:
        throw ArgumentError('Invalid MediaType: $value');
    }
  }

  String toJson() => name;
}

enum Orientation {
  portrait,
  landscape;

  static Orientation fromString(String value) {
    switch (value.toLowerCase()) {
      case 'portrait':
        return Orientation.portrait;
      case 'landscape':
        return Orientation.landscape;
      default:
        throw ArgumentError('Invalid Orientation: $value');
    }
  }

  String toJson() => name;
}

class MediaAssetData {

  MediaAssetData({
    this.assetId,
    this.localPath,
    this.isTemp,
    this.file,
    this.mediaType,
    this.height,
    this.width,
    this.extension,
    this.duration,
    this.orientation,
    this.thumbnailPath,
    this.isCaptured,
  });

  factory MediaAssetData.fromJson(Map<String, dynamic> json) => MediaAssetData(
      assetId: json['assetId'] as String?,
      localPath: json['localPath'] as String?,
      isTemp: json['isTemp'] as String?,
      file: json['file'] != null ? File(json['file'] as String) : null,
      mediaType: json['mediaType'] != null
          ? SelectedMediaType.fromString(json['mediaType'] as String)
          : null,
      height: json['height'] as int?,
      width: json['width'] as int?,
      extension: json['extension'] as String?,
      duration: json['duration'] as int?,
      orientation: json['orientation'] != null
          ? Orientation.fromString(json['orientation'] as String)
          : null,
      thumbnailPath: json['thumbnailPath'] as String?,
      isCaptured: json['isCaptured'] as bool?,
    );
  String? assetId;
  String? localPath;
  String? isTemp;
  File? file;
  SelectedMediaType? mediaType;
  int? height;
  int? width;
  String? extension;
  int? duration;
  Orientation? orientation;
  String? thumbnailPath;
  bool? isCaptured;

  // Calculate orientation from height and width when not given
  Orientation? get calculatedOrientation {
    if (orientation != null) return orientation;
    if (height != null && width != null) {
      return height! > width! ? Orientation.portrait : Orientation.landscape;
    }
    return null;
  }

  // JSON serialization
  Map<String, dynamic> toJson() => {
      'assetId': assetId,
      'localPath': localPath,
      'isTemp': isTemp,
      'file': file?.path,
      'mediaType': mediaType?.toJson(),
      'height': height,
      'width': width,
      'extension': extension,
      'duration': duration,
      'orientation': orientation?.toJson(),
      'thumbnailPath': thumbnailPath,
      'isCaptured': isCaptured,
    };

  // ===== Override equality and hashCode =====
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MediaAssetData &&
              runtimeType == other.runtimeType &&
              assetId == other.assetId;

  @override
  int get hashCode => assetId.hashCode;
}