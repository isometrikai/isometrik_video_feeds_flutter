import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/isr_utils.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Custom Reels Player for both Video and Photo content
class IsmReelsVideoPlayerView extends StatefulWidget {
  const IsmReelsVideoPlayerView({
    super.key,
    required this.mediaUrl,
    required this.mediaType, // 0 for picture, 1 for video
    this.onDoubleTap,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.isReelsLongPressed,
    this.isReelsMuted,
    required this.onTapVolume,
    required this.profilePhoto,
    this.hasTags,
    required this.name,
    this.firstName,
    this.lastName,
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
    this.productCount,
    this.onPressSave,
    this.isLiked = false,
    this.likesCount = 0,
    this.onPressLike,
    this.onPressMoreButton,
    this.onTapCartIcon,
    this.onTapComment,
    this.onTapShare,
    this.commentCount = 0,
    this.isCreatePostButtonVisible,
    this.isScheduledPost,
  });

  final String? mediaUrl;
  final int mediaType; // 0 for picture, 1 for video
  final void Function()? onDoubleTap;
  final void Function()? onLongPressStart;
  final void Function()? onLongPressEnd;
  final bool? isReelsLongPressed;
  final bool? isReelsMuted;
  final VoidCallback? onTapVolume;
  final String profilePhoto;
  final List<String>? hasTags;
  final String name;
  final String? firstName;
  final String? lastName;
  final bool? isVerifiedUser;
  final bool isFollow;
  final Future<bool> Function()? onPressFollowFollowing;
  final String description;
  final bool isSelfProfile;
  final Function()? onTapUserProfilePic;
  final String? postId;
  final Future<void> Function()? onCreatePost;
  final Function()? onTapReport;
  final bool? showBlur;
  final String thumbnail;
  final bool? needBottomPadding;
  final bool isAssetUploading;
  final bool? isSavedPost;
  final int? productCount;
  final Future<bool> Function()? onPressSave;
  final bool isLiked;
  final num likesCount;
  final Future<bool> Function()? onPressLike;
  final VoidCallback? onPressMoreButton;
  final VoidCallback? onTapCartIcon;
  final VoidCallback? onTapComment;
  final VoidCallback? onTapShare;
  final int? commentCount;
  final bool? isCreatePostButtonVisible;
  final bool? isScheduledPost;

  @override
  State<IsmReelsVideoPlayerView> createState() => _IsmReelsVideoPlayerViewState();
}

class _IsmReelsVideoPlayerViewState extends State<IsmReelsVideoPlayerView> {
  // Add constants for media types
  static const int kPictureType = 0;
  static const int kVideoType = 1;
  late TapGestureRecognizer _tapGestureRecognizer;

  VideoPlayerController? videoPlayerController;

  var _isPlaying = true;

  var _isPlayPauseActioned = false;

  var _isFollowLoading = false;

  bool _isExpandedDescription = false;

  var _isSaveLoading = false;

  var _isLikeLoading = false;

  var _isMuted = false;

  final _maxLengthToShow = 100;

// In _IsmReelsVideoPlayerViewState class
  bool _isCurrentPage = false;

  @override
  void initState() {
    super.initState();
    _isMuted = false;
    _tapGestureRecognizer = TapGestureRecognizer();
    debugPrint('IsmReelsVideoPlayerView ...Post by ...${widget.name}\n Post url ${widget.mediaUrl}');
    if (widget.mediaType == kVideoType) {
      // Initialize video but don't play yet
      _initializeVideoPlayer(shouldPlay: false);
    }
  }

  Future<void> _initializeVideoPlayer({bool shouldPlay = false}) async {
    if (videoPlayerController != null) return;

    debugPrint('Initializing video player for: ${widget.mediaUrl}');
    if (widget.mediaUrl?.isStringEmptyOrNull == false) {
      var mediaUrl = widget.mediaUrl!;
      if (mediaUrl.startsWith('http:')) {
        mediaUrl = mediaUrl.replaceFirst('http:', 'https:');
      }

      videoPlayerController = VideoPlayerController.network(mediaUrl);

      try {
        await videoPlayerController?.initialize();
        await videoPlayerController?.setLooping(true);
        await videoPlayerController?.setVolume(1.0);

        if (mounted) {
          setState(() {});
          // Only play if this is the current page
          if (shouldPlay && _isCurrentPage) {
            videoPlayerController?.play();
          }
        }
      } catch (e) {
        debugPrint('Error initializing video player: $e');
      }
    }
  }

// Add this method to handle page visibility
  void _handlePageVisibility(bool isCurrentPage) {
    if (_isCurrentPage == isCurrentPage) return;

    _isCurrentPage = isCurrentPage;

    if (videoPlayerController == null || !videoPlayerController!.value.isInitialized) {
      if (isCurrentPage) {
        _initializeVideoPlayer(shouldPlay: true);
      }
      return;
    }

    if (isCurrentPage) {
      videoPlayerController?.play();
    } else {
      videoPlayerController?.pause();
    }
  }

  /// Method For Update The Tree Carefully
  void mountUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  //initialize vide player controller
  void initializeVideoPlayer() async {
    debugPrint('IsmReelsVideoPlayerView....initializeVideoPlayer video url ${widget.mediaUrl}');
    if (widget.mediaUrl?.isStringEmptyOrNull == false) {
      var mediaUrl = widget.mediaUrl!;
      if (mediaUrl.startsWith('http:')) {
        mediaUrl = mediaUrl.replaceFirst('http:', 'https:');
        debugPrint('IsmReelsVideoPlayerView....initializeVideoPlayer video url converted to https $mediaUrl');
      }
      videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(mediaUrl),
      );
    }
    if (videoPlayerController == null) return;
    try {
      await videoPlayerController?.initialize();
      // Always start with volume on
      await videoPlayerController?.setVolume(1.0);
      debugPrint('IsmReelsVideoPlayerView....initializeVideoPlayer name ${widget.name}');
    } catch (e) {
      debugPrint('IsmReelsVideoPlayerView...catch video url ${widget.mediaUrl}');
      IsrVideoReelUtility.debugCatchLog(error: e);
    }
    await videoPlayerController?.setLooping(true);
    mountUpdate();
  }

  @override
  void dispose() {
    _tapGestureRecognizer.dispose();
    videoPlayerController?.pause();
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
      );
    }

    if (widget.mediaType == kPictureType) {
      return AppImage.network(
        widget.mediaUrl ?? '',
        width: IsrDimens.getScreenWidth(context),
        height: IsrDimens.getScreenHeight(context),
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

  void _togglePlayPause() {
    if (widget.showBlur == true || widget.mediaType == kPictureType) {
      return;
    }
    _isPlaying = !_isPlaying;
    if (_isPlaying) {
      videoPlayerController?.pause();
    } else {
      videoPlayerController?.play();
    }
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
            onDoubleTap: () async {
              if (widget.onDoubleTap != null) {
                widget.onDoubleTap!();
                mountUpdate();
                await Future<void>.delayed(const Duration(seconds: 1));
                mountUpdate();
              }
            },
            onLongPressStart: (details) {
              if (widget.mediaType == kVideoType) {
                videoPlayerController?.pause();
              }
              if (widget.onLongPressStart != null) {
                widget.onLongPressStart!();
              }
              mountUpdate();
            },
            onLongPressEnd: (value) {
              if (widget.mediaType == kVideoType) {
                videoPlayerController?.play();
              }
              if (widget.onLongPressEnd != null) {
                widget.onLongPressEnd!();
              }
              mountUpdate();
            },
            child: VisibilityDetector(
              key: Key('${widget.mediaUrl}'),
              onVisibilityChanged: (info) {
                if (widget.showBlur == true || widget.mediaType == kPictureType) {
                  return;
                }
                if (info.visibleFraction > 0.9) {
                  _handlePageVisibility(info.visibleFraction > 0.9);
                  mountUpdate();
                  if (videoPlayerController?.value.isPlaying == false) {
                    videoPlayerController?.seekTo(Duration.zero);
                    videoPlayerController?.play();
                    _isPlaying = !_isPlaying;
                    mountUpdate();
                  }
                } else {
                  _isPlayPauseActioned = false; // Reset play/pause icon state when video becomes visible
                  mountUpdate();
                  if (videoPlayerController?.value.isPlaying == true) {
                    videoPlayerController?.pause();
                    _isPlaying = !_isPlaying;
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
                        opacity: widget.isReelsLongPressed == true ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 100),
                        child: Container(
                          height: IsrDimens.getScreenHeight(context),
                          width: IsrDimens.getScreenWidth(context),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                IsrColors.black.changeOpacity(.6),
                                IsrColors.black.changeOpacity(.0),
                                IsrColors.black.changeOpacity(.0),
                                IsrColors.black.changeOpacity(.4),
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

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Bottom section
              Expanded(
                child: _buildBottomSection(),
              ),

              // Right side actions
              _buildRightSideActions(),
            ],
          ),

          // Video controls
          if (widget.mediaType == kVideoType && videoPlayerController?.value.isInitialized == true)
            AnimatedOpacity(
              opacity: _isPlayPauseActioned ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Center(
                child: InkWell(
                  onTap: _togglePlayPause,
                  child: AppImage.svg(
                    _isPlayPauseActioned ? AssetConstants.reelsPlaySvg : AssetConstants.pausedRoundedSvg,
                  ),
                ),
              ),
            ),
        ],
      );

  Widget _buildRightSideActions() => Padding(
        padding: IsrDimens.edgeInsets(bottom: IsrDimens.forty, right: IsrDimens.sixteen),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TapHandler(
              borderRadius: IsrDimens.thirty,
              onTap: widget.isSelfProfile
                  ? null
                  : () {
                      if (widget.onTapUserProfilePic != null) {
                        widget.onTapUserProfilePic!();
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
                  widget.profilePhoto,
                  width: IsrDimens.thirtyFive,
                  height: IsrDimens.thirtyFive,
                  isProfileImage: true,
                  name: '${widget.firstName ?? ''} ${widget.lastName ?? ''}',
                ),
              ),
            ),
            IsrDimens.boxHeight(IsrDimens.fifteen),
            if (widget.isCreatePostButtonVisible == true) ...[
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
              IsrDimens.boxHeight(IsrDimens.five),
              Text(
                IsrTranslationFile.create,
                style: IsrStyles.white12,
              ),
              IsrDimens.boxHeight(IsrDimens.ten),
            ],
            // if (widget.mediaType == kVideoType) ...[
            //   _buildActionButton(
            //     icon: _isMuted ? AssetConstants.icVolumeMute : AssetConstants.icVolumeUp,
            //     label: _isMuted ? IsrTranslationFile.unmute : IsrTranslationFile.mute,
            //     onTap: _toggleSound,
            //   ),
            //   IsrDimens.boxHeight(IsrDimens.twenty),
            // ],
            _buildActionButton(
              icon: widget.isLiked ? AssetConstants.icLikeSelected : AssetConstants.icLikeUnSelected,
              label: widget.likesCount.toString(),
              onTap: _callLikeFunction,
              isLoading: _isLikeLoading,
            ),
            IsrDimens.boxHeight(IsrDimens.twenty),
            _buildActionButton(
              icon: AssetConstants.icCommentIcon,
              label: widget.commentCount.toString(),
              onTap: () {
                if (widget.onTapComment != null) {
                  widget.onTapComment!();
                }
              },
            ),
            IsrDimens.boxHeight(IsrDimens.twenty),
            _buildActionButton(
              icon: AssetConstants.icShareIcon,
              label: IsrTranslationFile.share,
              onTap: () {
                if (widget.onTapShare != null) {
                  widget.onTapShare!();
                }
              },
            ),
            if (widget.isScheduledPost == false) ...[
              IsrDimens.boxHeight(IsrDimens.twenty),
              _buildActionButton(
                icon: widget.isSavedPost == true ? AssetConstants.icSaveSelected : AssetConstants.icSaveUnSelected,
                label: widget.isSavedPost == true ? IsrTranslationFile.saved : IsrTranslationFile.save,
                onTap: _callSaveFunction,
                isLoading: _isSaveLoading,
              ),
            ],
            IsrDimens.boxHeight(IsrDimens.twenty),
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
          Container(
            decoration: BoxDecoration(
              color: Colors.transparent.changeOpacity(0.2),
              borderRadius: BorderRadius.circular(IsrDimens.fifty),
              boxShadow: [
                BoxShadow(
                  color: Colors.transparent.changeOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            padding: IsrDimens.edgeInsetsAll(IsrDimens.eight),
            child: GestureDetector(
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
          ),
          if (label.isStringEmptyOrNull == false) ...[
            IsrDimens.boxHeight(IsrDimens.four),
            Container(
              padding: IsrDimens.edgeInsetsSymmetric(
                horizontal: IsrDimens.eight,
                vertical: IsrDimens.four,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(IsrDimens.fifty),
                boxShadow: [
                  BoxShadow(
                    color: Colors.transparent.changeOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 0,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Text(
                label ?? '',
                style: IsrStyles.white12.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      );

  Widget _buildBottomSection() => Padding(
        padding: IsrDimens.edgeInsets(left: IsrDimens.sixteen, right: IsrDimens.sixteen, bottom: IsrDimens.forty),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Shop button
            if ((widget.productCount ?? 0) > 0) ...[
              TapHandler(
                onTap: () {
                  if (widget.onTapCartIcon != null) {
                    widget.onTapCartIcon!();
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
                            style: IsrStyles.primaryText12
                                .copyWith(color: IsrColors.color0F1E91, fontWeight: FontWeight.w700),
                          ),
                          IsrDimens.boxHeight(IsrDimens.four),
                          Text(
                            '${widget.productCount} ${IsrTranslationFile.products}',
                            style: IsrStyles.primaryText10
                                .copyWith(color: IsrColors.color0F1E91, fontWeight: FontWeight.w500),
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
                                    onTap: widget.isSelfProfile
                                        ? null
                                        : () {
                                            if (widget.onTapUserProfilePic != null) {
                                              widget.onTapUserProfilePic!();
                                            }
                                          },
                                    child: Text(
                                      widget.name.length > 15 ? '${widget.name.substring(0, 10)}...' : widget.name,
                                      style: IsrStyles.white14.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
                                  if (!widget.isFollow && !_isFollowLoading && !widget.isSelfProfile)
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
                                  if (_isFollowLoading)
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
                        ],
                      ),

                      // Description
                      if (widget.description.isNotEmpty) ...[
                        IsrDimens.boxHeight(IsrDimens.four),
                        RichText(
                          text: TextSpan(
                            children: [
                              // Tags
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
                              // Description
                              TextSpan(
                                text: _isExpandedDescription
                                    ? widget.description
                                    : widget.description.length > _maxLengthToShow
                                        ? '${widget.description.substring(0, _maxLengthToShow)}...'
                                        : widget.description,
                                style: IsrStyles.white14.copyWith(
                                  color: IsrColors.white.changeOpacity(0.9),
                                ),
                              ),
                              // Read More / Read Less
                              if (widget.description.length > _maxLengthToShow)
                                TextSpan(
                                  text: _isExpandedDescription
                                      ? ' ${IsrTranslationFile.readLess}'
                                      : ' ${IsrTranslationFile.readMore}',
                                  style: IsrStyles.white14.copyWith(
                                    color: IsrColors.appColor.changeOpacity(0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  recognizer: _tapGestureRecognizer
                                    ..onTap = () {
                                      setState(() {
                                        _isExpandedDescription = !_isExpandedDescription;
                                      });
                                    },
                                ),
                            ],
                          ),
                        ),
                      ],
                      // if (widget.description.isNotEmpty && widget.description.length > _maxLengthToShow)
                      //   Padding(
                      //     padding: IsrDimens.edgeInsets(left: IsrDimens.eight),
                      //     child: GestureDetector(
                      //       onTap: () {
                      //         setState(() {
                      //           _isExpandedDescription = !_isExpandedDescription;
                      //         });
                      //       },
                      //       child: Text(
                      //         !_isExpandedDescription ? 'Read More' : 'Read Less',
                      //         style: IsrStyles.white14.copyWith(
                      //           color: IsrColors.appColor.changeOpacity(0.6),
                      //           fontWeight: FontWeight.w500,
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                    ],
                  ),
                ),
              ],
            ),
            if ((widget.productCount ?? 0) > 0) ...[
              IsrDimens.boxHeight(IsrDimens.eight),
              _buildCommissionTag(),
            ],
          ],
        ),
      );

  Widget _buildCommissionTag() => Container(
        padding: IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.twelve, vertical: IsrDimens.six),
        decoration: BoxDecoration(
          color: Colors.black.changeOpacity(0.6),
          borderRadius: IsrDimens.borderRadiusAll(20),
        ),
        child: Text(
          IsrTranslationFile.creatorEarnsCommission,
          style: IsrStyles.white10.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  //calls api to follow and unfollow user
  Future<void> _callFollowFunction() async {
    if (widget.onPressFollowFollowing == null) return;
    _isFollowLoading = true;
    mountUpdate();

    try {
      final success = await widget.onPressFollowFollowing!();
      if (!success) {
        // Reset loading if follow failed
        _isFollowLoading = false;
      }
    } finally {
      _isFollowLoading = false;
      mountUpdate();
    }
  }

  Future<void> _callSaveFunction() async {
    if (widget.onPressSave == null) return;
    _isSaveLoading = true;
    mountUpdate();

    try {
      final success = await widget.onPressSave!();
      if (!success) {
        _isSaveLoading = false;
      }
    } finally {
      _isSaveLoading = false;
      mountUpdate();
    }
  }

  Future<void> _callLikeFunction() async {
    if (widget.onPressLike == null || _isLikeLoading) return;
    _isLikeLoading = true;
    mountUpdate();

    try {
      final success = await widget.onPressLike!();
      if (!success) {
        _isLikeLoading = false;
      }
    } finally {
      _isLikeLoading = false;
      mountUpdate();
    }
  }

  void _toggleSound() {
    if (widget.mediaType != kVideoType) return;

    setState(() {
      _isMuted = !_isMuted;
      videoPlayerController?.setVolume(_isMuted ? 0.0 : 1.0);
    });
    widget.onTapVolume?.call();
  }
}
