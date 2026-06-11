import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/utils/isr_image_sound_registry.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/video_player_widget.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/comment_count_action_widget.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/like_action_widget.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/post_feed_carousel_keep_alive_page.dart';
import 'package:ism_video_reel_player/presentation/screens/media/sound_selection/sound_track_detail_screen.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/post_feed_media_carousel.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/instagram_follow_chip.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/instagram_meta_vertical_scroll.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/post_feed_scroll_scope.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:lottie/lottie.dart';

/// Single post card for scrollable post-card feed tabs.
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
  final Future<bool> Function(ReelsData reelsData, bool currentLiked)?
      onPressLikeButton;
  final Future<bool> Function(ReelsData reelsData, bool currentSaved)?
      onPressSaveButton;
  final Future<int> Function()? onTapComment;
  final Future<void> Function()? onTapShare;
  final Future<void> Function()? onTapUserProfile;
  final Future<bool> Function(ReelsData reelsData, bool currentFollow)?
      onPressFollowButton;
  final String? loggedInUserId;
  final String? logIndex;

  @override
  State<IsmPostFeedCardView> createState() => _IsmPostFeedCardViewState();
}

class _IsmPostFeedCardViewState extends State<IsmPostFeedCardView> {
  static const int _kPictureType = 0;
  static const Duration _kPageBadgeAutoHideDuration = Duration(seconds: 2);
  final ValueNotifier<int> _mediaPageIndex = ValueNotifier(0);
  final ValueNotifier<bool> _pageBadgeVisible = ValueNotifier(true);
  final ValueNotifier<bool> _muteFeedbackVisible = ValueNotifier(false);
  final ValueNotifier<bool> _metaAlternatorShowsSound = ValueNotifier(true);
  final ValueNotifier<int> _videoOverlayTick = ValueNotifier(0);
  final ValueNotifier<bool> _likeAnimationVisible = ValueNotifier(false);
  late final PageController _mediaPageController;
  final Map<int, GlobalKey> _videoPlayerKeys = {};
  final GlobalKey _instagramMetaRowKey = GlobalKey();
  OverlayEntry? _instagramMetaMenuOverlay;
  VoidCallback? _instagramMetaMenuDismissHandler;
  var _isInstagramCaptionExpanded = false;
  Timer? _pageBadgeTimer;
  AudioPlayer? _imageSoundPlayer;
  String? _resolvedImageSoundUrl;
  String? _imageSoundLoadedUrl;
  var _resolvingImageSoundUrl = false;
  Timer? _metaAlternatorTimer;
  static const Duration _kMetaAlternatorInterval = Duration(seconds: 3);
  Timer? _likeAnimationTimer;
  bool _isLiked = false;
  void Function({
    ReelsData? reelData,
    PostSectionType? postSectionType,
    int? watchDuration,
    Future<bool> Function()? apiCallBack,
  })? _onLikeTap;

  static const String _kInstagramCaptionMoreSuffix = '... more';

  PostConfig get _postConfig => widget.reelsConfig.postConfig;
  PostUIConfig? get _uiConfig => _postConfig.postUIConfig;
  ActionIconConfig? get _actionIconConfig => _uiConfig?.actionIconConfig;
  TextStyleConfig? get _textStyleConfig => _uiConfig?.textStyleConfig;
  UserProfileConfig? get _userProfileConfig => _uiConfig?.userProfileConfig;
  FollowButtonConfig? get _followButtonConfig => _uiConfig?.followButtonConfig;
  LocationConfig? get _locationConfig => _uiConfig?.locationConfig;
  MentionConfig? get _mentionConfig => _uiConfig?.mentionConfig;

  PostFeedUIConfig get _feedUi => _postConfig.resolvedPostFeedUIConfig;

  bool get _isInstagramStyle =>
      _feedUi.cardStyle == PostFeedCardStyle.instagram;

  bool get _showActionCounts => _feedUi.showActionCounts || _isInstagramStyle;

  static const Color _instagramLikeColor = Color(0xFFED4956);

  double get _postFeedActionIconSize =>
      _actionIconConfig?.iconSize ??
      (_isInstagramStyle ? IsrDimens.twentyFour : IsrDimens.twenty);

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

  Widget _buildActionIconRow(
      List<({Widget widget, bool showsCount})> segments) {
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
  double _fixedCardMediaAspectRatio() {
    if (!_isInstagramStyle) return _feedUi.mediaAspectRatio;
    return FeedMediaOrientation.aspectRatioForReel(
      _reel,
      feedUi: _feedUi,
      paidLockStillUrl:
          _shouldShowPaidLockOverlay ? _paidLockStillImageUrl() : null,
    );
  }

  ReelsData get _reel => widget.reelsData;

  /// Locked paid post: blur + lock overlay for viewers who do not own the post.
  /// Prefer [TimeLineData] lock flags when present — they are refreshed on unlock.
  bool get _shouldShowPaidLockOverlay {
    if (_isViewerPostAuthor) return false;
    final timeline = _timelinePost;
    final locked = timeline?.isLocked ?? _reel.isLocked;
    if (locked != true) return false;
    final reason =
        (timeline?.lockReason ?? _reel.lockReason ?? '').toLowerCase();
    return reason == 'paid' || (_reel.isPaid == true);
  }

  bool get _canDoubleTapToLike =>
      !_shouldShowPaidLockOverlay &&
      _reel.postSetting?.isLikeButtonVisible == true;

  Future<void> _triggerLikeAnimation() async {
    _likeAnimationTimer?.cancel();
    if (_isLiked != true) {
      _onLikeTap?.call(
        reelData: _reel,
        postSectionType: widget.postSectionType,
        apiCallBack: widget.onPressLikeButton != null
            ? () => widget.onPressLikeButton!(_reel, _isLiked)
            : null,
      );
    }
    _likeAnimationVisible.value = true;
    _likeAnimationTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        _likeAnimationVisible.value = false;
      }
    });
  }

  Future<void> _handleCommentTap() async {
    await widget.onTapComment?.call();
  }

  TimeLineData? get _timelinePost =>
      _reel.postData is TimeLineData ? _reel.postData as TimeLineData : null;

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

  /// Paid-locked posts show a blurred still frame only — never decode video URLs in an image widget.
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

    if (_reel.mediaMetaDataList.isNotEmpty) {
      final meta = _reel.mediaMetaDataList.first;
      if (_isVideoMedia(meta)) {
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
    final raw = _reel.priceAmount;
    if (raw == null) return '';
    final amount = raw is num ? raw.toString() : raw.toString().trim();
    if (amount.isEmpty) return '';
    final c = (_reel.priceCurrency ?? '').trim().toLowerCase();
    if (c.isEmpty || c == '-') return amount;
    if (c == 'coin' || c == 'coins') return amount;
    if (c == 'usd') return '\$$amount';
    return '$amount $c'.trim();
  }

  bool get _isCoinCurrency {
    final c = (_reel.priceCurrency ?? '').trim().toLowerCase();
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
                pausePlayback: false,
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
                  pausePlayback: false,
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

  Widget _buildPaidLockedLayer() {
    const blurSigma = 28.0;

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

    return chrome(
      blurredChild: SizedBox.expand(
        child: AppImage.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          cacheKey: imageUrl,
          cacheManager: IsrPostFeedImageCacheManager.instance,
          fadeAnimationEnable: false,
        ),
      ),
    );
  }

  VideoCacheManager get _videoCacheManager =>
      widget.videoCacheManager ?? VideoCacheManager();

  @override
  void initState() {
    super.initState();
    VideoMuteController.notifier.addListener(_onGlobalMuteChanged);
    _mediaPageController = PageController();
    _schedulePageBadgeAutoHide();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_syncImageSoundPlayback());
    });
    _startMetaAlternatorIfNeeded();
  }

  bool _mayPlayFeedMedia() =>
      widget.reelsConfig.isTabVisible() &&
      widget.isPostVisible &&
      IsrVideoReelConfig.allowsPlayback &&
      !IsrVideoReelConfig.isAppInBackground;

  Future<void> _stopAllCardMedia() async {
    for (final key in _videoPlayerKeys.values) {
      VideoPlayerWidget.of(key)?.pauseForLifecycle();
    }
    _videoOverlayTick.value++;
    await _pauseImageSound();
  }

  @override
  void didUpdateWidget(covariant IsmPostFeedCardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final lockStateChanged =
        oldWidget.reelsData.isLocked != widget.reelsData.isLocked ||
            oldWidget.reelsData.lockReason != widget.reelsData.lockReason;
    final timeline = _timelinePost;
    final oldTimeline = oldWidget.reelsData.postData is TimeLineData
        ? oldWidget.reelsData.postData as TimeLineData
        : null;
    final timelineLockChanged = timeline?.isLocked != oldTimeline?.isLocked ||
        timeline?.lockReason != oldTimeline?.lockReason;
    if (lockStateChanged || timelineLockChanged) {
      _mediaPageIndex.value = 0;
      if (_mediaPageController.hasClients) {
        _mediaPageController.jumpToPage(0);
      }
    }
    if (oldWidget.isPostVisible != widget.isPostVisible ||
        lockStateChanged ||
        timelineLockChanged) {
      if (!widget.isPostVisible && oldWidget.isPostVisible) {
        unawaited(_stopAllCardMedia());
      } else {
        _syncCarouselVideoPlayback();
        unawaited(_syncImageSoundPlayback());
      }
    }
    if (oldWidget.reelsData.postId != widget.reelsData.postId) {
      _isInstagramCaptionExpanded = false;
      _metaAlternatorShowsSound.value = true;
      _startMetaAlternatorIfNeeded();
    }
  }

  @override
  void dispose() {
    VideoMuteController.notifier.removeListener(_onGlobalMuteChanged);
    _mediaPageIndex.dispose();
    _pageBadgeVisible.dispose();
    _muteFeedbackVisible.dispose();
    _metaAlternatorShowsSound.dispose();
    _videoOverlayTick.dispose();
    _likeAnimationVisible.dispose();
    _mediaPageController.dispose();
    _pageBadgeTimer?.cancel();
    _metaAlternatorTimer?.cancel();
    _likeAnimationTimer?.cancel();
    _dismissInstagramMetaMenu();
    unawaited(_disposeImageSound());
    super.dispose();
  }

  void _dismissInstagramMetaMenu([String? selection]) {
    final handler = _instagramMetaMenuDismissHandler;
    if (handler == null) return;
    _instagramMetaMenuDismissHandler = null;
    handler();
    if (selection != null) {
      unawaited(_handleInstagramMetaMenuSelection(selection));
    }
  }

  Future<void> _handleInstagramMetaMenuSelection(String selection) async {
    if (selection == 'location') {
      await _openPostLocation();
    } else if (selection == 'sound') {
      await _openSoundDetails();
    }
  }

  void _onMediaPageChanged(int index) {
    if (_mediaPageIndex.value == index) return;
    _mediaPageIndex.value = index;
    _syncCarouselVideoPlayback();
    unawaited(_syncImageSoundPlayback());
    if (!_pageBadgeVisible.value) {
      _pageBadgeVisible.value = true;
    }
    _schedulePageBadgeAutoHide();
  }

  void _syncCarouselVideoPlayback() {
    for (final entry in _videoPlayerKeys.entries) {
      VideoPlayerWidget.of(entry.value)?.syncParentVisibility();
    }
  }

  void _forceResumeVisibleMedia() {
    if (!mounted || !_mayPlayFeedMedia()) return;
    for (final entry in _videoPlayerKeys.entries) {
      if (_isCarouselVideoPageActive(entry.key)) {
        VideoPlayerWidget.of(entry.value)?.forceResume();
      } else {
        VideoPlayerWidget.of(entry.value)?.pauseForLifecycle();
      }
    }
    unawaited(_syncImageSoundPlayback());
  }

  bool _isCarouselVideoPageActive(int index) =>
      _mayPlayFeedMedia() && _mediaPageIndex.value == index;

  void _schedulePageBadgeAutoHide() {
    _pageBadgeTimer?.cancel();
    _pageBadgeTimer = Timer(_kPageBadgeAutoHideDuration, () {
      if (!mounted || !_pageBadgeVisible.value) return;
      _pageBadgeVisible.value = false;
    });
  }

  void _onGlobalMuteChanged() {
    if (!mounted) return;
    unawaited(
      _imageSoundPlayer?.setVolume(VideoMuteController.isMuted ? 0.0 : 1.0) ??
          Future.value(),
    );
  }

  bool get _isCurrentMediaImage {
    final list = _reel.mediaMetaDataList;
    if (list.isEmpty) return false;
    final i = _mediaPageIndex.value;
    if (i < 0 || i >= list.length) return false;
    return list[i].mediaType == _kPictureType;
  }

  bool _shouldShowImageSoundMuteControl(int pageIndex) {
    final mediaList = _reel.mediaMetaDataList;
    if (mediaList.isEmpty) return false;
    final index = pageIndex.clamp(0, mediaList.length - 1);
    if (_isVideoMedia(mediaList[index])) return false;
    return _reel.sound?.hasId == true;
  }

  Future<void> _syncImageSoundPlayback() async {
    if (!mounted) return;
    if (!_mayPlayFeedMedia()) {
      await _pauseImageSound();
      return;
    }
    if (_isCurrentMediaImage && (_reel.sound?.hasId ?? false)) {
      await _startImageSoundIfNeeded();
    } else {
      await _pauseImageSound();
    }
  }

  Future<void> _resolveImageSoundUrlIfNeeded() async {
    if (_resolvedImageSoundUrl != null && _resolvedImageSoundUrl!.isNotEmpty) {
      return;
    }
    final sound = _reel.sound;
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

  Future<void> _startImageSoundIfNeeded() async {
    if (!mounted || !_isCurrentMediaImage || !_mayPlayFeedMedia()) return;
    final sound = _reel.sound;
    if (sound == null || !sound.hasId) return;

    if (_resolvedImageSoundUrl == null || _resolvedImageSoundUrl!.isEmpty) {
      await _resolveImageSoundUrlIfNeeded();
    }
    if (!mounted || !_mayPlayFeedMedia()) return;
    final url = _resolvedImageSoundUrl;
    if (url == null || url.isEmpty) return;

    if (!await IsrImageSoundRegistry.beginPlaybackFor(this)) return;
    if (!mounted ||
        !_mayPlayFeedMedia() ||
        !IsrImageSoundRegistry.ownsPlayback(this)) {
      return;
    }

    final player = _imageSoundPlayer ??= AudioPlayer();
    IsrImageSoundRegistry.register(player);
    try {
      if (_imageSoundLoadedUrl != url) {
        await player.setReleaseMode(ReleaseMode.loop);
        await player.setSource(audioSourceFromUrlOrPath(url));
        _imageSoundLoadedUrl = url;
      }
      if (!mounted ||
          !_mayPlayFeedMedia() ||
          !IsrImageSoundRegistry.ownsPlayback(this)) {
        return;
      }
      await player.setVolume(VideoMuteController.isMuted ? 0.0 : 1.0);
      if (player.state != PlayerState.playing) {
        await player.resume();
      }
    } catch (e) {
      debugPrint('Post feed image sound playback failed: $e');
    }
  }

  Future<void> _pauseImageSound() async {
    final player = _imageSoundPlayer;
    IsrImageSoundRegistry.releaseOwner(this);
    if (player == null) return;
    try {
      await player.stop();
    } catch (_) {}
  }

  Future<void> _disposeImageSound() async {
    final player = _imageSoundPlayer;
    _imageSoundPlayer = null;
    _imageSoundLoadedUrl = null;
    _resolvedImageSoundUrl = null;
    IsrImageSoundRegistry.releaseOwner(this);
    if (player == null) return;
    IsrImageSoundRegistry.unregister(player);
    try {
      await player.stop();
      await player.release();
      await player.dispose();
    } catch (_) {}
  }

  bool get _hasPostSound => _reel.sound?.hasId == true;

  bool get _hasPostLocation => _reel.placeDataList?.isListEmptyOrNull == false;

  bool get _hasAlternatingInstagramMeta => _hasPostSound && _hasPostLocation;

  void _startMetaAlternatorIfNeeded() {
    _metaAlternatorTimer?.cancel();
    if (!_isInstagramStyle || !_hasAlternatingInstagramMeta) return;
    _metaAlternatorTimer = Timer.periodic(_kMetaAlternatorInterval, (_) {
      if (!mounted) return;
      _metaAlternatorShowsSound.value = !_metaAlternatorShowsSound.value;
    });
  }

  Future<void> _openPostLocation() async {
    final placeList = _reel.placeDataList ?? [];
    if (placeList.isEmpty) return;
    await widget.reelsConfig.onTapPlace?.call(_reel, placeList);
  }

  Future<void> _openSoundDetails() async {
    final sound = _reel.sound;
    if (sound == null || !sound.hasId) return;

    IsrVideoReelConfig.suppressPlayback();
    try {
      var track = PostSoundUtil.soundTrackFromPostSound(sound);
      if (track.trackUrl.trim().isEmpty) {
        final useCase = IsmInjectionUtils.getUseCase<SoundLibraryUseCase>();
        final result = await useCase.getSoundTrackById(
          isLoading: true,
          soundId: sound.id,
        );
        final resolved = result.data;
        if (resolved == null || resolved.trackUrl.trim().isEmpty) return;
        track = resolved;
      }
      if (!mounted) return;
      await Navigator.of(context, rootNavigator: true).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => SoundTrackDetailScreen(
            track: track,
            useSoundsApi: SoundLibraryFeatureUtil.useSoundsApi,
          ),
        ),
      );
    } finally {
      if (mounted) {
        IsrVideoReelConfig.releasePlaybackSuppression();
      }
    }
  }

  void _onTapInstagramHeaderMeta() {
    if (_hasAlternatingInstagramMeta) {
      unawaited(_showInstagramMetaActionMenuPopup());
      return;
    }
    if (_hasPostSound) {
      unawaited(_openSoundDetails());
      return;
    }
    if (_hasPostLocation) {
      unawaited(_openPostLocation());
    }
  }

  Future<void> _showInstagramMetaActionMenuPopup() async {
    if (_instagramMetaMenuOverlay != null) {
      _dismissInstagramMetaMenu();
      return;
    }

    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final anchorContext = _instagramMetaRowKey.currentContext;
      final renderBox = anchorContext?.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) return;

      final offset = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      final overlay = Overlay.of(context, rootOverlay: true);
      var barrierActive = false;

      void removeOverlay() {
        _instagramMetaMenuOverlay?.remove();
        _instagramMetaMenuOverlay = null;
        _instagramMetaMenuDismissHandler = null;
        PostFeedOverlayMenuCoordinator.unregister(removeOverlay);
      }

      _instagramMetaMenuDismissHandler = removeOverlay;
      PostFeedOverlayMenuCoordinator.register(removeOverlay);

      _instagramMetaMenuOverlay = OverlayEntry(
        builder: (overlayContext) => Stack(
          children: [
            if (barrierActive)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _dismissInstagramMetaMenu,
                ),
              ),
            Positioned(
              left: offset.dx,
              top: offset.dy + size.height + IsrDimens.four,
              child: _buildInstagramMetaActionMenuPanel(
                onSelectLocation: () => _dismissInstagramMetaMenu('location'),
                onSelectSound: () => _dismissInstagramMetaMenu('sound'),
              ),
            ),
          ],
        ),
      );

      overlay.insert(_instagramMetaMenuOverlay!);

      // Avoid dismissing on the same pointer event that opened the menu.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _instagramMetaMenuOverlay == null) return;
        barrierActive = true;
        _instagramMetaMenuOverlay!.markNeedsBuild();
      });
    });
  }

  Widget _buildInstagramMetaActionMenuPanel({
    required VoidCallback onSelectLocation,
    required VoidCallback onSelectSound,
  }) =>
      Material(
        color: _feedUi.backgroundColor,
        elevation: 8,
        borderRadius: BorderRadius.circular(IsrDimens.twelve),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 240,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_hasPostLocation)
                _buildInstagramMetaMenuTapItem(
                  icon: Icons.location_on_outlined,
                  label: 'View location',
                  onTap: onSelectLocation,
                ),
              if (_hasPostSound)
                _buildInstagramMetaMenuTapItem(
                  icon: Icons.music_note_outlined,
                  label: 'View audio details',
                  onTap: onSelectSound,
                ),
            ],
          ),
        ),
      );

  Widget _buildInstagramMetaMenuTapItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: IsrDimens.edgeInsetsSymmetric(
              horizontal: IsrDimens.sixteen,
              vertical: IsrDimens.twelve,
            ),
            child: _buildInstagramMetaMenuRow(icon: icon, label: label),
          ),
        ),
      );

  Widget _buildInstagramMetaMenuRow({
    required IconData icon,
    required String label,
  }) =>
      Row(
        children: [
          Icon(icon, size: IsrDimens.twenty, color: _feedUi.headerTextColor),
          IsrDimens.boxWidth(IsrDimens.twelve),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: IsrStyles.primaryText14.copyWith(
                color: _feedUi.headerTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );

  Widget _buildInstagramHeaderMetaRow({required bool onMediaOverlay}) {
    if (!_hasPostSound && !_hasPostLocation) return const SizedBox.shrink();

    final textColor =
        onMediaOverlay ? IsrColors.white : _feedUi.secondaryTextColor;
    final iconColor =
        onMediaOverlay ? IsrColors.white : _feedUi.secondaryTextColor;
    final textStyle = IsrStyles.primaryText12.copyWith(
      color: textColor,
      fontWeight: onMediaOverlay ? FontWeight.w500 : FontWeight.w400,
    );

    Widget buildRow({
      required Key key,
      required IconData icon,
      required String label,
    }) =>
        Row(
          key: key,
          children: [
            Icon(icon, size: IsrDimens.twelve, color: iconColor),
            IsrDimens.boxWidth(IsrDimens.four),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ),
          ],
        );

    final sound = _reel.sound;
    final locationLabel =
        _locationLabel ?? _reel.placeDataList?.firstOrNull?.placeName ?? '';

    Widget content;
    if (_hasAlternatingInstagramMeta) {
      final locationRow = buildRow(
        key: const ValueKey('instagram_meta_location'),
        icon: Icons.location_on_rounded,
        label: locationLabel,
      );
      final soundRow = buildRow(
        key: const ValueKey('instagram_meta_sound'),
        icon: Icons.music_note_rounded,
        label: sound?.displayLabel ?? '',
      );
      content = ValueListenableBuilder<bool>(
        valueListenable: _metaAlternatorShowsSound,
        builder: (context, showsSound, _) => InstagramMetaVerticalScroll(
          showSecond: showsSound,
          firstChild: locationRow,
          secondChild: soundRow,
        ),
      );
    } else if (_hasPostSound) {
      content = buildRow(
        key: const ValueKey('instagram_meta_sound_only'),
        icon: Icons.music_note_rounded,
        label: sound?.displayLabel ?? '',
      );
    } else {
      content = buildRow(
        key: const ValueKey('instagram_meta_location_only'),
        icon: Icons.location_on_rounded,
        label: locationLabel,
      );
    }

    return TapHandler(
      key: _instagramMetaRowKey,
      onTap: _onTapInstagramHeaderMeta,
      child: Padding(
        padding: EdgeInsets.only(top: IsrDimens.two),
        child: SizedBox(
          height: IsrDimens.sixteen,
          child: content,
        ),
      ),
    );
  }

  /// Same mention source as Following/reels overlay; falls back to timeline tags.
  List<MentionMetaData> get _allPostMentions {
    if (!_reel.mentions.isListEmptyOrNull) return _reel.mentions;
    final timeline = _timelinePost;
    final mentions = timeline?.tags?.mentions;
    if (mentions.isListEmptyOrNull) return const [];
    return mentions!
        .map(
          (m) => MentionMetaData(
            userId: m.userId,
            username: m.username,
            name: m.name,
            avatarUrl: m.avatarUrl,
            tag: m.tag,
            textPosition: m.textPosition != null
                ? MentionPosition(
                    start: m.textPosition?.start,
                    end: m.textPosition?.end,
                  )
                : null,
            mediaPosition: m.mediaPosition != null
                ? MediaPosition(
                    position: m.mediaPosition?.position,
                    x: m.mediaPosition?.x,
                    y: m.mediaPosition?.y,
                  )
                : null,
          ),
        )
        .toList();
  }

  bool _mentionMatchesMediaPage(MentionMetaData mention, int pageIndex) {
    final pos = mention.mediaPosition?.position;
    if (pos == null) return pageIndex == 0;
    final posInt = pos.toInt();
    // APIs may send 0-based or 1-based carousel indices.
    return posInt == pageIndex || posInt == pageIndex + 1;
  }

  List<MentionMetaData> _mentionsForMediaPage(int pageIndex) {
    final all = _allPostMentions;
    if (all.isEmpty) return const [];

    // Single-image posts: always show the same "N people" affordance as Following.
    if (_reel.mediaMetaDataList.length <= 1) return all;

    final forPage = all
        .where((mention) => _mentionMatchesMediaPage(mention, pageIndex))
        .toList();
    if (forPage.isNotEmpty) return forPage;

    // Carousel slide has no positioned tags — keep parity with Following.
    return all;
  }

  Widget _buildMediaTaggedPeopleControl(int pageIndex) {
    final mentions = _mentionsForMediaPage(pageIndex);
    if (mentions.isEmpty) return const SizedBox.shrink();

    // Match Instagram: compact gray pill, white icon — same scale as mute/comment.
    final iconSize = IsrDimens.sixteen;

    return Positioned(
      bottom: IsrDimens.twelve,
      left: IsrDimens.twelve,
      child: GestureDetector(
        onTap: () => _onTapMentionData(mentions),
        child: Container(
          padding: IsrDimens.edgeInsetsAll(IsrDimens.six),
          decoration: _postFeedMuteButtonDecoration,
          child: Icon(
            Icons.person_rounded,
            size: iconSize,
            color: IsrColors.white,
          ),
        ),
      ),
    );
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
      _textStyleConfig?.userNameStyle ??
      IsrStyles.white14.copyWith(fontWeight: FontWeight.w600);

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
      final relative =
          Utility.formatPublishedTimeAgo(DateTime.parse(raw!).toLocal());
      return relative.isEmpty ? null : relative;
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<SocialPostBloc, SocialPostState>(
        listenWhen: (previous, current) => current is PlayPauseVideoState,
        listener: (context, state) {
          if (state is! PlayPauseVideoState) return;
          if (!IsrVideoReelConfig.playPauseAppliesToSection(
            widget.postSectionType,
            state,
          )) {
            return;
          }
          if (!state.play) {
            unawaited(_stopAllCardMedia());
            return;
          }
          if (!_mayPlayFeedMedia()) {
            unawaited(_stopAllCardMedia());
            return;
          }
          if (!state.pausePlayback) {
            unawaited(_syncImageSoundPlayback());
            return;
          }
          _forceResumeVisibleMedia();
        },
        child: _buildCardBody(context),
      );

  Widget _buildCardBody(BuildContext context) {
    final mediaCount = _reel.mediaMetaDataList.length;
    final showCarouselDots = _feedUi.showCarouselDots && mediaCount > 1;
    // Instagram: dots sit in the strip between media and the action row.
    final showDotsBelowMedia = showCarouselDots && _isInstagramStyle;

    return ColoredBox(
      color: _feedUi.backgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isInstagramStyle)
            ValueListenableBuilder<int>(
              valueListenable: _mediaPageIndex,
              builder: (context, pageIndex, _) {
                if (!_showHeaderAboveMedia(pageIndex)) {
                  return const SizedBox.shrink();
                }
                return _buildPostHeaderAboveMedia(context);
              },
            ),
          _buildMediaSection(context),
          if (showDotsBelowMedia)
            _buildCarouselDotsBelowMedia(context, mediaCount),
          _buildActionsSection(context),
          _buildEngagementSection(context),
        ],
      ),
    );
  }

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

    if (_shouldShowPaidLockOverlay) {
      return _wrapMediaFrame(
        fixedWidth: fixedWidth,
        fixedHeight: fixedHeight,
        child: _buildPaidLockedLayer(),
      );
    }

    final stack = Stack(
      fit: StackFit.expand,
      children: [
        if (mediaList.length > 1)
          PostFeedMediaCarousel(
            key: ValueKey('post_feed_media_${_reel.postId}'),
            controller: _mediaPageController,
            onPageChanged: _onMediaPageChanged,
            itemCount: mediaList.length,
            itemBuilder: (context, index) => PostFeedCarouselKeepAlivePage(
              child: _buildMediaItem(
                mediaList[index],
                index,
              ),
            ),
          )
        else
          _buildMediaItem(mediaList.first, 0),
        if (_isInstagramStyle)
          ValueListenableBuilder<int>(
            valueListenable: _mediaPageIndex,
            builder: (context, pageIndex, _) {
              if (!_showMediaOverlayHeader(pageIndex)) {
                return const SizedBox.shrink();
              }
              return _buildMediaTopOverlay(context);
            },
          )
        else if (_showMediaOverlayHeader(0))
          _buildMediaTopOverlay(context),
        if (_feedUi.showCarouselPageBadge && mediaList.length > 1)
          ValueListenableBuilder<int>(
            valueListenable: _mediaPageIndex,
            builder: (context, page, _) => ValueListenableBuilder<bool>(
              valueListenable: _pageBadgeVisible,
              builder: (context, showBadge, _) => Positioned(
                top: _showMediaOverlayHeader(page)
                    ? IsrDimens.twelve +
                        _postFeedActionIconSize +
                        IsrDimens.eight
                    : IsrDimens.twelve,
                right: IsrDimens.twelve,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: showBadge ? 1 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Container(
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
                        style: _textStyleConfig?.mediaCounterStyle ??
                            IsrStyles.white12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ValueListenableBuilder<int>(
          valueListenable: _mediaPageIndex,
          builder: (context, pageIndex, _) {
            if (!_shouldShowImageSoundMuteControl(pageIndex)) {
              return const SizedBox.shrink();
            }
            return Stack(
              children: [
                _buildImageSoundMuteControl(),
                ValueListenableBuilder<bool>(
                  valueListenable: _muteFeedbackVisible,
                  builder: (context, showFeedback, _) => showFeedback
                      ? _buildMuteToggleFeedback()
                      : const SizedBox.shrink(),
                ),
              ],
            );
          },
        ),
        ValueListenableBuilder<int>(
          valueListenable: _mediaPageIndex,
          builder: (context, pageIndex, _) =>
              _buildMediaTaggedPeopleControl(pageIndex),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _likeAnimationVisible,
          builder: (context, showLikeAnimation, _) {
            if (_shouldShowPaidLockOverlay || !showLikeAnimation) {
              return const SizedBox.shrink();
            }
            return Center(
              child: IgnorePointer(
                child: Lottie.asset(
                  AssetConstants.heartAnimation,
                  width: 250,
                  height: 250,
                  repeat: false,
                ),
              ),
            );
          },
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
      final probeListen =
          _isInstagramStyle && FeedMediaOrientation.shouldProbeForCurrentConfig;

      Widget frame(double aspectRatio) => AspectRatio(
            aspectRatio: aspectRatio,
            child: child,
          );

      if (probeListen) {
        return ClipRect(
          child: ListenableBuilder(
            listenable: FeedMediaOrientation.listenableForReel(
              _reel,
              paidLockStillUrl:
                  _shouldShowPaidLockOverlay ? _paidLockStillImageUrl() : null,
            ),
            builder: (context, _) => frame(_fixedCardMediaAspectRatio()),
          ),
        );
      }

      return ClipRect(
        child: frame(_fixedCardMediaAspectRatio()),
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
      final imageUrl = media.mediaUrl.trim();
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onDoubleTap: _canDoubleTapToLike ? _triggerLikeAnimation : null,
        child: AppImage.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          cacheKey: imageUrl,
          cacheManager: IsrPostFeedImageCacheManager.instance,
          fadeAnimationEnable: false,
          placeHolderWidget: (_, __) => PostFeedMediaPlaceholder(
            baseColor: _feedUi.dividerColor,
            highlightColor: _feedUi.backgroundColor,
          ),
        ),
      );
    }

    final playerKey = _videoPlayerKeys.putIfAbsent(
        index, () => GlobalKey(debugLabel: 'post_feed_video_$index'));

    final video = ClipRect(
      child: VideoPlayerWidget(
        key: playerKey,
        mediaUrl: media.mediaUrl,
        thumbnailUrl: media.thumbnailUrl,
        videoCacheManager: _videoCacheManager,
        isMuted: VideoMuteController.isMuted,
        aspectRatio: _fixedCardMediaAspectRatio(),
        videoFitOverride: BoxFit.cover,
        logIndex: '${widget.logIndex}-$index',
        visibilityManagedByParent: true,
        isParentVisible: () => _isCarouselVideoPageActive(index),
        postSectionType: widget.postSectionType,
        onVisibilityChanged: (_) {},
        onPlaybackStateChanged: () {
          if (mounted) _videoOverlayTick.value++;
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
            onDoubleTap: _canDoubleTapToLike ? _triggerLikeAnimation : null,
          ),
        ),
        ValueListenableBuilder<int>(
          valueListenable: _videoOverlayTick,
          builder: (context, _, __) => _buildVideoPlayPauseOverlay(playerKey),
        ),
        _buildVideoMuteControl(),
        ValueListenableBuilder<bool>(
          valueListenable: _muteFeedbackVisible,
          builder: (context, showFeedback, _) => showFeedback
              ? _buildMuteToggleFeedback()
              : const SizedBox.shrink(),
        ),
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
    _videoOverlayTick.value++;
  }

  void _toggleVideoMute() {
    VideoMuteController.toggle();
    unawaited(
      _imageSoundPlayer?.setVolume(VideoMuteController.isMuted ? 0.0 : 1.0) ??
          Future.value(),
    );
    _muteFeedbackVisible.value = true;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _muteFeedbackVisible.value = false;
    });
  }

  Widget _buildVideoPlayPauseOverlay(GlobalKey playerKey) {
    final playerState = VideoPlayerWidget.of(playerKey);
    if (playerState == null || !playerState.mounted) {
      return const SizedBox.shrink();
    }

    final showPlayIcon = playerState.showPausedIndicator;
    if (!showPlayIcon) {
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
              _buildFollowButton(variant: FollowChipVariant.feed),
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
          textColor: _userProfileConfig?.profileImagePlaceholderColor ??
              _feedUi.secondaryTextColor,
          name: '${_reel.firstName ?? ''} ${_reel.lastName ?? ''}',
        ),
      ),
    );
  }

  Widget _buildHeaderUserColumn() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TapHandler(
            onTap: () => widget.onTapUserProfile?.call(),
            child: Row(
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
          ] else if (_locationLabel != null && !_isInstagramStyle) ...[
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
          if (_isInstagramStyle)
            _buildInstagramHeaderMetaRow(onMediaOverlay: false),
        ],
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

  Widget _buildCarouselDotsBelowMedia(BuildContext context, int mediaCount) =>
      Padding(
        padding: IsrDimens.edgeInsetsSymmetric(
          vertical: _isInstagramStyle ? IsrDimens.six : IsrDimens.eight,
        ),
        child: Center(
          child: _buildCarouselDots(context, mediaCount),
        ),
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
                  _buildFollowButton(variant: FollowChipVariant.feed),
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
            textColor: _userProfileConfig?.profileImagePlaceholderColor ??
                IsrColors.white,
            name: '${_reel.firstName ?? ''} ${_reel.lastName ?? ''}',
          ),
        ),
      ),
    );
  }

  Widget _buildMediaUserTitle() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TapHandler(
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
          ),
          _buildInstagramHeaderMetaRow(onMediaOverlay: true),
        ],
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

  Widget _buildFollowButton({
    FollowChipVariant variant = FollowChipVariant.theme,
  }) {
    final timelineUser = _reel.postData is TimeLineData
        ? (_reel.postData as TimeLineData).user
        : null;
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
            width:
                _followButtonConfig?.followButtonMinWidth ?? IsrDimens.fiftySix,
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
                        IsrColors.white,
                  ),
                ),
              ),
            ),
          );
        }

        if (followRequestPending &&
            _reel.postSetting?.isUnFollowButtonVisible == true) {
          return _buildFollowChip(
            label: IsrTranslationFile.requested,
            filled: false,
            variant: variant,
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
            label: showRequest
                ? IsrTranslationFile.request
                : IsrTranslationFile.follow,
            filled: true,
            variant: variant,
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
            variant: variant,
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
    required FollowChipVariant variant,
  }) =>
      InstagramFollowChip(
        label: label,
        filled: filled,
        onTap: onTap,
        variant: variant,
        followButtonConfig: _followButtonConfig,
        headerTextColor: _feedUi.headerTextColor,
        feedBackgroundIsDark: _feedUi.backgroundColor.computeLuminance() < 0.5,
        followButtonTextStyle: _textStyleConfig?.followButtonTextStyle,
        followingButtonTextStyle: _textStyleConfig?.followingButtonTextStyle,
        textShadows: variant == FollowChipVariant.reelsOverlay
            ? const [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 3,
                  color: Color(0x99000000),
                ),
              ]
            : null,
      );

  Widget _buildPostFeedMuteIcon({required double size}) => Icon(
        VideoMuteController.isMuted
            ? Icons.volume_off_rounded
            : Icons.volume_up_rounded,
        size: size,
        color: Colors.white,
      );

  BoxDecoration get _postFeedMuteButtonDecoration => BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        shape: BoxShape.circle,
      );

  Widget _buildVideoMuteControl() => Positioned(
        bottom: IsrDimens.twelve,
        right: IsrDimens.twelve,
        child: ListenableBuilder(
          listenable: VideoMuteController.notifier,
          builder: (context, _) => GestureDetector(
            onTap: _toggleVideoMute,
            child: Container(
              padding: IsrDimens.edgeInsetsAll(IsrDimens.six),
              decoration: _postFeedMuteButtonDecoration,
              child: _buildPostFeedMuteIcon(size: IsrDimens.sixteen),
            ),
          ),
        ),
      );

  Widget _buildImageSoundMuteControl() => Positioned(
        bottom: IsrDimens.twelve,
        right: IsrDimens.twelve,
        child: ListenableBuilder(
          listenable: VideoMuteController.notifier,
          builder: (context, _) => GestureDetector(
            onTap: _toggleVideoMute,
            child: Container(
              padding: IsrDimens.edgeInsetsAll(IsrDimens.six),
              decoration: _postFeedMuteButtonDecoration,
              child: _buildPostFeedMuteIcon(size: IsrDimens.sixteen),
            ),
          ),
        ),
      );

  Widget _buildMuteToggleFeedback() => IgnorePointer(
        child: Center(
          child: Container(
            padding: IsrDimens.edgeInsetsAll(IsrDimens.sixteen),
            decoration: _postFeedMuteButtonDecoration,
            child: _buildPostFeedMuteIcon(size: IsrDimens.thirtyTwo),
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
        _feedUi.showCarouselDots && mediaCount > 1 && !_isInstagramStyle;

    final actionRow = Row(
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
    );

    return Padding(
      padding: IsrDimens.edgeInsetsSymmetric(
        horizontal: IsrDimens.twelve,
        vertical: _isInstagramStyle ? IsrDimens.four : IsrDimens.eight,
      ),
      child: showDotsInBar
          ? Stack(
              alignment: Alignment.center,
              children: [
                actionRow,
                _buildCarouselDots(context, mediaCount),
              ],
            )
          : actionRow,
    );
  }

  Widget _buildLeftActionIcons() {
    if (_reel.postSetting?.isLikeButtonVisible != true) {
      return _buildLeftActionIconsWithoutLike();
    }

    return LikeActionWidget(
      postId: _reel.postId ?? '',
      builder: (isLoading, isLiked, likeCount, onTap) {
        _isLiked = isLiked;
        _reel.isLiked = isLiked;
        _reel.likesCount = likeCount;
        _onLikeTap = onTap;
        final liked = isLiked == true;
        final count = likeCount > 0 ? likeCount : (_reel.likesCount ?? 0);
        final likeCountLabel = _showActionCounts && count > 0
            ? Utility.formatEngagementCount(count)
            : null;

        final segments = <({Widget widget, bool showsCount})>[
          (
            widget: _iconAction(
              icon: liked
                  ? (_actionIconConfig?.likeIconSelected ??
                      AssetConstants.icPostLikeIconSelected)
                  : (_actionIconConfig?.likeIconUnselected ??
                      AssetConstants.icPostLikeIcon),
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
      segments.add((
        widget: CommentCountActionWidget(
          postId: _reel.postId ?? '',
          builder: (commentCount) {
            _reel.commentCount = commentCount;
            final commentCountLabel = _showActionCounts && commentCount > 0
                ? Utility.formatEngagementCount(commentCount)
                : null;
            return _iconAction(
              icon: _actionIconConfig?.commentIcon ??
                  AssetConstants.icPostCommentIcon,
              countLabel: commentCountLabel,
              onTap: _handleCommentTap,
            );
          },
        ),
        showsCount: false,
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

  Widget _buildCarouselDots(BuildContext context, int mediaCount) =>
      ValueListenableBuilder<int>(
        valueListenable: _mediaPageIndex,
        builder: (context, page, _) => Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            mediaCount,
            (i) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (!_mediaPageController.hasClients ||
                    _mediaPageIndex.value == i) {
                  return;
                }
                _mediaPageController.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                );
              },
              child: Container(
                width: _isInstagramStyle ? IsrDimens.five : IsrDimens.six,
                height: _isInstagramStyle ? IsrDimens.five : IsrDimens.six,
                margin:
                    IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.two),
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
                  color: applyThemeColor
                      ? (iconColor ?? _feedUi.actionIconColor)
                      : null,
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

  void _onTapMentionData(List<MentionMetaData> mentionDataList) {
    if (mentionDataList.isListEmptyOrNull) return;
    widget.reelsConfig.onTapMentionTag?.call(_reel, mentionDataList);
  }

  TextStyle get _feedCaptionBodyStyle =>
      _textStyleConfig?.descriptionStyle ??
      IsrStyles.primaryText14.copyWith(color: _feedUi.headerTextColor);

  /// Shared feed link/hashtag blue (#006CD8).
  TextStyle get _feedLinkTextStyle => _feedCaptionBodyStyle.copyWith(
        color: const Color(0xFF006CD8),
        fontWeight: FontWeight.w400,
      );

  TextStyle get _feedUrlTextStyle =>
      _feedLinkTextStyle.copyWith(decoration: TextDecoration.underline);

  TextStyle get _feedHashtagTextStyle => _feedLinkTextStyle;

  TextStyle get _feedCaptionMoreStyle => _feedCaptionBodyStyle.copyWith(
        color: _feedUi.secondaryTextColor,
        fontWeight: FontWeight.w400,
      );

  TextStyle get _feedMetaTextStyle =>
      _textStyleConfig?.locationStyle ??
      IsrStyles.primaryText12.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: _feedUi.headerTextColor,
      );

  double get _feedMetaTextSize => _feedMetaTextStyle.fontSize ?? 12;

  double get _feedMetaIconSize => _feedMetaTextSize * 0.9;

  TextStyle get _feedTimestampTextStyle => IsrStyles.primaryText12.copyWith(
        color: _feedUi.secondaryTextColor,
      );

  TextStyle get _feedUsernameStyle => IsrStyles.primaryText14.copyWith(
        fontWeight: FontWeight.w600,
        color: _feedUi.headerTextColor,
      );

  ({String caption, String hashtags}) _splitCaptionAndHashtags(
      String description) {
    final index = description.indexOf('#');
    if (index < 0) {
      return (caption: description, hashtags: '');
    }
    return (
      caption: description.substring(0, index).trimRight(),
      hashtags: description.substring(index).trim(),
    );
  }

  TextSpan _buildDescriptionTextSpan(String text) =>
      Utility.buildPostDescriptionTextSpan(
        text,
        _reel.mentions,
        _reel.tagDataList ?? [],
        _feedCaptionBodyStyle,
        (mention) => _onTapMentionData([mention]),
        mentionStyle: _textStyleConfig?.mentionStyle ??
            _feedCaptionBodyStyle.copyWith(fontWeight: FontWeight.w600),
        hashtagStyle: _textStyleConfig?.hashtagStyle ?? _feedHashtagTextStyle,
        urlStyle: _textStyleConfig?.urlStyle ?? _feedUrlTextStyle,
      );

  Color get _feedMetaIconColor =>
      _locationConfig?.locationIconColor ??
      _mentionConfig?.mentionIconColor ??
      _feedUi.headerTextColor;

  Widget _buildMetaDotSeparator() => Padding(
        padding: IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.six),
        child: Text(
          '·',
          style: _feedMetaTextStyle.copyWith(
            fontSize: (_feedMetaTextStyle.fontSize ?? 12) + 4,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      );

  /// Material icons include invisible side padding; shift so the glyph lines up
  /// with caption / timestamp text on the left edge.
  Widget _buildOpticallyAlignedMetaIcon(
    Widget icon, {
    required double size,
    double leftInset = 0,
  }) =>
      SizedBox(
        width: size - leftInset,
        height: size,
        child: OverflowBox(
          maxWidth: size,
          alignment: Alignment.centerLeft,
          child: Transform.translate(
            offset: Offset(-leftInset, 0),
            child: icon,
          ),
        ),
      );

  Widget _buildCompactMetaItem({
    required Widget icon,
    required String label,
    required double iconSpacing,
    VoidCallback? onTap,
  }) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        icon,
        IsrDimens.boxWidth(iconSpacing),
        Text(
          label,
          style: _feedMetaTextStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
    if (onTap == null) return content;
    return TapHandler(onTap: onTap, child: content);
  }

  Widget _buildFeedLocationIcon() {
    final size = _locationConfig?.locationIconSize ?? _feedMetaIconSize;
    final Widget icon;
    if (_locationConfig?.locationIcon != null) {
      icon = AppImage.svg(
        _locationConfig!.locationIcon!,
        width: size,
        height: size,
        color: _feedMetaIconColor,
      );
    } else {
      icon = Icon(
        Icons.location_on,
        size: size,
        color: _feedMetaIconColor,
      );
    }
    return _buildOpticallyAlignedMetaIcon(icon, size: size, leftInset: 2.5);
  }

  Widget _buildFeedMentionIcon() {
    final size = _mentionConfig?.mentionIconSize ?? _feedMetaIconSize;
    final Widget icon;
    if (_mentionConfig?.mentionIcon != null) {
      icon = AppImage.svg(
        _mentionConfig!.mentionIcon!,
        width: size,
        height: size,
        color: _feedMetaIconColor,
      );
    } else {
      icon = Icon(
        Icons.people,
        size: size,
        color: _feedMetaIconColor,
      );
    }
    return _buildOpticallyAlignedMetaIcon(icon, size: size, leftInset: 1.5);
  }

  /// Compact meta row with icons for location and tagged people.
  Widget _buildCompactInstagramMetaLine({
    required bool hasLocation,
    required bool hasMentions,
  }) {
    final mentionList = _reel.mentions;
    final placeList = _reel.placeDataList ?? [];
    final mentionLabel = hasMentions
        ? (mentionList.length == 1
            ? mentionList.first.username ?? ''
            : '${mentionList.length} people')
        : null;
    final locationLabel = hasLocation
        ? (_locationLabel ?? placeList.firstOrNull?.placeName)
        : null;

    final segments = <Widget>[];
    void addSegment(Widget segment) {
      if (segments.isNotEmpty) {
        segments.add(_buildMetaDotSeparator());
      }
      segments.add(segment);
    }

    if (locationLabel.isStringEmptyOrNull == false) {
      addSegment(
        _buildCompactMetaItem(
          icon: _buildFeedLocationIcon(),
          label: locationLabel!,
          iconSpacing: _locationConfig?.locationIconSpacing ?? IsrDimens.four,
          onTap: () async {
            await widget.reelsConfig.onTapPlace?.call(_reel, placeList);
          },
        ),
      );
    }
    if (mentionLabel.isStringEmptyOrNull == false) {
      addSegment(
        _buildCompactMetaItem(
          icon: _buildFeedMentionIcon(),
          label: mentionLabel!,
          iconSpacing: _mentionConfig?.mentionIconSpacing ?? IsrDimens.four,
          onTap: () => _onTapMentionData(mentionList),
        ),
      );
    }
    if (segments.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Wrap(
        spacing: 0,
        runSpacing: IsrDimens.four,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: segments,
      ),
    );
  }

  bool _captionSpanFitsOneLine({
    required BuildContext context,
    required double maxWidth,
    required TextSpan span,
  }) {
    final painter = TextPainter(
      text: span,
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout(maxWidth: maxWidth);
    return !painter.didExceedMaxLines;
  }

  bool _instagramCaptionNeedsExpansion({
    required BuildContext context,
    required double maxWidth,
    required TextSpan usernameSpan,
    required String caption,
    required bool hasHashtags,
    required bool hasLocation,
    required bool hasMentions,
  }) {
    if (hasHashtags) return true;
    if (!_isInstagramStyle && (hasLocation || hasMentions)) return true;
    if (caption.isEmpty) return false;
    return !_captionSpanFitsOneLine(
      context: context,
      maxWidth: maxWidth,
      span: TextSpan(
        children: [
          usernameSpan,
          _buildDescriptionTextSpan(caption),
        ],
      ),
    );
  }

  void _toggleInstagramCaptionExpansion() {
    setState(() => _isInstagramCaptionExpanded = !_isInstagramCaptionExpanded);
  }

  TextSpan _buildCollapsedInstagramCaptionSpan({
    required BuildContext context,
    required double maxWidth,
    required TextSpan usernameSpan,
    required String caption,
    required bool showMore,
  }) {
    final moreSpan = TextSpan(
      text: _kInstagramCaptionMoreSuffix,
      style: _feedCaptionMoreStyle,
    );

    if (!showMore) {
      return TextSpan(
        children: [
          usernameSpan,
          if (caption.isNotEmpty) _buildDescriptionTextSpan(caption),
        ],
      );
    }

    if (caption.isEmpty) {
      return TextSpan(children: [usernameSpan, moreSpan]);
    }

    var low = 0;
    var high = caption.length;
    var best = 0;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final candidate = caption.substring(0, mid).trimRight();
      final span = TextSpan(
        children: [
          usernameSpan,
          if (candidate.isNotEmpty) _buildDescriptionTextSpan(candidate),
          moreSpan,
        ],
      );
      if (_captionSpanFitsOneLine(
        context: context,
        maxWidth: maxWidth,
        span: span,
      )) {
        best = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    final truncated = caption.substring(0, best).trimRight();
    return TextSpan(
      children: [
        usernameSpan,
        if (truncated.isNotEmpty) _buildDescriptionTextSpan(truncated),
        moreSpan,
      ],
    );
  }

  Widget _buildExpandedInstagramCaption(
    TextSpan usernameSpan,
    ({String caption, String hashtags}) parts,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                usernameSpan,
                if (parts.caption.isNotEmpty)
                  _buildDescriptionTextSpan(parts.caption),
              ],
            ),
          ),
          if (parts.hashtags.isNotEmpty) ...[
            IsrDimens.boxHeight(IsrDimens.two),
            RichText(text: _buildDescriptionTextSpan(parts.hashtags)),
          ],
        ],
      );

  Widget _buildCollapsedInstagramCaption({
    required BuildContext context,
    required double maxWidth,
    required TextSpan usernameSpan,
    required ({String caption, String hashtags}) parts,
    required bool showMore,
  }) =>
      RichText(
        maxLines: 1,
        overflow: TextOverflow.clip,
        text: _buildCollapsedInstagramCaptionSpan(
          context: context,
          maxWidth: maxWidth,
          usernameSpan: usernameSpan,
          caption: parts.caption,
          showMore: showMore,
        ),
      );

  Widget _buildInstagramEngagementContent(
    BuildContext context, {
    required String description,
    required bool hasMentions,
    required bool hasLocation,
    required bool showTimestamp,
    required String? timestampLabel,
  }) {
    final hasMeta = !_isInstagramStyle && (hasMentions || hasLocation);
    final parts =
        description.isNotEmpty ? _splitCaptionAndHashtags(description) : null;
    final usernameSpan = TextSpan(
      text: '${_reel.userName ?? ''} ',
      style: _feedUsernameStyle,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final needsExpansion = _instagramCaptionNeedsExpansion(
          context: context,
          maxWidth: maxWidth,
          usernameSpan: usernameSpan,
          caption: parts?.caption ?? '',
          hasHashtags: parts?.hashtags.isNotEmpty ?? false,
          hasLocation: hasLocation,
          hasMentions: hasMentions,
        );
        final showCaption = description.isNotEmpty;
        final showMeta = _isInstagramCaptionExpanded && hasMeta;

        return GestureDetector(
          onTap: needsExpansion ? _toggleInstagramCaptionExpansion : null,
          behavior: HitTestBehavior.translucent,
          child: Container(
            width: double.infinity,
            alignment: AlignmentDirectional.centerStart,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showCaption)
                  _isInstagramCaptionExpanded
                      ? _buildExpandedInstagramCaption(usernameSpan, parts!)
                      : _buildCollapsedInstagramCaption(
                          context: context,
                          maxWidth: maxWidth,
                          usernameSpan: usernameSpan,
                          parts: parts!,
                          showMore: needsExpansion,
                        ),
                if (showMeta) ...[
                  if (showCaption) IsrDimens.boxHeight(IsrDimens.eight),
                  _buildCompactInstagramMetaLine(
                    hasLocation: hasLocation,
                    hasMentions: hasMentions,
                  ),
                ],
                if (showTimestamp && timestampLabel != null) ...[
                  if (showCaption || showMeta)
                    SizedBox(
                      width: double.infinity,
                      height: showMeta ? IsrDimens.two : IsrDimens.four,
                    ),
                  Text(
                    timestampLabel,
                    style: _feedTimestampTextStyle,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEngagementSection(BuildContext context) {
    final likes = _reel.likesCount ?? 0;
    final description = _reel.description?.trim() ?? '';
    final showLikesLine = likes > 0 && !_showActionCounts;
    final showTimestamp = (_feedUi.showPostTimestamp || _isInstagramStyle) &&
        _postTimestampLabel != null;
    final showLegacyLocation = _locationLabel != null && !_isInstagramStyle;
    final hasMentions = _reel.mentions.isListEmptyOrNull == false;
    final hasLocation = _reel.placeDataList?.isListEmptyOrNull == false;
    final showInstagramTimestamp =
        _isInstagramStyle && showTimestamp && _postTimestampLabel != null;
    final showInstagramEngagement =
        _isInstagramStyle && (description.isNotEmpty || showInstagramTimestamp);

    return Padding(
      padding: IsrDimens.edgeInsetsSymmetric(
        horizontal: IsrDimens.twelve,
        vertical: _isInstagramStyle ? IsrDimens.four : IsrDimens.eight,
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
          if (showLegacyLocation) ...[
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
          if (showInstagramEngagement) ...[
            if (showLikesLine || showLegacyLocation)
              IsrDimens.boxHeight(IsrDimens.six),
            _buildInstagramEngagementContent(
              context,
              description: description,
              hasMentions: hasMentions,
              hasLocation: hasLocation,
              showTimestamp: showInstagramTimestamp,
              timestampLabel: _postTimestampLabel,
            ),
          ] else if (description.isNotEmpty) ...[
            if (showLikesLine || showLegacyLocation)
              IsrDimens.boxHeight(IsrDimens.six),
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
                  Utility.buildPostDescriptionTextSpan(
                    description,
                    _reel.mentions,
                    _reel.tagDataList ?? const [],
                    _textStyleConfig?.descriptionStyle ?? _feedCaptionBodyStyle,
                    (mention) {
                      widget.reelsConfig.onTapMentionTag?.call(
                        _reel,
                        [mention],
                      );
                    },
                    mentionStyle: _textStyleConfig?.mentionStyle,
                    hashtagStyle: _textStyleConfig?.hashtagStyle,
                    urlStyle: _textStyleConfig?.urlStyle,
                  ),
                ],
              ),
            ),
          ] else if (showTimestamp) ...[
            if (showLikesLine || showLegacyLocation || description.isNotEmpty)
              IsrDimens.boxHeight(IsrDimens.four),
            Text(
              _postTimestampLabel!,
              style: IsrStyles.primaryText12.copyWith(
                color: _feedUi.secondaryTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
