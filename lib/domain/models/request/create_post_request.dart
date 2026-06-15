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
    this.postId,
    this.settings,
    this.mentions,
    this.soundId,
    this.soundSnapshot,
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
        scheduleTime: json['scheduled_at'] as String? ?? '',
        settings: json['settings'] == null
            ? null
            : PostSettingModel.fromJson(
                json['settings'] as Map<String, dynamic>),
        mentions: json['mentions'] == null
            ? []
            : List<MentionData>.from((json['mentions'] as List)
                .map((x) => MentionData.fromJson(x as Map<String, dynamic>))),
        soundId: json['sound_id'] as String?,
        soundSnapshot: json['sound_snapshot'] == null
            ? null
            : Map<String, dynamic>.from(
                json['sound_snapshot'] as Map<String, dynamic>,
              ),
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
  String? soundId;
  Map<String, dynamic>? soundSnapshot;

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
        'mentions': mentions == null
            ? []
            : List<dynamic>.from(mentions!.map((x) => x.toJson())),
        if (soundId != null && soundId!.isNotEmpty) 'sound_id': soundId,
        if (soundSnapshot != null && soundSnapshot!.isNotEmpty)
          'sound_snapshot': soundSnapshot,
      };
}

class PostSettingModel {
  factory PostSettingModel.fromJson(Map<String, dynamic> json) {
    final isPaid = _readBool(json['is_paid'], key: 'is_paid');
    final priceAmount =
        _readPriceAmount(json['price_amount'], key: 'price_amount');
    final normalizedIsPaid =
        (isPaid == true && priceAmount == null) ? false : isPaid;

    return PostSettingModel(
      advanceInterval:
          _readNum(json['advance_interval'], key: 'advance_interval') ?? 0,
      ageRestriction:
          _readBool(json['age_restriction'], key: 'age_restriction') ?? false,
      autoAdvance: _readBool(json['auto_advance'], key: 'auto_advance') ?? false,
      commentsEnabled:
          _readBool(json['comments_enabled'], key: 'comments_enabled') ?? false,
      duetEnabled: _readBool(json['duet_enabled'], key: 'duet_enabled') ?? false,
      saveEnabled: _readBool(json['save_enabled'], key: 'save_enabled') ?? false,
      downloadEnabled:
          _readBool(json['download_enabled'], key: 'download_enabled') ?? true,
      stitchEnabled:
          _readBool(json['stitch_enabled'], key: 'stitch_enabled') ?? false,
      isPaid: normalizedIsPaid,
      priceAmount: priceAmount,
      priceCurrency: json['price_currency'] as String?,
    );
  }

  PostSettingModel({
    this.advanceInterval,
    this.ageRestriction,
    this.autoAdvance,
    this.commentsEnabled,
    this.duetEnabled,
    this.saveEnabled,
    this.downloadEnabled,
    this.stitchEnabled,
    this.isPaid,
    this.priceAmount,
    this.priceCurrency,
  });

  final num? advanceInterval;
  final bool? ageRestriction;
  final bool? autoAdvance;
  final bool? commentsEnabled;
  final bool? duetEnabled;
  final bool? saveEnabled;
  final bool? downloadEnabled;
  final bool? stitchEnabled;
  final bool? isPaid;
  final Object? priceAmount;
  final String? priceCurrency;

  static bool? _readBool(dynamic value, {required String key}) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return null;
  }

  static num? _readNum(dynamic value, {required String key}) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) {
      final parsed = num.tryParse(value);
      if (parsed != null) return parsed;
    }
    return null;
  }

  static Object? _readPriceAmount(dynamic value, {required String key}) {
    if (value == null) return null;
    if (value is num || value is String) return value;
    return null;
  }

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'advance_interval': advanceInterval ?? 0,
      'age_restriction': ageRestriction ?? false,
      'auto_advance': autoAdvance ?? false,
      'comments_enabled': commentsEnabled ?? false,
      'duet_enabled': duetEnabled ?? false,
      'save_enabled': saveEnabled ?? false,
      'download_enabled': downloadEnabled ?? true,
      'stitch_enabled': stitchEnabled ?? false,
    };
    final shouldSendPaidFields = isPaid == true &&
        priceAmount != null &&
        (priceCurrency?.trim().isNotEmpty ?? false);
    if (shouldSendPaidFields) {
      payload['is_paid'] = true;
      payload['price_amount'] = priceAmount;
      payload['price_currency'] = priceCurrency;
    }
    return payload;
  }
}
