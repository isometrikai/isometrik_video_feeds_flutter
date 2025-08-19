import 'dart:convert';

import 'package:ism_video_reel_player_example/domain/domain.dart';

CreatePostRequest createPostRequestFromJson(String str) =>
    CreatePostRequest.fromJson(json.decode(str) as Map<String, dynamic>);

String createPostRequestToJson(CreatePostRequest data) => json.encode(data.toJson());

class CreatePostRequest {
  CreatePostRequest({
    this.caption,
    this.media,
    this.tags,
    this.previews,
    this.status,
    this.type,
    this.visibility,
    this.scheduleTime,
    this.postId,
  });

  factory CreatePostRequest.fromJson(Map<String, dynamic> json) => CreatePostRequest(
        postId: json['id'] as String? ?? '',
        caption: json['caption'] as String? ?? '',
        media: json['media'] == null
            ? []
            : List<MediaData>.from(
                (json['media'] as List).map((x) => MediaData.fromMap(x as Map<String, dynamic>))),
        tags: json['tags'] == null ? null : Tags.fromMap(json['tags'] as Map<String, dynamic>),
        previews: json['previews'] == null
            ? []
            : List<PreviewMedia>.from((json['previews'] as List)
                .map((x) => PreviewMedia.fromMap(x as Map<String, dynamic>))),
        status: json['status'] as String? ?? '',
        type: json['type'] as String? ?? '',
        visibility: json['visibility'] as String? ?? '',
        scheduleTime: json['scheduled_at'] as String? ?? '',
      );
  String? postId;
  String? caption;
  List<MediaData>? media;
  Tags? tags;
  List<PreviewMedia>? previews;
  String? status;
  String? type;
  String? visibility;
  String? scheduleTime;

  CreatePostRequest copyWith({
    String? postId,
    String? caption,
    List<MediaData>? media,
    List<PreviewMedia>? previews,
    Settings? settings,
    String? soundId,
    String? status,
    Tags? tags,
    String? type,
    String? visibility,
    String? scheduleTime,
  }) =>
      CreatePostRequest(
        postId: postId ?? this.postId,
        caption: caption ?? this.caption,
        media: media ?? this.media,
        previews: previews ?? this.previews,
        status: status ?? this.status,
        type: type ?? this.type,
        visibility: visibility ?? this.visibility,
        scheduleTime: scheduleTime ?? this.scheduleTime,
        tags: tags ?? this.tags,
      );

  Map<String, dynamic> toJson() => {
        'id': postId,
        'caption': caption,
        'media': media == null ? [] : List<dynamic>.from(media!.map((x) => x.toMap())),
        'previews': previews == null ? [] : List<dynamic>.from(previews!.map((x) => x.toMap())),
        'status': status,
        'type': type,
        'visibility': visibility,
        'scheduled_at': scheduleTime,
        'tags': tags?.toMap(),
      };
}
