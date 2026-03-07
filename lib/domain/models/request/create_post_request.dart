import 'dart:convert';

import 'package:ism_video_reel_player/domain/domain.dart';

CreatePostRequest createPostRequestFromJson(String str) =>
    CreatePostRequest.fromJson(json.decode(str) as Map<String, dynamic>);

String createPostRequestToJson(CreatePostRequest data) =>
    json.encode(data.toJson());

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
    this.soundId,
    this.soundSnapshot,
    this.postId,
    this.settings,
    this.mentions,
  });

  factory CreatePostRequest.fromJson(Map<String, dynamic> json) =>
      CreatePostRequest(
        postId: json['id'] as String? ?? '',
        caption: json['caption'] as String? ?? '',
        media: json['media'] == null
            ? []
            : List<MediaData>.from((json['media'] as List)
                .map((x) => MediaData.fromMap(x as Map<String, dynamic>))),
        tags: json['tags'] == null
            ? null
            : Tags.fromMap(json['tags'] as Map<String, dynamic>),
        previews: json['previews'] == null
            ? []
            : List<PreviewMedia>.from((json['previews'] as List)
                .map((x) => PreviewMedia.fromMap(x as Map<String, dynamic>))),
        status: json['status'] as String? ?? '',
        type: json['type'] as String? ?? '',
        visibility: json['visibility'] as String? ?? '',
        soundId: json['sound_id'] as String? ?? '',
        soundSnapshot: json['sound_snapshot'] == null
            ? null
            : SoundSnapshotData.fromJson(
                json['sound_snapshot'] as Map<String, dynamic>
        ),
        scheduleTime: json['scheduled_at'] as String? ?? '',
        settings: json['settings'] == null
            ? null
            : PostSettingModel.fromJson(
                json['settings'] as Map<String, dynamic>),
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
  String? soundId;
  SoundSnapshotData? soundSnapshot;
  PostSettingModel? settings;
  List<MentionData>? mentions;

  Map<String, dynamic> toJson() => {
        'id': postId,
        'caption': caption,
        'media': media == null
            ? []
            : List<dynamic>.from(media!.map((x) => x.toMap())),
        'previews': previews == null
            ? []
            : List<dynamic>.from(previews!.map((x) => x.toMap())),
        'status': status,
        'type': type,
        'visibility': visibility,
        'scheduled_at': scheduleTime,
        'tags': tags?.toMap(),
        'settings': settings?.toJson(),
        'sound_id': soundId,
        'sound_snapshot': soundSnapshot?.toJson(),
        'mentions': mentions == null
            ? []
            : List<dynamic>.from(mentions!.map((x) => x.toJson())),
      };
}

class SoundSnapshotData {

  factory SoundSnapshotData.fromJson(Map<String, dynamic> json) => SoundSnapshotData(
    loop: json['loop'] as bool? ?? true,
    originalStatus: json['original_status'] as String? ?? '',
    volume: json['volume'] as num? ?? 1.0,
  );

  const SoundSnapshotData({
    this.loop = true,
    this.originalStatus,
    this.volume = 1.0,
  });

  final bool loop;
  final String? originalStatus;
  final num volume;

  Map<String, dynamic> toJson() => {
    'loop': loop,
    'original_status': originalStatus,
    'volume': volume,
  };
}

class PostSettingModel {
  factory PostSettingModel.fromJson(Map<String, dynamic> json) =>
      PostSettingModel(
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
        'advance_interval': advanceInterval ?? 0,
        'age_restriction': ageRestriction ?? false,
        'auto_advance': autoAdvance ?? false,
        'comments_enabled': commentsEnabled ?? false,
        'duet_enabled': duetEnabled ?? false,
        'save_enabled': saveEnabled ?? false,
        'stitch_enabled': stitchEnabled ?? false,
      };
}
