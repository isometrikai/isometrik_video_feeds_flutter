import 'package:ism_video_reel_player/utils/utils.dart';

class CreateStoryRequest {
  CreateStoryRequest({
    required this.mediaUrl,
    required this.mediaType,
    this.caption,
    this.expiresInHours,
    required this.mediaPosition,
    this.assetId,
    this.description,
    this.extraData,
    this.privacy,
    this.soundId,
    this.soundSnapshot,
    this.tags,
    this.textFormatting,
    this.videoDurationSeconds,
    this.previewUrl,
  });

  final String mediaUrl;
  final String mediaType;
  final String? caption;

  final int? expiresInHours;

  final int mediaPosition;
  final String? assetId;
  final String? description;
  final Map<String, dynamic>? extraData;
  final String? privacy;
  final String? soundId;
  final Map<String, dynamic>? soundSnapshot;
  final Map<String, dynamic>? tags;
  final Map<String, dynamic>? textFormatting;
  final int? videoDurationSeconds;
  final String? previewUrl;

  Map<String, dynamic> toJson() {
    final isVideo = mediaType.toLowerCase().contains('video');
    final apiMediaType = isVideo ? 'video' : 'image';

    final media = <String, dynamic>{
      'url': mediaUrl,
      'media_type': apiMediaType,
      'position': mediaPosition,
    };
    if (assetId.isStringEmptyOrNull == false) {
      media['asset_id'] = assetId;
    }
    if (description.isStringEmptyOrNull == false) {
      media['description'] = description;
    }
    if (isVideo) {
      final durationSec =
          (videoDurationSeconds ?? 1).clamp(1, 86400).toDouble();
      media['duration'] = durationSec;
      if (previewUrl.isStringEmptyOrNull == false) {
        media['preview_url'] = previewUrl;
      }
    }

    final out = <String, dynamic>{
      'media': media,
    };
    if (caption.isStringEmptyOrNull == false) {
      out['caption'] = caption;
    }
    if (extraData != null && extraData!.isNotEmpty) {
      out['extra_data'] = extraData;
    }
    if (privacy.isStringEmptyOrNull == false) {
      out['privacy'] = privacy;
    }
    if (soundId.isStringEmptyOrNull == false) {
      out['sound_id'] = soundId;
    }
    if (soundSnapshot != null && soundSnapshot!.isNotEmpty) {
      out['sound_snapshot'] = soundSnapshot;
    }
    if (tags != null && tags!.isNotEmpty) {
      out['tags'] = tags;
    }
    if (textFormatting != null && textFormatting!.isNotEmpty) {
      out['text_formatting'] = textFormatting;
    }
    if (expiresInHours != null) {
      out['expires_in_hours'] = expiresInHours;
    }
    return out;
  }
}

class CreateStoryHighlightRequest {
  CreateStoryHighlightRequest({
    required this.title,
    this.coverUrl,
    this.sortOrder,
    this.storyIds,
  });

  final String title;
  final String? coverUrl;
  final int? sortOrder;
  final List<String>? storyIds;

  Map<String, dynamic> toJson() => {
        'title': title,
        'cover_url': coverUrl,
        'sort_order': sortOrder,
        'story_ids': storyIds,
      }.removeEmptyValues();
}

class UpdateStoryHighlightRequest {
  UpdateStoryHighlightRequest({
    this.title,
    this.coverUrl,
    this.sortOrder,
  });

  final String? title;
  final String? coverUrl;
  final int? sortOrder;

  Map<String, dynamic> toJson() => {
        'title': title,
        'cover_url': coverUrl,
        'sort_order': sortOrder,
      }.removeEmptyValues();
}

class AddStoriesToHighlightRequest {
  AddStoriesToHighlightRequest({
    required this.storyIds,
  });

  final List<String> storyIds;

  Map<String, dynamic> toJson() => {'story_ids': storyIds};
}
