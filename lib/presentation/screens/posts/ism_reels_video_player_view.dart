import 'dart:async';
import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/video_player_widget.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:lottie/lottie.dart';

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
    this.overlayPadding,
  });

  final VideoCacheManager? videoCacheManager;
  final ReelsData? reelsData;
  final VoidCallback? onPressMoreButton;
  final Future<void> Function()? onCreatePost;
  final Future<void> Function()? onPressFollowButton;
  final Future<void> Function()? onPressLikeButton;
  final Future<void> Function()? onPressSaveButton;
  final String? loggedInUserId;
  final VoidCallback? onVideoCompleted;
  final Function(List<MentionMetaData>)? onTapMentionTag;
  final Function(String)? onTapCartIcon;
  final EdgeInsetsGeometry? overlayPadding;

  @override
  State<IsmReelsVideoPlayerView> createState() => _IsmReelsVideoPlayerViewState();
}

class _IsmReelsVideoPlayerViewState extends State<IsmReelsVideoPlayerView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware
    implements PostHelperCallBacks {
  // Use MediaCacheFactory instead of direct VideoCacheManager
  VideoCacheManager get _videoCacheManager => widget.videoCacheManager ?? VideoCacheManager();

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

  final ValueNotifier<bool> _isFollowLoading = ValueNotifier(false);
  final ValueNotifier<bool> _isExpandedDescription = ValueNotifier(false);
  final ValueNotifier<bool> _isSaveLoading = ValueNotifier(false);
  final ValueNotifier<bool> _isLikeLoading = ValueNotifier(false);

  // Audio state management
  static bool _globalMuteState = false; // Global mute state that persists across all videos
  bool _isMuted = false;
  Timer? _audioDebounceTimer;
  final _maxLengthToShow = 50;
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

  @override
  void initState() {
    _onStartInit();
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

    _mentionedMetaDataList =
        _reelData.mentions.where((mentionData) => mentionData.mediaPosition != null).toList();
    _pageMentionMetaDataList = _mentionedMetaDataList
        .where((mention) => mention.mediaPosition?.position == _currentPageNotifier.value + 1)
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
    for (var i = 1; i <= 1 && (currentIndex + i) < _reelData.mediaMetaDataList.length; i++) {
      final nextIndex = currentIndex + i;
      final mediaData = _reelData.mediaMetaDataList[nextIndex];

      if (mediaData.mediaType == kVideoType && mediaData.mediaUrl.isStringEmptyOrNull == false) {
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
      final currentPage = _pageController!.page?.round() ?? _currentPageNotifier.value;
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

    _pageMentionMetaDataList = _mentionedMetaDataList
        .where((mention) => mention.mediaPosition?.position == _currentPageNotifier.value + 1)
        .toList();

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
    // Analytics logging is now handled by VideoPlayerWidget
    _logImagePostEvent();
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
    final isLocalUrl = imageUrl.isStringEmptyOrNull == false && Utility.isLocalUrl(imageUrl);
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

  Widget _buildMediaContent() {
    Widget mediaWidget;

    if (_reelData.showBlur == true) {
      mediaWidget = _getImageWidget(
        imageUrl: _reelData.mediaMetaDataList[_currentPageNotifier.value].thumbnailUrl,
        width: IsrDimens.getScreenWidth(context),
        height: IsrDimens.getScreenHeight(context),
        fit: BoxFit.cover,
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
          onDoubleTap: () async {
            _triggerLikeAnimation(); // Always show animation
            if (_reelData.isLiked != true) {
              await _callLikeFunction();
            }
          },
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
              key: const PageStorageKey('media_pageview'),
              // Add a key
              onPageChanged: _onPageChanged,
              itemCount: _reelData.mediaMetaDataList.length,
              itemBuilder: (context, index) => _buildPageView(index),
            ),
          ),
          Positioned(
            bottom: IsrDimens.hundred,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<int>(
              valueListenable: _currentPageNotifier,
              builder: (context, value, child) => _buildMediaIndicators(value),
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
    if (_reelData.mediaMetaDataList[_currentPageNotifier.value].mediaType == kPictureType) {
      return _getImageWidget(
        imageUrl: _reelData.mediaMetaDataList[_currentPageNotifier.value].mediaUrl,
        width: IsrDimens.getScreenWidth(context),
        height: IsrDimens.getScreenHeight(context),
        fit: BoxFit.cover,
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
      onVideoCompleted: () {
        // For single video, notify parent to move to next post
        widget.onVideoCompleted?.call();
      },
      postHelperCallBacks: this,
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

  Widget _buildMediaIndicators(int currentPage) {
    if (!_hasMultipleMedia) return const SizedBox.shrink();

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _reelData.mediaMetaDataList.length,
          (index) => Container(
            margin: IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.two),
            width: IsrDimens.ten,
            height: IsrDimens.ten,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == currentPage ? IsrColors.white : IsrColors.white.changeOpacity(0.4),
            ),
          ),
        ),
      ),
    );
  }

  void _callOnTapMentionData(List<MentionMetaData> mentionDataList) {
    if (widget.onTapMentionTag != null) {
      _pauseForNavigation();
      widget.onTapMentionTag?.call(mentionDataList);
      _resumeAfterNavigation();
    }
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
      onTap: () {
        _pauseForNavigation();
        _callOnTapMentionData(mentionList);
        _resumeAfterNavigation();
      },
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

    return TapHandler(
      onTap: () async {
        _pauseForNavigation();
        await _reelData.onTapPlace?.call(placeList);
        _resumeAfterNavigation();
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

    // Show actual location name for single location, or simplified text for multiple
    var locationText = placeList.first.placeName ?? '';
    if (placeList.length > 1) {
      locationText += ' +${placeList.length - 1} more';
    }

    return Text(
      locationText,
      style: IsrStyles.white14.copyWith(
        fontWeight: FontWeight.w600,
        color: IsrColors.white,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  void _togglePlayPause() {
    // Pause video on long press start
    final key = _getCurrentVideoPlayerKey();
    final videoPlayerState = VideoPlayerWidget.of(key);
    videoPlayerState?.pause();
  }

  void _resumePlayback() {
    // Resume video on long press release
    final key = _getCurrentVideoPlayerKey();
    final videoPlayerState = VideoPlayerWidget.of(key);
    videoPlayerState?.play();
  }

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          // Only the main GestureDetector as child of the outer Stack
          GestureDetector(
            onTap: _toggleMuteAndUnMute,
            onLongPressStart: (_) => _togglePlayPause(),
            onDoubleTap: () async {
              _triggerLikeAnimation(); // Always show animation
              if (_reelData.isLiked != true) {
                await _callLikeFunction();
              }
            },
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
                    _reelData.mediaMetaDataList[_currentPageNotifier.value].mediaType == kVideoType)
                  Center(
                    child: AnimatedScale(
                      scale: _muteIconScale,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.elasticOut,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.changeOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(24),
                        child: AppImage.svg(
                          _isMuted
                              ? AssetConstants.muteRoundedSvg
                              : AssetConstants.unMuteRoundedSvg,
                          width: 70,
                          height: 70,
                        ),
                      ),
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
                      padding: widget.overlayPadding,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: _reelData.footerWidget?.child ??
                                  _buildBottomSectionWithoutOverlay(),
                            ),
                          ),
                          _reelData.actionWidget?.child ?? _buildRightSideActions(),
                        ],
                      ),
                    ),
                  ),
                ),
                // Persistent mute icon indicator in top-right (placed last to be on top)
                if (_isMuted &&
                    _reelData.mediaMetaDataList[_currentPageNotifier.value].mediaType == kVideoType)
                  Positioned(
                    top: IsrDimens.oneHundredForty,
                    right: IsrDimens.sixteen,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _toggleMuteAndUnMute,
                      child: Container(
                        padding: EdgeInsets.all(IsrDimens.eight),
                        decoration: BoxDecoration(
                          color: Colors.black.changeOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: AppImage.svg(
                          AssetConstants.muteRoundedSvg,
                          width: IsrDimens.twenty,
                          height: IsrDimens.twenty,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );

  Widget _buildRightSideActions() => RepaintBoundary(
        child: Padding(
          padding: IsrDimens.edgeInsets(bottom: IsrDimens.forty, right: IsrDimens.sixteen),
          child: Column(
            spacing: IsrDimens.twenty,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_reelData.postSetting?.isProfilePicVisible == true)
                TapHandler(
                  borderRadius: IsrDimens.thirty,
                  onTap: () async {
                    if (_reelData.onTapUserProfile != null) {
                      _pauseForNavigation();
                      await _reelData.onTapUserProfile!(true);
                      _resumeAfterNavigation();
                    }
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
                      name: '${_reelData.firstName ?? ''} ${_reelData.lastName ?? ''}',
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
                ValueListenableBuilder(
                    valueListenable: _isLikeLoading,
                    builder: (context, value, child) => _buildActionButton(
                          icon: _reelData.isLiked == true
                              ? AssetConstants.icLikeSelected
                              : AssetConstants.icLikeUnSelected,
                          label: _reelData.likesCount.toString(),
                          onTap: _callLikeFunction,
                          isLoading: value,
                        )),
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
                  icon: AssetConstants.icShareIcon,
                  label: IsrTranslationFile.share,
                  onTap: () async {
                    if (_reelData.onTapShare != null) {
                      _pauseForNavigation();
                      _reelData.onTapShare!();
                      _resumeAfterNavigation();
                    }
                  },
                ),
              if (_reelData.postStatus != 0 &&
                  _reelData.postSetting?.isSaveButtonVisible == true) ...[
                ValueListenableBuilder<bool>(
                  valueListenable: _isSaveLoading,
                  builder: (context, value, child) => _buildActionButton(
                    icon: _reelData.isSavedPost == true
                        ? AssetConstants.icSaveSelected
                        : AssetConstants.icSaveUnSelected,
                    label: _reelData.isSavedPost == true
                        ? IsrTranslationFile.saved
                        : IsrTranslationFile.save,
                    onTap: _callSaveFunction,
                    isLoading: value,
                  ),
                ),
              ],
              if (_reelData.postSetting?.isMoreButtonVisible == true)
                _buildActionButton(
                  icon: AssetConstants.icMoreIcon,
                  label: '',
                  onTap: () async {
                    if (widget.onPressMoreButton != null) {
                      _pauseForNavigation();
                      widget.onPressMoreButton!();
                      _resumeAfterNavigation();
                    }
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
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: isLoading
                ? SizedBox(
                    width: IsrDimens.twentyFour,
                    height: IsrDimens.twentyFour,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                    ),
                  )
                : AppImage.asset(icon),
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
      );

  Widget _buildBottomSectionWithoutOverlay() => Padding(
        padding: IsrDimens.edgeInsets(
            left: IsrDimens.sixteen, right: IsrDimens.sixteen, bottom: IsrDimens.fifteen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if ((_reelData.productCount ?? 0) > 0) ...[
              TapHandler(
                onTap: () {
                  if (widget.onTapCartIcon != null) {
                    _pauseForNavigation();
                    widget.onTapCartIcon?.call(_reelData.postId ?? '');
                    _resumeAfterNavigation();
                  }
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
                                color: IsrColors.color0F1E91, fontWeight: FontWeight.w700),
                          ),
                          IsrDimens.boxHeight(IsrDimens.four),
                          Text(
                            '${_reelData.productCount} ${_reelData.productCount == 1 ? IsrTranslationFile.product : IsrTranslationFile.products}',
                            style: IsrStyles.primaryText10.copyWith(
                                color: IsrColors.color0F1E91, fontWeight: FontWeight.w500),
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
                                      if (_reelData.onTapUserProfile != null) {
                                        _pauseForNavigation();
                                        await _reelData.onTapUserProfile!(false);
                                        _resumeAfterNavigation();
                                      }
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
                        ValueListenableBuilder<bool>(
                          valueListenable: _isExpandedDescription,
                          builder: (context, value, child) {
                            final fullDescription = _reelData.description ?? '';
                            final shouldTruncate = fullDescription.length > _maxLengthToShow;

                            // Show truncated version when collapsed, full version when expanded
                            final displayText = shouldTruncate && !value
                                ? fullDescription.substring(0, _maxLengthToShow)
                                : fullDescription;

                            // OPTIMIZATION: Cache parsed description to avoid reparsing on every build
                            if (_lastParsedDescription != displayText.trim() ||
                                _cachedDescriptionTextSpan == null) {
                              _lastParsedDescription = displayText.trim();
                              _cachedDescriptionTextSpan = _buildDescriptionTextSpan(
                                displayText.trim(),
                                _mentionedDataList,
                                _taggedDataList,
                                IsrStyles.white14
                                    .copyWith(color: IsrColors.white.changeOpacity(0.9)),
                                (mention) {
                                  _callOnTapMentionData([mention]);
                                },
                              );
                            }

                            return GestureDetector(
                              onTap: () {
                                if (shouldTruncate) {
                                  _isExpandedDescription.value = !_isExpandedDescription.value;
                                }
                              },
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    _cachedDescriptionTextSpan!,
                                    if (shouldTruncate)
                                      TextSpan(
                                        text: value ? ' ' : ' ... ',
                                        style:
                                            IsrStyles.white14.copyWith(fontWeight: FontWeight.w700),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            // _isExpandedDescription.value =
                                            //     !_isExpandedDescription.value;
                                          },
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      // Mentioned Users and Location in same row
                      if (_reelData.mentions.isListEmptyOrNull == false ||
                          _reelData.placeDataList?.isListEmptyOrNull == false) ...[
                        IsrDimens.boxHeight(IsrDimens.eight),
                        Row(
                          children: [
                            // Mentioned Users Section
                            if (_reelData.mentions.isListEmptyOrNull == false) ...[
                              Expanded(
                                child: _buildMentionedUsersSection(),
                              ),
                              if (_reelData.placeDataList?.isListEmptyOrNull == false) ...[
                                IsrDimens.boxWidth(IsrDimens.ten),
                              ],
                            ],
                            // Location Section
                            if (_reelData.placeDataList?.isListEmptyOrNull == false) ...[
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
        padding:
            IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.six, vertical: IsrDimens.three),
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

    // FOLLOW button
    if (_reelData.postSetting?.isFollowButtonVisible == true && _reelData.isFollow == false) {
      return ValueListenableBuilder<bool>(
        valueListenable: _isFollowLoading,
        builder: (context, isLoading, child) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: isLoading
              ? SizedBox(
                  width: IsrDimens.sixty,
                  height: IsrDimens.twentyFour,
                  child: Center(
                    child: SizedBox(
                      width: IsrDimens.sixteen,
                      height: IsrDimens.sixteen,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : Container(
                  height: IsrDimens.twentyFour,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(IsrDimens.twenty),
                  ),
                  child: MaterialButton(
                    minWidth: IsrDimens.sixty,
                    height: IsrDimens.twentyFour,
                    padding: IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.twelve),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(IsrDimens.twenty)),
                    onPressed: _callFollowFunction,
                    child: Text(
                      IsrTranslationFile.follow,
                      style: IsrStyles.white12.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
        ),
      );
    }

    // FOLLOWING button (Unfollow option visible)
    if (_reelData.isFollow == true && _reelData.postSetting?.isUnFollowButtonVisible == true) {
      return Container(
        height: IsrDimens.twentyFour,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(IsrDimens.twenty),
        ),
        child: MaterialButton(
          minWidth: IsrDimens.sixty,
          height: IsrDimens.twentyFour,
          padding: IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.twelve),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(IsrDimens.twenty),
          ),
          onPressed: _callFollowFunction,
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

    // Otherwise, show nothing
    return const SizedBox.shrink();
  }

  //calls api to follow and unfollow user
  Future<void> _callFollowFunction() async {
    if (widget.onPressFollowButton == null) return;
    _isFollowLoading.value = true;

    try {
      await widget.onPressFollowButton!();
    } finally {
      _isFollowLoading.value = false;
    }
  }

  Future<void> _callSaveFunction() async {
    if (widget.onPressSaveButton == null || _isSaveLoading.value) return;
    _isSaveLoading.value = true;

    try {
      await widget.onPressSaveButton!();
    } finally {
      _isSaveLoading.value = false;
    }
  }

  Future<void> _callLikeFunction() async {
    if (widget.onPressLikeButton == null || _isLikeLoading.value) return;
    _isLikeLoading.value = true;
    try {
      final wasLiked = _reelData.isLiked == true;
      await widget.onPressLikeButton!();
      // Only show animation if it was not liked before and is now liked
      if (!wasLiked && _reelData.isLiked == true) {
        _triggerLikeAnimation();
      }
      // If already liked, just do dislike (no animation)
    } finally {
      _isLikeLoading.value = false;
    }
  }

  void _triggerLikeAnimation() {
    _likeAnimationTimer?.cancel();
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
    if (_reelData.onTapComment != null) {
      // Pause video before opening comments
      _pauseForNavigation();

      final commentCount = await _reelData.onTapComment!(_reelData.commentCount ?? 0);

      // Resume video when coming back
      _resumeAfterNavigation();

      if (commentCount != null) {
        _reelData.commentCount = commentCount;
      }
      if (mounted) {
        setBuilderState.call(() {});
      }
    }
  }

  /// Pauses video when navigating away from reel screen
  void _pauseForNavigation() {
    // Navigation is handled by individual VideoPlayerWidgets
  }

  /// Resumes video when returning to reel screen
  void _resumeAfterNavigation() {
    // Navigation is handled by individual VideoPlayerWidgets
  }

  Widget _buildPageView(int index) {
    final media = _reelData.mediaMetaDataList[index];
    if (media.mediaType == kPictureType) {
      return SizedBox(
        key: ValueKey('media_$index'), // Consistent key
        child: _getImageWidget(
          imageUrl: media.mediaUrl,
          width: IsrDimens.getScreenWidth(context),
          height: IsrDimens.getScreenHeight(context),
          fit: BoxFit.cover,
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
          onVideoCompleted: () {
            // Handle video completion for carousel
            if (_hasMultipleMedia) {
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
          },
        ),
      );
    }
  }

  /// Handles mute/unmute toggle for videos only, with animation.
  void _toggleMuteAndUnMute() {
    if (_reelData.mediaMetaDataList[_currentPageNotifier.value].mediaType != kVideoType) {
      // Only allow mute/unmute for videos
      return;
    }

    // Debounce audio operations to prevent flickering - increased to 250ms for stability
    _audioDebounceTimer?.cancel();
    _audioDebounceTimer = Timer(const Duration(milliseconds: 250), _performMuteToggle);
  }

  void _performMuteToggle() {
    setState(() {
      _isMuted = !_isMuted;
      _globalMuteState = _isMuted; // Update global mute state
    });
    // Volume change is handled by VideoPlayerWidget via didUpdateWidget
    _triggerMuteAnimation();
  }

  /// log image post event
  void _logImagePostEvent() {
    if (_reelData.mediaMetaDataList[_currentPageNotifier.value].mediaType == kPictureType) {
      sendAnalyticsEvent({
        'media_url': _reelData.mediaMetaDataList[_currentPageNotifier.value].mediaUrl,
      });
    }
  }

  /// Implementation of PostHelperCallBacks interface
  /// This method is called by VideoPlayerWidget to send analytics events
  @override
  void sendAnalyticsEvent(Map<String, dynamic> analyticsData) async {
    final socialPostBloc = IsmInjectionUtils.getOtherClass<SocialPostBloc>();
    try {
      // Get device info from dependency injection
      final deviceInfoManager = IsmInjectionUtils.getOtherClass<DeviceInfoManager>();

      // Prepare analytics event in the required format: "Post Viewed"
      final postViewedEvent = {
        'event': 'Post Viewed',
        'post_id': _reelData.postId ?? '',
        'post_type': _reelData.mediaMetaDataList.length > 1
            ? 'carousel'
            : _reelData.mediaMetaDataList[_currentPageNotifier.value].mediaType == kVideoType
                ? 'video'
                : 'image',
        'dwell_time': analyticsData['view_duration'] ?? 0,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Old data structure (commented out)
      // final postViewedEvent = {
      //   // Post information
      //   'post_id': _reelData.postId ?? '',
      //   'post_title': _reelData.description ?? '',
      //
      //   // Video/Media watch metrics
      //   'duration_watched': analyticsData['view_duration'] ?? 0, // seconds
      //   'total_duration': analyticsData['total_duration'] ?? 0, // seconds
      //   'completion_rate':
      //       analyticsData['view_completion_rate'] ?? 0, // percentage
      //
      //   // Device information
      //   'platform': Platform.isIOS ? 'iOS' : 'Android',
      //   'device_model': deviceInfoManager.deviceModel ?? 'Unknown',
      //   'app_version': appVersion,
      //
      //   // Content information
      //   'category': 'General', // Customize based on your data
      //   'content_type':
      //       _reelData.mediaMetaDataList[_currentPageNotifier.value].mediaType ==
      //               kVideoType
      //           ? 'video'
      //           : 'image',
      //
      //   // User information
      //   'user_id': widget.loggedInUserId ?? '', // Logged in user (viewer)
      //   'creator_user_id': _reelData.userId ?? '', // Post creator
      //   'creator_user_name': _reelData.userName ?? '',
      //
      //   // Geolocation (customize as needed)
      //   'location': 'US', // Add your location logic here
      //
      //   // Additional metadata
      //   'view_source': analyticsData['view_source'] ?? 'feed',
      //   'media_url': analyticsData['media_url'] ?? '',
      //   'timestamp': DateTime.now().toIso8601String(),
      // };

      debugPrint('📊 Post Viewed Event: ${jsonEncode(postViewedEvent)}');

      socialPostBloc.sendAnalyticsEvent(
        eventName: EventType.view.value,
        properties: postViewedEvent.removeEmptyValues(),
      );
    } catch (e) {
      debugPrint('❌ Error sending analytics event: $e');
      return null;
    }
  }
}
