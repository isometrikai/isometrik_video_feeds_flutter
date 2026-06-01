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

  bool get _isInstagramStyle => _feedUi.cardStyle == PostFeedCardStyle.instagram;

  bool get _showActionCounts => _feedUi.showActionCounts || _isInstagramStyle;

  static const Color _instagramLikeColor = Color(0xFFED4956);

  double get _postFeedActionIconSize =>
      _actionIconConfig?.iconSize ?? (_isInstagramStyle ? IsrDimens.twentyFour : IsrDimens.twenty);

  bool _isVideoMedia(MediaMetaData media) => media.mediaType != _kPictureType;

  /// Gap between two action groups; widens when either side shows a count label.
  double _gapBetweenActions({
    required bool previousShowsCount,
    required bool nextShowsCount,
  }) {
    if (!_showActionCounts || (!previousShowsCount && !nextShowsCount)) {
      return _feedUi.actionIconGapCompact;
    }
    if (previousShowsCount && nextShowsCount) {
      return _feedUi.actionIconGapWithCount;
    }
    return (_feedUi.actionIconGapCompact + _feedUi.actionIconGapWithCount) / 2;
  }

  Widget _buildActionIconRow(List<({Widget widget, bool showsCount})> segments) {
    if (segments.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[segments.first.widget];
    for (var i = 1; i < segments.length; i++) {
      children.add(
        SizedBox(
          width: _gapBetweenActions(
            previousShowsCount: segments[i - 1].showsCount,
            nextShowsCount: segments[i].showsCount,
          ),
        ),
      );
      children.add(segments[i].widget);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }

  bool _showHeaderAboveMedia(int mediaIndex) {
    if (!_isInstagramStyle) return false;
    final mediaList = _reel.mediaMetaDataList;
    if (mediaList.isEmpty) return false;
    final index = mediaIndex.clamp(0, mediaList.length - 1);
    return !_isVideoMedia(mediaList[index]);
  }

  bool _showMediaOverlayHeader(int mediaIndex) {
    if (!_isInstagramStyle) return true;
    final mediaList = _reel.mediaMetaDataList;
    if (mediaList.isEmpty) return false;
    final index = mediaIndex.clamp(0, mediaList.length - 1);
    return _isVideoMedia(mediaList[index]);
  }

  /// Carousel frame size is locked to the first media item (Instagram-style).
  double get _fixedCardMediaAspectRatio {
    if (!_isInstagramStyle) return _feedUi.mediaAspectRatio;
    final mediaList = _reel.mediaMetaDataList;
    if (mediaList.isEmpty) return _feedUi.mediaAspectRatio;
    final first = mediaList.first;
    if (_isVideoMedia(first)) {
      return _feedUi.videoMediaAspectRatio;
    }
    return FeedMediaOrientation.aspectRatioForImageUrl(
      first.mediaUrl,
      portraitAspectRatio: _feedUi.imageMediaAspectRatio,
      landscapeAspectRatio: _feedUi.landscapeMediaAspectRatio,
    );
  }

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

  TextStyle get _headerUserNameStyle =>
      _textStyleConfig?.userNameStyle ??
      IsrStyles.primaryText14.copyWith(
        fontWeight: FontWeight.w600,
        color: _feedUi.headerTextColor,
      );

  String? get _postTimestampLabel {
    final raw = _reel.createOn?.trim();
    if (raw.isStringEmptyOrNull == true) return null;
    try {
      final relative = Utility.formatPublishedTimeAgo(DateTime.parse(raw!).toLocal());
      return relative.isEmpty ? null : relative;
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInstagramStyle) {
      return ValueListenableBuilder<int>(
        valueListenable: _mediaPageIndex,
        builder: (context, pageIndex, _) => _buildCardBody(context, pageIndex),
      );
    }
    return _buildCardBody(context, 0);
  }

  Widget _buildCardBody(BuildContext context, int mediaIndex) {
    final mediaCount = _reel.mediaMetaDataList.length;
    final showDotsBelowMedia = _isInstagramStyle &&
        _feedUi.showCarouselDots &&
        mediaCount > 1 &&
        _showHeaderAboveMedia(mediaIndex);

    return ColoredBox(
      color: _feedUi.backgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_showHeaderAboveMedia(mediaIndex)) _buildPostHeaderAboveMedia(context),
          _buildMediaSection(context, mediaIndex),
          if (showDotsBelowMedia) _buildCarouselDotsBelowMedia(context, mediaCount),
          _buildActionsSection(context),
          _buildEngagementSection(context),
        ],
      ),
    );
  }

  Widget _buildMediaSection(BuildContext context, int mediaIndex) {
    final mediaList = _reel.mediaMetaDataList;
    final fixedHeight = _feedUi.mediaFrameHeight;
    final fixedWidth = _feedUi.mediaFrameWidth;
    if (mediaList.isEmpty) {
      return _wrapMediaFrame(
        mediaIndex: mediaIndex,
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
        if (_showMediaOverlayHeader(mediaIndex)) _buildMediaTopOverlay(context),
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
      mediaIndex: mediaIndex,
      fixedWidth: fixedWidth,
      fixedHeight: fixedHeight,
      child: stack,
    );
  }

  Widget _wrapMediaFrame({
    required Widget child,
    required int mediaIndex,
    double? fixedWidth,
    double? fixedHeight,
  }) {
    final hasFixedWidth = fixedWidth != null && fixedWidth > 0;
    final hasFixedHeight = fixedHeight != null && fixedHeight > 0;
    final aspectRatio = _fixedCardMediaAspectRatio;

    if (!hasFixedWidth && !hasFixedHeight) {
      return ClipRect(
        child: AspectRatio(aspectRatio: aspectRatio, child: child),
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
        fadeAnimationEnable: true,
        placeHolderWidget: (_, __) => PostFeedMediaPlaceholder(
          baseColor: _feedUi.dividerColor,
          highlightColor: _feedUi.backgroundColor,
        ),
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
        aspectRatio: _fixedCardMediaAspectRatio,
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

  Widget _buildPostHeaderAboveMedia(BuildContext context) => Padding(
        padding: IsrDimens.edgeInsetsSymmetric(
          horizontal: IsrDimens.twelve,
          vertical: IsrDimens.ten,
        ),
        child: Row(
          children: [
            if (_reel.postSetting?.isProfilePicVisible == true) ...[
              _buildHeaderProfileAvatar(),
              IsrDimens.boxWidth(IsrDimens.ten),
            ],
            Expanded(child: _buildHeaderUserColumn()),
            if (!_isViewerPostAuthor) ...[
              IsrDimens.boxWidth(IsrDimens.eight),
              _buildFollowButton(instagramChipStyle: true),
            ],
            if (_reel.postSetting?.isMoreButtonVisible == true) ...[
              IsrDimens.boxWidth(IsrDimens.four),
              _buildHeaderMoreButton(),
            ],
          ],
        ),
      );

  Widget _buildHeaderProfileAvatar() {
    final size = _userProfileConfig?.profileImageSize ?? IsrDimens.thirtyTwo;
    return TapHandler(
      borderRadius: size / 2,
      onTap: () => widget.onTapUserProfile?.call(),
      child: ClipOval(
        child: AppImage.network(
          _reel.profilePhoto ?? '',
          width: size,
          height: size,
          isProfileImage: true,
          textColor:
              _userProfileConfig?.profileImagePlaceholderColor ?? _feedUi.secondaryTextColor,
          name: '${_reel.firstName ?? ''} ${_reel.lastName ?? ''}',
        ),
      ),
    );
  }

  Widget _buildHeaderUserColumn() => TapHandler(
        onTap: () => widget.onTapUserProfile?.call(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    _reel.userName ?? '',
                    style: _headerUserNameStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_reel.isVerifiedUser == true) ...[
                  IsrDimens.boxWidth(IsrDimens.four),
                  AppImage.svg(
                    AssetConstants.icVerifiedIcon,
                    width: IsrDimens.fourteen,
                    height: IsrDimens.fourteen,
                  ),
                ],
              ],
            ),
            if (_feedUi.headerSubtitle?.isNotEmpty == true) ...[
              IsrDimens.boxHeight(IsrDimens.two),
              Text(
                _feedUi.headerSubtitle!,
                style: IsrStyles.primaryText12.copyWith(
                  color: _feedUi.secondaryTextColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ] else if (_locationLabel != null) ...[
              IsrDimens.boxHeight(IsrDimens.two),
              Text(
                _locationLabel!,
                style: IsrStyles.primaryText12.copyWith(
                  color: _feedUi.secondaryTextColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      );

  Widget _buildHeaderMoreButton() => GestureDetector(
        onTap: widget.onPressMoreButton,
        child: AppImage.svg(
          _actionIconConfig?.moreIcon ?? AssetConstants.icMoreIcon,
          width: _postFeedActionIconSize,
          height: _postFeedActionIconSize,
          color: _feedUi.actionIconColor,
        ),
      );

  Widget _buildCarouselDotsBelowMedia(BuildContext context, int mediaCount) => Padding(
        padding: IsrDimens.edgeInsets(
          top: IsrDimens.eight,
          bottom: IsrDimens.four,
        ),
        child: _buildCarouselDots(context, mediaCount),
      );

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
                  _buildFollowButton(instagramChipStyle: false),
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

  Widget _buildFollowButton({required bool instagramChipStyle}) {
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
            instagramChipStyle: instagramChipStyle,
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
            instagramChipStyle: instagramChipStyle,
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
            instagramChipStyle: instagramChipStyle,
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
    required bool instagramChipStyle,
  }) {
    final height = _followButtonConfig?.followButtonHeight ?? IsrDimens.twentyEight;
    final instagramFilledDecoration = BoxDecoration(
      color: const Color(0xFFEFEFEF),
      borderRadius: BorderRadius.circular(IsrDimens.eight),
    );
    final instagramOutlinedDecoration = BoxDecoration(
      color: const Color(0xFFEFEFEF),
      borderRadius: BorderRadius.circular(IsrDimens.eight),
      border: Border.all(color: const Color(0xFFDBDBDB)),
    );

    return Container(
      height: height,
      decoration: filled
          ? (instagramChipStyle
              ? instagramFilledDecoration
              : (_followButtonConfig?.followButtonDecoration ??
                  BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(IsrDimens.eight),
                  )))
          : (instagramChipStyle
              ? instagramOutlinedDecoration
              : (_followButtonConfig?.followingButtonDecoration ??
                  BoxDecoration(
                    borderRadius: BorderRadius.circular(IsrDimens.eight),
                    border: Border.all(color: IsrColors.white, width: IsrDimens.one),
                  ))),
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
              ? (instagramChipStyle
                  ? IsrStyles.primaryText12.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _feedUi.headerTextColor,
                    )
                  : (_textStyleConfig?.followButtonTextStyle ??
                      IsrStyles.white12.copyWith(fontWeight: FontWeight.w600)))
              : (instagramChipStyle
                  ? IsrStyles.primaryText12.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _feedUi.headerTextColor,
                    )
                  : (_textStyleConfig?.followingButtonTextStyle ??
                      IsrStyles.white12.copyWith(fontWeight: FontWeight.w600))),
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
    final showDotsInBar =
        !_isInstagramStyle && _feedUi.showCarouselDots && mediaCount > 1;

    return Padding(
      padding: IsrDimens.edgeInsetsSymmetric(
        horizontal: IsrDimens.twelve,
        vertical: _isInstagramStyle ? IsrDimens.six : IsrDimens.eight,
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
                        ? (_actionIconConfig?.saveIconSelected ??
                            AssetConstants.icPostSaveIconSelected)
                        : (_actionIconConfig?.saveIconUnselected ??
                            AssetConstants.icPostSaveIcon),
                    applyThemeColor: !isSaved,
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
          if (showDotsInBar)
            IgnorePointer(
              child: _buildCarouselDots(context, mediaCount),
            ),
        ],
      ),
    );
  }

  Widget _buildLeftActionIcons() {
    if (_reel.postSetting?.isLikeButtonVisible != true) {
      return _buildLeftActionIconsWithoutLike();
    }

    return LikeActionWidget(
      postId: _reel.postId ?? '',
      builder: (isLoading, isLiked, likeCount, onTap) {
        final liked = isLiked == true;
        final count = likeCount > 0 ? likeCount : (_reel.likesCount ?? 0);
        final likeCountLabel =
            _showActionCounts && count > 0 ? Utility.formatEngagementCount(count) : null;

        final segments = <({Widget widget, bool showsCount})>[
          (
            widget: _iconAction(
              icon: liked
                  ? (_actionIconConfig?.likeIconSelected ??
                      AssetConstants.icPostLikeIconSelected)
                  : (_actionIconConfig?.likeIconUnselected ?? AssetConstants.icPostLikeIcon),
              applyThemeColor: !liked,
              iconColor: liked ? _instagramLikeColor : _feedUi.actionIconColor,
              countLabel: likeCountLabel,
              onTap: () => onTap(
                reelData: _reel,
                postSectionType: widget.postSectionType,
                apiCallBack: widget.onPressLikeButton != null
                    ? () => widget.onPressLikeButton!(_reel, liked)
                    : null,
              ),
            ),
            showsCount: likeCountLabel != null,
          ),
          ..._commentAndShareSegments(),
        ];

        return _buildActionIconRow(segments);
      },
    );
  }

  List<({Widget widget, bool showsCount})> _commentAndShareSegments() {
    final segments = <({Widget widget, bool showsCount})>[];

    if (_reel.postSetting?.isCommentButtonVisible == true) {
      final commentCount = _reel.commentCount ?? 0;
      final commentCountLabel = _showActionCounts && commentCount > 0
          ? Utility.formatEngagementCount(commentCount)
          : null;
      segments.add((
        widget: _iconAction(
          icon: _actionIconConfig?.commentIcon ?? AssetConstants.icPostCommentIcon,
          countLabel: commentCountLabel,
          onTap: () => widget.onTapComment?.call(),
        ),
        showsCount: commentCountLabel != null,
      ));
    }

    if (_reel.postSetting?.isShareButtonVisible == true) {
      segments.add((
        widget: _iconAction(
          icon: _actionIconConfig?.shareIcon ?? AssetConstants.icPostShareIcon,
          onTap: () => widget.onTapShare?.call(),
        ),
        showsCount: false,
      ));
    }

    return segments;
  }

  Widget _buildLeftActionIconsWithoutLike() =>
      _buildActionIconRow(_commentAndShareSegments());

  Widget _buildCarouselDots(BuildContext context, int mediaCount) => ValueListenableBuilder<int>(
        valueListenable: _mediaPageIndex,
        builder: (context, page, _) => Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            mediaCount,
            (i) => Container(
              width: _isInstagramStyle ? IsrDimens.five : IsrDimens.six,
              height: _isInstagramStyle ? IsrDimens.five : IsrDimens.six,
              margin: IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.two),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == page
                    ? (_isInstagramStyle
                        ? const Color(0xFF0095F6)
                        : Theme.of(context).primaryColor)
                    : _feedUi.secondaryTextColor.withValues(alpha: 0.35),
              ),
            ),
          ),
        ),
      );

  Widget _iconAction({
    required String icon,
    required VoidCallback onTap,
    String? countLabel,
    Color? iconColor,
    bool applyThemeColor = true,
  }) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: IsrDimens.edgeInsetsSymmetric(vertical: IsrDimens.two),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: _postFeedActionIconSize,
                height: _postFeedActionIconSize,
                child: AppImage.svg(
                  icon,
                  width: _postFeedActionIconSize,
                  height: _postFeedActionIconSize,
                  fit: BoxFit.contain,
                  color: applyThemeColor ? (iconColor ?? _feedUi.actionIconColor) : null,
                ),
              ),
              if (countLabel != null) ...[
                IsrDimens.boxWidth(IsrDimens.six),
                Text(
                  countLabel,
                  style: _textStyleConfig?.actionLabelStyle ??
                      IsrStyles.primaryText14.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _feedUi.headerTextColor,
                        height: 1.1,
                      ),
                ),
              ],
            ],
          ),
        ),
      );

  Widget _buildEngagementSection(BuildContext context) {
    final likes = _reel.likesCount ?? 0;
    final description = _reel.description?.trim() ?? '';
    final showLikesLine = likes > 0 && !_showActionCounts;
    final showTimestamp =
        (_feedUi.showPostTimestamp || _isInstagramStyle) && _postTimestampLabel != null;
    final showLocation = _locationLabel != null && !_isInstagramStyle;

    return Padding(
      padding: IsrDimens.edgeInsetsSymmetric(
        horizontal: IsrDimens.twelve,
        vertical: _isInstagramStyle ? IsrDimens.six : IsrDimens.eight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLikesLine)
            Text(
              likes == 1 ? '1 like' : '$likes likes',
              style: IsrStyles.primaryText14.copyWith(
                fontWeight: FontWeight.w600,
                color: _feedUi.headerTextColor,
              ),
            ),
          if (showLocation) ...[
            if (showLikesLine) IsrDimens.boxHeight(IsrDimens.four),
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
            if (showLikesLine || showLocation) IsrDimens.boxHeight(IsrDimens.six),
            RichText(
              maxLines: _isInstagramStyle ? 2 : 3,
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
          if (showTimestamp) ...[
            if (showLikesLine || showLocation || description.isNotEmpty)
              IsrDimens.boxHeight(IsrDimens.four),
            Text(
              _postTimestampLabel!,
              style: IsrStyles.primaryText12.copyWith(
                color: _feedUi.secondaryTextColor,
              ),
            ),
          ],
          if (_isInstagramStyle) IsrDimens.boxHeight(IsrDimens.four),
        ],
      ),
    );
  }
}
