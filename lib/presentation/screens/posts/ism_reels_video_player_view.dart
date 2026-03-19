import 'dart:async';
import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/video_player_widget.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/like_action_widget.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:lottie/lottie.dart';
import 'package:preload_page_view/preload_page_view.dart';
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
    required this.currentIndex,
  });

  final VideoCacheManager? videoCacheManager;
  final ReelsData? reelsData;
  final VoidCallback? onPressMoreButton;
  final Future<void> Function()? onCreatePost;
  final Future<bool> Function(ReelsData reelsData, bool currentFollow)? onPressFollowButton;
  final Future<bool> Function(ReelsData reelsData, bool currentLiked)? onPressLikeButton;
  final Future<bool> Function(ReelsData reelsData, bool currentSaved)? onPressSaveButton;
  final String? loggedInUserId;
  final VoidCallback? onVideoCompleted;
  final Function(List<MentionMetaData>)? onTapMentionTag;
  final Function(String)? onTapCartIcon;
  final int index;
  final ValueNotifier<int> currentIndex;
  final ReelsConfig reelsConfig;
  final PostSectionType postSectionType;

  @override
  State<IsmReelsVideoPlayerView> createState() => _IsmReelsVideoPlayerViewState();
}

class _IsmReelsVideoPlayerViewState extends State<IsmReelsVideoPlayerView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware
    implements PostHelperCallBacks {
  // Use MediaCacheFactory instead of direct VideoCacheManager
  VideoCacheManager get _videoCacheManager => widget.videoCacheManager ?? VideoCacheManager();
  PostConfig get _postConfig => widget.reelsConfig.postConfig;

  // Config helper getters
  PostUIConfig? get _uiConfig => _postConfig.postUIConfig;
  ActionIconConfig? get _actionIconConfig => _uiConfig?.actionIconConfig;
  TextStyleConfig? get _textStyleConfig => _uiConfig?.textStyleConfig;
  ShopUIConfig? get _shopUIConfig => _uiConfig?.shopUIConfig;
  FollowButtonConfig? get _followButtonConfig => _uiConfig?.followButtonConfig;
  MediaIndicatorConfig? get _mediaIndicatorConfig => _uiConfig?.mediaIndicatorConfig;
  UserProfileConfig? get _userProfileConfig => _uiConfig?.userProfileConfig;
  DescriptionConfig? get _descriptionConfig => _uiConfig?.descriptionConfig;
  LocationConfig? get _locationConfig => _uiConfig?.locationConfig;
  MentionConfig? get _mentionConfig => _uiConfig?.mentionConfig;

  // Add constants for media types
  static const int kPictureType = 0;
  static const int kVideoType = 1;

  // Carousel related variables
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(0);
  PreloadPageController? _pageController;

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
  static bool _globalMuteState = false; // Global mute state that persists across all videos
  bool _isMuted = false;
  Timer? _audioDebounceTimer;

  // Description config values with fallbacks
  int get _maxLengthToShow => _descriptionConfig?.maxLengthToShow ?? 50;
  int get _maxLinesToShow => _descriptionConfig?.maxLinesToShow ?? 2;

  /// Strong text shadows for visibility on any background
  List<Shadow> get _textShadows =>
      _descriptionConfig?.textShadows ??
      [
        Shadow(
          color: Colors.black.changeOpacity(0.9),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
        Shadow(
          color: Colors.black.changeOpacity(0.7),
          blurRadius: 4,
        ),
        Shadow(
          color: Colors.black.changeOpacity(0.5),
          blurRadius: 8,
        ),
      ];
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
  bool _isImagePaused = false;

  bool get _isPreloaded => widget.index != widget.currentIndex.value;

  // current media progress tracking
  Duration _currentMediaWatchDuration = Duration.zero;
  final ValueNotifier<double> _currentMediaProgress = ValueNotifier<double>(0.0);
  bool _isSeeking = false; // Flag to prevent progress updates during seeking

  // post Progress Tracking
  int get _postTotalDurationSeconds =>
      _reelData.mediaMetaDataList.isEmpty
          ? 0
          : _reelData.mediaMetaDataList
          .map((e) => e.durationSeconds)
          .reduce((a, b) => a + b);
  Duration _postWatchDuration = Duration.zero;
  final ValueNotifier<double> _postProgress = ValueNotifier<double>(0.0);
  bool _wasVisiblePost = false;
  void _onCurrentIndexChanged() {
    final isVisible = widget.currentIndex.value == widget.index;
    if (_wasVisiblePost && !isVisible) {
      _logWatchPostEvent();
    }
    debugPrint('IsmReelsVideoPlayerView: _onCurrentIndexChanged {Post index: ${widget.index}, currentIndex: ${widget.currentIndex.value}}');
    _wasVisiblePost = isVisible;
  }

  @override
  void initState() {
    _onStartInit();
    _wasVisiblePost = widget.currentIndex.value == widget.index;
    widget.currentIndex.addListener(_onCurrentIndexChanged);
    debugPrint(
        'IsmReelsVideoPlayerView: initState index: ${widget.index}, visibleIndex: ${widget.currentIndex.value}, tabType: ${widget.postSectionType}');
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Capture the BuildContext for SDK use
    IsrVideoReelConfig.buildContext = context;
    debugPrint(
        'IsmReelsVideoPlayerView: didChangeDependencies index: ${widget.index}, visibleIndex: ${widget.currentIndex.value}, tabType: ${widget.postSectionType}');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint(
        'IsmReelsVideoPlayerView: didChangeAppLifecycleState index: ${widget.index}, visibleIndex: ${widget.currentIndex.value}, tabType: ${widget.postSectionType}');
    // Lifecycle is handled by individual VideoPlayerWidgets
  }

  // RouteAware methods for navigation detection
  @override
  void didPopNext() {
    debugPrint(
        'IsmReelsVideoPlayerView: didPopNext index: ${widget.index}, visibleIndex: ${widget.currentIndex.value}, tabType: ${widget.postSectionType}');
    // Navigation is handled by individual VideoPlayerWidgets
  }

  @override
  void didPushNext() {
    debugPrint(
        'IsmReelsVideoPlayerView: didPushNext index: ${widget.index}, visibleIndex: ${widget.currentIndex.value}, tabType: ${widget.postSectionType}');
    if (_wasVisiblePost) _logWatchPostEvent();
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
    _pageController = PreloadPageController(initialPage: 0);

    // Preload next videos for smoother experience
    _preloadNextVideos();

    //resent image progress
    _resetPostProgress();

    // Start image view timer only if current media is an image
    if (_reelData.mediaMetaDataList[_currentPageNotifier.value].mediaType == kPictureType) {
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
      final allMedia = [
        ...nextThumbnails,
        ...nextVideos,
      ];
      MediaCacheFactory.precacheMedia(allMedia, highPriority: true).then((_) {
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

    _resetMediaProgress();

    // Restart image view timer only if new page is an image
    if (_reelData.mediaMetaDataList[index].mediaType == kPictureType) {
      _startOrResumeImageProgress();
    }

    mountUpdate();
  }

  /// Disposes the current video controller if not cached, and cleans up state.
  @override
  void dispose() {
    if (_wasVisiblePost) {
      _logWatchPostEvent();
    }
    widget.currentIndex.removeListener(_onCurrentIndexChanged);
    WidgetsBinding.instance.removeObserver(this);
    _tapGestureRecognizer?.dispose();
    _pageController?.dispose();
    _likeAnimationTimer?.cancel();
    _muteAnimationTimer?.cancel();
    _audioDebounceTimer?.cancel();
    _imageViewTimer?.cancel();
    _currentMediaProgress.dispose();
    _postProgress.dispose();
    debugPrint(
        'IsmReelsVideoPlayerView: dispose index: ${widget.index}, visibleIndex: ${widget.currentIndex.value}, tabType: ${widget.postSectionType}');
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

  double imageVisibilityFraction = 0;

  Widget _buildImageWithBlurredBackground({
    required String imageUrl,
  }) =>
      VisibilityDetector(
        key: ValueKey('image_${imageUrl.hashCode}'),
        onVisibilityChanged: (visibilityInfo) {
          imageVisibilityFraction = visibilityInfo.visibleFraction;

          if (imageVisibilityFraction == 1.0) {
            // Fully visible → play
            _startOrResumeImageProgress();
          } else {
            // Partially visible / not visible → pause
            _pauseImageProgress();
          }
        },
        child: BlocListener<SocialPostBloc, SocialPostState>(
          listenWhen: (previous, current) => current is PlayPauseVideoState,
          listener: (context, state) {
            if (!mounted) return; // Safety check: Widget is disposed

            if (state is PlayPauseVideoState) {
              if (state.play) {
                if (imageVisibilityFraction == 1.0) {
                  // Fully visible → play
                  _startOrResumeImageProgress();
                } else {
                  // Partially visible / not visible → pause
                  _pauseImageProgress();
                }
              } else {
                _pauseImageProgress();
              }
            }
          },
          child: Container(
            color: Colors.black,
            child: Center(
              child: _getImageWidget(
                imageUrl: imageUrl,
                width: IsrDimens.getScreenWidth(context),
                height: IsrDimens.getScreenHeight(context),
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      );

  Widget _buildMediaContent() {
    Widget mediaWidget;

    if (_reelData.showBlur == true) {
      mediaWidget = _getImageWidget(
        imageUrl: _reelData.mediaMetaDataList[_currentPageNotifier.value].thumbnailUrl,
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
            child: PreloadPageView.builder(
              preloadPagesCount: 1,
              controller: _pageController,
              // padEnds: false,
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
    if (_reelData.mediaMetaDataList[_currentPageNotifier.value].mediaType == kPictureType) {
      return _buildImageWithBlurredBackground(
        imageUrl: _reelData.mediaMetaDataList[_currentPageNotifier.value].mediaUrl,
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
      videoProgressCallBack: (totalDuration, currentPosition) {
        _currentMediaWatchDuration   = currentPosition;
        // Update progress (0.0 to 1.0) only if not seeking
        if (totalDuration.inMilliseconds > 0 && !_isSeeking) {
          _currentMediaProgress.value = currentPosition.inMilliseconds / totalDuration.inMilliseconds;
        }
        media.durationSeconds = totalDuration.inSeconds;
        _updatePostProgress();
      },
      isPreloaded: _isPreloaded,
      logIndex: '${widget.index}-0-}',
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
    final primaryColor = Theme.of(context).primaryColor;
    final mediaCount = _reelData.mediaMetaDataList.length;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: IsrDimens.eight),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          mediaCount,
          (index) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : (_mediaIndicatorConfig?.indicatorSpacing ?? IsrDimens.two),
                right: index == mediaCount - 1
                    ? 0
                    : (_mediaIndicatorConfig?.indicatorSpacing ?? IsrDimens.two),
              ),
              child: _buildSingleMediaIndicator(
                index: index,
                currentPage: currentPage,
                primaryColor: primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSingleMediaIndicator({
    required int index,
    required int currentPage,
    required Color primaryColor,
  }) {
    final isCurrentMedia = index == currentPage;
    final isCompletedMedia = index < currentPage;
    final isVideo = _reelData.mediaMetaDataList[index].mediaType == kVideoType;
    final borderRadius =
        _mediaIndicatorConfig?.indicatorBorderRadius ?? BorderRadius.circular(IsrDimens.two);
    final indicatorHeight = _mediaIndicatorConfig?.indicatorHeight ?? IsrDimens.six;

    // For completed media segments - show solid white (fully progressed)
    if (isCompletedMedia) {
      return Container(
        height: indicatorHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _mediaIndicatorConfig?.completedColor ??
              const Color(0xFFFFFFFF), // Pure white for completed
          borderRadius: borderRadius,
        ),
      );
    }

    // For upcoming media segments - show semi-transparent white (pending)
    if (!isCurrentMedia) {
      return Container(
        height: indicatorHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _mediaIndicatorConfig?.pendingColor ??
              const Color(0x80FFFFFF), // 50% white for pending
          borderRadius: borderRadius,
        ),
      );
    }

    // For current media - show progress bar or seekbar
    if (isVideo) {
      return _buildVideoSeekbar(primaryColor, borderRadius);
    } else {
      return _buildImageProgressIndicator(primaryColor, borderRadius);
    }
  }

  Widget _buildVideoSeekbar(Color pendingColor, BorderRadius borderRadius) =>
      ValueListenableBuilder<double>(
        valueListenable: _currentMediaProgress,
        builder: (context, progress, child) => GestureDetector(
          onHorizontalDragStart: (_) => _onSeekStart(),
          onHorizontalDragEnd: (_) => _onSeekEnd(),
          onHorizontalDragUpdate: (details) {
            final box = context.findRenderObject() as RenderBox;
            final localPosition = box.globalToLocal(details.globalPosition);
            final newProgress = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
            _onSeekVideo(newProgress);
          },
          child: Container(
            height: _mediaIndicatorConfig?.indicatorHeight ?? IsrDimens.six,
            decoration: BoxDecoration(
              color: _mediaIndicatorConfig?.pendingColor ??
                  const Color(0x80FFFFFF), // 50% white for pending - always visible
              borderRadius: borderRadius,
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: _mediaIndicatorConfig?.progressColor ??
                        const Color(0xFFFFFFFF), // Pure white for progressed
                    borderRadius: borderRadius,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildImageProgressIndicator(Color pendingColor, BorderRadius borderRadius) =>
      ValueListenableBuilder<double>(
        valueListenable: _currentMediaProgress, // Used for both video and image progress
        builder: (context, progress, child) => Container(
          height: _mediaIndicatorConfig?.indicatorHeight ?? IsrDimens.six,
          decoration: BoxDecoration(
            color: _mediaIndicatorConfig?.pendingColor ??
                const Color(0x80FFFFFF), // 50% white for pending - always visible
            borderRadius: borderRadius,
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: _mediaIndicatorConfig?.progressColor ??
                      const Color(0xFFFFFFFF), // Pure white for progressed
                  borderRadius: borderRadius,
                ),
              ),
            ),
          ),
        ),
      );

  void _onSeekStart() {
    _isSeeking = true;
    // Pause video while seeking
    final key = _getCurrentVideoPlayerKey();
    final videoPlayerState = VideoPlayerWidget.of(key);
    videoPlayerState?.pause();
  }

  void _onSeekEnd() {
    // Seek to the final position before resuming
    final key = _getCurrentVideoPlayerKey();
    final videoPlayerState = VideoPlayerWidget.of(key);
    if (videoPlayerState != null) {
      final duration = videoPlayerState.duration;
      if (duration != null) {
        final position = Duration(
          milliseconds: (duration.inMilliseconds * _currentMediaProgress.value).toInt(),
        );
        videoPlayerState.seekTo(position);
      }
    }
    // Delay resetting the flag to allow seek to complete
    Future.delayed(const Duration(milliseconds: 100), () {
      _isSeeking = false;
      videoPlayerState?.play();
    });
  }

  void _onSeekVideo(double value) {
    // Only update the progress value during seeking - don't seek video yet
    _currentMediaProgress.value = value;
  }

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
        style: _textStyleConfig?.mediaCounterStyle ??
            IsrStyles.white12.copyWith(
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
          if (_mentionConfig?.mentionIcon != null)
            AppImage.svg(
              _mentionConfig!.mentionIcon!,
              width: _mentionConfig?.mentionIconSize ?? IsrDimens.fifteen,
              height: _mentionConfig?.mentionIconSize ?? IsrDimens.fifteen,
              color: _mentionConfig?.mentionIconColor ?? IsrColors.white,
            )
          else
            Icon(
              Icons.people,
              size: _mentionConfig?.mentionIconSize ?? IsrDimens.fifteen,
              color: _mentionConfig?.mentionIconColor ?? IsrColors.white,
              shadows: _textShadows,
            ),
          IsrDimens.boxWidth(_mentionConfig?.mentionIconSpacing ?? IsrDimens.five),
          Expanded(
            child: Text(
              mentionList.length == 1
                  ? mentionList.first.username ?? ''
                  : '${mentionList.length} people',
              style: _textStyleConfig?.mentionStyle ??
                  IsrStyles.white14.copyWith(
                    fontWeight: FontWeight.w600,
                    color: IsrColors.white,
                    shadows: _textShadows,
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

    return GestureDetector(
      onTap: () async {
        await widget.reelsConfig.onTapPlace?.call(
          _reelData,
          placeList,
        );
      },
      child: Row(
        children: [
          if (_locationConfig?.locationIcon != null)
            AppImage.svg(
              _locationConfig!.locationIcon!,
              width: _locationConfig?.locationIconSize ?? IsrDimens.fifteen,
              height: _locationConfig?.locationIconSize ?? IsrDimens.fifteen,
              color: _locationConfig?.locationIconColor ?? IsrColors.white,
            )
          else
            Icon(
              Icons.location_on,
              size: _locationConfig?.locationIconSize ?? IsrDimens.fifteen,
              color: _locationConfig?.locationIconColor ?? IsrColors.white,
              shadows: _textShadows,
            ),
          IsrDimens.boxWidth(_locationConfig?.locationIconSpacing ?? IsrDimens.three),
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
      style: _textStyleConfig?.locationStyle ??
          IsrStyles.white14.copyWith(
            fontWeight: FontWeight.w600,
            color: IsrColors.white,
            decoration: TextDecoration.none,
            shadows: _textShadows,
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
  Widget build(BuildContext context) {
    debugPrint(
        'IsmReelsVideoPlayerView: build index: ${widget.index}, visibleIndex: ${widget.currentIndex.value}, tabType: ${widget.postSectionType}');
    return Stack(
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
                  _reelData.mediaMetaDataList[_currentPageNotifier.value].mediaType == kVideoType)
                Center(
                  child: AnimatedScale(
                    scale: _muteIconScale,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.elasticOut,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: AppImage.svg(
                        _isMuted
                            ? (_actionIconConfig?.muteIcon ?? AssetConstants.icMuteIcon)
                            : (_actionIconConfig?.unmuteIcon ?? AssetConstants.icUnMuteIcon),
                      ),
                    ),
                  ),
                ),

              // show progress indicator if there are multiple videos or single media is video or autoMoveNextMedia is true
              if (_reelData.mediaMetaDataList.isNotEmpty ||
                  _reelData.mediaMetaDataList.firstOrNull?.mediaType == kVideoType ||
                  widget.onVideoCompleted != null)
                Positioned(
                  bottom:
                      widget.reelsConfig.overlayPadding?.resolve(TextDirection.ltr).bottom ?? 0 + 3,
                  left: 0,
                  right: 0,
                  child: ValueListenableBuilder<int>(
                    valueListenable: _currentPageNotifier,
                    builder: (context, value, child) => _buildMediaIndicators(value),
                  ),
                ),

              // Bottom gradient overlay for text readability
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: Container(
                      height: IsrDimens.getScreenHeight(context) * 0.45,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.2),
                            Colors.black.withValues(alpha: 0.5),
                            Colors.black.withValues(alpha: 0.7),
                          ],
                          stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              //right action
              //kept separate so that it does not bloc touch/gesture to underlying widgets
              Positioned(
                right: widget.reelsConfig.overlayPadding?.resolve(TextDirection.ltr).right ?? 0,
                bottom: widget.reelsConfig.overlayPadding?.resolve(TextDirection.ltr).bottom ?? 0,
                child: widget.reelsConfig.actionWidget?.call(_reelData).child ??
                    _buildRightSideActions(),
              ),

              //bottom section
              //kept separate so that it does not bloc touch/gesture to underlying widgets
              Positioned(
                right: 40,
                bottom: widget.reelsConfig.overlayPadding?.resolve(TextDirection.ltr).bottom ?? 0,
                left: widget.reelsConfig.overlayPadding?.resolve(TextDirection.ltr).left ?? 0,
                child: widget.reelsConfig.footerWidget?.call(_reelData).child ??
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
  }

  Widget _buildRightSideActions() => RepaintBoundary(
        child: Padding(
          padding: IsrDimens.edgeInsets(bottom: IsrDimens.forty, right: IsrDimens.sixteen),
          child: Column(
            spacing: IsrDimens.twenty,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
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
                        icon: Icon(
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
                          ? (_actionIconConfig?.likeIconSelected ?? AssetConstants.icLikeSelected)
                          : (_actionIconConfig?.likeIconUnselected ??
                              AssetConstants.icLikeUnSelected),
                      label: likeCount.toString(),
                      onTap: () => onTap(
                        reelData: _reelData,
                        watchDuration: _postWatchDuration.inSeconds,
                        postSectionType: widget.postSectionType,
                        apiCallBack: widget.onPressLikeButton != null
                            ? () => widget.onPressLikeButton!(_reelData, isLiked)
                            : null,
                      ),
                      isLoading: false, //isLoading,
                    );
                  },
                ),
              if (_reelData.postSetting?.isCommentButtonVisible == true)
                StatefulBuilder(
                  builder: (context, setBuilderState) => _buildActionButton(
                    icon: _actionIconConfig?.commentIcon ?? AssetConstants.icCommentIcon,
                    label: _reelData.commentCount.toString(),
                    onTap: () {
                      _handleCommentClick(setBuilderState);
                    },
                  ),
                ),
              if (_reelData.postSetting?.isShareButtonVisible == true)
                _buildActionButton(
                  icon: _actionIconConfig?.shareIcon ?? AssetConstants.icShareIconSvg,
                  label: IsrTranslationFile.share,
                  onTap: () async {
                    if (widget.reelsConfig.onTapShare == null) return;
                    await widget.reelsConfig.onTapShare!(_reelData);
                  },
                ),
              if (_reelData.postStatus != 0 && _reelData.postSetting?.isSaveButtonVisible == true)
                SaveActionWidget(
                  postId: _reelData.postId ?? '',
                  builder: (isLoading, isSaved, onTap) {
                    _reelData.isSavedPost = isSaved;
                    return _buildActionButton(
                      icon: isSaved == true
                          ? (_actionIconConfig?.saveIconSelected ?? AssetConstants.icSaveSelected)
                          : (_actionIconConfig?.saveIconUnselected ??
                              AssetConstants.icSaveUnSelected),
                      label: isSaved == true ? IsrTranslationFile.saved : IsrTranslationFile.save,
                      onTap: () => onTap(
                        reelData: _reelData,
                        watchDuration: _postWatchDuration.inSeconds,
                        postSectionType: widget.postSectionType,
                        apiCallBack: widget.onPressSaveButton != null
                            ? () => widget.onPressSaveButton!(_reelData, isSaved)
                            : null,
                      ),
                      isLoading: false, //isLoading,
                    );
                  },
                ),
              if (_reelData.postSetting?.isMoreButtonVisible == true)
                _buildActionButton(
                  icon: _actionIconConfig?.moreIcon ?? AssetConstants.icMoreIcon,
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
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                    ),
                  )
                : Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: _actionIconConfig?.iconShadow ??
                          [
                            BoxShadow(
                              color: Colors.black.changeOpacity(0.2),
                              blurRadius: IsrDimens.three,
                              spreadRadius: IsrDimens.three,
                            ),
                          ],
                    ),
                    child: AppImage.svg(
                      icon,
                      width: _actionIconConfig?.iconSize ?? IsrDimens.twentyFive,
                      height: _actionIconConfig?.iconSize ?? IsrDimens.twentyFive,
                    ),
                  ),
            if (label.isStringEmptyOrNull == false) ...[
              IsrDimens.boxHeight(IsrDimens.four),
              Text(
                label ?? '',
                style: _textStyleConfig?.actionLabelStyle ??
                    IsrStyles.white12.copyWith(
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                      shadows: _textShadows,
                    ),
              ),
            ],
          ],
        ),
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
                  if (widget.onTapCartIcon == null) return;
                  widget.onTapCartIcon?.call(_reelData.postId ?? '');
                },
                child: Container(
                  padding: _shopUIConfig?.shopContainerPadding ??
                      IsrDimens.edgeInsetsSymmetric(
                        horizontal: IsrDimens.twelve,
                        vertical: IsrDimens.eight,
                      ),
                  decoration: _shopUIConfig?.shopContainerDecoration ??
                      BoxDecoration(
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
                      AppImage.svg(
                        _shopUIConfig?.cartIcon ?? AssetConstants.icCartIcon,
                        width: _shopUIConfig?.shopIconSize,
                        height: _shopUIConfig?.shopIconSize,
                        color: _shopUIConfig?.shopIconColor,
                      ),
                      IsrDimens.boxWidth(IsrDimens.eight),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            IsrTranslationFile.shop,
                            style: _textStyleConfig?.shopTitleStyle ??
                                IsrStyles.primaryText12.copyWith(
                                    color: IsrColors.color0F1E91, fontWeight: FontWeight.w700),
                          ),
                          IsrDimens.boxHeight(IsrDimens.four),
                          Text(
                            '${_reelData.productCount} ${_reelData.productCount == 1 ? IsrTranslationFile.product : IsrTranslationFile.products}',
                            style: _textStyleConfig?.shopSubtitleStyle ??
                                IsrStyles.primaryText10.copyWith(
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
                                if (_reelData.postSetting?.isProfilePicVisible == true) ...[
                                  TapHandler(
                                    borderRadius: IsrDimens.thirty,
                                    onTap: () async {
                                      if (widget.reelsConfig.onTapUserProfile == null) {
                                        return;
                                      }
                                      await widget.reelsConfig.onTapUserProfile!(_reelData);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(
                                          _userProfileConfig?.profileImageBorderRadius ??
                                              IsrDimens.thirty,
                                        ),
                                        border: _userProfileConfig?.profileImageBorder,
                                        boxShadow: _userProfileConfig?.profileImageShadow ??
                                            [
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
                                        width: _userProfileConfig?.profileImageSize ??
                                            IsrDimens.thirtyFive,
                                        height: _userProfileConfig?.profileImageSize ??
                                            IsrDimens.thirtyFive,
                                        isProfileImage: true,
                                        textColor:
                                            _userProfileConfig?.profileImagePlaceholderColor ??
                                                IsrColors.white,
                                        name:
                                            '${_reelData.firstName ?? ''} ${_reelData.lastName ?? ''}',
                                      ),
                                    ),
                                  ),
                                  IsrDimens.boxWidth(IsrDimens.eight),
                                ],
                                Flexible(
                                  child: TapHandler(
                                    onTap: () async {
                                      if (widget.reelsConfig.onTapUserProfile == null) {
                                        return;
                                      }
                                      await widget.reelsConfig.onTapUserProfile?.call(_reelData);
                                    },
                                    child: Text(
                                      _reelData.userName ?? '',
                                      style: _textStyleConfig?.userNameStyle ??
                                          IsrStyles.white14.copyWith(
                                            fontWeight: FontWeight.w600,
                                            shadows: _textShadows,
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
                                  final fullDescription = _reelData.description ?? '';

                                  // Safety check: If empty after trimming, hide widget
                                  if (fullDescription.trim().isEmpty) {
                                    return const SizedBox.shrink();
                                  }

                                  final descriptionLineCount = fullDescription.split('\n').length;
                                  final shouldTruncate =
                                      fullDescription.length > _maxLengthToShow ||
                                          descriptionLineCount > _maxLinesToShow;

                                  // Show truncated version when collapsed, full version when expanded
                                  // FIX: Prevent substring out of bounds error
                                  String displayText;
                                  if (shouldTruncate && !value) {
                                    final safeLength = fullDescription.length < _maxLengthToShow
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
                                  if (_lastParsedDescription != displayText.trim() ||
                                      _cachedDescriptionTextSpan == null) {
                                    _lastParsedDescription = displayText.trim();
                                    _cachedDescriptionTextSpan = _buildDescriptionTextSpan(
                                      displayText.trim(),
                                      _mentionedDataList,
                                      _taggedDataList,
                                      _textStyleConfig?.descriptionStyle ??
                                          IsrStyles.white14.copyWith(
                                            color: IsrColors.white.changeOpacity(0.9),
                                            shadows: _textShadows,
                                          ),
                                      (mention) => _callOnTapMentionData([mention]),
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
                                              text: value ? ' less' : ' ... more',
                                              style: value
                                                  ? (_descriptionConfig?.collapseTextStyle ??
                                                      IsrStyles.white14.copyWith(
                                                        fontWeight: FontWeight.w700,
                                                        color: IsrColors.white.changeOpacity(0.7),
                                                        shadows: _textShadows,
                                                      ))
                                                  : (_descriptionConfig?.expandTextStyle ??
                                                      IsrStyles.white14.copyWith(
                                                        fontWeight: FontWeight.w700,
                                                        color: IsrColors.white.changeOpacity(0.7),
                                                        shadows: _textShadows,
                                                      )),
                                              // Removed empty TapGestureRecognizer to prevent memory leak
                                              // Parent GestureDetector handles the tap
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                } catch (_) {
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
          style: _textStyleConfig?.commissionTagStyle ??
              IsrStyles.white10.copyWith(
                color: IsrColors.colorF4F4F4,
                decoration: TextDecoration.none,
              ),
        ),
      );

  Widget _buildFollowButton() => FollowActionWidget(
        postId: _reelData.postId ?? '',
        userId: _reelData.userId ?? '',
        builder: (isLoading, isFollowing, onTap) {
          // Update reel data state (non-blocking, for UI sync)
          _reelData.isFollow = isFollowing;

          // Show loading indicator during API call
          if (isLoading) {
            return Container(
              width: _followButtonConfig?.followButtonMinWidth ?? IsrDimens.sixty,
              height: _followButtonConfig?.followButtonHeight ?? IsrDimens.twentyFour,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(IsrDimens.twenty),
              ),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _followButtonConfig?.loadingIndicatorColor ?? IsrColors.white,
                    ),
                  ),
                ),
              ),
            );
          } else if (!isFollowing && _reelData.postSetting?.isUnFollowButtonVisible == true) {
            return Container(
              height: _followButtonConfig?.followButtonHeight ?? IsrDimens.twentyFour,
              decoration: _followButtonConfig?.followButtonDecoration ??
                  BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(IsrDimens.twenty),
                  ),
              child: MaterialButton(
                minWidth: _followButtonConfig?.followButtonMinWidth ?? IsrDimens.sixty,
                height: _followButtonConfig?.followButtonHeight ?? IsrDimens.twentyFour,
                padding: _followButtonConfig?.followButtonPadding ??
                    IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.twelve),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(IsrDimens.twenty)),
                onPressed: () => onTap(
                  reelData: _reelData,
                  postSectionType: widget.postSectionType,
                  watchDuration: _postWatchDuration.inSeconds,
                  apiCallBack: widget.onPressFollowButton != null
                      ? () => widget.onPressFollowButton!(_reelData, isFollowing)
                      : null,
                ),
                child: Text(
                  IsrTranslationFile.follow,
                  style: _textStyleConfig?.followButtonTextStyle ??
                      IsrStyles.white12.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            );
          } else if (isFollowing && _reelData.postSetting?.isFollowButtonVisible == true) {
            return Container(
              height: _followButtonConfig?.followButtonHeight ?? IsrDimens.twentyFour,
              decoration: _followButtonConfig?.followingButtonDecoration ??
                  BoxDecoration(
                    borderRadius: BorderRadius.circular(IsrDimens.twenty),
                    border: Border.all(color: Theme.of(context).primaryColor, width: IsrDimens.two),
                  ),
              child: MaterialButton(
                minWidth: _followButtonConfig?.followButtonMinWidth ?? IsrDimens.sixty,
                height: _followButtonConfig?.followButtonHeight ?? IsrDimens.twentyFour,
                padding: _followButtonConfig?.followButtonPadding ??
                    IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.twelve),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(IsrDimens.twenty),
                ),
                onPressed: () => onTap(reelData: _reelData),
                // <-- your unfollow logic
                child: Text(
                  IsrTranslationFile.following,
                  style: _textStyleConfig?.followingButtonTextStyle ??
                      IsrStyles.primaryText12.copyWith(
                        fontWeight: FontWeight.w600,
                        color: IsrColors.colorF4F4F4,
                      ),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      );

  Future<void> _triggerLikeAnimation() async {
    _likeAnimationTimer?.cancel();
    if (_reelData.isLiked != true) {
      _onLikeTap?.call(
        reelData: _reelData,
        watchDuration: _postWatchDuration.inSeconds,
        postSectionType: widget.postSectionType,
        apiCallBack: widget.onPressLikeButton != null
            ? () => widget.onPressLikeButton!(_reelData, _reelData.isLiked == true)
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
          final mentionStyle = _textStyleConfig?.mentionStyle ??
              defaultStyle.copyWith(
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.none,
              );
          spans.add(TextSpan(
            text: matchedText,
            style: mentionStyle,
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
          final hashtagStyle = _textStyleConfig?.hashtagStyle ??
              defaultStyle.copyWith(
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.none,
              );
          spans.add(TextSpan(
            text: matchedText,
            style: hashtagStyle,
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
    final isMediaPreloaded = _currentPageNotifier.value != index;
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
          videoProgressCallBack: (totalDuration, currentPosition) {
            _currentMediaWatchDuration = currentPosition;
            // Update progress (0.0 to 1.0) only if not seeking
            if (totalDuration.inMilliseconds > 0 && !_isSeeking) {
              _currentMediaProgress.value = currentPosition.inMilliseconds / totalDuration.inMilliseconds;
            }
            media.durationSeconds = totalDuration.inSeconds;
            _updatePostProgress();
          },
          isPreloaded: _isPreloaded || isMediaPreloaded,
            logIndex: '${widget.index}-$index}'
        ),
      );
    }
  }

  void _moveToNextMedia() {
    // Handle video completion for carousel
    if (_hasMultipleMedia && widget.reelsConfig.autoMoveNextMedia) {
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
    } else if (!_hasMultipleMedia ||
        _currentPageNotifier.value == _reelData.mediaMetaDataList.length - 1) {
      // Single video, notify parent to move to next post
      widget.onVideoCompleted?.call();
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

  void _resetPostProgress() {
    _postWatchDuration = Duration.zero;
    _postProgress.value = 0.0;
    _resetMediaProgress();
  }

  void _resetMediaProgress() {
    _imageViewTimer?.cancel();
    _currentMediaWatchDuration = Duration.zero;
    _currentMediaProgress.value = 0.0;
  }

  /// Updates post-level watch duration and progress (all media combined).
  /// Call whenever current media progress changes (video callback or image timer).
  void _updatePostProgress() {
    final currentPage = _currentPageNotifier.value;
    final totalSeconds = _postTotalDurationSeconds;
    if (totalSeconds <= 0) return;

    // Sum duration of all fully-watched media (previous pages)
    var completedSeconds = 0;
    for (var i = 0; i < currentPage && i < _reelData.mediaMetaDataList.length; i++) {
      completedSeconds += _reelData.mediaMetaDataList[i].durationSeconds;
    }

    _postWatchDuration = Duration(seconds: completedSeconds) + _currentMediaWatchDuration;
    final progress = _postWatchDuration.inSeconds / totalSeconds;
    _postProgress.value = progress.clamp(0.0, 1.0);
    // debugPrint('IsmReelsVideoPlayerView: Post Duration {PostId:- ${_reelData.postId}, Post Duration: ${_postWatchDuration.inSeconds}, TotalDuration: ${totalSeconds}, Progress: ${_postProgress.value}}');
    if (_finalWatchDurationSeconds < _postWatchDuration.inSeconds || _finalWatchProgress < _postProgress.value) {
      _finalWatchDurationSeconds = _postWatchDuration.inSeconds;
      _finalWatchProgress = _postProgress.value;
    }
  }

  /// Starts the image view timer if current media is an image
  void _startOrResumeImageProgress() {
    if (widget.currentIndex.value != widget.index) {
      // to check if the reel is preloaded or not
      return;
    }
    final shouldAutoMove =
        widget.reelsConfig.autoMoveNextMedia || widget.onVideoCompleted != null;
    final imageTotalDuration = Duration(
        seconds: _reelData
            .mediaMetaDataList[_currentPageNotifier.value].durationSeconds
            .clamp(AppConstants.minImagePostDurationSeconds,
                AppConstants.maxImagePostDurationSeconds));

    _imageViewTimer?.cancel();
    _isImagePaused = false;

    const tick = Duration(milliseconds: 50);

    _imageViewTimer = Timer.periodic(tick, (timer) {
      if (_isImagePaused) return;

      _currentMediaWatchDuration += tick;

      final progress = _currentMediaWatchDuration.inMilliseconds / imageTotalDuration.inMilliseconds;

      _currentMediaProgress.value = progress.clamp(0.0, 1.0);
      _updatePostProgress();

      if (_currentMediaWatchDuration >= imageTotalDuration) {
        timer.cancel();
        _currentMediaWatchDuration = Duration.zero;

        // Only auto-move to next if configured to do so
        if (shouldAutoMove) {
          _moveToNextMedia();
        } else {
          // Keep progress at 100% when complete but don't auto-move
          _currentMediaProgress.value = 1.0;
        }
      }
    });
  }

  void _pauseImageProgress() {
    _isImagePaused = true;
  }

  double _finalWatchProgress = 0.0;
  int _finalWatchDurationSeconds = 0;
  /// Logs view watch data when the user leaves (next/previous post or navigates away).
  /// Only sends once per view and if watch was meaningful (≥25% or ≥3s).
  void _logWatchPostEvent() {
    if (_finalWatchProgress >= 0.25 || _finalWatchDurationSeconds >= 3) {
      debugPrint('IsmReelsVideoPlayerView: log Post View {PostId: ${_reelData.postId}, Post Duration: $_finalWatchDurationSeconds, Progress: $_finalWatchProgress}, TotalDuration: $_postTotalDurationSeconds');
      sendAnalyticsEvent(EventType.postViewed.value, {
        'view_duration': _finalWatchDurationSeconds,
        'view_completion_rate': (_finalWatchProgress * 100).toInt()
      });
      _finalWatchDurationSeconds = 0;
      _finalWatchProgress = 0.0;
    }
  }

  /// Implementation of PostHelperCallBacks interface
  /// This method is called by VideoPlayerWidget to send analytics events
  @override
  void sendAnalyticsEvent(String eventName, Map<String, dynamic> analyticsData) async {
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
      EventQueueProvider.instance.addEvent(eventName, finalAnalyticsDataMap.removeEmptyValues());
    } catch (e) {
      debugPrint('❌ Error sending analytics event: $e');
      return null;
    }
  }
}
