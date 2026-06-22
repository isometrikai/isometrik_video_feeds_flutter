import 'dart:async';
import 'dart:convert';
import 'dart:ui' show ImageFilter;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/video_player_widget.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/comment_count_action_widget.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/instagram_follow_chip.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/like_action_widget.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/isr_image_sound_registry.dart';
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
    this.lifecycleResumeTick,
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
  final ValueNotifier<int> currentIndex;
  final ValueNotifier<int>? lifecycleResumeTick;
  final ReelsConfig reelsConfig;
  final PostSectionType postSectionType;

  @override
  State<IsmReelsVideoPlayerView> createState() =>
      _IsmReelsVideoPlayerViewState();
}

class _IsmReelsVideoPlayerViewState extends State<IsmReelsVideoPlayerView>
    with SingleTickerProviderStateMixin, RouteAware
    implements PostHelperCallBacks {
  // Use MediaCacheFactory instead of direct VideoCacheManager
  VideoCacheManager get _videoCacheManager =>
      widget.videoCacheManager ?? VideoCacheManager();
  PostConfig get _postConfig => widget.reelsConfig.postConfig;
  bool get _showFloatingComments =>
      IsrVideoReelConfig.commentConfig.showFloatingcomments;
  CommentUIConfig? get _commentUiConfig =>
      IsrVideoReelConfig.commentConfig.commentUIConfig;
  BelowCommentsConfig? get _belowCommentsConfig =>
      _commentUiConfig?.belowCommentsConfig;

  // Config helper getters
  PostUIConfig? get _uiConfig => _postConfig.postUIConfig;
  ActionIconConfig? get _actionIconConfig =>
      _uiConfig?.reelsActionIconConfig ?? _uiConfig?.actionIconConfig;
  bool get _isGlassReelsActionIcons =>
      _actionIconConfig?.containerStyle == ActionIconContainerStyle.glass;

  /// Uniform dim above media so glass chrome and white captions stay readable
  /// on bright and dark backgrounds.
  static const double _reelsMediaScrimOpacity = 0.25;
  TextStyleConfig? get _textStyleConfig => _uiConfig?.textStyleConfig;
  ShopUIConfig? get _shopUIConfig => _uiConfig?.shopUIConfig;
  PostLinkUIConfig? get _postLinkUIConfig => _uiConfig?.postLinkUIConfig;
  FollowButtonConfig? get _followButtonConfig => _uiConfig?.followButtonConfig;
  bool get _shouldShowPostLinkChip =>
      IsrVideoReelConfig.createEditPostConfig.enableBusinessLink &&
      _reelData.postLink?.isValid == true;
  MediaIndicatorConfig? get _mediaIndicatorConfig =>
      _uiConfig?.mediaIndicatorConfig;
  UserProfileConfig? get _userProfileConfig => _uiConfig?.userProfileConfig;
  DescriptionConfig? get _descriptionConfig => _uiConfig?.descriptionConfig;
  LocationConfig? get _locationConfig => _uiConfig?.locationConfig;
  MentionConfig? get _mentionConfig => _uiConfig?.mentionConfig;

  double _overlayBottomInset(BuildContext context) =>
      IsrDimens.resolveOverlayBottomInset(
        context,
        widget.reelsConfig.overlayPadding,
      );

  static const double _scrubTouchZoneHeight = 52;
  static const double _scrubBarExpandedHeight = 10;
  static const double _scrubThumbSize = 16;
  static const double _glassScrubIdleBarHeight = 4;
  static const double _glassScrubThumbSize = 14;
  /// Dedicated touch strip for glass seek — shorter than [_scrubTouchZoneHeight]
  /// so overlay content can sit closer without overlapping tappable rows.
  static const double _glassScrubTouchZoneHeight = 20;
  static const double _glassScrubContentGap = 4;
  static const Color _glassScrubTrackColor = Color(0x59FFFFFF);
  static const Duration _scrubExpandDuration = Duration(milliseconds: 180);

  Color get _indicatorCompletedColor =>
      _mediaIndicatorConfig?.completedColor ??
      (_isGlassReelsActionIcons
          ? IsrColors.white
          : IsrColors.appColor.applyOpacity(0.7));

  Color get _indicatorPendingColor =>
      _mediaIndicatorConfig?.pendingColor ??
      (_isGlassReelsActionIcons
          ? _glassScrubTrackColor
          : const Color(0x80FFFFFF));

  Color get _indicatorProgressColor =>
      _mediaIndicatorConfig?.progressColor ??
      (_isGlassReelsActionIcons
          ? IsrColors.white
          : IsrColors.appColor.applyOpacity(0.7));

  bool get _shouldShowMediaIndicators =>
      !_shouldShowPaidLockOverlay &&
      (_isTextOnlyPost ||
          _reelData.mediaMetaDataList.isNotEmpty ||
          _reelData.mediaMetaDataList.firstOrNull?.mediaType == kVideoType ||
          widget.onVideoCompleted != null);

  double _glassScrubLayerHeight(double idleBarHeight) {
    final seekStripHeight = _glassScrubTouchZoneHeight > _glassScrubThumbSize
        ? _glassScrubTouchZoneHeight
        : _glassScrubThumbSize;
    return seekStripHeight;
  }

  double _mediaIndicatorClearance({required bool expanded}) {
    if (!_shouldShowMediaIndicators) return 0;
    final isGlass = _isGlassReelsActionIcons;
    final idleBarHeight = isGlass
        ? _glassScrubIdleBarHeight
        : (_mediaIndicatorConfig?.indicatorHeight ?? IsrDimens.six)
            .clamp(4.0, 8.0);
    if (_hasMultipleMedia) {
      return idleBarHeight + IsrDimens.ten;
    }
    if (isGlass) {
      return _glassScrubLayerHeight(idleBarHeight) + _glassScrubContentGap;
    }
    final barAreaHeight = expanded ? _scrubThumbSize : idleBarHeight;
    return barAreaHeight + IsrDimens.ten;
  }

  double _contentBottomInset(
    BuildContext context, {
    required bool scrubExpanded,
  }) =>
      _overlayBottomInset(context) +
      _mediaIndicatorClearance(expanded: scrubExpanded);

  bool _isVideoAtPage(int page) {
    if (_isTextOnlyPost) return false;
    if (page < 0 || page >= _reelData.mediaMetaDataList.length) return false;
    return _reelData.mediaMetaDataList[page].mediaType == kVideoType;
  }

  // Add constants for media types
  static const int kPictureType = 0;
  static const int kVideoType = 1;

  // Carousel related variables
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(0);
  PreloadPageController? _pageController;

  TapGestureRecognizer? _tapGestureRecognizer;

  // GlobalKeys to control video players for tap play/pause.
  final GlobalKey _currentVideoPlayerKey = GlobalKey();
  final Map<int, GlobalKey> _videoPlayerKeys = {};
  final ValueNotifier<int> _videoOverlayTick = ValueNotifier(0);

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
  bool _isLikeActionLoading = false;

  Timer? _audioDebounceTimer;

  // Description config values with fallbacks
  int get _maxLengthToShow => _descriptionConfig?.maxLengthToShow ?? 50;
  int get _maxLinesToShow => _descriptionConfig?.maxLinesToShow ?? 2;

  /// Subtle shadow for white overlay text — readable on light and dark media.
  List<Shadow> get _textShadows =>
      _descriptionConfig?.textShadows ??
      const [
        Shadow(
          color: Color(0x99000000),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
      ];

  /// Centered halo — action labels sit directly under icons, so avoid a
  /// downward offset that reads as a disconnected smudge below the bubble.
  List<Shadow> get _reelsActionLabelShadows => const [
        Shadow(
          color: Color(0x99000000),
          blurRadius: 2,
          offset: Offset.zero,
        ),
      ];

  TextStyle get _reelsActionLabelStyle {
    final configured = _textStyleConfig?.actionLabelStyle;
    final fallback = IsrStyles.white12;
    return TextStyle(
      inherit: false,
      fontSize: configured?.fontSize ?? fallback.fontSize,
      fontWeight: configured?.fontWeight ?? FontWeight.w500,
      fontFamily: configured?.fontFamily ?? fallback.fontFamily,
      letterSpacing: configured?.letterSpacing,
      height: configured?.height,
      shadows: configured?.shadows ?? _reelsActionLabelShadows,
      decoration: TextDecoration.none,
      decorationColor: Colors.transparent,
    );
  }

  Widget _reelsOverlayLabel(
    String text, {
    VoidCallback? onTap,
    Key? labelKey,
    bool singleLine = false,
  }) {
    final style = _reelsActionLabelStyle;
    final label = ReelsOverlayText(
      text,
      key: labelKey,
      fontSize: style.fontSize,
      fontWeight: style.fontWeight,
      fontFamily: style.fontFamily,
      letterSpacing: style.letterSpacing,
      height: style.height,
      shadows: style.shadows,
      maxLines: singleLine ? 1 : null,
      overflow: singleLine ? TextOverflow.visible : null,
    );
    if (onTap == null) return label;
    return GestureDetector(onTap: onTap, child: label);
  }

  /// Overlay text that stays white and ignores theme [DefaultTextStyle] merge.
  TextStyle _overlayTextStyle(
    TextStyle fallback, {
    TextStyle? custom,
    FontWeight? fontWeight,
    Color? color,
    bool includeShadow = true,
  }) {
    final style = custom ?? fallback;
    return TextStyle(
      inherit: false,
      color: color ?? style.color ?? fallback.color ?? IsrColors.white,
      fontSize: style.fontSize ?? fallback.fontSize,
      fontWeight: fontWeight ?? style.fontWeight ?? fallback.fontWeight,
      fontFamily: style.fontFamily ?? fallback.fontFamily,
      letterSpacing: style.letterSpacing ?? fallback.letterSpacing,
      height: style.height ?? fallback.height,
      decoration: TextDecoration.none,
      shadows: includeShadow ? (style.shadows ?? _textShadows) : null,
    );
  }

  /// Glassy reels: white caption URLs. Default/plain: SDK theme link color.
  TextStyle? _buildReelsUrlStyle() {
    if (!_isGlassReelsActionIcons) return null;

    final linkColor = ReelsOverlayText.foreground.withValues(alpha: 0.9);
    return _overlayTextStyle(
      IsrStyles.white14,
      color: linkColor,
    ).copyWith(
      decoration: TextDecoration.underline,
      decorationColor: linkColor,
      fontWeight: FontWeight.w400,
    );
  }

  bool get _hasMentionOrLocation =>
      _reelData.mentions.isListEmptyOrNull == false ||
      _reelData.placeDataList?.isListEmptyOrNull == false;

  static const double _glassChipIconSize = 16;

  Widget _buildMentionAndLocationRow() {
    if (!_hasMentionOrLocation) return const SizedBox.shrink();

    final hasMentions = _reelData.mentions.isListEmptyOrNull == false;
    final hasPlaces = _reelData.placeDataList?.isListEmptyOrNull == false;

    if (_isGlassReelsActionIcons) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (hasMentions) _buildMentionedUsersSection(),
          if (hasMentions && hasPlaces) IsrDimens.boxWidth(IsrDimens.ten),
          if (hasPlaces)
            Flexible(
              fit: FlexFit.loose,
              child: _buildLocationSection(),
            ),
        ],
      );
    }

    return Row(
      children: [
        if (hasMentions) ...[
          Expanded(child: _buildMentionedUsersSection()),
          if (hasPlaces) IsrDimens.boxWidth(IsrDimens.ten),
        ],
        if (hasPlaces) Expanded(child: _buildLocationSection()),
      ],
    );
  }

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
  List<CommentDataItem> _floatingComments = [];
  int _floatingCommentsTotal = 0;
  bool _hasFetchedFloatingComments = false;

  bool _showLikeAnimation = false;
  Timer? _likeAnimationTimer;

  // Image view tracking
  Timer? _imageViewTimer;
  bool _isImagePaused = false;
  bool _isPlaybackBlocked = false;

  // Audio playback for image posts that carry a sound (Instagram-style).
  AudioPlayer? _imageSoundPlayer;
  String? _imageSoundLoadedUrl;
  String? _resolvedImageSoundUrl;
  bool _resolvingImageSoundUrl = false;

  bool get _isPreloaded => widget.index != widget.currentIndex.value;

  // current media progress tracking
  Duration _currentMediaWatchDuration = Duration.zero;
  final ValueNotifier<double> _currentMediaProgress =
      ValueNotifier<double>(0.0);
  final ValueNotifier<bool> _isSeekBarExpanded = ValueNotifier<bool>(false);
  bool _isSeeking = false; // Flag to prevent progress updates during seeking

  // post Progress Tracking
  int get _postTotalDurationSeconds {
    if (_isTextOnlyPost) {
      return AppConstants.defaultImagePostDurationSeconds;
    }
    if (_reelData.mediaMetaDataList.isEmpty) return 0;
    return _reelData.mediaMetaDataList
        .map((e) => e.durationSeconds)
        .reduce((a, b) => a + b);
  }

  Duration _postWatchDuration = Duration.zero;
  final ValueNotifier<double> _postProgress = ValueNotifier<double>(0.0);
  bool _wasVisiblePost = false;
  void _onGlobalMuteChanged() {
    if (!mounted) return;
    setState(() {});
  }

  bool get _isCurrentReel => widget.currentIndex.value == widget.index;

  void _onLifecycleResumeTick() {
    if (!_isCurrentReel) {
      unawaited(_stopImageSound());
      return;
    }
    if (!widget.reelsConfig.isTabVisible() ||
        !IsrVideoReelConfig.allowsPlayback) {
      return;
    }
    _isPlaybackBlocked = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isCurrentReel) return;
      _resumePlayback();
    });
  }

  void _onCurrentIndexChanged() {
    final isVisible = widget.currentIndex.value == widget.index;
    if (_wasVisiblePost && !isVisible) {
      _logWatchPostEvent();
      _pauseImageProgress();
      unawaited(_stopImageSound());
      final key = _getCurrentVideoPlayerKey();
      VideoPlayerWidget.of(key)?.pause();
    } else if (!_wasVisiblePost && isVisible) {
      if (!_hasFetchedFloatingComments) {
        _fetchFloatingCommentsIfNeeded();
      }
      if (!_isPlaybackBlocked &&
          widget.reelsConfig.isTabVisible() &&
          IsrVideoReelConfig.allowsPlayback) {
        _resumePlayback();
        if (_isCurrentMediaImage) {
          unawaited(_startImageSoundIfNeeded());
        }
      }
    }
    debugPrint(
        'IsmReelsVideoPlayerView: _onCurrentIndexChanged {Post index: ${widget.index}, currentIndex: ${widget.currentIndex.value}}');
    _wasVisiblePost = isVisible;
  }

  @override
  void initState() {
    _onStartInit();
    _wasVisiblePost = widget.currentIndex.value == widget.index;
    widget.currentIndex.addListener(_onCurrentIndexChanged);
    widget.lifecycleResumeTick?.addListener(_onLifecycleResumeTick);
    VideoMuteController.notifier.addListener(_onGlobalMuteChanged);
    debugPrint(
        'IsmReelsVideoPlayerView: initState index: ${widget.index}, visibleIndex: ${widget.currentIndex.value}, tabType: ${widget.postSectionType}');
    super.initState();
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
  void didUpdateWidget(IsmReelsVideoPlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.reelsData;
    if (next == null) return;
    if (identical(oldWidget.reelsData, next)) return;
    if (oldWidget.reelsData?.postId != next.postId) return;
    _applySoftReelDataUpdate(next);
  }

  /// Merge engagement/caption/follow changes without restarting video or
  /// clearing floating comments (host-cache silent detail refresh).
  void _applySoftReelDataUpdate(ReelsData data) {
    _reelData = data;
    _postDescription = data.description ?? '';
    _mentionedDataList = data.mentions;
    _taggedDataList = data.tagDataList ?? [];
    _mentionedMetaDataList = data.mentions
        .where((mentionData) => mentionData.mediaPosition != null)
        .toList();
    _pageMentionMetaDataList = _mentionedMetaDataList
        .where(
          (mention) =>
              mention.mediaPosition?.position == _currentPageNotifier.value + 1,
        )
        .toList();
    if (mounted) setState(() {});
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

  bool get _isViewerPostAuthor {
    final uid = widget.loggedInUserId;
    if (uid.isStringEmptyOrNull == true) return false;
    return uid == _reelData.userId;
  }

  /// Locked paid post for feeds: blur + lock overlay for viewers who do not own the post.
  bool get _shouldShowPaidLockOverlay {
    if (_isViewerPostAuthor) return false;
    if (_reelData.isLocked != true) return false;
    final reason = (_reelData.lockReason ?? '').toLowerCase();
    final isPaidLocked = reason == 'paid' || (_reelData.isPaid == true);
    return isPaidLocked;
  }

  TimeLineData? get _timelinePost => _reelData.postData is TimeLineData
      ? _reelData.postData as TimeLineData
      : null;

  bool get _isTextOnlyPost => _timelinePost?.isTextOnlyPost == true;

  /// Text-only posts and image slides advance on a timer (not video playback).
  bool get _usesTimedAdvance => _isTextOnlyPost || _isCurrentMediaImage;

  int get _currentTimedAdvanceDurationSeconds {
    if (_isTextOnlyPost) {
      return AppConstants.defaultImagePostDurationSeconds;
    }
    return _reelData
        .mediaMetaDataList[_currentPageNotifier.value].durationSeconds
        .clamp(AppConstants.minImagePostDurationSeconds,
            AppConstants.maxImagePostDurationSeconds);
  }

  static bool _looksLikeStreamingOrVideoUrl(String url) {
    final u = url.trim().toLowerCase();
    if (u.isEmpty) return false;
    return u.endsWith('.mp4') ||
        u.endsWith('.mov') ||
        u.endsWith('.m3u8') ||
        u.endsWith('.webm') ||
        u.endsWith('.m4v') ||
        u.contains('.m3u8');
  }

  /// Paid-locked posts show a blurred still frame only — never decode the video URL in an image widget.
  String? _paidLockStillImageUrl() {
    String? usableStill(String? candidate) {
      final s = candidate?.trim() ?? '';
      if (s.isEmpty || _looksLikeStreamingOrVideoUrl(s)) return null;
      return s;
    }

    Iterable<PreviewMedia> sortedPreviews() sync* {
      final previews = _timelinePost?.previews;
      if (previews.isListEmptyOrNull == true) return;
      final list = List<PreviewMedia>.from(previews!)
        ..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));
      for (final p in list) {
        yield p;
      }
    }

    if (_reelData.mediaMetaDataList.isNotEmpty) {
      final meta = _reelData.mediaMetaDataList[_currentPageNotifier.value];
      if (meta.mediaType == kVideoType) {
        final thumb = usableStill(meta.thumbnailUrl);
        if (thumb != null) return thumb;
        for (final p in sortedPreviews()) {
          final hit = usableStill(p.url);
          if (hit != null) return hit;
        }
        return null;
      }
      final fromMedia = usableStill(meta.mediaUrl);
      if (fromMedia != null) return fromMedia;
      final fromThumb = usableStill(meta.thumbnailUrl);
      if (fromThumb != null) return fromThumb;
    }

    for (final p in sortedPreviews()) {
      final hit = usableStill(p.url);
      if (hit != null) return hit;
    }
    return null;
  }

  String _paidUnlockPriceLabel() {
    final raw = _reelData.priceAmount;
    if (raw == null) return '';
    final amount = raw is num ? raw.toString() : raw.toString().trim();
    if (amount.isEmpty) return '';
    final c = (_reelData.priceCurrency ?? '').trim().toLowerCase();
    if (c.isEmpty || c == '-') return amount;
    if (c == 'coin' || c == 'coins') return amount;
    if (c == 'usd') return '\$$amount';
    return '$amount $c'.trim();
  }

  bool get _isCoinCurrency {
    final c = (_reelData.priceCurrency ?? '').trim().toLowerCase();
    return c == 'coin' || c == 'coins';
  }

  Future<void> _onPaidUnlockPressed() async {
    final cb = _postConfig.postCallBackConfig?.onPaidPostUnlock;
    final post = _timelinePost;
    if (cb != null && post != null) {
      if (mounted) {
        context.read<SocialPostBloc>().add(
              PlayPauseVideoEvent(
                play: false,
                scopedPostSection: widget.postSectionType,
              ),
            );
      }
      try {
        await cb(post);
      } finally {
        if (mounted) {
          context.read<SocialPostBloc>().add(
                PlayPauseVideoEvent(
                  play: true,
                  scopedPostSection: widget.postSectionType,
                ),
              );
        }
      }
      return;
    }
    Utility.showAppDialog(
      message: _paidUnlockPriceLabel().isEmpty
          ? IsrTranslationFile.paidPostLockedSubtitle
          : '${IsrTranslationFile.unlockFor} ${_paidUnlockPriceLabel()}',
    );
  }

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

    // Initialize PageController for carousel
    _pageController = PreloadPageController(initialPage: 0);

    if (!_shouldShowPaidLockOverlay) {
      // Preload next videos for smoother experience
      _preloadNextVideos();

      //resent image progress
      _resetPostProgress();

      // Start timed advance for text-only posts or image slides.
      if (_isTextOnlyPost) {
        _startOrResumeImageProgress();
      } else {
        final mediaList = _reelData.mediaMetaDataList;
        final page = _currentPageNotifier.value;
        if (mediaList.isNotEmpty &&
            page < mediaList.length &&
            mediaList[page].mediaType == kPictureType) {
          _startOrResumeImageProgress();
        }
      }
    }

    unawaited(_fetchFloatingCommentsIfNeeded());
  }

  Future<void> _fetchFloatingCommentsIfNeeded(
      {bool forceRefresh = false}) async {
    if (!_showFloatingComments || !mounted) return;
    if (!forceRefresh && _hasFetchedFloatingComments) return;
    if (widget.currentIndex.value != widget.index) return;
    if ((_reelData.postSetting?.isCommentButtonVisible ?? false) == false) {
      return;
    }
    final postId = _reelData.postId;
    if (postId.isStringEmptyOrNull) return;

    _hasFetchedFloatingComments = true;
    context.read<SocialPostBloc>().add(
          GetPostCommentsEvent(
            postId: postId!,
            isLoading: false,
            refreshPostDetailAfterComments:
                IsrVideoReelConfig.feedCacheConfig != null,
            onComplete: (comments, {total = 0}) {
              if (!mounted) return;
              final sortedComments = comments.toList()
                ..sort(
                  (a, b) => (b.commentedOn?.millisecondsSinceEpoch ?? 0)
                      .compareTo(a.commentedOn?.millisecondsSinceEpoch ?? 0),
                );
              setState(() {
                final maxVisibleComments =
                    _belowCommentsConfig?.maxVisibleComments ?? 2;
                _floatingComments =
                    sortedComments.take(maxVisibleComments).toList();
                _floatingCommentsTotal = total > 0
                    ? total
                    : (_reelData.commentCount ?? sortedComments.length);
                if (_floatingCommentsTotal > 0) {
                  _reelData.commentCount = _floatingCommentsTotal;
                }
              });
            },
          ),
        );
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
      final currentPage =
          _pageController!.page?.round() ?? _currentPageNotifier.value;
      if (currentPage != index) {
        // PageController is out of sync, jump to correct page
        _pageController!.jumpToPage(index);
      }
    }

    if (_currentPageNotifier.value == index) return;

    _isSeekBarExpanded.value = false;
    if (_isSeeking) {
      IsrVideoReelConfig.unlockReelsFeedScroll();
      _isSeeking = false;
    }

    // Hide mentions when changing pages
    if (_mentionsVisible) {
      _mentionsVisible = false;
    }

    // Update current page notifier
    _currentPageNotifier.value = index;

    _pageMentionMetaDataList = _mentionedMetaDataList
        .where((mention) =>
            mention.mediaPosition?.position == _currentPageNotifier.value + 1)
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
    widget.lifecycleResumeTick?.removeListener(_onLifecycleResumeTick);
    VideoMuteController.notifier.removeListener(_onGlobalMuteChanged);
    IsrImageSoundRegistry.releaseOwner(this);
    _tapGestureRecognizer?.dispose();
    _pageController?.dispose();
    _likeAnimationTimer?.cancel();
    _audioDebounceTimer?.cancel();
    _imageViewTimer?.cancel();
    unawaited(_disposeImageSound());
    _currentMediaProgress.dispose();
    _isSeekBarExpanded.dispose();
    if (_isSeeking) {
      IsrVideoReelConfig.unlockReelsFeedScroll();
      _isSeeking = false;
    }
    _postProgress.dispose();
    _videoOverlayTick.dispose();
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

  double imageVisibilityFraction = 0;

  Widget _buildImageWithBlurredBackground({
    required String imageUrl,
  }) =>
      VisibilityDetector(
        key: ValueKey('image_${imageUrl.hashCode}'),
        onVisibilityChanged: (visibilityInfo) {
          imageVisibilityFraction = visibilityInfo.visibleFraction;

          if (imageVisibilityFraction == 1.0 &&
              IsrVideoReelConfig.allowsPlayback) {
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

            if (state is PlayPauseVideoState && _handlesPlayPauseState(state)) {
              _setPlaybackBlocked(
                state.play,
                pausePlayback: state.pausePlayback,
              );
              if (!state.pausePlayback) return;
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

  Widget _buildPaidLockedLayer() {
    const blurSigma = 28.0;
    // final primary = Theme.of(context).colorScheme.primary;

    Widget chrome({Widget? blurredChild}) => Stack(
          fit: StackFit.expand,
          children: [
            if (blurredChild != null)
              ImageFiltered(
                imageFilter:
                    ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: blurredChild,
              )
            else
              ColoredBox(color: Colors.grey.shade900),
            Container(color: Colors.black.withValues(alpha: 0.42)),
            Center(
              child: Padding(
                padding: IsrDimens.edgeInsetsSymmetric(
                    horizontal: IsrDimens.twentyEight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: IsrDimens.edgeInsetsAll(IsrDimens.eighteen),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: IsrDimens.forty,
                      ),
                    ),
                    IsrDimens.boxHeight(IsrDimens.sixteen),
                    Text(
                      IsrTranslationFile.paidPostLockedTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: IsrDimens.eighteen,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                        shadows: _textShadows,
                      ),
                    ),
                    IsrDimens.boxHeight(IsrDimens.eight),
                    Text(
                      IsrTranslationFile.paidPostLockedSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: IsrDimens.fourteen,
                        height: 1.35,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    IsrDimens.boxHeight(IsrDimens.twentyTwo),
                    OutlinedButton(
                      onPressed: _onPaidUnlockPressed,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        padding: IsrDimens.edgeInsetsSymmetric(
                          horizontal: IsrDimens.twentyTwo,
                          vertical: IsrDimens.twelve,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(IsrDimens.twentyFive),
                        ),
                      ),
                      child: _paidUnlockPriceLabel().isEmpty
                          ? Text(
                              IsrTranslationFile.unlockFor,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: IsrDimens.fifteen,
                                decoration: TextDecoration.none,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  IsrTranslationFile.unlockFor,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: IsrDimens.fifteen,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                IsrDimens.boxWidth(IsrDimens.six),
                                if (_isCoinCurrency) ...[
                                  const Icon(
                                    Icons.monetization_on_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  IsrDimens.boxWidth(IsrDimens.four),
                                ],
                                Text(
                                  _paidUnlockPriceLabel(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: IsrDimens.fifteen,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

    final imageUrl = _paidLockStillImageUrl();
    if (imageUrl == null || imageUrl.isStringEmptyOrNull == true) {
      return chrome(blurredChild: null);
    }

    final blurredBackground = SizedBox.expand(
      child: Container(
        color: Colors.black,
        child: Center(
          child: _getImageWidget(
            imageUrl: imageUrl,
            width: IsrDimens.getScreenWidth(context),
            height: IsrDimens.getScreenHeight(context),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.low,
          ),
        ),
      ),
    );
    return chrome(blurredChild: blurredBackground);
  }

  Widget _buildMediaContent() {
    if (_shouldShowPaidLockOverlay) {
      return _buildPaidLockedLayer();
    }

    Widget mediaWidget;

    if (_isTextOnlyPost) {
      mediaWidget = SizedBox.expand(
        child: FeedTextPostContent(
          formatting: _timelinePost!.textPostFormatting,
        ),
      );
    } else if (_reelData.showBlur == true) {
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

    // Media only — tap play/pause is handled by the outer [GestureDetector].
    return mediaWidget;
  }

  Widget _buildMediaCarousel() => Stack(
        fit: StackFit.expand,
        children: [
          PreloadPageView.builder(
            preloadPagesCount: 1,
            controller: _pageController,
            // padEnds: false,
            // key: const PageStorageKey('media_pageview'),
            // Add a key
            onPageChanged: _onPageChanged,
            itemCount: _reelData.mediaMetaDataList.length,
            itemBuilder: (context, index) => _buildPageView(index),
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
      return _buildVideoContent(
        media: _reelData.mediaMetaDataList[_currentPageNotifier.value],
        key: _currentVideoPlayerKey,
        logIndex: '${widget.index}-0}',
        isPreloaded: _isPreloaded,
      );
    }
  }

  Widget _buildVideoContent(
          {required MediaMetaData media,
          Key? key,
          String? logIndex,
          bool isPreloaded = false}) =>
      VideoPlayerWidget(
        key: key,
        mediaUrl: media.mediaUrl,
        thumbnailUrl: media.thumbnailUrl,
        videoCacheManager: _videoCacheManager,
        isMuted: VideoMuteController.isMuted,
        onVisibilityChanged: (isVisible) {
          // Visibility is handled internally by VideoPlayerWidget
        },
        onVideoCompleted: _moveToNextMedia,
        videoProgressCallBack: (totalDuration, currentPosition) {
          _currentMediaWatchDuration = currentPosition;
          // Update progress (0.0 to 1.0) only if not seeking
          if (totalDuration.inMilliseconds > 0 && !_isSeeking) {
            _currentMediaProgress.value =
                currentPosition.inMilliseconds / totalDuration.inMilliseconds;
          }
          media.durationSeconds = totalDuration.inSeconds;
          _updatePostProgress();
        },
        isPreloaded: isPreloaded,
        logIndex: logIndex,
        isParentVisible: widget.reelsConfig.isTabVisible,
        postSectionType: widget.postSectionType,
        onPlaybackStateChanged: () {
          if (mounted) _videoOverlayTick.value++;
        },
      );

  Widget _buildMediaIndicators(int currentPage) {
    final primaryColor = Theme.of(context).primaryColor;
    final mediaCount = _isTextOnlyPost ? 1 : _reelData.mediaMetaDataList.length;
    if (mediaCount == 0) return const SizedBox.shrink();

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
                left: index == 0
                    ? 0
                    : (_mediaIndicatorConfig?.indicatorSpacing ??
                        IsrDimens.two),
                right: index == mediaCount - 1
                    ? 0
                    : (_mediaIndicatorConfig?.indicatorSpacing ??
                        IsrDimens.two),
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
    final isVideo = !_isTextOnlyPost &&
        _reelData.mediaMetaDataList[index].mediaType == kVideoType;
    final borderRadius = _mediaIndicatorConfig?.indicatorBorderRadius ??
        BorderRadius.circular(IsrDimens.two);
    final indicatorHeight =
        _mediaIndicatorConfig?.indicatorHeight ?? IsrDimens.six;

    // For completed media segments - show solid fill (fully progressed)
    if (isCompletedMedia) {
      return Container(
        height: indicatorHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _indicatorCompletedColor,
          borderRadius: borderRadius,
        ),
      );
    }

    // For upcoming media segments - show semi-transparent (pending)
    if (!isCurrentMedia) {
      return Container(
        height: indicatorHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _indicatorPendingColor,
          borderRadius: borderRadius,
        ),
      );
    }

    // For current media - show in-segment progress (carousel) or defer to
    // the full-width seekbar overlay for a single video post.
    if (isVideo && !_hasMultipleMedia) {
      return SizedBox(height: indicatorHeight);
    }
    return _buildImageProgressIndicator(primaryColor, borderRadius);
  }

  Widget _buildMediaProgressLayer(int currentPage) {
    if (_hasMultipleMedia) {
      return _buildMediaIndicators(currentPage);
    }
    if (_isVideoAtPage(currentPage)) {
      return _buildVideoScrubOverlay(currentPage);
    }
    return _buildMediaIndicators(currentPage);
  }

  Widget _buildVideoScrubOverlay(int currentPage) {
    final isGlass = _isGlassReelsActionIcons;
    final pendingColor = _mediaIndicatorConfig?.pendingColor ??
        (isGlass ? _glassScrubTrackColor : const Color(0x80FFFFFF));
    final progressColor = _mediaIndicatorConfig?.progressColor ??
        (isGlass ? IsrColors.white : IsrColors.appColor.applyOpacity(0.9));
    final idleBarHeight = isGlass
        ? _glassScrubIdleBarHeight
        : (_mediaIndicatorConfig?.indicatorHeight ?? IsrDimens.six)
            .clamp(4.0, 8.0);
    final borderRadius = _mediaIndicatorConfig?.indicatorBorderRadius ??
        BorderRadius.circular(IsrDimens.two);

    if (isGlass) {
      return ValueListenableBuilder<double>(
        valueListenable: _currentMediaProgress,
        builder: (context, progress, __) =>
            _buildGlassVideoScrubTrack(
          currentPage: currentPage,
          progress: progress.clamp(0.0, 1.0),
          pendingColor: pendingColor,
          progressColor: progressColor,
          borderRadius: borderRadius,
          barHeight: _glassScrubIdleBarHeight,
          thumbSize: _glassScrubThumbSize,
        ),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: _isSeekBarExpanded,
      builder: (context, expanded, _) => ValueListenableBuilder<double>(
        valueListenable: _currentMediaProgress,
        builder: (context, progress, __) {
          final barHeight =
              expanded ? _scrubBarExpandedHeight : idleBarHeight;
          final clampedProgress = progress.clamp(0.0, 1.0);

          return _buildScrubTrackListener(
            currentPage: currentPage,
            barHeight: barHeight,
            idleBarHeight: idleBarHeight,
            clampedProgress: clampedProgress,
            pendingColor: pendingColor,
            progressColor: progressColor,
            borderRadius: borderRadius,
            expanded: expanded,
            showThumb: expanded,
            thumbSize: _scrubThumbSize,
            expandOnSeekStart: true,
            isGlass: false,
          );
        },
      ),
    );
  }

  Widget _buildGlassVideoScrubTrack({
    required int currentPage,
    required double progress,
    required Color pendingColor,
    required Color progressColor,
    required BorderRadius borderRadius,
    required double barHeight,
    required double thumbSize,
  }) =>
      _buildScrubTrackListener(
        currentPage: currentPage,
        barHeight: barHeight,
        idleBarHeight: barHeight,
        clampedProgress: progress,
        pendingColor: pendingColor,
        progressColor: progressColor,
        borderRadius: borderRadius,
        expanded: false,
        showThumb: true,
        thumbSize: thumbSize,
        expandOnSeekStart: false,
        isGlass: true,
      );

  Widget _buildScrubTrackListener({
    required int currentPage,
    required double barHeight,
    required double idleBarHeight,
    required double clampedProgress,
    required Color pendingColor,
    required Color progressColor,
    required BorderRadius borderRadius,
    required bool expanded,
    required bool showThumb,
    required double thumbSize,
    required bool expandOnSeekStart,
    required bool isGlass,
  }) =>
      Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          _onSeekStart(expand: expandOnSeekStart);
          _updateSeekFromGlobalPosition(context, event.position);
        },
        onPointerMove: (event) {
          if (!_isSeeking) return;
          _updateSeekFromGlobalPosition(context, event.position);
        },
        onPointerUp: (_) {
          if (_isSeeking) _onSeekEnd();
        },
        onPointerCancel: (_) {
          if (_isSeeking) _cancelSeekInteraction();
        },
        child: SizedBox(
          height: isGlass
              ? _glassScrubLayerHeight(idleBarHeight)
              : _scrubTouchZoneHeight,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: IsrDimens.eight),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final trackWidth = constraints.maxWidth;
                    final thumbLeft =
                        (trackWidth * clampedProgress) - (thumbSize / 2);
                    final stackHeight =
                        isGlass ? thumbSize : (expanded ? thumbSize : idleBarHeight);
                    final trackRadius =
                        expanded ? BorderRadius.circular(5) : borderRadius;
                    final track = Container(
                      height: barHeight,
                      width: trackWidth,
                      decoration: BoxDecoration(
                        color: pendingColor,
                        borderRadius: trackRadius,
                      ),
                      child: ClipRRect(
                        borderRadius: trackRadius,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: clampedProgress,
                            heightFactor: 1,
                            child: ColoredBox(color: progressColor),
                          ),
                        ),
                      ),
                    );
                    final thumb = showThumb
                        ? Positioned(
                            left: thumbLeft.clamp(
                              0.0,
                              trackWidth - thumbSize,
                            ),
                            child: Container(
                              width: thumbSize,
                              height: thumbSize,
                              decoration: BoxDecoration(
                                color: progressColor,
                                shape: BoxShape.circle,
                                border: isGlass
                                    ? null
                                    : Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x66000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : null;

                    return SizedBox(
                      height: stackHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.centerLeft,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: isGlass
                                ? track
                                : AnimatedContainer(
                                    duration: _scrubExpandDuration,
                                    curve: Curves.easeOutCubic,
                                    height: barHeight,
                                    width: trackWidth,
                                    decoration: BoxDecoration(
                                      color: pendingColor,
                                      borderRadius: trackRadius,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: trackRadius,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: FractionallySizedBox(
                                          widthFactor: clampedProgress,
                                          heightFactor: 1,
                                          child:
                                              ColoredBox(color: progressColor),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                          if (thumb != null) thumb,
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );

  void _updateSeekFromGlobalPosition(
    BuildContext context,
    Offset globalPosition,
  ) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final localPosition = box.globalToLocal(globalPosition);
    final horizontalPadding = IsrDimens.eight;
    final trackWidth = box.size.width - (horizontalPadding * 2);
    if (trackWidth <= 0) return;
    final dx = (localPosition.dx - horizontalPadding).clamp(0.0, trackWidth);
    final newProgress = (dx / trackWidth).clamp(0.0, 1.0);
    _onSeekVideo(newProgress);
  }

  Widget _buildImageProgressIndicator(
          Color pendingColor, BorderRadius borderRadius) =>
      ValueListenableBuilder<double>(
        valueListenable:
            _currentMediaProgress, // Used for both video and image progress
        builder: (context, progress, child) => Container(
          height: _mediaIndicatorConfig?.indicatorHeight ?? IsrDimens.six,
          decoration: BoxDecoration(
            color: _indicatorPendingColor,
            borderRadius: borderRadius,
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: _indicatorProgressColor,
                  borderRadius: borderRadius,
                ),
              ),
            ),
          ),
        ),
      );

  void _onSeekStart({bool expand = false}) {
    _isSeeking = true;
    IsrVideoReelConfig.lockReelsFeedScroll();
    if (expand) {
      _isSeekBarExpanded.value = true;
    }
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
          milliseconds:
              (duration.inMilliseconds * _currentMediaProgress.value).toInt(),
        );
        videoPlayerState.seekTo(position);
      }
    }
    // Delay resetting the flag to allow seek to complete
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _isSeeking = false;
      _isSeekBarExpanded.value = false;
      IsrVideoReelConfig.unlockReelsFeedScroll();
      videoPlayerState?.play();
    });
  }

  void _cancelSeekInteraction() {
    if (!_isSeeking) return;
    _isSeeking = false;
    _isSeekBarExpanded.value = false;
    IsrVideoReelConfig.unlockReelsFeedScroll();
  }

  void _onSeekVideo(double value) {
    // Only update the progress value during seeking - don't seek video yet
    _currentMediaProgress.value = value;
  }

  void _callOnTapMentionData(List<MentionMetaData> mentionDataList) {
    if (widget.onTapMentionTag == null) return;
    widget.onTapMentionTag?.call(mentionDataList);
  }

  void _onTapBelowCommentUserTag(String userId) {
    if (userId.isStringEmptyOrNull) return;
    _callOnTapMentionData([MentionMetaData(userId: userId)]);
  }

  void _onTapFloatingCommentProfile(String userId) {
    if (userId.isStringEmptyOrNull) return;
    final postData = _reelData.postData is TimeLineData
        ? _reelData.postData as TimeLineData
        : null;
    widget.reelsConfig.postConfig.postCallBackConfig?.onProfileClick
        ?.call(postData, userId, null);
  }

  void _onTapBelowCommentHashtag(String hashtag) {
    if (hashtag.isStringEmptyOrNull) return;
    _callOnTapMentionData([MentionMetaData(tag: hashtag)]);
  }

  Widget _buildMediaCounter(int currentPage) {
    if (!_hasMultipleMedia) return const SizedBox.shrink();

    return Material(
      type: MaterialType.transparency,
      child: Container(
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
          style: _overlayTextStyle(
            IsrStyles.white12,
            custom: _textStyleConfig?.mediaCounterStyle,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMentionedUsersSection() {
    final mentionList = _reelData.mentions;

    if (mentionList.isListEmptyOrNull) {
      return const SizedBox.shrink();
    }

    final iconSize = _isGlassReelsActionIcons
        ? _glassChipIconSize
        : (_mentionConfig?.mentionIconSize ?? IsrDimens.fifteen);

    final iconGap = _isGlassReelsActionIcons
        ? IsrDimens.four
        : (_mentionConfig?.mentionIconSpacing ?? IsrDimens.five);

    final mentionLabel = mentionList.length == 1
        ? mentionList.first.username ?? ''
        : '${mentionList.length} people';

    final mentionText = Text(
      mentionLabel,
      style: _overlayTextStyle(
        IsrStyles.white14,
        custom: _textStyleConfig?.mentionStyle,
        fontWeight:
            _isGlassReelsActionIcons ? FontWeight.w500 : FontWeight.w600,
        includeShadow: !_isGlassReelsActionIcons,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    final content = Row(
      mainAxisSize:
          _isGlassReelsActionIcons ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (_mentionConfig?.mentionIcon != null)
          AppImage.svg(
            _mentionConfig!.mentionIcon!,
            width: iconSize,
            height: iconSize,
            color: _mentionConfig?.mentionIconColor ?? IsrColors.white,
          )
        else
          Icon(
            Icons.people,
            size: iconSize,
            color: _mentionConfig?.mentionIconColor ?? IsrColors.white,
            shadows: _isGlassReelsActionIcons ? null : _textShadows,
          ),
        IsrDimens.boxWidth(iconGap),
        if (_isGlassReelsActionIcons)
          mentionText
        else
          Expanded(child: mentionText),
      ],
    );

    if (_isGlassReelsActionIcons) {
      return TapHandler(
        onTap: () => _callOnTapMentionData(mentionList),
        child: GlassPillContainer(
          glassConfig: _actionIconConfig?.glassConfig,
          child: content,
        ),
      );
    }

    return TapHandler(
      onTap: () => _callOnTapMentionData(mentionList),
      child: content,
    );
  }

  Widget _buildLocationSection() {
    final placeList = _reelData.placeDataList ?? [];
    if (placeList.isListEmptyOrNull) return const SizedBox.shrink();

    final iconSize = _isGlassReelsActionIcons
        ? _glassChipIconSize
        : (_locationConfig?.locationIconSize ?? IsrDimens.fifteen);

    final iconGap = _isGlassReelsActionIcons
        ? IsrDimens.four
        : (_locationConfig?.locationIconSpacing ?? IsrDimens.three);

    final locationText = _buildSimpleLocationText(placeList);

    final content = Row(
      mainAxisSize:
          _isGlassReelsActionIcons ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (_locationConfig?.locationIcon != null)
          AppImage.svg(
            _locationConfig!.locationIcon!,
            width: iconSize,
            height: iconSize,
            color: _locationConfig?.locationIconColor ?? IsrColors.white,
          )
        else
          Icon(
            Icons.location_on,
            size: iconSize,
            color: _locationConfig?.locationIconColor ?? IsrColors.white,
            shadows: _isGlassReelsActionIcons ? null : _textShadows,
          ),
        IsrDimens.boxWidth(iconGap),
        if (_isGlassReelsActionIcons)
          Flexible(child: locationText)
        else
          Expanded(child: locationText),
      ],
    );

    if (_isGlassReelsActionIcons) {
      return GestureDetector(
        onTap: () async {
          await widget.reelsConfig.onTapPlace?.call(
            _reelData,
            placeList,
          );
        },
        child: GlassPillContainer(
          glassConfig: _actionIconConfig?.glassConfig,
          child: content,
        ),
      );
    }

    return GestureDetector(
      onTap: () async {
        await widget.reelsConfig.onTapPlace?.call(
          _reelData,
          placeList,
        );
      },
      child: content,
    );
  }

  String _soundThumbnailUrl(PostSoundInfo sound) {
    final thumb = (sound.thumbnailUrl ?? '').trim();
    if (thumb.isNotEmpty) return thumb;
    final media = _reelData.mediaMetaDataList;
    if (media.isNotEmpty) {
      final preview = media.first.thumbnailUrl.trim();
      if (preview.isNotEmpty) return preview;
    }
    return '';
  }

  Widget _buildSoundDisc(String imageUrl) {
    final size = 20.responsiveDimension;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: IsrColors.white,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.changeOpacity(0.35),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl.isNotEmpty
            ? AppImage.network(
                imageUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
              )
            : ColoredBox(
                color: IsrColors.black.changeOpacity(0.45),
                child: Center(
                  child: PostSoundIcon(
                    size: 10.responsiveDimension,
                    style: PostSoundIconStyle.onDark,
                  ),
                ),
              ),
      ),
    );
  }

  /// Default reels sound row (plain theme): disc + title below comments area.
  Widget _buildPostSoundRow() {
    final sound = _reelData.sound;
    if (sound == null || !sound.hasId) return const SizedBox.shrink();
    final title = (sound.title ?? '').trim();
    final label = title.isNotEmpty ? title : sound.displayLabel;
    final thumbUrl = _soundThumbnailUrl(sound);

    return TapHandler(
      onTap: _onTapPostSound,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildSoundDisc(thumbUrl),
          IsrDimens.boxWidth(IsrDimens.six),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: IsrStyles.white14.copyWith(
                fontWeight: FontWeight.w500,
                color: IsrColors.white,
                shadows: _textShadows,
              ),
            ),
          ),
          // IsrDimens.boxWidth(IsrDimens.six),
        ],
      ),
    );
  }

  Widget _buildReelsProfileAvatar() {
    final size = _userProfileConfig?.profileImageSize ?? IsrDimens.thirtyFive;
    final firstName = _reelData.firstName ?? '';
    final lastName = _reelData.lastName ?? '';
    final initials =
        Utility.getInitials(firstName: firstName, lastName: lastName);
    final nameSeed = '$firstName $lastName'.trim().isNotEmpty
        ? '$firstName $lastName'
        : (_reelData.userName ?? initials);

    return TapHandler(
      borderRadius: size / 2,
      onTap: () async {
        if (widget.reelsConfig.onTapUserProfile == null) return;
        await widget.reelsConfig.onTapUserProfile!(_reelData);
      },
      child: AppImage.network(
        _reelData.profilePhoto ?? '',
        width: size,
        height: size,
        isProfileImage: true,
        border: _userProfileConfig?.profileImageBorder ??
            Border.all(
              color: IsrColors.white.withValues(alpha: 0.9),
              width: IsrDimens.one,
            ),
        name: '$firstName $lastName',
        placeHolderWidget: (h, w) => FeedProfileInitialsPlaceholder(
          initials: initials,
          size: h ?? w ?? size,
          seed: nameSeed,
        ),
      ),
    );
  }

  Widget _buildGlassyUsernameLabel() => TapHandler(
        onTap: () async {
          if (widget.reelsConfig.onTapUserProfile == null) return;
          await widget.reelsConfig.onTapUserProfile!(_reelData);
        },
        child: Text(
          _reelData.userName ?? '',
          style: _overlayTextStyle(
            IsrStyles.white14,
            custom: _textStyleConfig?.userNameStyle,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );

  static const double _glassyHeaderGap = 10;

  /// Glassy reels header — profile [10] username (+ sound) [10] follow.
  /// Content hugs when short; sound expands until follow reaches overlay inset.
  Widget _buildGlassyUserHeader() {
    final hasSound = _reelData.sound?.hasId ?? false;

    final content = hasSound
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGlassyUsernameLabel(),
              IsrDimens.boxHeight(IsrDimens.four),
              _buildGlassyUsernameSoundRow(),
            ],
          )
        : _buildGlassyUsernameLabel();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (_reelData.postSetting?.isProfilePicVisible == true) ...[
          _buildReelsProfileAvatar(),
          const SizedBox(width: _glassyHeaderGap),
        ],
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: content,
              ),
              const SizedBox(width: _glassyHeaderGap),
              _buildFollowButton(),
            ],
          ),
        ),
      ],
    );
  }

  /// Glassy reels: note + scrolling title/artist below username.
  Widget _buildGlassyUsernameSoundRow() {
    final sound = _reelData.sound;
    if (sound == null || !sound.hasId) return const SizedBox.shrink();

    return ReelsSoundMarqueeRow(
      sound: sound,
      textStyle: _overlayTextStyle(
        IsrStyles.white12,
        color: IsrColors.white.changeOpacity(0.85),
        fontWeight: FontWeight.w400,
        includeShadow: false,
      ),
      onTap: _onTapPostSound,
    );
  }

  Future<void> _onTapPostSound() async {
    final postData = _reelData.postData is TimeLineData
        ? _reelData.postData as TimeLineData
        : null;
    final sound = _reelData.sound;
    if (sound == null || !sound.hasId) return;

    final handler = _postConfig.postCallBackConfig?.onUseThisSound;
    if (handler != null && postData != null) {
      await handler(postData, sound);
      return;
    }

    IsrVideoReelConfig.suppressPlayback();
    try {
      await IsrAppNavigator.navigateToSoundPostsDetail(
        context,
        sound: sound,
        sourcePost: postData,
      );
    } finally {
      if (mounted) {
        IsrVideoReelConfig.releasePlaybackSuppression();
      }
    }
  }

  bool get _shouldSpinGlassySoundDisc {
    if (_isCurrentMediaVideo) return !_isReelsPlaybackPaused;
    return true;
  }

  static const double _glassyReelsSoundDiscSize = 24;

  /// Same horizontal inset as the glass action column (16px + centered 24px disc in 40px slot).
  double _glassySoundDiscRightInset(BuildContext context) {
    final overlayRight = widget.reelsConfig.overlayPadding
            ?.resolve(Directionality.of(context))
            .right ??
        0;
    return overlayRight +
        IsrDimens.sixteen +
        (_reelsSideActionSlotWidth - _glassyReelsSoundDiscSize) / 2;
  }

  /// Glassy reels — spinning sound disc beside the comment block (Figma).
  Widget _buildGlassyBottomRightSoundDisc() {
    final sound = _reelData.sound;
    if (sound == null || !sound.hasId) return const SizedBox.shrink();

    return ValueListenableBuilder<int>(
      valueListenable: _videoOverlayTick,
      builder: (context, _, __) => ReelsGlassySoundDisc(
        imageUrl: _soundThumbnailUrl(sound),
        onTap: _onTapPostSound,
        spin: _shouldSpinGlassySoundDisc,
        size: _glassyReelsSoundDiscSize,
      ),
    );
  }

  Widget _buildSimpleLocationText(List<PlaceMetaData> placeList) {
    if (placeList.isEmpty) return const SizedBox.shrink();

    if (placeList.first.placeName.isEmpty) return const SizedBox.shrink();

    return Text(
      placeList.first.placeName,
      style: _overlayTextStyle(
        IsrStyles.white14,
        custom: _textStyleConfig?.locationStyle,
        fontWeight:
            _isGlassReelsActionIcons ? FontWeight.w500 : FontWeight.w600,
        includeShadow: !_isGlassReelsActionIcons,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  bool get _isCurrentMediaVideo {
    if (_isTextOnlyPost) return false;
    final list = _reelData.mediaMetaDataList;
    if (list.isEmpty) return false;
    final index = _currentPageNotifier.value.clamp(0, list.length - 1);
    return list[index].mediaType == kVideoType;
  }

  bool get _shouldShowReelsMuteControl {
    if (!_isCurrentMediaVideo) return false;
    return true;
  }

  bool get _isReelsPlaybackPaused {
    if (!_isCurrentMediaVideo) return false;
    final player = VideoPlayerWidget.of(_getCurrentVideoPlayerKey());
    return player != null && player.mounted && player.showPausedIndicator;
  }

  BoxDecoration get _reelsControlButtonDecoration => BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        shape: BoxShape.circle,
      );

  /// Tap anywhere on the reel: pause / resume (Instagram-style, video only).
  void _onReelTapTogglePlayPause() {
    if (!mounted || _shouldShowPaidLockOverlay || !_isCurrentMediaVideo) return;

    final player = VideoPlayerWidget.of(_getCurrentVideoPlayerKey());
    if (player == null || !player.mounted) return;

    if (player.isPlaying) {
      player.pause();
    } else {
      player.play();
    }
    _videoOverlayTick.value++;
  }

  void _resumePlayback() {
    if (!mounted) return; // Safety check: Widget is disposed
    if (!_isCurrentReel) return;
    if (_shouldShowPaidLockOverlay) return;
    if (!IsrVideoReelConfig.allowsPlayback ||
        IsrVideoReelConfig.isAppInBackground) {
      return;
    }
    if (!widget.reelsConfig.isTabVisible()) return;

    // Resume video on long press release
    final key = _getCurrentVideoPlayerKey();
    final videoPlayerState = VideoPlayerWidget.of(key);
    if (videoPlayerState != null && videoPlayerState.mounted) {
      videoPlayerState.forceResume(activeReel: true);
    }
    VisibilityDetectorController.instance.notifyNow();

    // Resume timed advance for text-only posts or image slides.
    if (_usesTimedAdvance) {
      _startOrResumeImageProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        'IsmReelsVideoPlayerView: build index: ${widget.index}, visibleIndex: ${widget.currentIndex.value}, tabType: ${widget.postSectionType}');
    return IsrSdkTextStyleScope(
      useReelsOverlayDefaults: true,
      child: BlocListener<SocialPostBloc, SocialPostState>(
        listenWhen: (previous, current) => current is PlayPauseVideoState,
        listener: (context, state) {
          if (state is PlayPauseVideoState && _handlesPlayPauseState(state)) {
            _setPlaybackBlocked(
              state.play,
              pausePlayback: state.pausePlayback,
            );
          }
        },
        child: ValueListenableBuilder<bool>(
          valueListenable: _isSeekBarExpanded,
          builder: (context, scrubExpanded, _) {
            final contentBottom = _contentBottomInset(
              context,
              scrubExpanded: scrubExpanded,
            );

            return Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTap: _shouldShowPaidLockOverlay
                      ? null
                      : _onReelTapTogglePlayPause,
                  onDoubleTap:
                      _shouldShowPaidLockOverlay ? null : _triggerLikeAnimation,
                  child: Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.center,
                    children: [
                      _buildMediaContent(),
                      if (!_shouldShowPaidLockOverlay &&
                          _isGlassReelsActionIcons)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: ColoredBox(
                              color: Colors.black.withValues(
                                alpha: _reelsMediaScrimOpacity,
                              ),
                            ),
                          ),
                        ),
                      if (!_shouldShowPaidLockOverlay && _showLikeAnimation)
                        Center(
                          child: Lottie.asset(
                            AssetConstants.heartAnimation,
                            width: 250,
                            height: 250,
                            repeat: false,
                          ),
                        ),
                      ValueListenableBuilder<int>(
                        valueListenable: _videoOverlayTick,
                        builder: (context, _, __) => _buildReelsPausedOverlay(),
                      ),

                      // Bottom gradient for plain reels; glass reels use the
                      // full-screen scrim above media instead.
                      if (!_isGlassReelsActionIcons)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: IgnorePointer(
                            child: RepaintBoundary(
                              child: Container(
                                height:
                                    IsrDimens.getScreenHeight(context) * 0.45,
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
                      if (!_shouldShowPaidLockOverlay)
                        _isGlassReelsActionIcons
                            ? Positioned(
                                top: 0,
                                bottom: 0,
                                right: widget.reelsConfig.overlayPadding
                                        ?.resolve(Directionality.of(context))
                                        .right ??
                                    0,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: widget.reelsConfig.actionWidget
                                          ?.call(_reelData)
                                          .child ??
                                      _buildRightSideActions(),
                                ),
                              )
                            : Positioned(
                                right: widget.reelsConfig.overlayPadding
                                        ?.resolve(Directionality.of(context))
                                        .right ??
                                    0,
                                bottom: contentBottom,
                                child: widget.reelsConfig.actionWidget
                                        ?.call(_reelData)
                                        .child ??
                                    _buildRightSideActions(),
                              ),

                      //bottom section
                      //kept separate so that it does not bloc touch/gesture to underlying widgets
                      Positioned(
                        right: _reelsOverlayRightContentInset,
                        bottom: contentBottom,
                        left: widget.reelsConfig.overlayPadding
                                ?.resolve(Directionality.of(context))
                                .left ??
                            0,
                        child: widget.reelsConfig.footerWidget
                                ?.call(_reelData)
                                .child ??
                            _buildBottomSectionWithoutOverlay(),
                      ),

                      // Glassy reels — sound disc aligned with right action column.
                      if (_isGlassReelsActionIcons &&
                          (_reelData.sound?.hasId ?? false) &&
                          !_shouldShowPaidLockOverlay)
                        Positioned(
                          right: _glassySoundDiscRightInset(context),
                          bottom: contentBottom + IsrDimens.sixteen,
                          child: _buildGlassyBottomRightSoundDisc(),
                        ),
                    ],
                  ),
                ),
                // Outside tap-to-pause so scrubbing does not toggle playback.
                if (_shouldShowMediaIndicators)
                  Positioned(
                    bottom: _overlayBottomInset(context),
                    left: 0,
                    right: 0,
                    child: ValueListenableBuilder<int>(
                      valueListenable: _currentPageNotifier,
                      builder: (context, value, child) =>
                          _buildMediaProgressLayer(value),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Instagram-style paused overlay: small mute on top, large play below (video only).
  Widget _buildReelsPausedOverlay() {
    if (_shouldShowPaidLockOverlay ||
        !_isCurrentMediaVideo ||
        !_isReelsPlaybackPaused) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_shouldShowReelsMuteControl)
            ListenableBuilder(
              listenable: VideoMuteController.notifier,
              builder: (context, _) => GestureDetector(
                onTap: _toggleMuteAndUnMute,
                child: Container(
                  padding: IsrDimens.edgeInsetsAll(IsrDimens.eight),
                  decoration: _reelsControlButtonDecoration,
                  child: Icon(
                    VideoMuteController.isMuted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    color: IsrColors.white,
                    size: IsrDimens.twenty,
                  ),
                ),
              ),
            ),
          if (_shouldShowReelsMuteControl) SizedBox(height: IsrDimens.sixteen),
          IgnorePointer(
            child: Container(
              padding: IsrDimens.edgeInsetsAll(IsrDimens.twelve),
              decoration: _reelsControlButtonDecoration,
              child: Icon(
                Icons.play_arrow_rounded,
                color: IsrColors.white,
                size: IsrDimens.forty,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightSideActions() => RepaintBoundary(
        child: Padding(
          padding: _isGlassReelsActionIcons
              ? IsrDimens.edgeInsets(right: IsrDimens.sixteen)
              : IsrDimens.edgeInsets(
                  bottom: IsrDimens.forty,
                  right: IsrDimens.sixteen,
                ),
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
                    _reelsOverlayLabel(IsrTranslationFile.create),
                  ],
                ),
              ],
              if (_reelData.postSetting?.isLikeButtonVisible == true)
                LikeActionWidget(
                  key: ValueKey('like_action_${_reelData.postId}'),
                  postId: _reelData.postId ?? '',
                  initialLikeCount: _reelData.likesCount,
                  initialIsLiked: _reelData.isLiked,
                  builder: (isLoading, isLiked, likeCount, onTap) {
                    _isLikeActionLoading = isLoading;
                    _reelData.isLiked = isLiked;
                    _reelData.likesCount = likeCount;
                    _onLikeTap = onTap;
                    final likeIcon = isLiked == true
                        ? (_actionIconConfig?.likeIconSelected ??
                            AssetConstants.icLikeSelected)
                        : (_actionIconConfig?.likeIconUnselected ??
                            AssetConstants.icLikeUnSelected);
                    return _buildReelsSideActionColumn(
                      icon: ActionIconContainer(
                        config: _actionIconConfig,
                        child: ActionIconImage(
                          path: likeIcon,
                          config: _actionIconConfig,
                        ),
                      ),
                      label: likeCount.toString(),
                      labelKey: ValueKey(
                        'like_count_${_reelData.postId}_$likeCount',
                      ),
                      onIconTap: () => onTap(
                        reelData: _reelData,
                        watchDuration: _postWatchDuration.inSeconds,
                        postSectionType: widget.postSectionType,
                        apiCallBack: widget.onPressLikeButton != null
                            ? () => widget.onPressLikeButton!(
                                  _reelData,
                                  isLiked,
                                )
                            : null,
                      ),
                      onLabelTap: _handleLikeCountTap,
                    );
                  },
                ),
              if (_postConfig.showViewCount) _buildEyeViewAction(),
              if (_reelData.postSetting?.isCommentButtonVisible == true)
                CommentCountActionWidget(
                  postId: _reelData.postId ?? '',
                  builder: (commentCount) {
                    _reelData.commentCount = commentCount;
                    return _buildActionButton(
                      icon: _actionIconConfig?.commentIcon ??
                          AssetConstants.icCommentIcon,
                      label: commentCount.toString(),
                      onTap: _handleCommentClick,
                    );
                  },
                ),
              if (_reelData.postSetting?.isShareButtonVisible == true)
                _buildActionButton(
                  icon: _actionIconConfig?.shareIcon ??
                      AssetConstants.icShareIconSvg,
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
                          ? (_actionIconConfig?.saveIconSelected ??
                              AssetConstants.icSaveSelected)
                          : (_actionIconConfig?.saveIconUnselected ??
                              AssetConstants.icSaveUnSelected),
                      label: isSaved == true
                          ? IsrTranslationFile.saved
                          : IsrTranslationFile.save,
                      onTap: () => onTap(
                        reelData: _reelData,
                        watchDuration: _postWatchDuration.inSeconds,
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
                  icon:
                      _actionIconConfig?.moreIcon ?? AssetConstants.icMoreIcon,
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

  Widget _buildEyeViewAction() => GestureDetector(
        onTap: _handleViewCountTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ActionIconContainer(
              config: _actionIconConfig,
              child: Icon(
                Icons.remove_red_eye_outlined,
                color: IsrColors.white,
                size: _actionIconConfig?.iconSize ?? IsrDimens.twentyFive,
              ),
            ),
            IsrDimens.boxHeight(IsrDimens.four),
            _reelsOverlayLabel((_reelData.viewCount ?? 0).toString()),
          ],
        ),
      );

  Future<void> _handleViewCountTap() async {
    final callback = _postConfig.postCallBackConfig?.onViewCountClicked;
    if (callback == null) return;
    final postData = _reelData.postData;
    if (postData is! TimeLineData) return;
    try {
      await callback(postData);
    } catch (e) {
      debugPrint('Failed to handle view count tap: $e');
    }
  }

  Future<void> _handleLikeCountTap() async {
    if (_isLikeActionLoading) return;
    final callback = _postConfig.postCallBackConfig?.onLikeCountClicked;
    if (callback == null) return;
    final postData = _reelData.postData;
    if (postData is! TimeLineData) return;
    try {
      await callback(postData);
    } catch (e) {
      debugPrint('Failed to handle like count tap: $e');
    }
  }

  static const double _plainActionIconShadowClipExtension = 3;

  double get _reelsSideActionSlotWidth {
    if (_isGlassReelsActionIcons) {
      return _actionIconConfig?.glassConfig?.containerSize.toDouble() ?? 40;
    }
    return _actionIconConfig?.iconSize ?? IsrDimens.twentyFive;
  }

  double get _reelsSideActionIconSlotHeight {
    if (_isGlassReelsActionIcons) {
      return _reelsSideActionSlotWidth;
    }
    return _reelsSideActionSlotWidth + _plainActionIconShadowClipExtension;
  }

  /// Space between bottom-left overlay content and right-side action buttons.
  double get _reelsOverlayRightContentInset {
    if (!_isGlassReelsActionIcons) return 40;
    return _reelsSideActionSlotWidth + IsrDimens.sixteen;
  }

  /// Isolates icon paint from count labels so shadows never bleed onto digits.
  /// Glass uses a 40×40 clip; plain uses icon width + a small shadow margin.
  Widget _buildReelsSideActionColumn({
    required Widget icon,
    String? label,
    Key? labelKey,
    VoidCallback? onIconTap,
    VoidCallback? onLabelTap,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    final slotWidth = _reelsSideActionSlotWidth;
    final iconSlotHeight = _reelsSideActionIconSlotHeight;
    final labelGap =
        _isGlassReelsActionIcons ? IsrDimens.eight : IsrDimens.four;

    Widget iconSlot;
    if (isLoading) {
      iconSlot = SizedBox(
        width: slotWidth,
        height: iconSlotHeight,
        child: Center(
          child: SizedBox(
            width: IsrDimens.twenty,
            height: IsrDimens.twenty,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      );
    } else {
      iconSlot = RepaintBoundary(
        child: SizedBox(
          width: slotWidth,
          height: iconSlotHeight,
          child: ClipRect(
            clipBehavior: Clip.hardEdge,
            child: Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: onIconTap ?? onTap,
                behavior: HitTestBehavior.opaque,
                child: icon,
              ),
            ),
          ),
        ),
      );
    }

    Widget? labelWidget;
    if (label.isStringEmptyOrNull == false) {
      final overlayLabel = _reelsOverlayLabel(
        label!,
        onTap: onLabelTap ?? onTap,
        labelKey: labelKey ?? ValueKey('reels_action_$label'),
        singleLine: true,
      );
      labelWidget = RepaintBoundary(child: overlayLabel);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        iconSlot,
        if (labelWidget != null) ...[
          IsrDimens.boxHeight(labelGap),
          labelWidget,
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required String icon,
    String? label,
    required VoidCallback onTap,
    VoidCallback? onIconTap,
    VoidCallback? onLabelTap,
    bool isLoading = false,
  }) =>
      _buildReelsSideActionColumn(
        icon: ActionIconContainer(
          config: _actionIconConfig,
          child: ActionIconImage(
            path: icon,
            config: _actionIconConfig,
          ),
        ),
        label: label,
        onTap: onTap,
        onIconTap: onIconTap,
        onLabelTap: onLabelTap,
        isLoading: isLoading,
      );

  Future<void> _onPostLinkTap() async {
    final link = _reelData.postLink;
    if (link == null || !link.isValid) return;
    final hostHandler = _postConfig.postCallBackConfig?.onPostLinkClick;
    if (hostHandler != null && _reelData.postData is TimeLineData) {
      await hostHandler(_reelData.postData as TimeLineData, link);
      return;
    }
    Utility.launchExternalUrl(
        link.url.contains('://') ? link.url : 'https://${link.url}');
  }

  Widget _buildPostLinkChip() {
    final link = _reelData.postLink!;
    final linkConfig = _postLinkUIConfig;
    return TapHandler(
      onTap: _onPostLinkTap,
      child: Container(
        constraints: BoxConstraints(maxWidth: 220.responsiveDimension),
        padding: linkConfig?.containerPadding ??
            IsrDimens.edgeInsetsSymmetric(
              horizontal: IsrDimens.sixteen,
              vertical: IsrDimens.ten,
            ),
        decoration: linkConfig?.containerDecoration ??
            BoxDecoration(
              color: Colors.white.changeOpacity(0.92),
              borderRadius: BorderRadius.circular(IsrDimens.twentyFour),
            ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              linkConfig?.icon ?? Icons.link_rounded,
              size: linkConfig?.iconSize ?? 18.responsiveDimension,
              color: linkConfig?.iconColor ?? IsrColors.color0F1E91,
            ),
            IsrDimens.boxWidth(IsrDimens.eight),
            Flexible(
              child: Text(
                link.displayTitle,
                style: linkConfig?.textStyle ??
                    IsrStyles.primaryText12.copyWith(
                      color: IsrColors.color0F1E91,
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IsrDimens.boxWidth(IsrDimens.four),
            Icon(
              Icons.chevron_right,
              size: 16.responsiveDimension,
              color: linkConfig?.iconColor ?? IsrColors.color0F1E91,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSectionWithoutOverlay() {
    final publishedTimeLabel = _postPublishedTimeLabel();

    return Padding(
      padding: _isGlassReelsActionIcons
          ? IsrDimens.edgeInsets(
              left: IsrDimens.sixteen,
              right: IsrDimens.sixteen,
            )
          : IsrDimens.edgeInsets(
              left: IsrDimens.sixteen,
              right: IsrDimens.sixteen,
              bottom: IsrDimens.fifteen,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                  color: IsrColors.color0F1E91,
                                  fontWeight: FontWeight.w700),
                        ),
                        IsrDimens.boxHeight(IsrDimens.four),
                        Text(
                          '${_reelData.productCount} ${_reelData.productCount == 1 ? IsrTranslationFile.product : IsrTranslationFile.products}',
                          style: _textStyleConfig?.shopSubtitleStyle ??
                              IsrStyles.primaryText10.copyWith(
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
          if (_shouldShowPostLinkChip) ...[
            _buildPostLinkChip(),
            IsrDimens.boxHeight(IsrDimens.twelve),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isGlassReelsActionIcons)
                      _buildGlassyUserHeader()
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                if (_reelData
                                        .postSetting?.isProfilePicVisible ==
                                    true) ...[
                                  _buildReelsProfileAvatar(),
                                  IsrDimens.boxWidth(IsrDimens.eight),
                                ],
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
                                      style: _overlayTextStyle(
                                        IsrStyles.white14,
                                        custom: _textStyleConfig?.userNameStyle,
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
                                final shouldTruncate =
                                    fullDescription.length > _maxLengthToShow ||
                                        descriptionLineCount > _maxLinesToShow;

                                // Show truncated version when collapsed, full version when expanded
                                // FIX: Prevent substring out of bounds error
                                String displayText;
                                if (shouldTruncate && !value) {
                                  final safeLength =
                                      fullDescription.length < _maxLengthToShow
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
                                      Utility.buildPostDescriptionTextSpan(
                                    displayText.trim(),
                                    _mentionedDataList,
                                    _taggedDataList,
                                    _overlayTextStyle(
                                      IsrStyles.white14,
                                      custom:
                                          _textStyleConfig?.descriptionStyle,
                                      color: IsrColors.white.changeOpacity(0.9),
                                    ),
                                    (mention) =>
                                        _callOnTapMentionData([mention]),
                                    mentionStyle:
                                        _textStyleConfig?.mentionStyle != null
                                            ? _overlayTextStyle(
                                                IsrStyles.white14,
                                                custom: _textStyleConfig
                                                    ?.mentionStyle,
                                                fontWeight: FontWeight.w600,
                                              )
                                            : null,
                                    hashtagStyle:
                                        _textStyleConfig?.hashtagStyle != null
                                            ? _overlayTextStyle(
                                                IsrStyles.white14,
                                                custom: _textStyleConfig
                                                    ?.hashtagStyle,
                                                fontWeight: FontWeight.w600,
                                              )
                                            : null,
                                    urlStyle: _buildReelsUrlStyle(),
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
                                            text: value
                                                ? (_descriptionConfig
                                                        ?.lessText ??
                                                    ' less')
                                                : (_descriptionConfig
                                                        ?.moreText ??
                                                    ' ... more'),
                                            style: value
                                                ? _overlayTextStyle(
                                                    IsrStyles.white14,
                                                    custom: _descriptionConfig
                                                        ?.collapseTextStyle,
                                                    fontWeight: FontWeight.w700,
                                                    color: IsrColors.white
                                                        .changeOpacity(0.7),
                                                  )
                                                : _overlayTextStyle(
                                                    IsrStyles.white14,
                                                    custom: _descriptionConfig
                                                        ?.expandTextStyle,
                                                    fontWeight: FontWeight.w700,
                                                    color: IsrColors.white
                                                        .changeOpacity(0.7),
                                                  ),
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
                    if (!_isGlassReelsActionIcons && _hasMentionOrLocation) ...[
                      IsrDimens.boxHeight(IsrDimens.eight),
                      _buildMentionAndLocationRow(),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (publishedTimeLabel != null) ...[
            IsrDimens.boxHeight(IsrDimens.six),
            Text(
              publishedTimeLabel,
              style: _overlayTextStyle(IsrStyles.white12),
            ),
          ],
          if (_isGlassReelsActionIcons && _hasMentionOrLocation) ...[
            IsrDimens.boxHeight(IsrDimens.eight),
            _buildMentionAndLocationRow(),
          ],
          if (_showFloatingComments) ...[
            IsrDimens.boxHeight(IsrDimens.eight),
            _buildFloatingCommentsSection(),
          ],
          if ((_reelData.productCount ?? 0) > 0) ...[
            IsrDimens.boxHeight(IsrDimens.eight),
            _buildCommissionTag(),
          ],
          if (!_isGlassReelsActionIcons &&
              (_reelData.sound?.hasId ?? false)) ...[
            IsrDimens.boxHeight(IsrDimens.eight),
            _buildPostSoundRow(),
          ],
        ],
      ),
    );
  }

  /// Uses [ReelsData.createOn] (timeline `published_at`) for upload/publish time.
  String? _postPublishedTimeLabel() {
    final raw = _reelData.createOn?.trim();
    if (raw.isStringEmptyOrNull) return null;
    try {
      final dt = DateTime.parse(raw!).toLocal();
      final relative = Utility.formatPublishedTimeAgo(dt);
      return relative.isEmpty ? null : relative;
    } catch (_) {
      return raw;
    }
  }

  Widget _buildFloatingCommentsSection() {
    final total = _resolvedViewAllCommentsCount;
    if (_floatingComments.isEmpty && total <= 0) {
      return const SizedBox.shrink();
    }

    final usernameStyle = _overlayTextStyle(
      IsrStyles.white12,
      custom: _isGlassReelsActionIcons
          ? _belowCommentsConfig?.usernameStyle
          : (_belowCommentsConfig?.usernameStyle ??
              _textStyleConfig?.userNameStyle),
      fontWeight: _isGlassReelsActionIcons ? null : FontWeight.w700,
      includeShadow: !_isGlassReelsActionIcons,
    );
    final commentStyle = _overlayTextStyle(
      IsrStyles.white12,
      custom: _belowCommentsConfig?.commentTextStyle ??
          _textStyleConfig?.descriptionStyle,
      color: _isGlassReelsActionIcons
          ? IsrColors.white.changeOpacity(0.92)
          : IsrColors.white.changeOpacity(0.9),
      fontWeight: _isGlassReelsActionIcons ? FontWeight.w400 : null,
      includeShadow: !_isGlassReelsActionIcons,
    );
    final userTagStyle = _overlayTextStyle(
      IsrStyles.white12,
      custom: _belowCommentsConfig?.userTagTextStyle,
      fontWeight: FontWeight.w600,
      includeShadow: !_isGlassReelsActionIcons,
    );
    final hashtagStyle = _overlayTextStyle(
      IsrStyles.white12,
      custom: _belowCommentsConfig?.hashtagTextStyle,
      fontWeight: FontWeight.w600,
      includeShadow: !_isGlassReelsActionIcons,
    );
    final buttonStyle = _isGlassReelsActionIcons
        ? _overlayTextStyle(
            IsrStyles.white12,
            custom: _belowCommentsConfig?.viewAllCommentsStyle,
            color: IsrColors.white,
            fontWeight: FontWeight.w500,
            includeShadow: false,
          )
        : _overlayTextStyle(
            IsrStyles.white12,
            custom: _belowCommentsConfig?.viewAllCommentsStyle ??
                _descriptionConfig?.expandTextStyle,
            includeShadow: !_isGlassReelsActionIcons,
          );

    final commentSpacing =
        _belowCommentsConfig?.commentSpacing ?? IsrDimens.four;
    final maxLinesPerComment = _belowCommentsConfig?.maxLinesPerComment ?? 2;
    final viewAllCommentsText = _viewAllCommentsLabel();
    final animationDuration = Duration(
      milliseconds:
          _belowCommentsConfig?.animationDurationInMilliseconds ?? 220,
    );
    final animationOffsetY = _belowCommentsConfig?.animationOffsetY ?? 0.06;
    final animationKey = _floatingComments
        .map((comment) =>
            '${comment.id}_${comment.commentedOn?.millisecondsSinceEpoch}_${comment.comment}')
        .join('|');

    return RepaintBoundary(
      child: AnimatedSwitcher(
        duration: animationDuration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: Alignment.topLeft,
          clipBehavior: Clip.none,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        ),
        transitionBuilder: (child, animation) {
          final slideAnimation = Tween<Offset>(
            begin: Offset(0, animationOffsetY),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: slideAnimation,
              child: child,
            ),
          );
        },
        child: Column(
          key: ValueKey(animationKey),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._floatingComments.map((comment) {
              final username = comment.fullName?.trim().isNotEmpty == true
                  ? comment.fullName!.trim()
                  : (comment.commentedBy ?? '').trim();
              return Padding(
                padding: IsrDimens.edgeInsets(bottom: commentSpacing),
                child: RichText(
                  maxLines: maxLinesPerComment,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: username,
                        style: usernameStyle,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _onTapFloatingCommentProfile(
                                comment.commentedByUserId ?? '',
                              ),
                      ),
                      const TextSpan(text: ' '),
                      ...Utility.buildCommentTextSpans(
                        comment.comment ?? '',
                        commentStyle,
                        comment.tags,
                        userNameStyle: userTagStyle,
                        hashTagStyle: hashtagStyle,
                        onUsernameTap: _onTapBelowCommentUserTag,
                        onHashtagTap: _onTapBelowCommentHashtag,
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (total > 0 || _floatingComments.isNotEmpty)
              TapHandler(
                onTap: _handleCommentClick,
                child: Text(
                  viewAllCommentsText,
                  style: buttonStyle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  int get _resolvedViewAllCommentsCount {
    if (_floatingCommentsTotal > 0) return _floatingCommentsTotal;
    final reelCount = _reelData.commentCount ?? 0;
    if (reelCount > 0) return reelCount;
    return _floatingComments.length;
  }

  String _viewAllCommentsLabel() {
    final fallback =
        _belowCommentsConfig?.viewAllCommentsText ?? 'View all comments';
    if (!_isGlassReelsActionIcons) return fallback;

    final total = _resolvedViewAllCommentsCount;
    if (total <= 0) return fallback;

    if (total == 1) return 'View 1 comment';
    return 'View all $total comments';
  }

  Widget _buildCommissionTag() => Container(
        padding: IsrDimens.edgeInsetsSymmetric(
            horizontal: IsrDimens.six, vertical: IsrDimens.three),
        decoration: BoxDecoration(
          color: Colors.black.changeOpacity(0.5),
          borderRadius: IsrDimens.borderRadiusAll(5),
        ),
        child: Text(
          IsrTranslationFile.creatorEarnsCommission,
          style: _overlayTextStyle(
            IsrStyles.white10,
            custom: _textStyleConfig?.commissionTagStyle,
            color: IsrColors.colorF4F4F4,
          ),
        ),
      );

  Widget _buildFollowButton() {
    final timelineUser = _reelData.postData is TimeLineData
        ? (_reelData.postData as TimeLineData).user
        : null;
    final chipVariant = _isGlassReelsActionIcons
        ? FollowChipVariant.theme
        : FollowChipVariant.reelsOverlay;
    final chipTextShadows = _isGlassReelsActionIcons ? null : _textShadows;

    InstagramFollowChip followChip({
      required String label,
      required bool filled,
      required VoidCallback onTap,
    }) =>
        InstagramFollowChip(
          label: label,
          filled: filled,
          variant: chipVariant,
          followButtonConfig: _followButtonConfig,
          followButtonTextStyle: _textStyleConfig?.followButtonTextStyle,
          followingButtonTextStyle: _textStyleConfig?.followingButtonTextStyle,
          textShadows: chipTextShadows,
          onTap: onTap,
        );

    return FollowActionWidget(
      postId: _reelData.postId ?? '',
      userId: _reelData.userId ?? '',
      isTargetPrivate: (timelineUser?.isPrivate ?? 0) == 1,
      initialFollowStatus: timelineUser?.followStatus,
      initialIsRequested: timelineUser?.isRequested,
      builder: (isLoading, isFollowing, followRequestPending, onTap) {
        // Update reel data state (non-blocking, for UI sync)
        _reelData.isFollow = isFollowing;

        // Show loading indicator during API call
        if (isLoading) {
          return SizedBox(
            height: _followButtonConfig?.followButtonHeight ??
                IsrDimens.twentyEight,
            child: Center(
              child: SizedBox(
                width: IsrDimens.sixteen,
                height: IsrDimens.sixteen,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _followButtonConfig?.loadingIndicatorColor ??
                        IsrColors.primaryTextColor,
                  ),
                ),
              ),
            ),
          );
        } else if (followRequestPending &&
            _reelData.postSetting?.isUnFollowButtonVisible == true) {
          return followChip(
            label: IsrTranslationFile.requested,
            filled: false,
            onTap: () => onTap(
              reelData: _reelData,
              postSectionType: widget.postSectionType,
              watchDuration: _postWatchDuration.inSeconds,
              apiCallBack: widget.onPressFollowButton != null
                  ? () => widget.onPressFollowButton!(_reelData, isFollowing)
                  : null,
            ),
          );
        } else if (!isFollowing &&
            !followRequestPending &&
            _reelData.postSetting?.isUnFollowButtonVisible == true) {
          final private = (timelineUser?.isPrivate ?? 0) == 1;
          final showRequest = FollowRelationshipUi.showRequestPrimaryLabel(
            isFollowing: isFollowing,
            isPrivateAccount: private,
            isRequested: timelineUser?.isRequested,
            followStatus: timelineUser?.followStatus,
          );
          return followChip(
            label: showRequest
                ? IsrTranslationFile.request
                : IsrTranslationFile.follow,
            filled: true,
            onTap: () => onTap(
              reelData: _reelData,
              postSectionType: widget.postSectionType,
              watchDuration: _postWatchDuration.inSeconds,
              apiCallBack: widget.onPressFollowButton != null
                  ? () => widget.onPressFollowButton!(_reelData, isFollowing)
                  : null,
            ),
          );
        } else if (isFollowing &&
            _reelData.postSetting?.isFollowButtonVisible == true) {
          return followChip(
            label: IsrTranslationFile.following,
            filled: false,
            onTap: () => onTap(
              reelData: _reelData,
              postSectionType: widget.postSectionType,
              watchDuration: _postWatchDuration.inSeconds,
              apiCallBack: widget.onPressFollowButton != null
                  ? () => widget.onPressFollowButton!(_reelData, isFollowing)
                  : null,
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
        watchDuration: _postWatchDuration.inSeconds,
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

  void _handleCommentClick() async {
    if (widget.reelsConfig.onTapComment == null) return;
    await widget.reelsConfig.onTapComment!(
      _reelData,
      _reelData.commentCount ?? 0,
    );
    await _fetchFloatingCommentsIfNeeded(forceRefresh: true);
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
        child: _buildVideoContent(
            media: media,
            key: _videoPlayerKeys[index],
            logIndex: '${widget.index}-$index}',
            isPreloaded: _isPreloaded || index != _currentPageNotifier.value),
      );
    }
  }

  void _moveToNextMedia() {
    if (_isPlaybackBlocked) return;
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

  /// Handles mute/unmute toggle for videos, and for image posts that carry a
  /// sound (Instagram-style image-with-audio).
  void _toggleMuteAndUnMute() {
    if (_isTextOnlyPost) return;
    final list = _reelData.mediaMetaDataList;
    if (list.isEmpty) return;
    final isVideo = list[_currentPageNotifier.value].mediaType == kVideoType;
    final hasImageSound =
        _isCurrentMediaImage && (_reelData.sound?.hasId ?? false);
    if (!isVideo && !hasImageSound) {
      return;
    }

    // Debounce audio operations to prevent flickering - increased to 250ms for stability
    _audioDebounceTimer?.cancel();
    _audioDebounceTimer =
        Timer(const Duration(milliseconds: 250), _performMuteToggle);
  }

  void _performMuteToggle() {
    VideoMuteController.toggle();
    setState(() {});
    // Volume change is handled by VideoPlayerWidget via didUpdateWidget.
    // For image-with-sound, apply mute state directly to the audio player.
    unawaited(
      _imageSoundPlayer?.setVolume(VideoMuteController.isMuted ? 0.0 : 1.0) ??
          Future.value(),
    );
    _videoOverlayTick.value++;
  }

  void _resetPostProgress() {
    _postWatchDuration = Duration.zero;
    _postProgress.value = 0.0;
    _resetMediaProgress();
  }

  void _resetMediaProgress() {
    _imageViewTimer?.cancel();
    unawaited(_stopImageSound());
    _currentMediaWatchDuration = Duration.zero;
    _currentMediaProgress.value = 0.0;
  }

  bool get _isCurrentMediaImage {
    final list = _reelData.mediaMetaDataList;
    final i = _currentPageNotifier.value;
    if (list.isEmpty || i < 0 || i >= list.length) return false;
    return list[i].mediaType == kPictureType;
  }

  Future<void> _resolveImageSoundUrlIfNeeded() async {
    if (_resolvedImageSoundUrl != null && _resolvedImageSoundUrl!.isNotEmpty) {
      return;
    }
    final sound = _reelData.sound;
    if (sound == null || !sound.hasId) return;
    final direct = (sound.previewUrl ?? '').trim();
    if (direct.isNotEmpty) {
      _resolvedImageSoundUrl = direct;
      return;
    }
    if (_resolvingImageSoundUrl) return;
    _resolvingImageSoundUrl = true;
    try {
      final useCase = IsmInjectionUtils.getUseCase<SoundLibraryUseCase>();
      final result = await useCase.getSoundTrackById(
        isLoading: false,
        soundId: sound.id,
      );
      final track = result.data;
      if (track != null && track.trackUrl.isNotEmpty) {
        _resolvedImageSoundUrl = track.trackUrl;
      }
    } catch (e) {
      debugPrint('Failed to resolve image sound url for ${sound.id}: $e');
    } finally {
      _resolvingImageSoundUrl = false;
    }
  }

  int _imageSoundSlideIndex() {
    final list = _reelData.mediaMetaDataList;
    final current = _currentPageNotifier.value;
    var imageIndex = 0;
    for (var i = 0; i < current && i < list.length; i++) {
      if (list[i].mediaType == kPictureType) {
        imageIndex++;
      }
    }
    return imageIndex;
  }

  Future<void> _startImageSoundIfNeeded() async {
    if (!mounted) return;
    if (!_isCurrentMediaImage) return;
    if (_shouldShowPaidLockOverlay) return;
    if (_isImagePaused || _isPlaybackBlocked) return;
    if (!_isCurrentReel) return;
    if (!widget.reelsConfig.isTabVisible()) return;
    if (IsrVideoReelConfig.isAppInBackground ||
        !IsrVideoReelConfig.allowsPlayback) {
      return;
    }
    final sound = _reelData.sound;
    if (sound == null || !sound.hasId) return;

    if (_resolvedImageSoundUrl == null || _resolvedImageSoundUrl!.isEmpty) {
      await _resolveImageSoundUrlIfNeeded();
    }
    if (!mounted ||
        !_isCurrentReel ||
        !widget.reelsConfig.isTabVisible() ||
        IsrVideoReelConfig.isAppInBackground ||
        !IsrVideoReelConfig.allowsPlayback) {
      return;
    }
    final url = _resolvedImageSoundUrl;
    if (url == null || url.isEmpty) return;

    if (!await IsrImageSoundRegistry.beginPlaybackFor(this)) return;
    if (!mounted ||
        !_isCurrentReel ||
        !widget.reelsConfig.isTabVisible() ||
        IsrVideoReelConfig.isAppInBackground ||
        !IsrVideoReelConfig.allowsPlayback ||
        !IsrImageSoundRegistry.ownsPlayback(this)) {
      return;
    }

    final player = _imageSoundPlayer ??= AudioPlayer();
    IsrImageSoundRegistry.register(player);
    try {
      final slideIndex = _imageSoundSlideIndex();
      final startOffset = Duration(
        seconds: slideIndex * PostSoundUtil.imageSoundSecondsPerSlide,
      );
      final clipKey = '$url#$slideIndex';
      if (_imageSoundLoadedUrl != clipKey) {
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(
          audioSourceFromUrlOrPath(url),
        );
        await player.seek(startOffset);
        _imageSoundLoadedUrl = clipKey;
      }
      if (!mounted ||
          !_isCurrentReel ||
          !widget.reelsConfig.isTabVisible() ||
          !IsrImageSoundRegistry.ownsPlayback(this)) {
        return;
      }
      await player.setVolume(VideoMuteController.isMuted ? 0.0 : 1.0);
      if (player.state != PlayerState.playing) {
        await player.resume();
      }
    } catch (e) {
      debugPrint('Image sound playback failed: $e');
    }
  }

  Future<void> _pauseImageSound() async {
    final player = _imageSoundPlayer;
    if (player == null) return;
    try {
      if (player.state == PlayerState.playing) {
        await player.pause();
      }
    } catch (_) {}
  }

  Future<void> _stopImageSound() async {
    final player = _imageSoundPlayer;
    IsrImageSoundRegistry.releaseOwner(this);
    if (player == null) return;
    try {
      await player.stop();
    } catch (_) {}
    _imageSoundLoadedUrl = null;
  }

  Future<void> _disposeImageSound() async {
    final player = _imageSoundPlayer;
    _imageSoundPlayer = null;
    _imageSoundLoadedUrl = null;
    IsrImageSoundRegistry.releaseOwner(this);
    if (player == null) return;
    IsrImageSoundRegistry.unregister(player);
    try {
      await player.stop();
      await player.release();
      await player.dispose();
    } catch (_) {}
  }

  /// Updates post-level watch duration and progress (all media combined).
  /// Call whenever current media progress changes (video callback or image timer).
  void _updatePostProgress() {
    final currentPage = _currentPageNotifier.value;
    final totalSeconds = _postTotalDurationSeconds;
    if (totalSeconds <= 0) return;

    // Sum duration of all fully-watched media (previous pages)
    var completedSeconds = 0;
    for (var i = 0;
        i < currentPage && i < _reelData.mediaMetaDataList.length;
        i++) {
      completedSeconds += _reelData.mediaMetaDataList[i].durationSeconds;
    }

    _postWatchDuration =
        Duration(seconds: completedSeconds) + _currentMediaWatchDuration;
    final progress = _postWatchDuration.inSeconds / totalSeconds;
    _postProgress.value = progress.clamp(0.0, 1.0);
    // debugPrint('IsmReelsVideoPlayerView: Post Duration {PostId:- ${_reelData.postId}, Post Duration: ${_postWatchDuration.inSeconds}, TotalDuration: ${totalSeconds}, Progress: ${_postProgress.value}}');
    if (_finalWatchDurationSeconds < _postWatchDuration.inSeconds ||
        _finalWatchProgress < _postProgress.value) {
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
    if (_shouldShowPaidLockOverlay ||
        _isPlaybackBlocked ||
        !IsrVideoReelConfig.allowsPlayback ||
        IsrVideoReelConfig.isAppInBackground) {
      return;
    }
    final shouldAutoMove =
        widget.reelsConfig.autoMoveNextMedia || widget.onVideoCompleted != null;
    final imageTotalDuration =
        Duration(seconds: _currentTimedAdvanceDurationSeconds);

    _imageViewTimer?.cancel();
    _isImagePaused = false;
    unawaited(_startImageSoundIfNeeded());

    const tick = Duration(milliseconds: 50);

    _imageViewTimer = Timer.periodic(tick, (timer) {
      if (_isImagePaused) return;

      _currentMediaWatchDuration += tick;

      final progress = _currentMediaWatchDuration.inMilliseconds /
          imageTotalDuration.inMilliseconds;

      _currentMediaProgress.value = progress.clamp(0.0, 1.0);
      _updatePostProgress();

      if (_currentMediaWatchDuration >= imageTotalDuration) {
        timer.cancel();
        _currentMediaWatchDuration = Duration.zero;

        // Only auto-move to next if configured to do so
        if (shouldAutoMove && !_isPlaybackBlocked) {
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
    unawaited(_stopImageSound());
  }

  bool _handlesPlayPauseState(PlayPauseVideoState state) =>
      IsrVideoReelConfig.playPauseAppliesToSection(
        widget.postSectionType,
        state,
      );

  void _setPlaybackBlocked(
    bool isPlaying, {
    bool pausePlayback = true,
  }) {
    final shouldBlock = !isPlaying;
    final isCurrentReel = _isCurrentReel;
    final tabVisible = widget.reelsConfig.isTabVisible();
    if (!shouldBlock) {
      _isPlaybackBlocked = false;
      if (!isCurrentReel) {
        unawaited(_stopImageSound());
        return;
      }
      if (pausePlayback && tabVisible && IsrVideoReelConfig.allowsPlayback) {
        _resumePlayback();
        if (_isCurrentMediaImage) {
          unawaited(_startImageSoundIfNeeded());
        }
      }
      return;
    }
    if (_isPlaybackBlocked == shouldBlock) {
      if (_isPlaybackBlocked && !isCurrentReel) {
        unawaited(_stopImageSound());
      }
      return;
    }
    _isPlaybackBlocked = shouldBlock;
    if (_isPlaybackBlocked) {
      unawaited(_stopImageSound());
      if (!pausePlayback) return;
      _isImagePaused = true;
      _imageViewTimer?.cancel();
      final key = _getCurrentVideoPlayerKey();
      VideoPlayerWidget.of(key)?.pause();
      return;
    }
    if (!pausePlayback) {
      if (isCurrentReel && tabVisible) {
        unawaited(_syncImageSoundAfterOverlay());
      }
      return;
    }
    if (isCurrentReel && tabVisible && IsrVideoReelConfig.allowsPlayback) {
      _resumePlayback();
      if (_isCurrentMediaImage) {
        unawaited(_startImageSoundIfNeeded());
      }
    }
  }

  Future<void> _syncImageSoundAfterOverlay() async {
    if (!mounted || _isPlaybackBlocked || !widget.reelsConfig.isTabVisible()) {
      return;
    }
    if (_isCurrentMediaImage && (_reelData.sound?.hasId ?? false)) {
      await _startImageSoundIfNeeded();
    } else {
      await _pauseImageSound();
    }
  }

  double _finalWatchProgress = 0.0;
  int _finalWatchDurationSeconds = 0;

  /// Logs view watch data when the user leaves (next/previous post or navigates away).
  /// Only sends once per view and if watch was meaningful (≥25% or ≥3s).
  void _logWatchPostEvent() {
    if (_finalWatchProgress >= 0.25 || _finalWatchDurationSeconds >= 3) {
      debugPrint(
          'IsmReelsVideoPlayerView: log Post View {PostId: ${_reelData.postId}, Post Duration: $_finalWatchDurationSeconds, Progress: $_finalWatchProgress}, TotalDuration: $_postTotalDurationSeconds');
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
          .logEvent(eventName, finalAnalyticsDataMap.removeEmptyValues());
    } catch (e) {
      debugPrint('❌ Error sending analytics event: $e');
      return null;
    }
  }
}
