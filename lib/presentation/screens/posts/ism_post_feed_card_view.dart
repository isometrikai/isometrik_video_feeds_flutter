import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/video_player_widget.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/like_action_widget.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// Single post card for [FeedLayoutType.postFeed].
class IsmPostFeedCardView extends StatefulWidget {
  const IsmPostFeedCardView({
    super.key,
    required this.reelsData,
    required this.reelsConfig,
    required this.postSectionType,
    required this.isPostVisible,
    this.videoCacheManager,
    this.onPressMoreButton,
    this.onPressLikeButton,
    this.onPressSaveButton,
    this.onTapComment,
    this.onTapShare,
    this.onTapUserProfile,
    this.onPressFollowButton,
    this.loggedInUserId,
    this.logIndex,
  });

  final ReelsData reelsData;
  final ReelsConfig reelsConfig;
  final PostSectionType postSectionType;
  final bool isPostVisible;
  final VideoCacheManager? videoCacheManager;
  final VoidCallback? onPressMoreButton;
  final Future<bool> Function(ReelsData reelsData, bool currentLiked)? onPressLikeButton;
  final Future<bool> Function(ReelsData reelsData, bool currentSaved)? onPressSaveButton;
  final Future<int> Function()? onTapComment;
  final Future<void> Function()? onTapShare;
  final Future<void> Function()? onTapUserProfile;
  final Future<bool> Function(ReelsData reelsData, bool currentFollow)? onPressFollowButton;
  final String? loggedInUserId;
  final String? logIndex;

  @override
  State<IsmPostFeedCardView> createState() => _IsmPostFeedCardViewState();
}

class _IsmPostFeedCardViewState extends State<IsmPostFeedCardView> {
  static const int _kPictureType = 0;
  final ValueNotifier<int> _mediaPageIndex = ValueNotifier(0);
  late final PageController _mediaPageController;
  final Map<int, GlobalKey> _videoPlayerKeys = {};
  var _showMuteIconBriefly = false;

  PostConfig get _postConfig => widget.reelsConfig.postConfig;
  PostUIConfig? get _uiConfig => _postConfig.postUIConfig;
  ActionIconConfig? get _actionIconConfig => _uiConfig?.actionIconConfig;
  TextStyleConfig? get _textStyleConfig => _uiConfig?.textStyleConfig;
  UserProfileConfig? get _userProfileConfig => _uiConfig?.userProfileConfig;
  FollowButtonConfig? get _followButtonConfig => _uiConfig?.followButtonConfig;

  PostFeedUIConfig get _feedUi => _postConfig.postFeedUIConfig ?? const PostFeedUIConfig();

  double get _postFeedActionIconSize => _actionIconConfig?.iconSize ?? IsrDimens.twenty;

  ReelsData get _reel => widget.reelsData;

  VideoCacheManager get _videoCacheManager => widget.videoCacheManager ?? VideoCacheManager();

  @override
  void initState() {
    super.initState();
    VideoMuteController.notifier.addListener(_onGlobalMuteChanged);
    _mediaPageController = PageController();
  }

  @override
  void dispose() {
    VideoMuteController.notifier.removeListener(_onGlobalMuteChanged);
    _mediaPageIndex.dispose();
    _mediaPageController.dispose();
    super.dispose();
  }

  void _onGlobalMuteChanged() {
    if (!mounted) return;
    setState(() {});
  }

  String? get _locationLabel {
    final place = _reel.placeDataList?.firstOrNull;
    if (place == null) return null;
    if (place.placeName.isNotEmpty) return place.placeName;
    if (place.city?.isNotEmpty == true) return place.city;
    return null;
  }

  bool get _isViewerPostAuthor {
    final uid = widget.loggedInUserId;
    if (uid.isStringEmptyOrNull == true) return false;
    return uid == _reel.userId;
  }

  TextStyle get _mediaOverlayNameStyle =>
      _textStyleConfig?.userNameStyle ?? IsrStyles.white14.copyWith(fontWeight: FontWeight.w600);

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: _feedUi.backgroundColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMediaSection(context),
            _buildActionsSection(context),
            _buildEngagementSection(context),
          ],
        ),
      );

  Widget _buildMediaSection(BuildContext context) {
    final mediaList = _reel.mediaMetaDataList;
    final fixedHeight = _feedUi.mediaFrameHeight;
    final fixedWidth = _feedUi.mediaFrameWidth;
    if (mediaList.isEmpty) {
      return _wrapMediaFrame(
        fixedWidth: fixedWidth,
        fixedHeight: fixedHeight,
        child: ColoredBox(color: _feedUi.dividerColor),
      );
    }

    final stack = Stack(
      fit: StackFit.expand,
      children: [
        if (mediaList.length > 1)
          PageView.builder(
            controller: _mediaPageController,
            onPageChanged: (index) => _mediaPageIndex.value = index,
            itemCount: mediaList.length,
            itemBuilder: (context, index) => _buildMediaItem(
              mediaList[index],
              index,
            ),
          )
        else
          _buildMediaItem(mediaList.first, 0),
        _buildMediaTopOverlay(context),
        if (_feedUi.showCarouselPageBadge && mediaList.length > 1)
          Positioned(
            top: IsrDimens.twelve,
            right: IsrDimens.twelve,
            child: ValueListenableBuilder<int>(
              valueListenable: _mediaPageIndex,
              builder: (context, page, _) => Container(
                padding: IsrDimens.edgeInsetsSymmetric(
                  horizontal: IsrDimens.ten,
                  vertical: IsrDimens.four,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(IsrDimens.twelve),
                ),
                child: Text(
                  '${page + 1}/${mediaList.length}',
                  style: _textStyleConfig?.mediaCounterStyle ?? IsrStyles.white12,
                ),
              ),
            ),
          ),
      ],
    );

    return _wrapMediaFrame(
      fixedWidth: fixedWidth,
      fixedHeight: fixedHeight,
      child: stack,
    );
  }

  Widget _wrapMediaFrame({
    required Widget child,
    double? fixedWidth,
    double? fixedHeight,
  }) {
    final hasFixedWidth = fixedWidth != null && fixedWidth > 0;
    final hasFixedHeight = fixedHeight != null && fixedHeight > 0;

    if (!hasFixedWidth && !hasFixedHeight) {
      return ClipRect(
        child: AspectRatio(aspectRatio: _feedUi.mediaAspectRatio, child: child),
      );
    }

    return ClipRect(
      child: SizedBox(
        width: hasFixedWidth ? fixedWidth : double.infinity,
        height: hasFixedHeight ? fixedHeight : null,
        child: child,
      ),
    );
  }

  Widget _buildMediaItem(MediaMetaData media, int index) {
    if (media.mediaType == _kPictureType) {
      return AppImage.network(
        media.mediaUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    final playerKey =
        _videoPlayerKeys.putIfAbsent(index, () => GlobalKey(debugLabel: 'post_feed_video_$index'));

    final video = ClipRect(
      child: VideoPlayerWidget(
        key: playerKey,
        mediaUrl: media.mediaUrl,
        thumbnailUrl: media.thumbnailUrl,
        videoCacheManager: _videoCacheManager,
        isMuted: VideoMuteController.isMuted,
        aspectRatio: _feedUi.mediaAspectRatio,
        videoFitOverride: BoxFit.cover,
        logIndex: '${widget.logIndex}-$index',
        isParentVisible: () => widget.isPostVisible,
        onVisibilityChanged: (_) {
          if (mounted) setState(() {});
        },
      ),
    );

    if (!_feedUi.enableVideoTapControls) {
      return video;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        video,
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _toggleVideoPlayPause(playerKey),
          ),
        ),
        _buildVideoPlayPauseOverlay(playerKey),
        _buildVideoMuteControl(),
        if (_showMuteIconBriefly) _buildMuteToggleFeedback(),
      ],
    );
  }

  void _toggleVideoPlayPause(GlobalKey playerKey) {
    final playerState = VideoPlayerWidget.of(playerKey);
    if (playerState == null || !playerState.mounted) return;

    if (playerState.isPlaying) {
      playerState.pause();
    } else {
      playerState.play();
    }
    setState(() {});
  }

  void _toggleVideoMute() {
    VideoMuteController.toggle();
    setState(() => _showMuteIconBriefly = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _showMuteIconBriefly = false);
    });
  }

  Widget _buildVideoPlayPauseOverlay(GlobalKey playerKey) {
    final playerState = VideoPlayerWidget.of(playerKey);
    final showPauseOverlay =
        playerState != null && playerState.mounted && playerState.isManuallyPaused;

    if (!showPauseOverlay) {
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

  Widget _buildMediaTopOverlay(BuildContext context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.5),
                Colors.transparent,
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              IsrDimens.twelve,
              IsrDimens.twelve,
              IsrDimens.twelve,
              IsrDimens.twenty,
            ),
            child: Row(
              children: [
                if (_reel.postSetting?.isProfilePicVisible == true) ...[
                  _buildMediaProfileAvatar(),
                  IsrDimens.boxWidth(IsrDimens.eight),
                ],
                Expanded(child: _buildMediaUserTitle()),
                if (!_isViewerPostAuthor) ...[
                  IsrDimens.boxWidth(IsrDimens.eight),
                  _buildFollowButton(),
                ],
                if (_reel.postSetting?.isMoreButtonVisible == true) ...[
                  IsrDimens.boxWidth(IsrDimens.eight),
                  _buildMediaMoreButton(),
                ],
              ],
            ),
          ),
        ),
      );

  Widget _buildMediaProfileAvatar() {
    final size = _userProfileConfig?.profileImageSize ?? IsrDimens.thirtyTwo;
    return TapHandler(
      borderRadius: size / 2,
      onTap: () => widget.onTapUserProfile?.call(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: IsrColors.white, width: IsrDimens.one),
        ),
        child: ClipOval(
          child: AppImage.network(
            _reel.profilePhoto ?? '',
            width: size,
            height: size,
            isProfileImage: true,
            textColor: _userProfileConfig?.profileImagePlaceholderColor ?? IsrColors.white,
            name: '${_reel.firstName ?? ''} ${_reel.lastName ?? ''}',
          ),
        ),
      ),
    );
  }

  Widget _buildMediaUserTitle() => TapHandler(
        onTap: () => widget.onTapUserProfile?.call(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                _reel.userName ?? '',
                style: _mediaOverlayNameStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_reel.isVerifiedUser == true) ...[
              IsrDimens.boxWidth(IsrDimens.four),
              AppImage.svg(
                AssetConstants.icVerifiedIcon,
                width: IsrDimens.sixteen,
                height: IsrDimens.sixteen,
              ),
            ],
          ],
        ),
      );

  Widget _buildMediaMoreButton() => GestureDetector(
        onTap: widget.onPressMoreButton,
        child: AppImage.svg(
          _actionIconConfig?.moreIcon ?? AssetConstants.icMoreIcon,
          width: _postFeedActionIconSize,
          height: _postFeedActionIconSize,
          color: IsrColors.white,
        ),
      );

  Widget _buildFollowButton() {
    final timelineUser =
        _reel.postData is TimeLineData ? (_reel.postData as TimeLineData).user : null;
    return FollowActionWidget(
      postId: _reel.postId ?? '',
      userId: _reel.userId ?? '',
      isTargetPrivate: (timelineUser?.isPrivate ?? 0) == 1,
      initialFollowStatus: timelineUser?.followStatus,
      initialIsRequested: timelineUser?.isRequested,
      builder: (isLoading, isFollowing, followRequestPending, onTap) {
        _reel.isFollow = isFollowing;

        if (isLoading) {
          return SizedBox(
            width: _followButtonConfig?.followButtonMinWidth ?? IsrDimens.fiftySix,
            height: _followButtonConfig?.followButtonHeight ?? IsrDimens.twentyEight,
            child: Center(
              child: SizedBox(
                width: IsrDimens.sixteen,
                height: IsrDimens.sixteen,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _followButtonConfig?.loadingIndicatorColor ?? IsrColors.white,
                  ),
                ),
              ),
            ),
          );
        }

        if (followRequestPending && _reel.postSetting?.isUnFollowButtonVisible == true) {
          return _buildFollowChip(
            label: IsrTranslationFile.requested,
            filled: false,
            onTap: () => onTap(
              reelData: _reel,
              postSectionType: widget.postSectionType,
              apiCallBack: widget.onPressFollowButton != null
                  ? () => widget.onPressFollowButton!(_reel, isFollowing)
                  : null,
            ),
          );
        }

        if (!isFollowing &&
            !followRequestPending &&
            _reel.postSetting?.isUnFollowButtonVisible == true) {
          final private = (timelineUser?.isPrivate ?? 0) == 1;
          final showRequest = FollowRelationshipUi.showRequestPrimaryLabel(
            isFollowing: isFollowing,
            isPrivateAccount: private,
            isRequested: timelineUser?.isRequested,
            followStatus: timelineUser?.followStatus,
          );
          return _buildFollowChip(
            label: showRequest ? IsrTranslationFile.request : IsrTranslationFile.follow,
            filled: true,
            onTap: () => onTap(
              reelData: _reel,
              postSectionType: widget.postSectionType,
              apiCallBack: widget.onPressFollowButton != null
                  ? () => widget.onPressFollowButton!(_reel, isFollowing)
                  : null,
            ),
          );
        }

        if (isFollowing && _reel.postSetting?.isFollowButtonVisible == true) {
          return _buildFollowChip(
            label: IsrTranslationFile.following,
            filled: false,
            onTap: () => onTap(reelData: _reel),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildFollowChip({
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    final height = _followButtonConfig?.followButtonHeight ?? IsrDimens.twentyEight;
    return Container(
      height: height,
      decoration: filled
          ? (_followButtonConfig?.followButtonDecoration ??
              BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(IsrDimens.eight),
              ))
          : (_followButtonConfig?.followingButtonDecoration ??
              BoxDecoration(
                borderRadius: BorderRadius.circular(IsrDimens.eight),
                border: Border.all(color: IsrColors.white, width: IsrDimens.one),
              )),
      child: MaterialButton(
        onPressed: onTap,
        elevation: 0,
        highlightElevation: 0,
        minWidth: _followButtonConfig?.followButtonMinWidth ?? IsrDimens.fiftySix,
        height: height,
        padding: _followButtonConfig?.followButtonPadding ??
            IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.twelve),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(IsrDimens.eight),
        ),
        color: Colors.transparent,
        child: Text(
          label,
          style: filled
              ? (_textStyleConfig?.followButtonTextStyle ??
                  IsrStyles.white12.copyWith(fontWeight: FontWeight.w600))
              : (_textStyleConfig?.followingButtonTextStyle ??
                  IsrStyles.white12.copyWith(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildVideoMuteControl() => Positioned(
        bottom: IsrDimens.twelve,
        right: IsrDimens.twelve,
        child: GestureDetector(
          onTap: _toggleVideoMute,
          child: Container(
            padding: IsrDimens.edgeInsetsAll(IsrDimens.six),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
            child: AppImage.svg(
              VideoMuteController.isMuted
                  ? (_actionIconConfig?.muteIcon ?? AssetConstants.icMuteIcon)
                  : (_actionIconConfig?.unmuteIcon ?? AssetConstants.icUnMuteIcon),
              width: IsrDimens.sixteen,
              height: IsrDimens.sixteen,
              color: IsrColors.white,
            ),
          ),
        ),
      );

  Widget _buildMuteToggleFeedback() => IgnorePointer(
        child: Center(
          child: Container(
            padding: IsrDimens.edgeInsetsAll(IsrDimens.sixteen),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
            child: AppImage.svg(
              VideoMuteController.isMuted
                  ? (_actionIconConfig?.muteIcon ?? AssetConstants.icMuteIcon)
                  : (_actionIconConfig?.unmuteIcon ?? AssetConstants.icUnMuteIcon),
              width: IsrDimens.thirtyTwo,
              height: IsrDimens.thirtyTwo,
              color: IsrColors.white,
            ),
          ),
        ),
      );

  Widget _buildActionsSection(BuildContext context) {
    final mediaCount = _reel.mediaMetaDataList.length;

    final customBuilder = _feedUi.actionWidget;
    if (customBuilder != null) {
      return ValueListenableBuilder<int>(
        valueListenable: _mediaPageIndex,
        builder: (context, pageIndex, _) => Padding(
          padding: IsrDimens.edgeInsetsSymmetric(
            horizontal: IsrDimens.twelve,
            vertical: IsrDimens.eight,
          ),
          child: customBuilder(
            _reel,
            PostFeedActionBuildContext(
              currentMediaIndex: pageIndex,
              mediaCount: mediaCount,
              postSectionType: widget.postSectionType,
            ),
          ),
        ),
      );
    }

    final reelsAction = widget.reelsConfig.actionWidget?.call(_reel);
    if (reelsAction != null) {
      return Padding(
        padding: reelsAction.padding ??
            IsrDimens.edgeInsetsSymmetric(
              horizontal: IsrDimens.twelve,
              vertical: IsrDimens.eight,
            ),
        child: Align(
          alignment: reelsAction.alignment ?? Alignment.centerLeft,
          child: reelsAction.child,
        ),
      );
    }

    return _buildDefaultActionBar(context);
  }

  Widget _buildDefaultActionBar(BuildContext context) {
    final mediaCount = _reel.mediaMetaDataList.length;
    final showDots = _feedUi.showCarouselDots && mediaCount > 1;

    return Padding(
      padding: IsrDimens.edgeInsetsSymmetric(
        horizontal: IsrDimens.twelve,
        vertical: IsrDimens.eight,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildLeftActionIcons(),
              if (_reel.postSetting?.isSaveButtonVisible == true)
                SaveActionWidget(
                  postId: _reel.postId ?? '',
                  builder: (isLoading, isSaved, onTap) => _iconAction(
                    icon: isSaved
                        ? (_actionIconConfig?.saveIconSelected ?? AssetConstants.icPostSaveIcon)
                        : (_actionIconConfig?.saveIconUnselected ?? AssetConstants.icPostSaveIcon),
                    onTap: () => onTap(
                      reelData: _reel,
                      postSectionType: widget.postSectionType,
                      apiCallBack: widget.onPressSaveButton != null
                          ? () => widget.onPressSaveButton!(_reel, isSaved)
                          : null,
                    ),
                  ),
                )
              else
                SizedBox(width: _postFeedActionIconSize),
            ],
          ),
          if (showDots)
            IgnorePointer(
              child: _buildCarouselDots(context, mediaCount),
            ),
        ],
      ),
    );
  }

  Widget _buildLeftActionIcons() {
    final icons = <Widget>[];

    if (_reel.postSetting?.isLikeButtonVisible == true) {
      icons.add(
        LikeActionWidget(
          postId: _reel.postId ?? '',
          builder: (isLoading, isLiked, likeCount, onTap) {
            final liked = isLiked == true;
            return _iconAction(
              icon: liked
                  ? (_actionIconConfig?.likeIconSelected ?? AssetConstants.icPostLikeIcon)
                  : (_actionIconConfig?.likeIconUnselected ?? AssetConstants.icPostLikeIcon),
              onTap: () => onTap(
                reelData: _reel,
                postSectionType: widget.postSectionType,
                apiCallBack: widget.onPressLikeButton != null
                    ? () => widget.onPressLikeButton!(_reel, liked)
                    : null,
              ),
            );
          },
        ),
      );
    }

    if (_reel.postSetting?.isCommentButtonVisible == true) {
      if (icons.isNotEmpty) icons.add(IsrDimens.boxWidth(IsrDimens.twelve));
      icons.add(
        _iconAction(
          icon: _actionIconConfig?.commentIcon ?? AssetConstants.icPostCommentIcon,
          onTap: () => widget.onTapComment?.call(),
        ),
      );
    }

    if (_reel.postSetting?.isShareButtonVisible == true) {
      if (icons.isNotEmpty) icons.add(IsrDimens.boxWidth(IsrDimens.twelve));
      icons.add(
        _iconAction(
          icon: _actionIconConfig?.shareIcon ?? AssetConstants.icPostShareIcon,
          onTap: () => widget.onTapShare?.call(),
        ),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: icons);
  }

  Widget _buildCarouselDots(BuildContext context, int mediaCount) => ValueListenableBuilder<int>(
        valueListenable: _mediaPageIndex,
        builder: (context, page, _) => Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            mediaCount,
            (i) => Container(
              width: IsrDimens.six,
              height: IsrDimens.six,
              margin: IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.two),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == page
                    ? Theme.of(context).primaryColor
                    : _feedUi.secondaryTextColor.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      );

  Widget _iconAction({required String icon, required VoidCallback onTap}) => GestureDetector(
        onTap: onTap,
        child: AppImage.svg(
          icon,
          width: _postFeedActionIconSize,
          height: _postFeedActionIconSize,
          color: _feedUi.actionIconColor,
        ),
      );

  Widget _buildEngagementSection(BuildContext context) {
    final likes = _reel.likesCount ?? 0;
    final description = _reel.description?.trim() ?? '';
    return Padding(
      padding: IsrDimens.edgeInsetsSymmetric(
        horizontal: IsrDimens.twelve,
        vertical: IsrDimens.eight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (likes > 0)
            Text(
              likes == 1 ? '1 like' : '$likes likes',
              style: IsrStyles.primaryText14.copyWith(
                fontWeight: FontWeight.w600,
                color: _feedUi.headerTextColor,
              ),
            ),
          if (_locationLabel != null) ...[
            if (likes > 0) IsrDimens.boxHeight(IsrDimens.four),
            Text(
              _locationLabel!,
              style: _textStyleConfig?.locationStyle ??
                  IsrStyles.primaryText12.copyWith(
                    color: _feedUi.secondaryTextColor,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (description.isNotEmpty) ...[
            if (likes > 0 || _locationLabel != null) IsrDimens.boxHeight(IsrDimens.six),
            RichText(
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${_reel.userName ?? ''} ',
                    style: IsrStyles.primaryText14.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _feedUi.headerTextColor,
                    ),
                  ),
                  TextSpan(
                    text: description,
                    style: _textStyleConfig?.descriptionStyle ??
                        IsrStyles.primaryText14.copyWith(
                          color: _feedUi.headerTextColor,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
