import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/isr_utils.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Custom Reels Player for both Video and Photo content
class IsmReelsVideoPlayerView extends StatefulWidget {
  const IsmReelsVideoPlayerView({
    super.key,
    this.videoCacheManager,
    this.reelsData,
    this.onPressMoreButton,
    this.onCreatePost,
    this.onPressFollowButton,
    this.onPressLikeButton,
  });

  final VideoCacheManager? videoCacheManager;
  final ReelsData? reelsData;
  final VoidCallback? onPressMoreButton;
  final Future<void> Function()? onCreatePost;
  final Future<void> Function()? onPressFollowButton;
  final Future<void> Function()? onPressLikeButton;

  @override
  State<IsmReelsVideoPlayerView> createState() => _IsmReelsVideoPlayerViewState();
}

class _IsmReelsVideoPlayerViewState extends State<IsmReelsVideoPlayerView>
    with SingleTickerProviderStateMixin {
  VideoCacheManager get _videoCacheManager => widget.videoCacheManager ?? VideoCacheManager();

  // Add constants for media types
  static const int kPictureType = 0;
  static const int kVideoType = 1;
  TapGestureRecognizer? _tapGestureRecognizer;

  VideoPlayerController? _videoPlayerController;

  var _isPlaying = true;

  var _isPlayPauseActioned = false;

  // Track disposal to avoid using controller after dispose
  var _isDisposed = false;

  // Incremented on each init/swap to invalidate stale async completions
  int _controllerGeneration = 0;

  final ValueNotifier<bool> _isFollowLoading = ValueNotifier(false);

  final ValueNotifier<bool> _isExpandedDescription = ValueNotifier(false);

  final ValueNotifier<bool> _isSaveLoading = ValueNotifier(false);

  final ValueNotifier<bool> _isLikeLoading = ValueNotifier(false);

  var _isMuted = false;

  final _maxLengthToShow = 50;

  late ReelsData _reelData;

  @override
  void initState() {
    super.initState();
    _onStartInit();
  }

  bool get _controllerReady =>
      _videoPlayerController != null && !_isDisposed && _videoPlayerController!.value.isInitialized;

  void _onStartInit() async {
    _reelData = widget.reelsData!;
    _isMuted = false;
    _tapGestureRecognizer = TapGestureRecognizer();
    debugPrint(
        'IsmReelsVideoPlayerView ...Post by ...${_reelData.userName}\n Post url ${_reelData.mediaUrl}');
    if (_reelData.mediaType == kVideoType) {
      await _initializeVideoPlayer();
      mountUpdate();
    }
  }

  /// Method For Update The Tree Carefully
  void mountUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  //initialize vide player controller and initialization to use cache
  Future<void> _initializeVideoPlayer() async {
    if (_reelData.mediaUrl.isStringEmptyOrNull != false) return;

    final videoUrl = _reelData.mediaUrl;
    debugPrint('IsmReelsVideoPlayerView....initializeVideoPlayer video url $videoUrl');

    try {
      // Start new generation for this init
      _controllerGeneration++;
      final currentGen = _controllerGeneration;
      // First, try to get cached controller
      _videoPlayerController = _videoCacheManager.getCachedController(videoUrl);

      if (_videoPlayerController != null) {
        // Use cached controller
        debugPrint('IsmReelsVideoPlayerView....Using cached video controller for $videoUrl');
        _setupVideoController();
        return;
      } else {
        debugPrint('IsmReelsVideoPlayerView...._videoPlayerController is null for $videoUrl');
      }

      // If not cached, check if it's being initialized
      if (_videoCacheManager.isVideoInitializing(videoUrl)) {
        debugPrint('IsmReelsVideoPlayerView....Video is being initialized, waiting...');
        // Wait a bit and try again
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted || _isDisposed || currentGen != _controllerGeneration) return;
        _videoPlayerController = _videoCacheManager.getCachedController(videoUrl);
        if (_videoPlayerController != null) {
          _setupVideoController();
          return;
        }
      } else {
        debugPrint('IsmReelsVideoPlayerView....Video is not being initialized, waiting...');
      }

      // If still not available, initialize normally (fallback)
      await _initializeVideoControllerNormally(videoUrl, expectedGen: currentGen);
    } catch (e) {
      debugPrint('IsmReelsVideoPlayerView...catch video url ${_reelData.mediaUrl}');
      IsrVideoReelUtility.debugCatchLog(error: e);
    }
  }

  // Fallback initialization method
  Future<void> _initializeVideoControllerNormally(String videoUrl, {int? expectedGen}) async {
    debugPrint('IsmReelsVideoPlayerView....Initializing video controller normally $videoUrl');
    var mediaUrl = videoUrl;
    if (mediaUrl.startsWith('http:')) {
      mediaUrl = mediaUrl.replaceFirst('http:', 'https:');
    }

    _videoPlayerController = IsrVideoReelUtility.isLocalUrl(mediaUrl)
        ? VideoPlayerController.file(File(mediaUrl))
        : VideoPlayerController.networkUrl(Uri.parse(mediaUrl));

    if (_videoPlayerController == null) return;

    await _videoPlayerController?.initialize();
    if (!mounted || _isDisposed || (expectedGen != null && expectedGen != _controllerGeneration)) {
      try {
        await _videoPlayerController?.dispose();
      } catch (_) {}
      _videoPlayerController = null;
      return;
    }
    _setupVideoController();
  }

  // Setup video controller settings
  void _setupVideoController() {
    debugPrint('_setupVideoController....setup video controller');
    if (_isDisposed) return;
    _videoPlayerController?.play();
    _videoPlayerController?.setVolume(1.0);
    _videoPlayerController?.setLooping(true);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _tapGestureRecognizer?.dispose();
    // Mark as not visible in cache manager
    if (_reelData.mediaUrl.isStringEmptyOrNull == false) {
      _videoCacheManager.markAsNotVisible(_reelData.mediaUrl);
    }

    // Only dispose if this controller is not in cache
    if (_videoPlayerController != null &&
        _reelData.mediaUrl.isStringEmptyOrNull == false &&
        !_videoCacheManager.isVideoCached(_reelData.mediaUrl)) {
      _videoPlayerController?.pause();
      _videoPlayerController?.dispose();
    } else {
      // Just pause if it's cached
      _videoPlayerController?.pause();
    }

    _videoPlayerController = null;
    super.dispose();
  }

  Widget _buildMediaContent() {
    if (_reelData.showBlur == true) {
      return AppImage.network(
        _reelData.thumbnailUrl,
        width: IsrDimens.getScreenWidth(context),
        height: IsrDimens.getScreenHeight(context),
        fit: BoxFit.contain,
      );
    } else if (_reelData.mediaType == kPictureType) {
      return AppImage.network(
        _reelData.mediaUrl,
        width: IsrDimens.getScreenWidth(context),
        height: IsrDimens.getScreenHeight(context),
        fit: BoxFit.contain,
      );
    } else {
      return Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          if (_controllerReady) ...[
            RepaintBoundary(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  child: Builder(
                    builder: (context) {
                      final controller = _videoPlayerController;
                      if (controller == null) {
                        return const SizedBox.shrink();
                      }
                      final size = controller.value.size;
                      final aspect = controller.value.aspectRatio;
                      return SizedBox(
                        height: size.height,
                        width: size.width,
                        child: AspectRatio(
                          aspectRatio: aspect,
                          child: VideoPlayer(controller, key: ValueKey(controller.hashCode)),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ] else ...[
            AppImage.network(
              _reelData.thumbnailUrl,
              width: IsrDimens.getScreenWidth(context),
              height: IsrDimens.getScreenHeight(context),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
            ),
          ]
        ],
      );
    }
  }

  void _togglePlayPause() {
    if (_reelData.showBlur == true || _reelData.mediaType == kPictureType) {
      return;
    }
    if (!_controllerReady) return;
    if (_isPlaying) {
      _videoPlayerController?.pause();
    } else {
      _videoPlayerController?.play();
    }
    _isPlaying = !_isPlaying;
    _isPlayPauseActioned = !_isPlayPauseActioned;
    mountUpdate();
  }

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          // Media content with gesture detection
          GestureDetector(
            onTap: _togglePlayPause,
            child: VisibilityDetector(
              key: Key(_reelData.mediaUrl),
              onVisibilityChanged: (info) {
                if (_isDisposed) return;
                if (_reelData.showBlur == true || _reelData.mediaType == kPictureType) {
                  return;
                }

                // Update cache manager about visibility
                if (_reelData.mediaUrl.isStringEmptyOrNull == false) {
                  if (info.visibleFraction > 0.7) {
                    _videoCacheManager.markAsVisible(_reelData.mediaUrl);
                  } else {
                    _videoCacheManager.markAsNotVisible(_reelData.mediaUrl);
                  }
                }

                if (info.visibleFraction > 0.7) {
                  // mountUpdate();
                  if (_controllerReady && _videoPlayerController?.value.isPlaying == false) {
                    _videoPlayerController?.seekTo(Duration.zero);
                    _videoPlayerController?.play();
                    _isPlaying = true; // Update this line
                    mountUpdate();
                  }
                } else {
                  // mountUpdate();
                  if (_controllerReady && _videoPlayerController?.value.isPlaying == true) {
                    _videoPlayerController?.pause();
                    _isPlaying = false; // Update this line
                    _isPlayPauseActioned = false;
                    mountUpdate();
                  }
                }
              },
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  _buildMediaContent(),
                  // ClipRRect(
                  //   borderRadius: BorderRadius.zero,
                  //   child: SizedBox(
                  //     width: IsrDimens.getScreenWidth(context),
                  //     child: AnimatedOpacity(
                  //       opacity: widget.isReelsLongPressed == true ? 0.0 : 1.0,
                  //       duration: const Duration(milliseconds: 100),
                  //       child: Container(
                  //         height: IsrDimens.getScreenHeight(context),
                  //         width: IsrDimens.getScreenWidth(context),
                  //         decoration: BoxDecoration(
                  //           gradient: LinearGradient(
                  //             begin: Alignment.topCenter,
                  //             end: Alignment.bottomCenter,
                  //             colors: [
                  //               IsrColors.black.changeOpacity(.6),
                  //               IsrColors.black.changeOpacity(.0),
                  //               IsrColors.black.changeOpacity(.0),
                  //               IsrColors.black.changeOpacity(.4),
                  //             ],
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
          // if (_reelData.actionWidget != null)
          //   Padding(
          //     padding: _reelData.actionWidget?.padding ?? IsrDimens.edgeInsets(),
          //     child: Align(
          //       alignment: _reelData.actionWidget?.alignment ?? Alignment.bottomCenter,
          //       child: _reelData.actionWidget?.child,
          //     ),
          //   ),
          // if (_reelData.footerWidget != null)
          //   Padding(
          //     padding: _reelData.footerWidget?.padding ?? IsrDimens.edgeInsets(),
          //     child: Align(
          //       alignment: _reelData.footerWidget?.alignment ?? Alignment.bottomCenter,
          //       child: _reelData.footerWidget?.child,
          //     ),
          //   ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // // Bottom section
              Expanded(child: _reelData.footerWidget?.child ?? _buildBottomSection()),

              // Right side actions
              _reelData.actionWidget?.child ?? _buildRightSideActions(),
            ],
          ),

          // Video controls
          if (_reelData.mediaType == kVideoType &&
              _videoPlayerController?.value.isInitialized == true)
            AnimatedOpacity(
              opacity: _isPlayPauseActioned ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Center(
                child: InkWell(
                  onTap: _togglePlayPause,
                  child: AppImage.svg(
                    _isPlayPauseActioned
                        ? AssetConstants.reelsPlaySvg
                        : AssetConstants.pausedRoundedSvg,
                  ),
                ),
              ),
            ),
        ],
      );

  Widget _buildRightSideActions() => Padding(
        padding: IsrDimens.edgeInsets(bottom: IsrDimens.forty, right: IsrDimens.sixteen),
        child: Column(
          spacing: IsrDimens.twenty,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_reelData.postSetting?.isProfilePicVisible == true)
              TapHandler(
                borderRadius: IsrDimens.thirty,
                onTap: () {
                  if (_reelData.onTapUserProfile != null) {
                    _reelData.onTapUserProfile!(true);
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
                      color: Theme.of(context).primaryColor, // Blue background
                    ),
                    child: IconButton(
                      onPressed: () async {
                        if (widget.onCreatePost != null) {
                          await widget.onCreatePost!();
                        }
                      },
                      icon: const Icon(
                        Icons.add, // Simple plus icon
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
                onTap: () {
                  if (_reelData.onTapShare != null) {
                    _reelData.onTapShare!();
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
                    widget.onPressMoreButton!();
                  }
                },
              ),
          ],
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
              ),
            ),
          ],
        ],
      );

  Widget _buildBottomSection() => Padding(
        padding: IsrDimens.edgeInsets(
            left: IsrDimens.sixteen, right: IsrDimens.sixteen, bottom: IsrDimens.fifteen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Shop button
            if ((_reelData.productCount ?? 0) > 0) ...[
              TapHandler(
                onTap: () {
                  if (_reelData.onTapCartIcon != null) {
                    _reelData.onTapCartIcon!();
                  }
                },
                child: Container(
                  padding: IsrDimens.edgeInsetsSymmetric(
                    horizontal: IsrDimens.twelve,
                    vertical: IsrDimens.eight,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white, // Set to white for the background
                    borderRadius: BorderRadius.circular(IsrDimens.ten), // Rounded corners
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.changeOpacity(0.1), // Light shadow
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2), // Shadow offset
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

            // Profile info and description
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Right column - Username, follow button, and description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username and follow button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: TapHandler(
                                    onTap: () {
                                      if (_reelData.onTapUserProfile != null) {
                                        _reelData.onTapUserProfile!(false);
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
                                // Only show follow button if not following
                                _buildFollowButton(),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Description
                      if (_reelData.description.isStringEmptyOrNull == false) ...[
                        IsrDimens.boxHeight(IsrDimens.four),
                        ValueListenableBuilder<bool>(
                          valueListenable: _isExpandedDescription,
                          builder: (context, value, child) => RichText(
                            text: TextSpan(
                              children: [
                                // Tags
                                if (_reelData.hasTags?.isNotEmpty == true)
                                  ..._reelData.hasTags!.map(
                                    (tag) => TextSpan(
                                      text: '#$tag ',
                                      style: IsrStyles.white14.copyWith(
                                        color: IsrColors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                // Description
                                TextSpan(
                                  text: value
                                      ? _reelData.description
                                      : (_reelData.description?.length ?? 0) > _maxLengthToShow
                                          ? '${_reelData.description?.substring(0, _maxLengthToShow)}...'
                                          : _reelData.description,
                                  style: IsrStyles.white14.copyWith(
                                    color: IsrColors.white.changeOpacity(0.9),
                                  ),
                                ),
                                // Read More / Read Less
                                if ((_reelData.description?.length ?? 0) > _maxLengthToShow)
                                  TextSpan(
                                    text: value
                                        ? ' ${IsrTranslationFile.viewLess}'
                                        : ' ${IsrTranslationFile.viewMore}',
                                    style: IsrStyles.white14.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    recognizer: _tapGestureRecognizer
                                      ?..onTap = () {
                                        _isExpandedDescription.value =
                                            !_isExpandedDescription.value;
                                      },
                                  ),
                              ],
                            ),
                          ),
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
    if (_reelData.onPressSave == null) return;
    _isSaveLoading.value = true;

    try {
      final success = await _reelData.onPressSave!(_reelData.isSavedPost ?? false);
      if (success) {
        _reelData.isSavedPost = _reelData.isSavedPost == false;
      }
    } finally {
      _isSaveLoading.value = false;
    }
  }

  Future<void> _callLikeFunction() async {
    if (widget.onPressLikeButton == null || _isLikeLoading.value) return;
    _isLikeLoading.value = true;

    try {
      await widget.onPressLikeButton!();
    } finally {
      _isLikeLoading.value = false;
    }
  }

  void _toggleSound() {
    if (_reelData.mediaType != kVideoType) return;

    setState(() {
      _isMuted = !_isMuted;
      _videoPlayerController?.setVolume(_isMuted ? 0.0 : 1.0);
    });
    // widget.onTapVolume?.call();
  }

  void _handleCommentClick(StateSetter setBuilderState) async {
    if (_reelData.onTapComment != null) {
      final commentCount = await _reelData.onTapComment!(_reelData.commentCount ?? 0);
      if (commentCount != null) {
        _reelData.commentCount = commentCount;
      }
      setBuilderState.call(() {});
    }
  }
}
