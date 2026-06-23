import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/comment_count_action_widget.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/feed_text_post_content.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/like_action_widget.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/text_post_formatting.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// Full-screen viewer for formatted (gradient/card) text posts in the feed tab.
///
/// Action state (like, comment, more menu) stays in sync with the parent feed
/// card via shared [IsmSocialActionCubit] listeners and the same callbacks.
class FeedTextPostFullscreenView extends StatelessWidget {
  const FeedTextPostFullscreenView({
    super.key,
    required this.formatting,
    required this.reelsData,
    required this.postSectionType,
    required this.actionIconConfig,
    this.showActionCounts = true,
    this.onPressMoreButton,
    this.onPressLikeButton,
    this.onTapComment,
    this.onTapShare,
    this.formattedAspectRatio = 4 / 5,
  });

  final TextPostFormatting formatting;
  final ReelsData reelsData;
  final PostSectionType postSectionType;
  final ActionIconConfig actionIconConfig;
  final bool showActionCounts;
  final VoidCallback? onPressMoreButton;
  final Future<bool> Function(ReelsData reelsData, bool currentLiked)?
      onPressLikeButton;
  final Future<void> Function()? onTapComment;
  final Future<void> Function()? onTapShare;
  final double formattedAspectRatio;

  static const Color _likeColor = Color(0xFFED4956);
  static const Color _iconColor = Colors.white;

  static Future<void> open(
    BuildContext context, {
    required TextPostFormatting formatting,
    required ReelsData reelsData,
    required PostSectionType postSectionType,
    required ActionIconConfig actionIconConfig,
    bool showActionCounts = true,
    VoidCallback? onPressMoreButton,
    Future<bool> Function(ReelsData reelsData, bool currentLiked)?
        onPressLikeButton,
    Future<void> Function()? onTapComment,
    Future<void> Function()? onTapShare,
    double formattedAspectRatio = 4 / 5,
  }) =>
      Navigator.of(context, rootNavigator: true).push<void>(
        PageRouteBuilder<void>(
          opaque: true,
          pageBuilder: (_, __, ___) => FeedTextPostFullscreenView(
            formatting: formatting,
            reelsData: reelsData,
            postSectionType: postSectionType,
            actionIconConfig: actionIconConfig,
            showActionCounts: showActionCounts,
            onPressMoreButton: onPressMoreButton,
            onPressLikeButton: onPressLikeButton,
            onTapComment: onTapComment,
            onTapShare: onTapShare,
            formattedAspectRatio: formattedAspectRatio,
          ),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: animation,
            child: child,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final iconSize = actionIconConfig.iconSize ?? IsrDimens.twentyFour;
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            SizedBox(height: topInset + IsrDimens.eight),
            Padding(
              padding: IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.twelve),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ChromeIconButton(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      Icons.close,
                      color: _iconColor,
                      size: iconSize,
                    ),
                  ),
                  if (reelsData.postSetting?.isMoreButtonVisible == true)
                    _ChromeIconButton(
                      onTap: onPressMoreButton,
                      child: _buildActionSvg(
                        actionIconConfig.moreIcon ??
                            AssetConstants.icPostMoreIcon,
                        size: iconSize,
                        color: _iconColor,
                      ),
                    )
                  else
                    SizedBox(width: iconSize + IsrDimens.twenty),
                ],
              ),
            ),
            SizedBox(height: IsrDimens.sixteen),
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    IsrDimens.twentyFour,
                    0,
                    IsrDimens.twentyFour,
                    IsrDimens.eight,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth;
                      final maxHeight = constraints.maxHeight;
                      final minHeight = math.min(
                        maxHeight,
                        maxWidth / formattedAspectRatio,
                      );

                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: maxWidth,
                          maxHeight: maxHeight,
                          minHeight: minHeight,
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(IsrDimens.twelve),
                          child: FeedTextPostContent(
                            formatting: formatting,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                IsrDimens.sixteen,
                IsrDimens.twelve,
                IsrDimens.sixteen,
                bottomInset + IsrDimens.twelve,
              ),
              child: _buildBottomActions(iconSize),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(double iconSize) {
    final segments = <Widget>[];

    if (reelsData.postSetting?.isLikeButtonVisible == true) {
      segments.add(
        LikeActionWidget(
          postId: reelsData.postId ?? '',
          builder: (isLoading, isLiked, likeCount, onTap) {
            reelsData.isLiked = isLiked;
            reelsData.likesCount = likeCount;
            final liked = isLiked == true;
            final count = likeCount > 0 ? likeCount : (reelsData.likesCount ?? 0);
            return _actionSegment(
              icon: liked
                  ? (actionIconConfig.likeIconSelected ??
                      AssetConstants.icPostLikeIconSelected)
                  : (actionIconConfig.likeIconUnselected ??
                      AssetConstants.icPostLikeIcon),
              iconSize: iconSize,
              iconColor: liked ? _likeColor : _iconColor,
              applyThemeColor: !liked,
              countLabel: showActionCounts && count > 0
                  ? Utility.formatEngagementCount(count)
                  : null,
              onTap: () => onTap(
                reelData: reelsData,
                postSectionType: postSectionType,
                apiCallBack: onPressLikeButton != null
                    ? () => onPressLikeButton!(reelsData, liked)
                    : null,
              ),
            );
          },
        ),
      );
    }

    if (reelsData.postSetting?.isCommentButtonVisible == true) {
      segments.add(
        CommentCountActionWidget(
          postId: reelsData.postId ?? '',
          builder: (commentCount) {
            reelsData.commentCount = commentCount;
            return _actionSegment(
              icon: actionIconConfig.commentIcon ??
                  AssetConstants.icPostCommentIcon,
              iconSize: iconSize,
              countLabel: showActionCounts && commentCount > 0
                  ? Utility.formatEngagementCount(commentCount)
                  : null,
              onTap: () async {
                await onTapComment?.call();
              },
            );
          },
        ),
      );
    }

    if (reelsData.postSetting?.isShareButtonVisible == true) {
      segments.add(
        _actionSegment(
          icon: actionIconConfig.shareIcon ?? AssetConstants.icPostShareIcon,
          iconSize: iconSize,
          onTap: () => onTapShare?.call(),
        ),
      );
    }

    if (segments.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < segments.length; i++) ...[
          if (i > 0) SizedBox(width: IsrDimens.twenty),
          segments[i],
        ],
      ],
    );
  }

  Widget _actionSegment({
    required String icon,
    required double iconSize,
    required VoidCallback onTap,
    String? countLabel,
    Color? iconColor,
    bool applyThemeColor = true,
  }) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: IsrDimens.edgeInsetsSymmetric(vertical: IsrDimens.four),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionSvg(
                icon,
                size: iconSize,
                color: applyThemeColor ? (iconColor ?? _iconColor) : null,
                applyColorFilter: applyThemeColor,
              ),
              if (countLabel != null) ...[
                IsrDimens.boxWidth(IsrDimens.six),
                Text(
                  countLabel,
                  style: IsrStyles.white14.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
        ),
      );

  Widget _buildActionSvg(
    String icon, {
    required double size,
    Color? color,
    bool applyColorFilter = true,
  }) {
    if (actionIconConfig.useHostAppAssets) {
      return SizedBox(
        width: size,
        height: size,
        child: SvgPicture.asset(
          icon,
          width: size,
          height: size,
          fit: BoxFit.contain,
          bundle: rootBundle,
          colorFilter: applyColorFilter && color != null
              ? ColorFilter.mode(color, BlendMode.srcIn)
              : null,
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: AppImage.svg(
        icon,
        width: size,
        height: size,
        fit: BoxFit.contain,
        color: applyColorFilter ? color : null,
      ),
    );
  }
}

class _ChromeIconButton extends StatelessWidget {
  const _ChromeIconButton({
    required this.onTap,
    required this.child,
  });

  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white.withValues(alpha: 0.12),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: IsrDimens.edgeInsetsAll(IsrDimens.ten),
            child: child,
          ),
        ),
      );
}
