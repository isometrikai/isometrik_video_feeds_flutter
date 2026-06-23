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

  bool get _isVideo =>
      (post.media?.firstOrNull?.mediaType ?? '').toLowerCase() == 'video';

  bool get _showModerationOverlay => !PostReviewStatusUtil.isPublished(post);

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
          if (_showModerationOverlay)
            PostGridModerationOverlay.forPost(post),
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

  factory PostGridModerationOverlay.forPost(TimeLineData post) {
    return PostGridModerationOverlay(
      status: PostReviewStatusUtil.moderationStatusForGrid(post),
    );
  }

  final PostReviewStatus status;

  Color get _primaryColor =>
      IsrVideoReelConfig.socialConfig.themeConfig?.primaryColor ??
      IsrColors.appColor;

  @override
  Widget build(BuildContext context) {
    final style = _styleForStatus(status);
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 8,
          left: 8,
          child: _StatusBadge(
            label: PostReviewStatusUtil.gridStatusLabel(status),
            icon: style.icon,
            backgroundColor: style.backgroundColor,
            foregroundColor: style.foregroundColor,
            iconOnCircle: style.iconOnCircle,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
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
              textAlign: TextAlign.center,
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
    switch (status) {
      case PostReviewStatus.rejected:
        return const _GridStatusStyle(
          backgroundColor: Color(0xFFDC2626),
          foregroundColor: Colors.white,
          icon: Icons.close,
          iconOnCircle: true,
        );
      case PostReviewStatus.scheduled:
        return _GridStatusStyle(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          icon: Icons.schedule,
          iconOnCircle: true,
        );
      case PostReviewStatus.inReview:
      case PostReviewStatus.resubmitted:
        return const _GridStatusStyle(
          backgroundColor: Color(0xFFFBBF24),
          foregroundColor: Color(0xFF182028),
          icon: Icons.error_outline,
          iconOnCircle: false,
        );
    }
  }
}

class _GridStatusStyle {
  const _GridStatusStyle({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.iconOnCircle,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final bool iconOnCircle;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.iconOnCircle,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool iconOnCircle;

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
            if (iconOnCircle)
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 10, color: backgroundColor),
              )
            else
              Icon(icon, size: 14, color: foregroundColor),
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
