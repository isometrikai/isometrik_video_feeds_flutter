import 'package:intl/intl.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/res/res.dart';

/// Maps API post fields to [PostReviewStatus] and builds sheet data.
class PostReviewStatusUtil {
  PostReviewStatusUtil._();

  /// Resolves moderation UI status from timeline/API fields.
  static PostReviewStatus? fromApiFields({
    String? status,
    String? scheduledAt,
    int? postStatus,
  }) {
    final normalized = (status ?? '').toLowerCase().trim();

    if (normalized == 'processing') {
      return PostReviewStatus.processing;
    }
    if (normalized.contains('suspended') || postStatus == 2) {
      return PostReviewStatus.rejected;
    }
    if (normalized.contains('resubmit')) {
      return PostReviewStatus.resubmitted;
    }
    if (normalized.contains('review') || normalized.contains('pending') || postStatus == 1) {
      return PostReviewStatus.inReview;
    }
    if (normalized.contains('schedule')) {
      return PostReviewStatus.scheduled;
    }
    return null;
  }

  static PostReviewStatus? fromTimeLineData(TimeLineData post) => fromApiFields(
        status: post.status,
        scheduledAt: post.scheduledAt,
      );

  /// Whether the post is still being processed server-side (not tappable).
  static bool isProcessing(TimeLineData post) =>
      (post.status ?? '').toLowerCase().trim() == 'processing';

  /// Whether the post is live in the profile/grid (no moderation overlay).
  static bool isPublished(TimeLineData post) {
    // if (post.scheduledAt?.isNotEmpty == true) return false;

    final status = (post.status ?? '').toLowerCase().trim();
    if (status.isEmpty) return true;
    return status == 'published' || status == 'active' || status == 'live' || status == 'approved';
  }

  /// Status shown on grid tiles when [isPublished] is false.
  static PostReviewStatus moderationStatusForGrid(TimeLineData post) {
    if (isProcessing(post)) {
      return PostReviewStatus.processing;
    }
    if (isPublished(post)) {
      return PostReviewStatus.inReview;
    }
    return fromTimeLineData(post) ??
        (post.scheduledAt?.isNotEmpty == true
            ? PostReviewStatus.scheduled
            : PostReviewStatus.inReview);
  }

  static String gridStatusLabel(PostReviewStatus status) {
    switch (status) {
      case PostReviewStatus.rejected:
        return IsrTranslationFile.rejected;
      case PostReviewStatus.inReview:
      case PostReviewStatus.resubmitted:
        return IsrTranslationFile.inReview;
      case PostReviewStatus.scheduled:
        return IsrTranslationFile.scheduled;
      case PostReviewStatus.processing:
        return IsrTranslationFile.processing;
    }
  }

  static String statusIconAsset(PostReviewStatus status) {
    switch (status) {
      case PostReviewStatus.rejected:
        return AssetConstants.icRejectedPostIcon;
      case PostReviewStatus.scheduled:
        return AssetConstants.icScheduledPostIcon;
      case PostReviewStatus.inReview:
      case PostReviewStatus.resubmitted:
        return AssetConstants.icReviewPostIconBlack;
      case PostReviewStatus.processing:
        return AssetConstants.icReviewPostIconBlack;
    }
  }

  static String thumbnailUrl(TimeLineData post) {
    final preview = post.previews
        ?.map((e) => e.url ?? '')
        .where((url) => url.isNotEmpty)
        .firstOrNull;
    if (preview != null) return preview;

    final imageMedia = post.media
        ?.where((e) => (e.mediaType ?? '').toLowerCase() != 'video')
        .where((e) => e.url?.isNotEmpty == true)
        .firstOrNull;
    if (imageMedia?.url != null) {
      return imageMedia!.url!;
    }

    final media = post.media?.firstOrNull;
    final mediaPreview = media?.previewUrl ?? '';
    if (mediaPreview.isNotEmpty) return mediaPreview;
    return media?.url ?? '';
  }

  static PostDetailsSheetData sheetDataFromTimeLineData(
    TimeLineData post,
    PostReviewStatus status,
  ) {
    final previewUrl = thumbnailUrl(post);
    final rejectedItems = _rejectedItemsFromPost(post, sheetStatus: status);
    final totalMediaCount = _totalMediaCount(post);
    final postRejectionReason = _postRejectionReason(post);

    return PostDetailsSheetData(
      postId: post.id ?? '',
      status: status,
      sourcePost: post,
      previewImageUrl: previewUrl.isNotEmpty ? previewUrl : null,
      submittedAtLabel: _formatLabel(
        IsrTranslationFile.postDetailsSubmittedLabel,
        _submissionDate(post),
      ),
      reviewedAtLabel: switch (status) {
        PostReviewStatus.rejected ||
        PostReviewStatus.inReview ||
        PostReviewStatus.resubmitted =>
          null,
        _ => _formatLabel(
            IsrTranslationFile.postDetailsReviewedLabel,
            post.publishedAt,
          ),
      },
      scheduledForLabel: status == PostReviewStatus.scheduled
          ? _formatScheduledLabel(
              IsrTranslationFile.postDetailsScheduledForLabel,
              post.scheduledAt,
            )
          : null,
      rejectedCount: rejectedItems.isNotEmpty
          ? rejectedItems.length
          : (status == PostReviewStatus.rejected &&
                  !_hasModerationResults(post) &&
                  totalMediaCount > 0
              ? totalMediaCount
              : null),
      totalMediaCount: totalMediaCount > 0 ? totalMediaCount : null,
      rejectedItems: rejectedItems,
      rejectionReason: postRejectionReason.isNotEmpty ? postRejectionReason : null,
    );
  }

  static String _postRejectionReason(TimeLineData post) {
    final reason = (post.rejectionReason ?? '').trim();
    if (reason.isNotEmpty) return reason;
    return (post.lockReason ?? '').trim();
  }

  static bool _isRejectedModerationStatus(String? value) {
    final normalized = (value ?? '').toLowerCase().trim();
    if (normalized.isEmpty) return false;
    return normalized.contains('reject') ||
        normalized.contains('suspend') ||
        normalized.contains('denied') ||
        normalized.contains('failed') ||
        normalized.contains('blocked');
  }

  static bool _isPostRejected(TimeLineData post, {PostReviewStatus? sheetStatus}) {
    if (sheetStatus == PostReviewStatus.rejected) return true;
    return _isRejectedModerationStatus(post.status);
  }

  static bool _hasModerationResults(TimeLineData post) =>
      post.media?.any((m) => m.moderationResult != null) == true;

  static bool _isMediaFlagged(MediaData item) =>
      (item.moderationResult?.result ?? '').toLowerCase().trim() == 'flagged';

  static List<PostReviewRejectedItem> _rejectedItemsFromPost(
    TimeLineData post, {
    PostReviewStatus? sheetStatus,
  }) {
    final media = post.media ?? [];
    final postRejected = _isPostRejected(post, sheetStatus: sheetStatus);
    final postReason = _postRejectionReason(post);

    if (media.isNotEmpty) {
      if (_hasModerationResults(post)) {
        final items = <PostReviewRejectedItem>[];
        for (var i = 0; i < media.length; i++) {
          final item = media[i];
          if (!_isMediaFlagged(item)) continue;
          items.add(_mediaToRejectedItem(item, i, fallbackReason: postReason));
        }
        return items;
      }

      final items = <PostReviewRejectedItem>[];
      for (var i = 0; i < media.length; i++) {
        final item = media[i];
        final moderation = (item.moderationStatus ?? '').toLowerCase().trim();
        final isRejected =
            _isRejectedModerationStatus(moderation) || (postRejected && moderation.isEmpty);

        if (!isRejected) continue;
        items.add(_mediaToRejectedItem(item, i, fallbackReason: postReason));
      }

      if (items.isEmpty && postRejected) {
        return media
            .asMap()
            .entries
            .map((e) => _mediaToRejectedItem(e.value, e.key, fallbackReason: postReason))
            .toList();
      }
      return items;
    }

    if (postRejected && (post.previews?.isNotEmpty == true)) {
      return post.previews!.asMap().entries.map((e) {
        final index = e.key;
        final preview = e.value;
        final isVideo = (preview.mediaType ?? '').toLowerCase() == 'video';
        final mediaNumber = (preview.position ?? index + 1).toInt();
        return PostReviewRejectedItem(
          label: isVideo
              ? IsrTranslationFile.postReviewVideoLabel(mediaNumber)
              : IsrTranslationFile.postReviewImageLabel(mediaNumber),
          reason: postReason.isNotEmpty
              ? postReason
              : IsrTranslationFile.postDetailsDefaultRejectionReason,
          thumbnailUrl: preview.url,
          isVideo: isVideo,
        );
      }).toList();
    }

    return const [];
  }

  static PostReviewRejectedItem _mediaToRejectedItem(
    MediaData media,
    int index, {
    String fallbackReason = '',
  }) {
    final isVideo = (media.mediaType ?? '').toLowerCase() == 'video';
    final mediaNumber = (media.position ?? index + 1).toInt();
    final label = isVideo
        ? IsrTranslationFile.postReviewVideoLabel(mediaNumber)
        : IsrTranslationFile.postReviewImageLabel(mediaNumber);
    final thumbnail =
        isVideo ? (media.previewUrl?.isNotEmpty == true ? media.previewUrl : media.url) : media.url;
    final moderationDetails = (media.moderationResult?.details ?? '').trim();
    final reason = (media.rejectionReason ?? '').trim();

    return PostReviewRejectedItem(
      label: label,
      reason: moderationDetails.isNotEmpty
          ? moderationDetails
          : reason.isNotEmpty
              ? reason
              : (fallbackReason.isNotEmpty
                  ? fallbackReason
                  : IsrTranslationFile.postDetailsDefaultRejectionReason),
      thumbnailUrl: thumbnail,
      isVideo: isVideo,
      mediaNumber: mediaNumber,
      sourceIndex: index,
    );
  }

  static bool _isVideoMedia(MediaData media) {
    if ((media.mediaType ?? '').toLowerCase().trim() == 'video') return true;
    return (media.postType?.name ?? '').toLowerCase() == 'video';
  }

  static String _mediaThumbnail(MediaData media) {
    final isVideo = _isVideoMedia(media);
    if (isVideo) {
      return media.previewUrl?.isNotEmpty == true ? media.previewUrl! : (media.url ?? '');
    }
    return media.url ?? '';
  }

  static String _rejectionReasonForMedia(
    MediaData media, {
    String fallbackReason = '',
  }) {
    final moderationDetails = (media.moderationResult?.details ?? '').trim();
    final reason = (media.rejectionReason ?? '').trim();
    if (moderationDetails.isNotEmpty) return moderationDetails;
    if (reason.isNotEmpty) return reason;
    if (fallbackReason.isNotEmpty) return fallbackReason;
    return IsrTranslationFile.postDetailsDefaultRejectionReason;
  }

  static bool _isMediaRejectedForSheet(MediaData item, TimeLineData post) {
    if (_hasModerationResults(post)) {
      return _isMediaFlagged(item);
    }
    final postRejected = _isPostRejected(post);
    final moderation = (item.moderationStatus ?? '').toLowerCase().trim();
    if (_isRejectedModerationStatus(moderation)) return true;
    return postRejected && moderation.isEmpty;
  }

  /// All carousel items for the rejected-post details UI (approved + flagged).
  static List<PostReviewMediaItem> allMediaItemsForRejectedPost(TimeLineData post) {
    final media = post.media ?? [];
    if (media.isEmpty) return const [];

    final postReason = _postRejectionReason(post);
    return media.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final mediaNumber = (item.position ?? index + 1).toInt();
      final isVideo = _isVideoMedia(item);
      final rejected = _isMediaRejectedForSheet(item, post);

      return PostReviewMediaItem(
        mediaNumber: mediaNumber,
        sourceIndex: index,
        state: rejected
            ? PostReviewMediaItemState.rejected
            : PostReviewMediaItemState.approved,
        thumbnailUrl: _mediaThumbnail(item),
        isVideo: isVideo,
        rejectionReason: rejected ? _rejectionReasonForMedia(item, fallbackReason: postReason) : null,
      );
    }).toList();
  }

  static int _totalMediaCount(TimeLineData post) {
    if (post.media?.isNotEmpty == true) return post.media!.length;
    if (post.previews?.isNotEmpty == true) return post.previews!.length;
    return 0;
  }

  static String? _submissionDate(TimeLineData post) {
    final published = (post.publishedAt ?? '').trim();
    if (published.isNotEmpty) return published;
    final created = (post.createdAt ?? '').trim();
    if (created.isNotEmpty) return created;
    return null;
  }

  static String? _formatLabel(String prefix, String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return null;
    try {
      final local = DateTime.parse(isoDate).toLocal();
      return '$prefix ${DateFormat('MMM d').format(local)}';
    } catch (_) {
      return null;
    }
  }

  static String? _formatScheduledLabel(String prefix, String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return null;
    try {
      final local = DateTime.parse(isoDate).toLocal();
      return '$prefix ${DateFormat('MMM d, h:mm a').format(local)}';
    } catch (_) {
      return null;
    }
  }

  /// Whether this media item should be included when resubmitting a rejected post.
  static bool isMediaApprovedForResubmit(MediaData item, TimeLineData post) {
    if (_hasModerationResults(post)) {
      if (_isMediaFlagged(item)) return false;
      final result = (item.moderationResult?.result ?? '').toLowerCase().trim();
      if (item.moderationResult != null && result.isNotEmpty) {
        return result == 'approved';
      }
      return true;
    }
    final postRejected = _isPostRejected(post);
    final moderation = (item.moderationStatus ?? '').toLowerCase().trim();
    if (_isRejectedModerationStatus(moderation)) return false;
    if (postRejected && moderation.isEmpty) return false;
    return true;
  }

  /// Maps original 1-based carousel positions to new positions after excluding flagged media.
  static Map<int, int> approvedMediaPositionMap(TimeLineData post) {
    final media = post.media ?? [];
    final map = <int, int>{};
    var newPos = 1;
    for (var i = 0; i < media.length; i++) {
      final item = media[i];
      if (!isMediaApprovedForResubmit(item, post)) continue;
      final oldPos = (item.position ?? i + 1).toInt();
      map[oldPos] = newPos++;
    }
    return map;
  }
}
