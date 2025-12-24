import 'dart:async';
import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/video_player_widget.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/like_action_widget.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:lottie/lottie.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Custom Reels Player for both Video and Photo content with carousel support
class IsmReelsVideoPlayerView extends StatefulWidget {
  const IsmReelsVideoPlayerView({
    super.key,
    this.videoCacheManager,
    this.reelsData,
    this.onPressMoreButton,
    this.onCreatePost,
    this.onPressFollowButton,
    this.onPressLikeButton,
    this.onPressSaveButton,
    this.loggedInUserId,
    this.onVideoCompleted,
    this.onTapMentionTag,
    this.onTapCartIcon,
    required this.index,
    required this.reelsConfig,
    this.postSectionType = PostSectionType.following,
  });

  final VideoCacheManager? videoCacheManager;
  final ReelsData? reelsData;
  final VoidCallback? onPressMoreButton;
  final Future<void> Function()? onCreatePost;
  final Future<bool> Function(ReelsData reelsData, bool currentFollow)?
      onPressFollowButton;
  final Future<bool> Function(ReelsData reelsData, bool currentLiked)?
      onPressLikeButton;
  final Future<bool> Function(ReelsData reelsData, bool currentSaved)?
      onPressSaveButton;
  final String? loggedInUserId;
  final VoidCallback? onVideoCompleted;
  final Function(List<MentionMetaData>)? onTapMentionTag;
  final Function(String)? onTapCartIcon;
  final int index;
  final ReelsConfig reelsConfig;
  final PostSectionType postSectionType;

  @override
  State<IsmReelsVideoPlayerView> createState() =>
      _IsmReelsVideoPlayerViewState();
}

class _IsmReelsVideoPlayerViewState extends State<IsmReelsVideoPlayerView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware
    implements PostHelperCallBacks {
  // Use MediaCacheFactory instead of direct VideoCacheManager
  VideoCacheManager get _videoCacheManager =>
      widget.videoCacheManager ?? VideoCacheManager();

  // Add constants for media types
  static const int kPictureType = 0;
  static const int kVideoType = 1;

  // Carousel related variables
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(0);
  PageController? _pageController;

  TapGestureRecognizer? _tapGestureRecognizer;

  // GlobalKeys to control video players for long press pause/play
  // For single video, use _currentVideoPlayerKey
  // For carousel, use _videoPlayerKeys map
  final GlobalKey _currentVideoPlayerKey = GlobalKey();
  final Map<int, GlobalKey> _videoPlayerKeys = {};

  // Get the key for the current video player
  GlobalKey _getCurrentVideoPlayerKey() {
    if (_hasMultipleMedia) {
      final currentIndex = _currentPageNotifier.value;
      _videoPlayerKeys[currentIndex] ??= GlobalKey();
      return _videoPlayerKeys[currentIndex]!;
    } else {
      return _currentVideoPlayerKey;
    }
  }

  final ValueNotifier<bool> _isExpandedDescription = ValueNotifier(false);

  // to call like api from likeActionWidget
  Function({
    ReelsData? reelData,
    PostSectionType? postSectionType,
    int? watchDuration,
    Future<bool> Function()? apiCallBack,
  })? _onLikeTap;

  // Audio state management
  static bool _globalMuteState =
      false; // Global mute state that persists across all videos
  bool _isMuted = false;
  Timer? _audioDebounceTimer;
  final _maxLengthToShow = 50;
  final _maxLinesToShow = 2;
  late ReelsData _reelData;

  bool _mentionsVisible = false;
  var _postDescription = '';
  List<MentionMetaData> _mentionedMetaDataList = [];
  List<MentionMetaData> _pageMentionMetaDataList = [];
  List<MentionMetaData> _mentionedDataList = [];
  List<MentionMetaData> _taggedDataList = [];

  // OPTIMIZATION: Cache parsed description to avoid rebuilding text on every frame
  TextSpan? _cachedDescriptionTextSpan;
  String? _lastParsedDescription;

  bool _showLikeAnimation = false;
  Timer? _likeAnimationTimer;
  bool _showMuteAnimation = false;
  Timer? _muteAnimationTimer;
  double _muteIconScale = 1.0;

  // Image view tracking
  Timer? _imageViewTimer;
  final Duration _imageTotalDuration = const Duration(seconds: 10);
  Duration _imageElapsed = Duration.zero;
  bool _isImagePaused = false;

  bool _hasLoggedImageViewEvent = false;
  var _watchDuration = 0;

  // Video progress tracking
  final ValueNotifier<double> _videoProgress = ValueNotifier<double>(0.0);

  @override
  void initState() {
    _onStartInit();
    debugPrint('ism_reels_player: initState called desc: ${_reelData.description}');
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Capture the BuildContext for SDK use
    IsrVideoReelConfig.buildContext = context;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Lifecycle is handled by individual VideoPlayerWidgets
  }

  // RouteAware methods for navigation detection
  @override
  void didPopNext() {
    // Navigation is handled by individual VideoPlayerWidgets
  }

  @override
  void didPushNext() {
    // Navigation is handled by individual VideoPlayerWidgets
  }

  /// Returns true if the current post has multiple media items (carousel).
  bool get _hasMultipleMedia => _reelData.mediaMetaDataList.length > 1;

  void _onStartInit() async {
    _reelData = widget.reelsData!;

    // Only reset current page if not already initialized
    if (_currentPageNotifier.value != 0) {
      _currentPageNotifier.value = 0;
    }

    _mentionedMetaDataList = _reelData.mentions
        .where((mentionData) => mentionData.mediaPosition != null)
        .toList();
    _pageMentionMetaDataList = _mentionedMetaDataList
        .where((mention) =>
            mention.mediaPosition?.position == _currentPageNotifier.value + 1)
        .toList();
    _mentionedDataList = _reelData.mentions;
    _taggedDataList = _reelData.tagDataList ?? [];
    _postDescription = _reelData.description ?? '';
    _tapGestureRecognizer = TapGestureRecognizer();

    // Initialize local mute state with global state
    _isMuted = _globalMuteState;

    // Initialize PageController for carousel
    _pageController = PageController(initialPage: 0);

    // Preload next videos for smoother experience
    _preloadNextVideos();

    //resent image progress
    _resetImageProgress();

    // Start image view timer only if current media is an image
    if (_reelData.mediaMetaDataList[_currentPageNotifier.value].mediaType ==
        kPictureType) {
      _startOrResumeImageProgress();
    }
  }

  /// Method For Update The Tree Carefully
  void mountUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  /// Preloads next videos for smoother playback experience
  void _preloadNextVideos() {
    if (_reelData.mediaMetaDataList.length <= 1) return;

    // Preload next 2 videos and their thumbnails
    final currentIndex = _currentPageNotifier.value;
    final nextVideos = <String>[];
    final nextThumbnails = <String>[];

    // OPTIMIZATION: Only preload next 1 video to reduce memory pressure
    for (var i = 1;
        i <= 1 && (currentIndex + i) < _reelData.mediaMetaDataList.length;
        i++) {
      final nextIndex = currentIndex + i;
      final mediaData = _reelData.mediaMetaDataList[nextIndex];

      if (mediaData.mediaType == kVideoType &&
          mediaData.mediaUrl.isStringEmptyOrNull == false) {
        nextVideos.add(mediaData.mediaUrl);
        if (mediaData.thumbnailUrl.isNotEmpty) {
          nextThumbnails.add(mediaData.thumbnailUrl);
        }
      }
    }

    if (nextVideos.isNotEmpty) {
      // Preload videos and thumbnails together (non-blocking)
      final allMedia = [...nextVideos, ...nextThumbnails];
      MediaCacheFactory.precacheMedia(allMedia, highPriority: false).then((_) {
        debugPrint(
            '✅ VideoPlayer: Successfully preloaded ${nextVideos.length} videos and ${nextThumbnails.length} thumbnails');
      }).catchError((error) {
        debugPrint('❌ VideoPlayer: Error preloading next media: $error');
      });
    }
  }

  // Handle page change in carousel
  void _onPageChanged(int index) async {
    // Ensure PageController is in sync with the index
    if (_pageController != null && _pageController!.hasClients) {
      final currentPage =
          _pageController!.page?.round() ?? _currentPageNotifier.value;
      if (currentPage != index) {
        // PageController is out of sync, jump to correct page
        _pageController!.jumpToPage(index);
      }
    }

    if (_currentPageNotifier.value == index) return;

    // Hide mentions when changing pages
    if (_mentionsVisible) {
      _mentionsVisible = false;
    }

    // Update current page notifier
    _currentPageNotifier.value = index;

    // Reset video progress when changing pages
    _videoProgress.value = 0.0;

    _pageMentionMetaDataList = _mentionedMetaDataList
        .where((mention) =>
            mention.mediaPosition?.position == _currentPageNotifier.value + 1)
        .toList();

    _resetImageProgress();

    // Restart image view timer only if new page is an image
    if (_reelData.mediaMetaDataList[index].mediaType == kPictureType) {
      _startOrResumeImageProgress();
    }

    mountUpdate();
  }

  /// Disposes the current video controller if not cached, and cleans up state.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tapGestureRecognizer?.dispose();
    _pageController?.dispose();
    _likeAnimationTimer?.cancel();
    _muteAnimationTimer?.cancel();
    _audioDebounceTimer?.cancel();
    _imageViewTimer?.cancel();
    _videoProgress.dispose();
    // Analytics logging is now handled by VideoPlayerWidget
    _logImagePostEvent();
    debugPrint('ism_reels_player: dispose called desc: ${_reelData.description}');
    super.dispose();
  }

  Widget _getImageWidget({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    FilterQuality filterQuality = FilterQuality.high,
    bool showError = false,
  }) {
    final isLocalUrl =
        imageUrl.isStringEmptyOrNull == false && Utility.isLocalUrl(imageUrl);
    return isLocalUrl
        ? AppImage.file(
            imageUrl,
            width: width,
            height: height,
            fit: fit,
            filterQuality: filterQuality,
          )
        : AppImage.network(
            imageUrl,
            width: width,
            height: height,
            fit: fit,
            filterQuality: filterQuality,
            showError: showError,
          );
  }

  Widget _buildImageWithBlurredBackground({
    required String imageUrl,
  }) =>
      VisibilityDetector(
        key: ValueKey('image_${imageUrl.hashCode}'),
        onVisibilityChanged: (visibilityInfo) {
          final visibleFraction = visibilityInfo.visibleFraction;

          if (visibleFraction == 1.0) {
            // Fully visible → play
            _startOrResumeImageProgress();
          } else {
            // Partially visible / not visible → pause
            _pauseImageProgress();
          }
        },
        child:
      Container(
        color: Colors.black,
        child: Center(
          child: _getImageWidget(
            imageUrl: imageUrl,
            width: IsrDimens.getScreenWidth(context),
            height: IsrDimens.getScreenHeight(context),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,),
          ),
        ),
      );

  Widget _buildMediaContent() {
    Widget mediaWidget;

    if (_reelData.showBlur == true) {
      mediaWidget = _getImageWidget(
        imageUrl: _reelData
            .mediaMetaDataList[_currentPageNotifier.value].thumbnailUrl,
        width: IsrDimens.getScreenWidth(context),
        height: IsrDimens.getScreenHeight(context),
        fit: BoxFit.contain,
        showError: false,
      );
    } else if (_hasMultipleMedia) {
      mediaWidget = _buildMediaCarousel();
    } else {
      mediaWidget = _buildSingleMediaContent();
    }

    // Wrap media content with mentions overlay
    return Stack(
      children: [
        GestureDetector(
          onTap: _toggleMuteAndUnMute,
          onDoubleTap: _triggerLikeAnimation,
          child: mediaWidget,
        ),

        // // Mentions overlay with center area for tap-through
        // if (_mentionsVisible && _pageMentionMetaDataList.isListEmptyOrNull == false)
        //   _buildMentionsOverlayWithCenterArea(),
      ],
    );
  }

  Widget _buildMediaCarousel() => Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: _toggleMentions,
            child: PageView.builder(
              controller: _pageController,
              padEnds: false,
              // key: const PageStorageKey('media_pageview'),
              // Add a key
              onPageChanged: _onPageChanged,
              itemCount: _reelData.mediaMetaDataList.length,
              itemBuilder: (context, index) => _buildPageView(index),
            ),
          ),

          // Media counter
          Positioned(
            top: IsrDimens.sixty,
            right: IsrDimens.sixteen,
            child: ValueListenableBuilder<int>(
              valueListenable: _currentPageNotifier,
              builder: (context, value, child) => _buildMediaCounter(value),
            ),
          ),
        ],
      );

  Widget _buildSingleMediaContent() {
    debugPrint('mediaMetaDataList....${_reelData.mediaMetaDataList}');
    if (_reelData.mediaMetaDataList.isEmptyOrNull) {
      return const SizedBox.shrink();
    }
    if (_reelData.mediaMetaDataList[_currentPageNotifier.value].mediaType ==
        kPictureType) {
      return _buildImageWithBlurredBackground(
        imageUrl:
            _reelData.mediaMetaDataList[_currentPageNotifier.value].mediaUrl,
      );
    } else {
      return _buildVideoContent();
    }
  }

  Widget _buildVideoContent() {
    final media = _reelData.mediaMetaDataList[_currentPageNotifier.value];
    return VideoPlayerWidget(
      key: _currentVideoPlayerKey,
      mediaUrl: media.mediaUrl,
      thumbnailUrl: media.thumbnailUrl,
      videoCacheManager: _videoCacheManager,
      isMuted: _isMuted,
      onVisibilityChanged: (isVisible) {
        // Visibility is handled internally by VideoPlayerWidget
      },
      onVideoCompleted: _moveToNextMedia,
      postHelperCallBacks: this,
      videoProgressCallBack: (totalDuration, currentPosition) {
        _watchDuration = currentPosition;
        // Update progress (0.0 to 1.0)
        if (totalDuration > 0) {
          _videoProgress.value = currentPosition / totalDuration;
        }
      },
    );
  }

  void _toggleMentions() {
    if (_pageMentionMetaDataList.isListEmptyOrNull == false) {
      if (_mentionsVisible) {
        _autoHideMentions();
      } else {
        _toggleMuteAndUnMute();
      }
    } else {
      _toggleMuteAndUnMute();
      // _togglePlayPause();
    }
  }

  void _autoHideMentions() {
    if (_mentionsVisible) {
      setState(() {
        _mentionsVisible = false;
      });
    } else {
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted && _mentionsVisible) {
          setState(() {
            _mentionsVisible = false;
          });
        }
      });
    }
  }

  Widget _buildMediaIndicators(int currentPage) => Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: IsrDimens.four,
        children: List.generate(
          _reelData.mediaMetaDataList.length,
          (index) => Expanded(
            child: Container(
              height: IsrDimens.three,
              width: double.infinity,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                color: index < currentPage
                  ? IsrColors.white
                  : IsrColors.white.changeOpacity(0.2),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(IsrDimens.three),
                  topRight: Radius.circular(IsrDimens.three),
                ),
              ),
              child: (currentPage == index)
                  ? ValueListenableBuilder<double>(
                      valueListenable: _videoProgress,
                      builder: (context, progress, child) =>
                          LinearProgressIndicator(
                        backgroundColor: IsrColors.transparent,
                        color: IsrColors.white,
                        value: progress,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(IsrDimens.three),
                          topRight: Radius.circular(IsrDimens.three),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      );

  void _callOnTapMentionData(List<MentionMetaData> mentionDataList) {
    if (widget.onTapMentionTag == null) return;
    widget.onTapMentionTag?.call(mentionDataList);
  }

  Widget _buildMediaCounter(int currentPage) {
    if (!_hasMultipleMedia) return const SizedBox.shrink();

    return Container(
      padding: IsrDimens.edgeInsetsSymmetric(
        horizontal: IsrDimens.eight,
        vertical: IsrDimens.four,
      ),
      decoration: BoxDecoration(
        color: Colors.black.changeOpacity(0.6),
        borderRadius: BorderRadius.circular(IsrDimens.twelve),
      ),
      child: Text(
        '${currentPage + 1}/${_reelData.mediaMetaDataList.length}',
        style: IsrStyles.white12.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMentionedUsersSection() {
    final mentionList = _reelData.mentions;

    if (mentionList.isListEmptyOrNull) {
      return const SizedBox.shrink();
    }

    return TapHandler(
      onTap: () => _callOnTapMentionData(mentionList),
      child: Row(
        children: [
          Icon(
            Icons.people,
            size: IsrDimens.fifteen,
            color: IsrColors.white,
          ),
          IsrDimens.boxWidth(IsrDimens.five),
          Expanded(
            child: Text(
              mentionList.length == 1
                  ? mentionList.first.username ?? ''
                  : '${mentionList.length} people',
              style: IsrStyles.white14.copyWith(
                fontWeight: FontWeight.w600,
                color: IsrColors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    final placeList = _reelData.placeDataList ?? [];
    if (placeList.isListEmptyOrNull) return const SizedBox.shrink();

    return InkWell(
      onTap: () async {
        await widget.reelsConfig.onTapPlace?.call(
          _reelData,
          placeList,
        );
      },
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            size: IsrDimens.fifteen,
            color: IsrColors.white,
          ),
          IsrDimens.boxWidth(IsrDimens.three),
          Expanded(child: _buildSimpleLocationText(placeList)),
        ],
      ),
    );
  }

  Widget _buildSimpleLocationText(List<PlaceMetaData> placeList) {
    if (placeList.isEmpty) return const SizedBox.shrink();

    if (placeList.first.placeName.isEmpty) return const SizedBox.shrink();

    return Text(
      placeList.first.placeName,
      style: IsrStyles.white14.copyWith(
        fontWeight: FontWeight.w600,
        color: IsrColors.white,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  void _togglePlayPause() {
    if (!mounted) return; // Safety check: Widget is disposed

    // Pause video on long press start
    final key = _getCurrentVideoPlayerKey();
    final videoPlayerState = VideoPlayerWidget.of(key);
    if (videoPlayerState != null && videoPlayerState.mounted) {
      videoPlayerState.pause();
    }

    // Start image view timer only if current media is an image
    if (_reelData.mediaMetaDataList[_currentPageNotifier.value].mediaType == kPictureType) {
      _pauseImageProgress();
    }
  }

  void _resumePlayback() {
    if (!mounted) return; // Safety check: Widget is disposed

    // Resume video on long press release
    final key = _getCurrentVideoPlayerKey();
    final videoPlayerState = VideoPlayerWidget.of(key);
    if (videoPlayerState != null && videoPlayerState.mounted) {
      videoPlayerState.play();
    }

    // Start image view timer only if current media is an image
    if (_reelData.mediaMetaDataList[_currentPageNotifier.value].mediaType == kPictureType) {
      _startOrResumeImageProgress();
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          // Only the main GestureDetector as child of the outer Stack
          GestureDetector(
            onTap: _toggleMuteAndUnMute,
            onLongPressStart: (_) => _togglePlayPause(),
            onDoubleTap: _triggerLikeAnimation,
            onLongPressEnd: (_) => _resumePlayback(),
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                _buildMediaContent(),
                if (_showLikeAnimation)
                  Center(
                    child: Lottie.asset(
                      AssetConstants.heartAnimation,
                      width: 250,
                      height: 250,
                      repeat: false,
                    ),
                  ),
                if (_showMuteAnimation &&
                    _reelData.mediaMetaDataList[_currentPageNotifier.value]
                            .mediaType ==
                        kVideoType)
                  Center(
                    child: AnimatedScale(
                      scale: _muteIconScale,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.elasticOut,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        child: AppImage.svg(
                          _isMuted
                              ? AssetConstants.icMuteIcon
                              : AssetConstants.icUnMuteIcon,
                        ),
                      ),
                    ),
                  ),

                Positioned(
                  bottom: widget.reelsConfig.overlayPadding
                      ?.resolve(TextDirection.ltr)
                      .bottom ??
                      0,
                  left: 0,
                  right: 0,
                  child: ValueListenableBuilder<int>(
                    valueListenable: _currentPageNotifier,
                    builder: (context, value, child) => _buildMediaIndicators(value),
                  ),
                ),
                // Move overlays here so they don't block taps
                // OPTIMIZATION: Wrap gradient in RepaintBoundary for better scrolling
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: RepaintBoundary(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.center,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.3),
                            Colors.black.withValues(alpha: 0.6),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                // OPTIMIZATION: Separate RepaintBoundary for content overlay
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.1),
                              Colors.black.withValues(alpha: 0.3),
                              Colors.black.withValues(alpha: 0.6),
                            ],
                            stops: const [0.0, 0.3, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                //right action
                //kept separate so that it does not bloc touch/gesture to underlying widgets
                Positioned(
                  right: widget.reelsConfig.overlayPadding
                          ?.resolve(TextDirection.ltr)
                          .right ??
                      0,
                  bottom: widget.reelsConfig.overlayPadding
                          ?.resolve(TextDirection.ltr)
                          .bottom ??
                      0,
                  child:
                      widget.reelsConfig.actionWidget
                                      ?.call(_reelData)
                                      .child ??
                                  _buildRightSideActions(),
                ),

                //bottom section
                //kept separate so that it does not bloc touch/gesture to underlying widgets
                Positioned(
                  right: 40,
                  bottom: widget.reelsConfig.overlayPadding
                          ?.resolve(TextDirection.ltr)
                          .bottom ??
                      0,
                  left: widget.reelsConfig.overlayPadding
                          ?.resolve(TextDirection.ltr)
                          .left ??
                      0,
                  child:
                      widget.reelsConfig.footerWidget?.call(_reelData).child ??
                          _buildBottomSectionWithoutOverlay(),
                ),
                // Persistent mute icon indicator in top-right (placed last to be on top)
                // if (_isMuted &&
                //     _reelData.mediaMetaDataList[_currentPageNotifier.value].mediaType == kVideoType)
                //   Align(
                //     alignment: Alignment.center,
                //     child: GestureDetector(
                //       behavior: HitTestBehavior.opaque,
                //       onTap: _toggleMuteAndUnMute,
                //       child: const AppImage.svg(AssetConstants.icMuteIcon),
                //     ),
                //   ),
              ],
            ),
          ),
        ],
      );

  Widget _buildRightSideActions() => RepaintBoundary(
        child: Padding(
          padding: IsrDimens.edgeInsets(
              bottom: IsrDimens.forty, right: IsrDimens.sixteen),
          child: Column(
            spacing: IsrDimens.twenty,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_reelData.postSetting?.isProfilePicVisible == true)
                TapHandler(
                  borderRadius: IsrDimens.thirty,
                  onTap: () async {
                    if (widget.reelsConfig.onTapUserProfile == null) return;
                    await widget.reelsConfig.onTapUserProfile!(_reelData);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(IsrDimens.thirty),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.changeOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: AppImage.network(
                      _reelData.profilePhoto ?? '',
                      width: IsrDimens.thirtyFive,
                      height: IsrDimens.thirtyFive,
                      isProfileImage: true,
                      textColor: IsrColors.white,
                      name:
                          '${_reelData.firstName ?? ''} ${_reelData.lastName ?? ''}',
                    ),
                  ),
                ),
              if (_reelData.postSetting?.isCreatePostButtonVisible == true) ...[
                Column(
                  children: [
                    Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColor,
                      ),
                      child: IconButton(
                        onPressed: () async {
                          if (widget.onCreatePost != null) {
                            await widget.onCreatePost!();
                          }
                        },
                        icon: const Icon(
                          Icons.add,
                          color: IsrColors.white,
                        ),
                      ),
                    ),
                    IsrDimens.boxHeight(IsrDimens.ten),
                    Text(
                      IsrTranslationFile.create,
                      style: IsrStyles.white12,
                    ),
                  ],
                ),
              ],
              if (_reelData.postSetting?.isLikeButtonVisible == true)
                LikeActionWidget(
                  postId: _reelData.postId ?? '',
                  builder: (isLoading, isLiked, likeCount, onTap) {
                    _reelData.isLiked = isLiked;
                    _reelData.likesCount = likeCount;
                    _onLikeTap = onTap;
                    return _buildActionButton(
                      icon: isLiked == true
                          ? AssetConstants.icLikeSelected
                          : AssetConstants.icLikeUnSelected,
                      label: likeCount.toString(),
                      onTap: () => onTap(
                        reelData: _reelData,
                        watchDuration: _watchDuration,
                        postSectionType: widget.postSectionType,
                        apiCallBack: widget.onPressLikeButton != null
                            ? () =>
                                widget.onPressLikeButton!(_reelData, isLiked)
                            : null,
                      ),
                      isLoading: false, //isLoading,
                    );
                  },
                ),
              if (_reelData.postSetting?.isCommentButtonVisible == true)
                StatefulBuilder(
                  builder: (context, setBuilderState) => _buildActionButton(
                    icon: AssetConstants.icCommentIcon,
                    label: _reelData.commentCount.toString(),
                    onTap: () {
                      _handleCommentClick(setBuilderState);
                    },
                  ),
                ),
              if (_reelData.postSetting?.isShareButtonVisible == true)
                _buildActionButton(
                  icon: AssetConstants.icShareIconSvg,
                  label: IsrTranslationFile.share,
                  onTap: () async {
                    if (widget.reelsConfig.onTapShare == null) return;
                    await widget.reelsConfig.onTapShare!(_reelData);
                  },
                ),
              if (_reelData.postStatus != 0 &&
                  _reelData.postSetting?.isSaveButtonVisible == true)
                SaveActionWidget(
                  postId: _reelData.postId ?? '',
                  builder: (isLoading, isSaved, onTap) {
                    _reelData.isSavedPost = isSaved;
                    return _buildActionButton(
                      icon: isSaved == true
                          ? AssetConstants.icSaveSelected
                          : AssetConstants.icSaveUnSelected,
                      label: isSaved == true
                          ? IsrTranslationFile.saved
                          : IsrTranslationFile.save,
                      onTap: () => onTap(
                        reelData: _reelData,
                        watchDuration: _watchDuration,
                        postSectionType: widget.postSectionType,
                        apiCallBack: widget.onPressSaveButton != null
                            ? () =>
                                widget.onPressSaveButton!(_reelData, isSaved)
                            : null,
                      ),
                      isLoading: false, //isLoading,
                    );
                  },
                ),
              if (_reelData.postSetting?.isMoreButtonVisible == true)
                _buildActionButton(
                  icon: AssetConstants.icMoreIcon,
                  label: '',
                  onTap: () async {
                    if (widget.onPressMoreButton == null) return;
                    widget.onPressMoreButton!();
                  },
                ),
            ],
          ),
        ),
      );

  Widget _buildActionButton({
    required String icon,
    String? label,
    required VoidCallback onTap,
    bool isLoading = false,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isLoading
                ? SizedBox(
                    width: IsrDimens.twenty,
                    height: IsrDimens.twenty,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor),
                    ),
                  )
                : icon.endsWith('svg')
                    ? AppImage.svg(
                        icon,
                        width: IsrDimens.twentyFive,
                        height: IsrDimens.twentyFive,
                      )
                    : AppImage.svg(
                        icon,
                        width: IsrDimens.twentyFive,
                        height: IsrDimens.twentyFive,
                      ),
            if (label.isStringEmptyOrNull == false) ...[
              IsrDimens.boxHeight(IsrDimens.four),
              Text(
                label ?? '',
                style: IsrStyles.white12.copyWith(
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ],
        ),
      );

  Widget _buildBottomSectionWithoutOverlay() => Padding(
        padding: IsrDimens.edgeInsets(
            left: IsrDimens.sixteen,
            right: IsrDimens.sixteen,
            bottom: IsrDimens.fifteen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if ((_reelData.productCount ?? 0) > 0) ...[
              TapHandler(
                onTap: () {
                  if (widget.onTapCartIcon == null) return;
                  widget.onTapCartIcon?.call(_reelData.postId ?? '');
                },
                child: Container(
                  padding: IsrDimens.edgeInsetsSymmetric(
                    horizontal: IsrDimens.twelve,
                    vertical: IsrDimens.eight,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(IsrDimens.ten),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.changeOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppImage.svg(AssetConstants.icCartIcon),
                      IsrDimens.boxWidth(IsrDimens.eight),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            IsrTranslationFile.shop,
                            style: IsrStyles.primaryText12.copyWith(
                                color: IsrColors.color0F1E91,
                                fontWeight: FontWeight.w700),
                          ),
                          IsrDimens.boxHeight(IsrDimens.four),
                          Text(
                            '${_reelData.productCount} ${_reelData.productCount == 1 ? IsrTranslationFile.product : IsrTranslationFile.products}',
                            style: IsrStyles.primaryText10.copyWith(
                                color: IsrColors.color0F1E91,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              IsrDimens.boxHeight(IsrDimens.sixteen),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: TapHandler(
                                    onTap: () async {
                                      if (widget.reelsConfig.onTapUserProfile ==
                                          null) {
                                        return;
                                      }
                                      await widget.reelsConfig.onTapUserProfile
                                          ?.call(_reelData);
                                    },
                                    child: Text(
                                      _reelData.userName ?? '',
                                      style: IsrStyles.white14.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                IsrDimens.boxWidth(IsrDimens.eight),
                                _buildFollowButton(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_postDescription.isStringEmptyOrNull == false) ...[
                        IsrDimens.boxHeight(IsrDimens.eight),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: 350.responsiveDimension,
                            minHeight: 20, // Prevent grey box on empty content
                          ),
                          child: SingleChildScrollView(
                            child: ValueListenableBuilder<bool>(
                              valueListenable: _isExpandedDescription,
                              builder: (context, value, child) {
                                try {
                                  final fullDescription =
                                      _reelData.description ?? '';

                                  // Safety check: If empty after trimming, hide widget
                                  if (fullDescription.trim().isEmpty) {
                                    return const SizedBox.shrink();
                                  }

                                  final descriptionLineCount =
                                      fullDescription.split('\n').length;
                                  final shouldTruncate = fullDescription
                                              .length >
                                          _maxLengthToShow ||
                                      descriptionLineCount > _maxLinesToShow;

                                  // Show truncated version when collapsed, full version when expanded
                                  // FIX: Prevent substring out of bounds error
                                  String displayText;
                                  if (shouldTruncate && !value) {
                                    final safeLength = fullDescription.length <
                                            _maxLengthToShow
                                        ? fullDescription.length
                                        : _maxLengthToShow;
                                    displayText = fullDescription
                                        .substring(0, safeLength)
                                        .split('\n')
                                        .take(_maxLinesToShow)
                                        .join('\n');
                                  } else {
                                    displayText = fullDescription;
                                  }

                                  // OPTIMIZATION: Cache parsed description to avoid reparsing on every build
                                  if (_lastParsedDescription !=
                                          displayText.trim() ||
                                      _cachedDescriptionTextSpan == null) {
                                    _lastParsedDescription = displayText.trim();
                                    _cachedDescriptionTextSpan =
                                        _buildDescriptionTextSpan(
                                      displayText.trim(),
                                      _mentionedDataList,
                                      _taggedDataList,
                                      IsrStyles.white14.copyWith(
                                        color:
                                            IsrColors.white.changeOpacity(0.9),
                                      ),
                                      (mention) =>
                                          _callOnTapMentionData([mention]),
                                    );
                                  }

                                  // Safety check: Ensure cached TextSpan is not null
                                  if (_cachedDescriptionTextSpan == null) {
                                    debugPrint(
                                        '❌ Failed to build description TextSpan for post ${_reelData.postId}');
                                    return const SizedBox.shrink();
                                  }

                                  return GestureDetector(
                                    onTap: () {
                                      if (shouldTruncate) {
                                        _isExpandedDescription.value =
                                            !_isExpandedDescription.value;
                                      }
                                    },
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          _cachedDescriptionTextSpan!,
                                          if (shouldTruncate)
                                            TextSpan(
                                              text:
                                                  value ? ' less' : ' ... more',
                                              style: IsrStyles.white14.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: IsrColors.white
                                                    .changeOpacity(0.7),
                                              ),
                                              // Removed empty TapGestureRecognizer to prevent memory leak
                                              // Parent GestureDetector handles the tap
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                } catch (e, stackTrace) {
                                  // Catch any unexpected errors and log them
                                  debugPrint(
                                      '❌ Error building description widget: $e');
                                  debugPrint('   Post ID: ${_reelData.postId}');
                                  debugPrint(
                                      '   Description length: ${_postDescription.length}');
                                  debugPrint('   Stack trace: $stackTrace');
                                  // Return empty widget instead of showing grey box
                                  return const SizedBox.shrink();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                      // Mentioned Users and Location in same row
                      if (_reelData.mentions.isListEmptyOrNull == false ||
                          _reelData.placeDataList?.isListEmptyOrNull ==
                              false) ...[
                        IsrDimens.boxHeight(IsrDimens.eight),
                        Row(
                          children: [
                            // Mentioned Users Section
                            if (_reelData.mentions.isListEmptyOrNull ==
                                false) ...[
                              Expanded(
                                child: _buildMentionedUsersSection(),
                              ),
                              if (_reelData.placeDataList?.isListEmptyOrNull ==
                                  false) ...[
                                IsrDimens.boxWidth(IsrDimens.ten),
                              ],
                            ],
                            // Location Section
                            if (_reelData.placeDataList?.isListEmptyOrNull ==
                                false) ...[
                              Expanded(
                                child: _buildLocationSection(),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if ((_reelData.productCount ?? 0) > 0) ...[
              IsrDimens.boxHeight(IsrDimens.eight),
              _buildCommissionTag(),
            ],
          ],
        ),
      );

  Widget _buildCommissionTag() => Container(
        padding: IsrDimens.edgeInsetsSymmetric(
            horizontal: IsrDimens.six, vertical: IsrDimens.three),
        decoration: BoxDecoration(
          color: Colors.black.changeOpacity(0.5),
          borderRadius: IsrDimens.borderRadiusAll(5),
        ),
        child: Text(
          IsrTranslationFile.creatorEarnsCommission,
          style: IsrStyles.white10.copyWith(
            color: IsrColors.colorF4F4F4,
            decoration: TextDecoration.none,
          ),
        ),
      );

  Widget _buildFollowButton() {
    // Hide if it's self profile
    if (_reelData.isSelfProfile == true) return const SizedBox.shrink();

    return FollowActionWidget(
      postId: _reelData.postId ?? '',
      userId: _reelData.userId ?? '',
      builder: (isLoading, isFollowing, onTap) {
        // Update reel data state (non-blocking, for UI sync)
        _reelData.isFollow = isFollowing;

        // Show loading indicator during API call
        if (isLoading) {
          return Container(
            width: IsrDimens.sixty,
            height: IsrDimens.twentyFour,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(IsrDimens.twenty),
            ),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(IsrColors.white),
                ),
              ),
            ),
          );
        } else if (!isFollowing &&
            _reelData.postSetting?.isUnFollowButtonVisible == true) {
          return Container(
            height: IsrDimens.twentyFour,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(IsrDimens.twenty),
            ),
            child: MaterialButton(
              minWidth: IsrDimens.sixty,
              height: IsrDimens.twentyFour,
              padding:
                  IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.twelve),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(IsrDimens.twenty)),
              onPressed: () => onTap(
                reelData: _reelData,
                postSectionType: widget.postSectionType,
                watchDuration: _watchDuration,
                apiCallBack: widget.onPressFollowButton != null
                    ? () => widget.onPressFollowButton!(_reelData, isFollowing)
                    : null,
              ),
              child: Text(
                IsrTranslationFile.follow,
                style: IsrStyles.white12.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        } else if (isFollowing &&
            _reelData.postSetting?.isFollowButtonVisible == true) {
          return Container(
            height: IsrDimens.twentyFour,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(IsrDimens.twenty),
            ),
            child: MaterialButton(
              minWidth: IsrDimens.sixty,
              height: IsrDimens.twentyFour,
              padding:
                  IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.twelve),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(IsrDimens.twenty),
              ),
              onPressed: () => onTap(reelData: _reelData),
              // <-- your unfollow logic
              child: Text(
                IsrTranslationFile.following,
                style: IsrStyles.primaryText12.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Future<void> _triggerLikeAnimation() async {
    _likeAnimationTimer?.cancel();
    if (_reelData.isLiked != true) {
      _onLikeTap?.call(
        reelData: _reelData,
        watchDuration: _watchDuration,
        postSectionType: widget.postSectionType,
        apiCallBack: widget.onPressLikeButton != null
            ? () =>
                widget.onPressLikeButton!(_reelData, _reelData.isLiked == true)
            : null,
      );
    }
    setState(() {
      _showLikeAnimation = true;
    });
    _likeAnimationTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _showLikeAnimation = false;
        });
      }
    });
  }

  void _triggerMuteAnimation() {
    // Cancel any existing animation
    _muteAnimationTimer?.cancel();

    if (!mounted) return;

    setState(() {
      _showMuteAnimation = true;
      _muteIconScale = 1.3;
    });

    // Animate scale down after a short delay
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted && _showMuteAnimation) {
        setState(() {
          _muteIconScale = 1.0;
        });
      }
    });

    // Hide animation after delay
    _muteAnimationTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _showMuteAnimation = false;
        });
      }
    });
  }

  TextSpan _buildDescriptionTextSpan(
    String description,
    List<MentionMetaData> mentions,
    List<MentionMetaData> hashtags,
    TextStyle defaultStyle,
    void Function(MentionMetaData) onMentionTap,
  ) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'(@[a-zA-Z0-9_]+)|(#[a-zA-Z0-9_]+)');
    final matches = pattern.allMatches(description).toList();

    var lastIndex = 0;

    // Process each match
    for (final match in matches) {
      final start = match.start;
      final end = match.end;
      final matchedText = match.group(0)!;

      // Add normal text before the match (only if not empty/whitespace)
      if (lastIndex < start) {
        final textBefore = description.substring(lastIndex, start);
        if (textBefore.trim().isNotEmpty) {
          spans.add(TextSpan(
            text: textBefore,
            style: defaultStyle,
          ));
        } else if (textBefore.isNotEmpty) {
          // Add whitespace as-is for proper spacing
          spans.add(TextSpan(
            text: textBefore,
            style: defaultStyle,
          ));
        }
      }

      if (matchedText.startsWith('@') && mentions.isNotEmpty) {
        // Find the mention by username using where
        final matchingMentions = mentions.where(
          (m) => '@${m.username}' == matchedText,
        );

        if (matchingMentions.isNotEmpty && matchedText.isNotEmpty) {
          final mention = matchingMentions.first;
          spans.add(TextSpan(
            text: matchedText,
            style: defaultStyle.copyWith(
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.none,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                onMentionTap(mention);
              },
          ));
        } else {
          if (matchedText.isNotEmpty) {
            spans.add(TextSpan(
              text: matchedText,
              style: defaultStyle,
            ));
          }
        }
      } else if (matchedText.startsWith('#') && hashtags.isNotEmpty) {
        // Find the hashtag by tag using where
        final matchingHashtags = hashtags.where(
          (m) => '#${m.tag}' == matchedText,
        );

        if (matchingHashtags.isNotEmpty && matchedText.isNotEmpty) {
          final hashTag = matchingHashtags.first;
          spans.add(TextSpan(
            text: matchedText,
            style: defaultStyle.copyWith(
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.none,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                onMentionTap(hashTag);
              },
          ));
        } else {
          if (matchedText.isNotEmpty) {
            spans.add(TextSpan(
              text: matchedText,
              style: defaultStyle.copyWith(
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.none,
              ),
            ));
          }
        }
      } else {
        if (matchedText.isNotEmpty) {
          spans.add(TextSpan(
            text: matchedText,
            style: defaultStyle.copyWith(fontWeight: FontWeight.w400),
          ));
        }
      }

      lastIndex = end;
    }

    // Add remaining text after last match
    if (lastIndex < description.length) {
      final remainingText = description.substring(lastIndex);
      if (remainingText.trim().isNotEmpty) {
        spans.add(TextSpan(
          text: remainingText,
          style: defaultStyle,
        ));
      }
    }

    final textSpan = TextSpan(children: spans, style: defaultStyle);

    return textSpan;
  }

  void _handleCommentClick(StateSetter setBuilderState) async {
    if (widget.reelsConfig.onTapComment == null) return;
    final commentCount = await widget.reelsConfig.onTapComment!(
      _reelData,
      _reelData.commentCount ?? 0,
    );
    _reelData.commentCount = commentCount;
    if (mounted) setBuilderState.call(() {});
  }

  Widget _buildPageView(int index) {
    final media = _reelData.mediaMetaDataList[index];
    if (media.mediaType == kPictureType) {
      return SizedBox(
        key: ValueKey('media_$index'), // Consistent key
        child: _buildImageWithBlurredBackground(
          imageUrl: media.mediaUrl,
        ),
      );
    } else {
      // Video content - use VideoPlayerWidget with visibility detection for each video
      // Each video manages its own controller through the VideoPlayerWidget
      // Get or create key for this video player
      _videoPlayerKeys[index] ??= GlobalKey();

      return SizedBox(
        key: ValueKey('media_$index'), // Consistent key
        child: VideoPlayerWidget(
          key: _videoPlayerKeys[index],
          mediaUrl: media.mediaUrl,
          thumbnailUrl: media.thumbnailUrl,
          videoCacheManager: _videoCacheManager,
          isMuted: _isMuted,
          onVisibilityChanged: (isVisible) {
            // Visibility is handled internally by VideoPlayerWidget
          },
          onVideoCompleted: _moveToNextMedia,
          postHelperCallBacks: this,
          videoProgressCallBack: (totalDuration, currentPosition) {
            _watchDuration = currentPosition;
            // Update progress (0.0 to 1.0)
            if (totalDuration > 0) {
              _videoProgress.value = currentPosition / totalDuration;
              debugPrint('Video Progress: ${_videoProgress.value}');
            }
          },
        ),
      );
    }
  }

  void _moveToNextMedia() {
    // Handle video completion for carousel
    if (_hasMultipleMedia) {
      final index = _currentPageNotifier.value;
      // If there's a next media item in the carousel, move to it
      if (index < _reelData.mediaMetaDataList.length - 1) {
        final nextIndex = index + 1;
        _pageController?.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        // No more media in carousel, notify parent to move to next post and move to first media
        widget.onVideoCompleted?.call();
        _pageController?.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      // Single video, notify parent to move to next post
      widget.onVideoCompleted?.call();
    }
  }

  /// Handles mute/unmute toggle for videos only, with animation.
  void _toggleMuteAndUnMute() {
    if (_reelData.mediaMetaDataList[_currentPageNotifier.value].mediaType !=
        kVideoType) {
      // Only allow mute/unmute for videos
      return;
    }

    // Debounce audio operations to prevent flickering - increased to 250ms for stability
    _audioDebounceTimer?.cancel();
    _audioDebounceTimer =
        Timer(const Duration(milliseconds: 250), _performMuteToggle);
  }

  void _performMuteToggle() {
    setState(() {
      _isMuted = !_isMuted;
      _globalMuteState = _isMuted; // Update global mute state
    });
    // Volume change is handled by VideoPlayerWidget via didUpdateWidget
    _triggerMuteAnimation();
  }

  void _resetImageProgress() {
    _imageViewTimer?.cancel();
    _imageElapsed = Duration.zero;
    _videoProgress.value = 0.0;
  }

  /// Starts the image view timer if current media is an image
  void _startOrResumeImageProgress() {
    _imageViewTimer?.cancel();
    _isImagePaused = false;

    const tick = Duration(milliseconds: 50);

    _imageViewTimer = Timer.periodic(tick, (timer) {
      if (_isImagePaused) return;

      _imageElapsed += tick;

      final progress =
          _imageElapsed.inMilliseconds / _imageTotalDuration.inMilliseconds;

      _videoProgress.value = progress.clamp(0.0, 1.0);

      if (_imageElapsed >= _imageTotalDuration) {
        timer.cancel();
        _imageElapsed = Duration.zero;
        _moveToNextMedia();
      }
    });
  }

  void _pauseImageProgress() {
    _isImagePaused = true;
  }

  /// log image post event if user has watched for at least 2 seconds
  void _logImagePostEvent() {
    if (_hasLoggedImageViewEvent &&
        _reelData.mediaMetaDataList[_currentPageNotifier.value].mediaType ==
            kPictureType) {
      sendAnalyticsEvent(EventType.postViewed.value, {});
    }
  }

  /// Implementation of PostHelperCallBacks interface
  /// This method is called by VideoPlayerWidget to send analytics events
  @override
  void sendAnalyticsEvent(
      String eventName, Map<String, dynamic> analyticsData) async {
    try {
      // Prepare analytics event in the required format: "Post Viewed"
      final postViewedEvent = {
        'post_id': _reelData.postId ?? '',
        'view_source': 'feed',
      };
      final finalAnalyticsDataMap = {
        ...postViewedEvent,
        ...analyticsData,
      };

      debugPrint('📊 Post Viewed Event: ${jsonEncode(finalAnalyticsDataMap)}');
      EventQueueProvider.instance
          .addEvent(eventName, finalAnalyticsDataMap.removeEmptyValues());
    } catch (e) {
      debugPrint('❌ Error sending analytics event: $e');
      return null;
    }
  }
}
