class CreatePostRequest {
  CreatePostRequest({
    this.description,
    this.title,
    this.mediaType,
    this.url,
    this.thumbnailUrl,
    this.duration,
    this.allowComment = false,
    this.allowDownload = false,
    this.story = false,
    this.hasAudio = 0,
    this.imageUrl,
  });

  String? description;
  String? title;
  String? url;
  String? thumbnailUrl;
  int? duration;
  int? mediaType;
  bool? allowComment;
  bool? allowDownload;
  bool? story;
  int? hasAudio;
  String? imageUrl;

  Map<String, dynamic> toJson() => {
        'description': description,
        'url': url,
        'mediaType1': mediaType,
        'thumbnailUrl1': thumbnailUrl,
        'imageUrl1': imageUrl,
        'duration': duration,
        'allowComment': allowComment,
        'allowDownload': allowDownload,
        'story': story,
        'title': title,
        'hasAudio1': hasAudio,
      };
}
