class ImageData {
  ImageData({
    this.altText,
    this.extraLarge,
    this.large,
    this.medium,
    this.small,
    this.filePath,
    this.seqId,
  });

  factory ImageData.fromJson(Map<String, dynamic> json) => ImageData(
        altText: json['altText'] as String? ?? '',
        extraLarge: json['extraLarge'] as String? ?? '',
        large: json['large'] as String? ?? '',
        medium: json['medium'] as String? ?? '',
        small: json['small'] as String? ?? '',
        filePath: json['filePath'] as String? ?? '',
        seqId: json['seqId'] as num? ?? 0,
      );
  String? altText;
  String? extraLarge;
  String? large;
  String? medium;
  String? small;
  String? filePath;
  num? seqId;

  Map<String, dynamic> toJson() => {
        'altText': altText,
        'extraLarge': extraLarge,
        'large': large,
        'medium': medium,
        'small': small,
        'filePath': filePath,
        'seqId': seqId,
      };
}
