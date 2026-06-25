import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/bloc/posts/social_post_bloc.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/video_player_widget.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/comment_count_action_widget.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/feed_post_media_hero.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/feed_text_post_fullscreen_view.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/like_action_widget.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/text_post_formatting.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/post_feed_image_precache_service.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// Full-screen viewer for feed post content: text cards, images, and video.
///
/// Action state stays in sync with the parent feed card via shared
/// [IsmSocialActionCubit] listeners and the same callbacks.
class FeedPostFullscreenView extends StatefulWidget {
  FeedPostFullscreenView({
    super.key,
    required this.reelsData,
    required this.postSectionType,
    required this.actionIconConfig,
    this.showActionCounts = true,
    this.onPressMoreButton,
    this.onPressLikeButton,
    this.onTapComment,
    this.onTapShare,
    this.textFormatting,
    this.formattedAspectRatio = 4 / 5,
    this.mediaList,
    this.initialMediaIndex = 0,
    this.videoCacheManager,
    this.handoffSnapshot,
    this.onTapMentionTag,
    this.mentionConfig,
  }) : assert(
          textFormatting != null ||
              (mediaList != null && mediaList!.isNotEmpty),
          'Provide textFormatting or a non-empty mediaList.',
        );

  final ReelsData reelsData;
  final PostSectionType postSectionType;
  final ActionIconConfig actionIconConfig;
  final bool showActionCounts;
  final VoidCallback? onPressMoreButton;
  final Future<bool> Function(ReelsData reelsData, bool currentLiked)?
      onPressLikeButton;
  final Future<void> Function()? onTapComment;
  final Future<void> Function()? onTapShare;
  final TextPostFormatting? textFormatting;
  final double formattedAspectRatio;
  final List<MediaMetaData>? mediaList;
  final int initialMediaIndex;
  final VideoCacheManager? videoCacheManager;
  final FeedVideoPlayerHandoffSnapshot? handoffSnapshot;
  final void Function(List<MentionMetaData> mentions)? onTapMentionTag;
  final MentionConfig? mentionConfig;

  static const Color likeColor = Color(0xFFED4956);
  static const Color iconColor = Colors.white;
  static const int _pictureType = 0;

  static Future<void> open(
    BuildContext context, {
    required ReelsData reelsData,
    required PostSectionType postSectionType,
    required ActionIconConfig actionIconConfig,
    bool showActionCounts = true,
    VoidCallback? onPressMoreButton,
    Future<bool> Function(ReelsData reelsData, bool currentLiked)?
        onPressLikeButton,
    Future<void> Function()? onTapComment,
    Future<void> Function()? onTapShare,
    TextPostFormatting? textFormatting,
    double formattedAspectRatio = 4 / 5,
    List<MediaMetaData>? mediaList,
    int initialMediaIndex = 0,
    VideoCacheManager? videoCacheManager,
    FeedVideoPlayerHandoffSnapshot? handoffSnapshot,
    void Function(List<MentionMetaData> mentions)? onTapMentionTag,
    MentionConfig? mentionConfig,
  }) {
    final socialPostBloc = context.getOrCreateBloc<SocialPostBloc>();
    final socialActionCubit = context.getOrCreateBloc<IsmSocialActionCubit>();

    return Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, __, ___) => MultiBlocProvider(
          providers: [
            BlocProvider<SocialPostBloc>.value(value: socialPostBloc),
            BlocProvider<IsmSocialActionCubit>.value(
              value: socialActionCubit,
            ),
          ],
          child: FeedPostFullscreenView(
            reelsData: reelsData,
            postSectionType: postSectionType,
            actionIconConfig: actionIconConfig,
            showActionCounts: showActionCounts,
            onPressMoreButton: onPressMoreButton,
            onPressLikeButton: onPressLikeButton,
            onTapComment: onTapComment,
            onTapShare: onTapShare,
            textFormatting: textFormatting,
            formattedAspectRatio: formattedAspectRatio,
            mediaList: mediaList,
            initialMediaIndex: initialMediaIndex,
            videoCacheManager: videoCacheManager,
            handoffSnapshot: handoffSnapshot,
            onTapMentionTag: onTapMentionTag,
            mentionConfig: mentionConfig,
          ),
        ),
        transitionsBuilder: (_, animation, __, child) {
          // Let [Hero] drive the media flight; only fade chrome overlays.
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: Tween<double>(begin: 0.92, end: 1).animate(fade),
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<FeedPostFullscreenView> createState() => _FeedPostFullscreenViewState();
}

class _FeedPostFullscreenViewState extends State<FeedPostFullscreenView> {
  static const int _pictureType = FeedPostFullscreenView._pictureType;
  static const double _chromeIconSize = 20;
  static const double _chromeButtonPadding = 6;
  static const double _chromeEdgePadding = 16;

  late final PageController? _pageController;
  late int _currentMediaIndex;
  final Map<int, GlobalKey> _videoPlayerKeys = {};
  final ValueNotifier<int> _videoOverlayTick = ValueNotifier(0);

  bool get _isTextCard => widget.textFormatting != null;

  @override
  void initState() {
    super.initState();
    _currentMediaIndex = widget.initialMediaIndex.clamp(
      0,
      math.max(0, (widget.mediaList?.length ?? 1) - 1),
    );
    if (!_isTextCard) {
      _pageController = PageController(initialPage: _currentMediaIndex);
    } else {
      _pageController = null;
    }
  }

  @override
  void dispose() {
    _videoOverlayTick.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  bool _isPicture(MediaMetaData media) => media.mediaType == _pictureType;

  void _closePreview() {
    _commitActiveVideoHandoffToFeed();
    Navigator.of(context).pop();
  }

  void _commitActiveVideoHandoffToFeed() {
    final mediaList = widget.mediaList;
    if (mediaList == null || mediaList.isEmpty) return;
    final index = _currentMediaIndex.clamp(0, mediaList.length - 1);
    final media = mediaList[index];
    if (_isPicture(media)) return;
    final playerKey = _videoPlayerKeys[index];
    if (playerKey == null) return;
    VideoPlayerWidget.of(playerKey)?.publishHandoffReturnToFeed();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.actionIconConfig.iconSize ?? IsrDimens.twentyFour;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _closePreview();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  _chromeEdgePadding,
                  _chromeEdgePadding,
                  _chromeEdgePadding,
                  0,
                ),
                child: _buildTopChrome(),
              ),
              SizedBox(height: _isTextCard ? 0 : IsrDimens.sixteen),
              Expanded(child: _buildContentArea()),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  IsrDimens.sixteen,
                  _isTextCard ? 0 : IsrDimens.twelve,
                  IsrDimens.sixteen,
                  IsrDimens.twelve,
                ),
                child: _buildBottomActions(iconSize),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildTopChrome() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ChromeIconButton(
            onTap: _closePreview,
            padding: _chromeButtonPadding,
            child: Icon(
              Icons.close,
              color: FeedPostFullscreenView.iconColor,
              size: _chromeIconSize,
            ),
          ),
          if (widget.reelsData.postSetting?.isMoreButtonVisible == true)
            _ChromeIconButton(
              onTap: widget.onPressMoreButton,
              padding: _chromeButtonPadding,
              child: _buildActionSvg(
                widget.actionIconConfig.moreIcon ??
                    AssetConstants.icPostMoreIcon,
                size: _chromeIconSize,
                color: FeedPostFullscreenView.iconColor,
              ),
            )
          else
            SizedBox(
              width: _chromeIconSize + (_chromeButtonPadding * 2),
            ),
        ],
      );

  Widget _buildContentArea() {
    if (_isTextCard) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          IsrDimens.twentyFour,
          IsrDimens.sixteen,
          IsrDimens.twentyFour,
          IsrDimens.sixteen,
        ),
        child: FeedTextPostFullscreenCard(
          formatting: widget.textFormatting!.asPlainText(),
          mentions: resolveTextPostMentions(widget.reelsData),
          onMentionTap: widget.onTapMentionTag == null
              ? null
              : (mention) => widget.onTapMentionTag!([mention]),
          onMentionsTap: widget.onTapMentionTag,
          mentionConfig: widget.mentionConfig,
        ),
      );
    }

    final mediaList = widget.mediaList!;
    if (mediaList.length == 1) {
      return _buildMediaPage(mediaList.first, 0);
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: mediaList.length,
      onPageChanged: (index) {
        setState(() => _currentMediaIndex = index);
        _pauseInactiveVideos(activeIndex: index);
      },
      itemBuilder: (context, index) =>
          _buildMediaPage(mediaList[index], index),
    );
  }

  Widget _buildMediaPage(MediaMetaData media, int index) {
    final postId = widget.reelsData.postId ?? '';
    return LayoutBuilder(
      builder: (context, constraints) => ColoredBox(
        color: Colors.black,
        child: Center(
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: _isPicture(media)
                ? FeedPostMediaHeroScope(
                    postId: postId,
                    mediaIndex: index,
                    child: _buildPicturePageContent(media),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      FeedPostMediaHeroScope(
                        postId: postId,
                        mediaIndex: index,
                        child: FeedPostVideoHeroShell(
                          thumbnailUrl: media.thumbnailUrl,
                        ),
                      ),
                      _buildVideoPageContent(media, index),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPicturePageContent(MediaMetaData media) {
    final imageUrl = media.mediaUrl.trim();
    return AppImage.network(
      imageUrl,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      cacheKey: imageUrl,
      cacheManager: IsrPostFeedImageCacheManager.instance,
      fadeAnimationEnable: false,
    );
  }

  Widget _buildVideoPageContent(MediaMetaData media, int index) {
    final playerKey = _videoPlayerKeys.putIfAbsent(
      index,
      () => GlobalKey(debugLabel: 'feed_fullscreen_video_$index'),
    );
    final handoff = index == _currentMediaIndex
        ? (widget.handoffSnapshot ??
            FeedVideoPlayerHandoff.sessionFor(media.mediaUrl.trim()))
        : null;

    return Stack(
      fit: StackFit.expand,
      children: [
        VideoPlayerWidget(
          key: playerKey,
          mediaUrl: media.mediaUrl,
          thumbnailUrl: media.thumbnailUrl,
          videoCacheManager: widget.videoCacheManager ?? VideoCacheManager(),
          isMuted: VideoMuteController.isMuted,
          videoFitOverride: BoxFit.contain,
          visibilityManagedByParent: true,
          isParentVisible: () => _currentMediaIndex == index,
          postSectionType: widget.postSectionType,
          onVisibilityChanged: (_) {},
          onPlaybackStateChanged: () {
            if (mounted) _videoOverlayTick.value++;
          },
          initialHandoff: handoff,
          isHandoffReceiver: handoff != null,
        ),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _toggleVideoPlayPause(playerKey),
          ),
        ),
        ValueListenableBuilder<int>(
          valueListenable: _videoOverlayTick,
          builder: (context, _, __) => _buildVideoPlayPauseOverlay(playerKey),
        ),
      ],
    );
  }

  void _pauseInactiveVideos({required int activeIndex}) {
    for (final entry in _videoPlayerKeys.entries) {
      if (entry.key == activeIndex) continue;
      VideoPlayerWidget.of(entry.value)?.pause();
    }
  }

  void _toggleVideoPlayPause(GlobalKey playerKey) {
    final playerState = VideoPlayerWidget.of(playerKey);
    if (playerState == null || !playerState.mounted) return;

    if (playerState.isPlaying) {
      playerState.pause();
    } else {
      playerState.play();
    }
    _videoOverlayTick.value++;
  }

  Widget _buildVideoPlayPauseOverlay(GlobalKey playerKey) {
    final playerState = VideoPlayerWidget.of(playerKey);
    if (playerState == null ||
        !playerState.mounted ||
        !playerState.showPausedIndicator) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: Center(
        child: Container(
          padding: IsrDimens.edgeInsetsAll(IsrDimens.twelve),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.play_arrow_rounded,
            color: IsrColors.white,
            size: IsrDimens.forty,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(double iconSize) {
    final segments = <Widget>[];
    final reelsData = widget.reelsData;
    final actionIconConfig = widget.actionIconConfig;

    if (reelsData.postSetting?.isLikeButtonVisible == true) {
      segments.add(
        LikeActionWidget(
          postId: reelsData.postId ?? '',
          builder: (isLoading, isLiked, likeCount, onTap) {
            reelsData.isLiked = isLiked;
            reelsData.likesCount = likeCount;
            final liked = isLiked == true;
            final count =
                likeCount > 0 ? likeCount : (reelsData.likesCount ?? 0);
            return _actionSegment(
              icon: liked
                  ? (actionIconConfig.likeIconSelected ??
                      AssetConstants.icPostLikeIconSelected)
                  : (actionIconConfig.likeIconUnselected ??
                      AssetConstants.icPostLikeIcon),
              iconSize: iconSize,
              iconColor: liked
                  ? FeedPostFullscreenView.likeColor
                  : FeedPostFullscreenView.iconColor,
              applyThemeColor: !liked,
              countLabel: widget.showActionCounts && count > 0
                  ? Utility.formatEngagementCount(count)
                  : null,
              onTap: () => onTap(
                reelData: reelsData,
                postSectionType: widget.postSectionType,
                apiCallBack: widget.onPressLikeButton != null
                    ? () => widget.onPressLikeButton!(reelsData, liked)
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
              countLabel: widget.showActionCounts && commentCount > 0
                  ? Utility.formatEngagementCount(commentCount)
                  : null,
              onTap: () async {
                await widget.onTapComment?.call();
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
          onTap: () => widget.onTapShare?.call(),
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
                color: applyThemeColor
                    ? (iconColor ?? FeedPostFullscreenView.iconColor)
                    : null,
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
    if (widget.actionIconConfig.useHostAppAssets) {
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
    this.padding = 6,
  });

  final VoidCallback? onTap;
  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white.withValues(alpha: 0.12),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: child,
          ),
        ),
      );
}

/// Backwards-compatible alias for text-card fullscreen entry points.
typedef FeedTextPostFullscreenView = FeedPostFullscreenView;
