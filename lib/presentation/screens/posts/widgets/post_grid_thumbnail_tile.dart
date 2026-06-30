import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/post_review_status_util.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// Profile/search grid tile with optional moderation status overlay.
class PostGridThumbnailTile extends StatelessWidget {
  const PostGridThumbnailTile({
    super.key,
    required this.post,
    this.showVideoIndicator = true,
    this.borderRadius = 0,
  });

  final TimeLineData post;
  final bool showVideoIndicator;
  final double borderRadius;

  bool get _isVideo => (post.media?.firstOrNull?.mediaType ?? '').toLowerCase() == 'video';

  bool get _showModerationOverlay =>
      PostReviewStatusUtil.isProcessing(post) || !PostReviewStatusUtil.isPublished(post);

  @override
  Widget build(BuildContext context) {
    final coverUrl = PostReviewStatusUtil.thumbnailUrl(post);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (coverUrl.isNotEmpty)
            AppImage.network(
              coverUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              showError: true,
            )
          else
            const ColoredBox(
              color: Color(0xFFEBF0F5),
              child: Icon(Icons.image, color: Color(0xFF829CB6)),
            ),
          if (_showModerationOverlay) PostGridModerationOverlay.forPost(post),
          if (showVideoIndicator && _isVideo && !_showModerationOverlay)
            const Positioned(
              right: 6,
              top: 6,
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}

/// Status tag + "Tap for details" shown on non-published grid items.
class PostGridModerationOverlay extends StatelessWidget {
  const PostGridModerationOverlay({
    super.key,
    required this.status,
  });

  factory PostGridModerationOverlay.forPost(TimeLineData post) => PostGridModerationOverlay(
        status: PostReviewStatusUtil.moderationStatusForGrid(post),
      );

  final PostReviewStatus status;

  Color get _primaryColor =>
      IsrVideoReelConfig.socialConfig.themeConfig?.primaryColor ?? IsrColors.appColor;

  @override
  Widget build(BuildContext context) {
    final style = _styleForStatus(status);
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 8,
          left: 2,
          child: _StatusBadge(
            label: PostReviewStatusUtil.gridStatusLabel(status),
            iconAsset: style.iconAsset,
            backgroundColor: style.backgroundColor,
            foregroundColor: style.foregroundColor,
            iconSize: style.iconSize,
            iconColor: style.iconColor,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: status == PostReviewStatus.processing
              ? const SizedBox.shrink()
              : Container(
                  padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color(0x99000000),
                        Color(0x00000000),
                      ],
                    ),
                  ),
                  child: Text(
                    IsrTranslationFile.tapForDetails,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  _GridStatusStyle _styleForStatus(PostReviewStatus status) {
    final iconAsset = PostReviewStatusUtil.statusIconAsset(status);
    switch (status) {
      case PostReviewStatus.rejected:
        return _GridStatusStyle(
          backgroundColor: const Color(0xFFDC2626),
          foregroundColor: Colors.white,
          iconAsset: iconAsset,
          iconSize: 14,
        );
      case PostReviewStatus.scheduled:
        return _GridStatusStyle(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          iconAsset: iconAsset,
          iconSize: 14,
        );
      case PostReviewStatus.inReview:
      case PostReviewStatus.resubmitted:
        return _GridStatusStyle(
          backgroundColor: const Color(0xFFFBBF24),
          foregroundColor: const Color(0xFF182028),
          iconAsset: iconAsset,
          iconColor: Colors.black,
        );
      case PostReviewStatus.processing:
        return _GridStatusStyle(
          backgroundColor: const Color(0xFF6B7280),
          foregroundColor: Colors.white,
          iconAsset: iconAsset,
          iconColor: Colors.white,
        );
    }
  }
}

class _GridStatusStyle {
  const _GridStatusStyle({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.iconAsset,
    this.iconSize = 14,
    this.iconColor,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final String iconAsset;
  final double iconSize;
  final Color? iconColor;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.iconAsset,
    required this.backgroundColor,
    required this.foregroundColor,
    this.iconSize = 12,
    this.iconColor,
  });

  final String label;
  final String iconAsset;
  final Color backgroundColor;
  final Color foregroundColor;
  final double iconSize;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(5, 4, 8, 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppImage.svg(
              iconAsset,
              width: iconSize,
              height: iconSize,
              color: iconColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}
