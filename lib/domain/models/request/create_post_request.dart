import 'dart:convert';

import 'package:ism_video_reel_player/domain/domain.dart';

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
    this.settings,
    this.mentions,
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
        settings: json['settings'] == null
            ? null
            : PostSettingModel.fromJson(json['settings'] as Map<String, dynamic>),
        mentions: json['mentions'] == null
            ? []
            : List<MentionData>.from((json['mentions'] as List)
                .map((x) => MentionData.fromJson(x as Map<String, dynamic>))),
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
  PostSettingModel? settings;
  List<MentionData>? mentions;

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
        'settings': settings?.toJson(),
        'mentions': mentions == null ? [] : List<dynamic>.from(mentions!.map((x) => x.toJson())),
      };
}

class PostSettingModel {
  factory PostSettingModel.fromJson(Map<String, dynamic> json) => PostSettingModel(
        advanceInterval: json['advance_interval'] as num? ?? 0,
        ageRestriction: json['age_restriction'] as bool? ?? false,
        autoAdvance: json['auto_advance'] as bool? ?? false,
        commentsEnabled: json['comments_enabled'] as bool? ?? false,
        duetEnabled: json['duet_enabled'] as bool? ?? false,
        saveEnabled: json['save_enabled'] as bool? ?? false,
        stitchEnabled: json['stitch_enabled'] as bool? ?? false,
      );

  PostSettingModel({
    this.advanceInterval,
    this.ageRestriction,
    this.autoAdvance,
    this.commentsEnabled,
    this.duetEnabled,
    this.saveEnabled,
    this.stitchEnabled,
  });

  final num? advanceInterval;
  final bool? ageRestriction;
  final bool? autoAdvance;
  final bool? commentsEnabled;
  final bool? duetEnabled;
  final bool? saveEnabled;
  final bool? stitchEnabled;

  Map<String, dynamic> toJson() => {
        'advance_interval': advanceInterval,
        'age_restriction': ageRestriction,
        'auto_advance': autoAdvance,
        'comments_enabled': commentsEnabled,
        'duet_enabled': duetEnabled,
        'save_enabled': saveEnabled,
        'stitch_enabled': stitchEnabled,
      };
}
