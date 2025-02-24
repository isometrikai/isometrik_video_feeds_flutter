import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Custom Reels Player for both Video and Photo content
class IsrReelsVideoPlayerView extends StatefulWidget {
  const IsrReelsVideoPlayerView({
    super.key,
    required this.mediaUrl,
    required this.mediaType, // 0 for picture, 1 for video
    required this.onDoubleTap,
    required this.onLongPressStart,
    required this.onLongPressEnd,
    required this.isReelsLongPressed,
    required this.isReelsMuted,
    required this.onTapVolume,
    required this.profilePhoto,
    this.hasTags,
    required this.name,
    this.isVerifiedUser = false,
    required this.isFollow,
    this.onPressFollowFollowing,
    required this.description,
    required this.isSelfProfile,
    required this.onTapUserProfilePic,
    required this.postId,
    this.onCreatePost,
    this.onTapReport,
    this.showBlur = false,
    required this.thumbnail,
    this.needBottomPadding,
    this.isAssetUploading = false,
    this.isSavedPost,
    this.productList,
    this.onPressSave,
    this.isLiked = false,
    this.likesCount = 0,
    this.onPressLike,
  });

  final String? mediaUrl;
  final int mediaType; // 0 for picture, 1 for video
  final void Function() onDoubleTap;
  final void Function() onLongPressStart;
  final void Function() onLongPressEnd;
  final bool isReelsLongPressed;
  final bool isReelsMuted;
  final Function() onTapVolume;
  final String profilePhoto;
  final List<String>? hasTags;
  final String name;
  final bool? isVerifiedUser;
  final bool isFollow;
  final Future<bool> Function()? onPressFollowFollowing;
  final String description;
  final bool isSelfProfile;
  final Function() onTapUserProfilePic;
  final String? postId;
  final Future<void> Function()? onCreatePost;
  final Function()? onTapReport;
  final bool? showBlur;
  final String thumbnail;
  final bool? needBottomPadding;
  final bool isAssetUploading;
  final bool? isSavedPost;
  final List<FeaturedProductDataItem>? productList;
  final Future<bool> Function()? onPressSave;
  final bool isLiked;
  final num likesCount;
  final Future<bool> Function()? onPressLike;

  @override
  State<IsrReelsVideoPlayerView> createState() => _IsrReelsVideoPlayerViewState();
}

class _IsrReelsVideoPlayerViewState extends State<IsrReelsVideoPlayerView> {
  // Add constants for media types
  static const int kPictureType = 0;
  static const int kVideoType = 1;

  VideoPlayerController? videoPlayerController;

  var isPlaying = true;

  var playPausedAction = false;

  var isDoubleTapped = false;

  var isFollowLoading = false;

  var isVideoVisible = false;

  bool _isExpandedDescription = false;

  var isSaveLoading = false;

  var isLikeLoading = false;

  void playPause() async {
    if (widget.showBlur == true) {
      return;
    }
    playPausedAction = true;
    mountUpdate();
    await Future<void>.delayed(
      const Duration(milliseconds: 1000),
    );
    playPausedAction = false;
    mountUpdate();
  }

  @override
  void initState() {
    if (widget.mediaType == kVideoType) {
      initializeVideoPlayer();
    } else {
      mountUpdate();
    }
    super.initState();
  }

  void pauseVideoPlayer() {
    videoPlayerController?.setVolume(0);
    videoPlayerController?.pause();
    mountUpdate();
  }

  void playVideoPlayer() {
    videoPlayerController?.setVolume(1);
    videoPlayerController?.play();
    mountUpdate();
  }

  /// Method For Update The Tree Carefully
  void mountUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  //initialize vide player controller
  void initializeVideoPlayer({String url = ''}) async {
    if (url.isNotEmpty) {
      if (url.startsWith('http')) {
        videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(url),
        );
      } else {
        videoPlayerController = VideoPlayerController.file(File(url));
      }
    } else {
      debugPrint('initializeVideoPlayer video url ${widget.mediaUrl}');
      if (widget.mediaUrl != null && widget.mediaUrl!.isNotEmpty) {
        if (widget.mediaUrl!.startsWith('http')) {
          videoPlayerController = VideoPlayerController.networkUrl(
            Uri.parse(widget.mediaUrl ?? ''),
          );
        } else {
          videoPlayerController = VideoPlayerController.file(
            File(widget.mediaUrl!),
          );
        }
      }
    }
    if (videoPlayerController == null) return;
    try {
      await videoPlayerController?.initialize();
    } catch (e) {
      IsrVideoReelUtility.debugCatchLog(error: e);
    }
    await videoPlayerController?.setLooping(true);
    if (url.isNotEmpty) {
      await videoPlayerController?.play();
    }
    mountUpdate();
  }

  @override
  void dispose() {
    videoPlayerController?.pause();
    videoPlayerController?.setVolume(0.0);
    videoPlayerController?.dispose();
    videoPlayerController = null;
    super.dispose();
  }

  Widget _buildMediaContent() {
    if (widget.showBlur == true) {
      return AppImage.network(
        widget.thumbnail,
        width: IsrDimens.getScreenWidth(context),
        height: IsrDimens.getScreenHeight(context),
        fit: BoxFit.cover,
      );
    }

    if (widget.mediaType == kPictureType) {
      return AppImage.network(
        widget.mediaUrl ?? '',
        width: IsrDimens.getScreenWidth(context),
        height: IsrDimens.getScreenHeight(context),
        fit: BoxFit.cover,
      );
    }

    return videoPlayerController != null && videoPlayerController?.value.isInitialized == true
        ? FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              height: videoPlayerController?.value.size.height,
              width: videoPlayerController?.value.size.width,
              child: VideoPlayer(videoPlayerController!),
            ),
          )
        : const SizedBox();
  }

  Widget _buildRightSideActions() => Positioned(
        right: IsrDimens.sixteen,
        bottom: IsrDimens.forty,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent, // Background color for the shadow
                    borderRadius: BorderRadius.circular(IsrDimens.thirty), // Match the image's radius
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.applyOpacity(0.2), // Shadow color
                        spreadRadius: 2, // Spread radius
                        blurRadius: 5, // Blur radius
                        offset: const Offset(0, 2), // Shadow offset
                      ),
                    ],
                  ),
                  child: AppImage.network(
                    widget.profilePhoto,
                    width: IsrDimens.forty,
                    height: IsrDimens.forty,
                    isProfileImage: true,
                  ),
                ),
                IsrDimens.boxHeight(IsrDimens.ten),
                Container(
                  width: IsrDimens.forty,
                  height: IsrDimens.forty,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor, // Blue background
                  ),
                  child: IconButton(
                    onPressed: () async {
                      await IsrVideoReelUtility.showBottomSheet(
                        context: context,
                        CreatePostBottomSheet(
                          onCreateNewPost: () {
                            InjectionUtils.getBloc<PostBloc>().add(CameraEvent(context: context));
                          },
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.add, // Simple plus icon
                      color: IsrColors.white,
                      size: 24,
                    ),
                  ),
                ),
                IsrDimens.boxHeight(IsrDimens.five),
                Text(
                  IsrTranslationFile.create,
                  style: IsrStyles.white12,
                ),
              ],
            ),
            IsrDimens.boxHeight(IsrDimens.twenty),
            _buildActionButton(
              icon: widget.isLiked ? AssetConstants.icLikeSelected : AssetConstants.icLikeUnSelected,
              label: widget.likesCount.toString(),
              onTap: _callLikeFunction,
              isLoading: isLikeLoading,
            ),
            IsrDimens.boxHeight(IsrDimens.twenty),
            _buildActionButton(
              icon: AssetConstants.icCommentIcon,
              label: '10K',
              onTap: () {},
            ),
            IsrDimens.boxHeight(IsrDimens.twenty),
            _buildActionButton(
              icon: AssetConstants.icShareIcon,
              label: IsrTranslationFile.share,
              onTap: () {},
            ),
            IsrDimens.boxHeight(IsrDimens.twenty),
            _buildActionButton(
              icon: widget.isSavedPost == true ? AssetConstants.icSaveSelected : AssetConstants.icSaveUnSelected,
              label: widget.isSavedPost == true ? IsrTranslationFile.saved : IsrTranslationFile.save,
              onTap: _callSaveFunction,
              isLoading: isSaveLoading,
            ),
            IsrDimens.boxHeight(IsrDimens.twenty),
            _buildActionButton(
              icon: AssetConstants.icMoreIcon,
              onTap: () {},
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
                : AppImage.svg(
                    icon,
                    width: IsrDimens.twentyFour,
                    height: IsrDimens.twentyFour,
                  ),
          ),
          if (label != null) ...[
            IsrDimens.boxHeight(IsrDimens.four),
            Text(
              label,
              style: IsrStyles.white12,
            ),
          ],
        ],
      );

  Widget _buildBottomSection() => Positioned(
        bottom: IsrDimens.forty,
        left: IsrDimens.sixteen,
        right: IsrDimens.sixteen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Shop button
            if (widget.productList?.isNotEmpty == true) ...[
              Container(
                padding: IsrDimens.edgeInsetsSymmetric(
                  horizontal: IsrDimens.twelve,
                  vertical: IsrDimens.eight,
                ),
                decoration: BoxDecoration(
                  color: Colors.white, // Set to white for the background
                  borderRadius: BorderRadius.circular(IsrDimens.ten), // Rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.applyOpacity(0.1), // Light shadow
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
                          style: IsrStyles.primaryText12
                              .copyWith(color: IsrColors.color0F1E91, fontWeight: FontWeight.w700),
                        ),
                        IsrDimens.boxHeight(IsrDimens.four),
                        Text(
                          '${widget.productList!.length} ${IsrTranslationFile.products}',
                          style: IsrStyles.primaryText10
                              .copyWith(color: IsrColors.color0F1E91, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
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
                                  child: Text(
                                    widget.name.length > 15 ? '${widget.name.substring(0, 10)}...' : widget.name,
                                    style: IsrStyles.white14.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!widget.isSelfProfile) ...[
                                  IsrDimens.boxWidth(IsrDimens.eight),
                                  // Check if the user is verified
                                  if (widget.isVerifiedUser == false) ...[
                                    // Add the verified user icon
                                    SizedBox(
                                      height: IsrDimens.twentyFour,
                                      width: IsrDimens.twentyFour,
                                      child: const AppImage.svg(AssetConstants.icVerifiedIcon),
                                    ),
                                    IsrDimens.boxWidth(IsrDimens.eight),
                                  ],
                                  // Only show follow button if not following
                                  if (!widget.isFollow && !isFollowLoading)
                                    Container(
                                      height: IsrDimens.twentyFour,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        borderRadius: BorderRadius.circular(IsrDimens.twenty),
                                      ),
                                      child: MaterialButton(
                                        minWidth: IsrDimens.sixty,
                                        height: IsrDimens.twentyFour,
                                        padding: IsrDimens.edgeInsetsSymmetric(
                                          horizontal: IsrDimens.twelve,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(IsrDimens.twenty),
                                        ),
                                        onPressed: _callFollowFunction,
                                        child: Text(
                                          IsrTranslationFile.follow,
                                          style: IsrStyles.white12.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  // Show loading indicator while API call is in progress
                                  if (isFollowLoading)
                                    SizedBox(
                                      width: IsrDimens.sixty,
                                      height: IsrDimens.twentyFour,
                                      child: Center(
                                        child: SizedBox(
                                          width: IsrDimens.sixteen,
                                          height: IsrDimens.sixteen,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                          if (!_isExpandedDescription && widget.description.isNotEmpty)
                            Padding(
                              padding: IsrDimens.edgeInsets(left: IsrDimens.eight),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isExpandedDescription = true;
                                  });
                                },
                                child: Text(
                                  IsrTranslationFile.more,
                                  style: IsrStyles.white14.copyWith(
                                    color: IsrColors.white.applyOpacity(0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Description
                      if (widget.description.isNotEmpty) ...[
                        IsrDimens.boxHeight(IsrDimens.four),
                        RichText(
                          maxLines: _isExpandedDescription ? null : 1,
                          overflow: _isExpandedDescription ? TextOverflow.visible : TextOverflow.ellipsis,
                          text: TextSpan(
                            children: [
                              if (widget.hasTags?.isNotEmpty == true)
                                ...widget.hasTags!.map(
                                  (tag) => TextSpan(
                                    text: '#$tag ',
                                    style: IsrStyles.white14.copyWith(
                                      color: IsrColors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              TextSpan(
                                text: widget.description,
                                style: IsrStyles.white14.copyWith(
                                  color: IsrColors.white.applyOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (widget.mediaType == kVideoType) {
      videoPlayerController?.setVolume(widget.isReelsMuted ? 0.0 : 1.0);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Media content with gesture detection
        GestureDetector(
          onTap: () {
            if (widget.showBlur == true || widget.mediaType == kPictureType) {
              return;
            }
            isPlaying = !isPlaying;
            if (isPlaying) {
              videoPlayerController?.pause();
              playPause();
            } else {
              videoPlayerController?.play();
              playPause();
            }
          },
          onDoubleTap: () async {
            widget.onDoubleTap();
            isDoubleTapped = true;
            mountUpdate();
            await Future<void>.delayed(const Duration(seconds: 1));
            isDoubleTapped = false;
            mountUpdate();
          },
          onLongPressStart: (details) {
            if (widget.mediaType == kVideoType) {
              videoPlayerController?.pause();
            }
            widget.onLongPressStart();
            mountUpdate();
          },
          onLongPressEnd: (value) {
            if (widget.mediaType == kVideoType) {
              videoPlayerController?.play();
            }
            widget.onLongPressEnd();
            mountUpdate();
          },
          child: VisibilityDetector(
            key: Key('${widget.mediaUrl}'),
            onVisibilityChanged: (info) {
              if (widget.showBlur == true || widget.mediaType == kPictureType) {
                return;
              }
              if (info.visibleFraction > 0.1) {
                isVideoVisible = true;
                mountUpdate();
                if (videoPlayerController?.value.isPlaying == false) {
                  videoPlayerController?.seekTo(Duration.zero);
                  videoPlayerController?.play();
                  isPlaying = !isPlaying;
                  mountUpdate();
                }
              } else {
                isVideoVisible = false;
                mountUpdate();
                if (videoPlayerController?.value.isPlaying == true) {
                  videoPlayerController?.pause();
                  isPlaying = !isPlaying;
                  mountUpdate();
                }
              }
            },
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                _buildMediaContent(),
                ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: SizedBox(
                    width: IsrDimens.getScreenWidth(context),
                    child: AnimatedOpacity(
                      opacity: widget.isReelsLongPressed ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      child: Container(
                        height: IsrDimens.getScreenHeight(context),
                        width: IsrDimens.getScreenWidth(context),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              IsrColors.black.applyOpacity(.6),
                              IsrColors.black.applyOpacity(.0),
                              IsrColors.black.applyOpacity(.0),
                              IsrColors.black.applyOpacity(.4),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                IsrColors.black.applyOpacity(0.4),
                Colors.transparent,
                Colors.transparent,
                IsrColors.black.applyOpacity(0.4),
              ],
            ),
          ),
        ),

        // Right side actions
        _buildRightSideActions(),

        // Bottom section
        _buildBottomSection(),

        // Video controls
        if (widget.mediaType == kVideoType)
          AnimatedOpacity(
            opacity: playPausedAction ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            child: Center(
              child: AppImage.svg(
                isPlaying ? AssetConstants.pausedRoundedSvg : AssetConstants.reelsPlaySvg,
              ),
            ),
          ),

        // Double tap heart animation
        if (isDoubleTapped)
          Center(
            child: Lottie.asset(
              AssetConstants.heartAnimation,
              width: IsrDimens.oneHundredFifty,
              height: IsrDimens.oneHundredFifty,
              animate: true,
            ),
          ),
      ],
    );
  }

  //calls api to follow and unfollow user
  Future<void> _callFollowFunction() async {
    if (widget.onPressFollowFollowing == null) return;
    isFollowLoading = true;
    mountUpdate();

    try {
      final success = await widget.onPressFollowFollowing!();
      if (!success) {
        // Reset loading if follow failed
        isFollowLoading = false;
      }
    } finally {
      isFollowLoading = false;
      mountUpdate();
    }
  }

  Future<void> _callSaveFunction() async {
    if (widget.onPressSave == null) return;
    isSaveLoading = true;
    mountUpdate();

    try {
      final success = await widget.onPressSave!();
      if (!success) {
        isSaveLoading = false;
      }
    } finally {
      isSaveLoading = false;
      mountUpdate();
    }
  }

  Future<void> _callLikeFunction() async {
    if (widget.onPressLike == null) return;
    isLikeLoading = true;
    mountUpdate();

    try {
      final success = await widget.onPressLike!();
      if (!success) {
        isLikeLoading = false;
      }
    } finally {
      isLikeLoading = false;
      mountUpdate();
    }
  }
}
