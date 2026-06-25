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
    final preview = post.previews?.firstOrNull?.url;
    if (preview != null && preview.isNotEmpty) return preview;

    final imageMedia =
        post.media?.where((e) => (e.mediaType ?? '').toLowerCase() != 'video').firstOrNull;
    if (imageMedia?.url?.isNotEmpty == true) {
      return imageMedia!.url ?? '';
    }

    return post.media?.firstOrNull?.previewUrl ?? post.media?.firstOrNull?.url ?? '';
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
          : (status == PostReviewStatus.rejected && totalMediaCount > 0 ? totalMediaCount : null),
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

  static List<PostReviewRejectedItem> _rejectedItemsFromPost(
    TimeLineData post, {
    PostReviewStatus? sheetStatus,
  }) {
    final media = post.media ?? [];
    final postRejected = _isPostRejected(post, sheetStatus: sheetStatus);
    final postReason = _postRejectionReason(post);

    if (media.isNotEmpty) {
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
    final reason = (media.rejectionReason ?? '').trim();

    return PostReviewRejectedItem(
      label: label,
      reason: reason.isNotEmpty
          ? reason
          : (fallbackReason.isNotEmpty
              ? fallbackReason
              : IsrTranslationFile.postDetailsDefaultRejectionReason),
      thumbnailUrl: thumbnail,
      isVideo: isVideo,
    );
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
}
