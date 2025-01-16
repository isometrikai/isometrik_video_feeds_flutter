import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/export.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Custom Reels Player
class ReelsVideoPlayerView extends StatefulWidget {
  const ReelsVideoPlayerView({
    Key? key,
    required this.videoUrl,
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
    this.productList,
  }) : super(key: key);

  final String? videoUrl;
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
  final Function()? onPressFollowFollowing;
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
  final List<FeaturedProductDataItem>? productList;

  @override
  State<ReelsVideoPlayerView> createState() => _ReelsVideoPlayerViewState();
}

class _ReelsVideoPlayerViewState extends State<ReelsVideoPlayerView> {
  VideoPlayerController? videoPlayerController;

  var isPlaying = true;

  var playPausedAction = false;

  var isDoubleTapped = false;

  var isFollowLoading = false;

  var isVideoVisible = false;

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
    initializeVideoPlayer();
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
      if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
        if (widget.videoUrl!.startsWith('http')) {
          videoPlayerController = VideoPlayerController.networkUrl(
            Uri.parse(widget.videoUrl ?? ''),
          );
        } else {
          videoPlayerController = VideoPlayerController.file(
            File(widget.videoUrl!),
          );
        }
      }
    }
    if (videoPlayerController == null) return;
    try {
      await videoPlayerController?.initialize();
    } catch (e) {
      IsmVideoReelUtility.debugCatchLog(error: e);
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

  @override
  Widget build(context) {
    videoPlayerController?.setVolume(widget.isReelsMuted ? 0.0 : 1.0);
    return SafeArea(
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: IsrDimens.getScreenWidth(context),
              child: GestureDetector(
                onTap: () {
                  if (widget.showBlur == true) return;
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
                  videoPlayerController?.pause();
                  widget.onLongPressStart();
                  mountUpdate();
                },
                onLongPressEnd: (value) {
                  videoPlayerController?.play();
                  widget.onLongPressEnd();
                  mountUpdate();
                },
                child: VisibilityDetector(
                  key: Key('${widget.videoUrl}'),
                  onVisibilityChanged: (info) {
                    if (widget.showBlur == true) return;
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
                      widget.showBlur == true
                          ? AppImage.network(
                              widget.thumbnail,
                              width: IsrDimens.getScreenWidth(context),
                              height: IsrDimens.getScreenHeight(context),
                            )
                          : videoPlayerController != null && videoPlayerController?.value.isInitialized == true
                              ? FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    height: videoPlayerController?.value.size.height,
                                    width: videoPlayerController?.value.size.width,
                                    child: VideoPlayer(videoPlayerController!),
                                  ),
                                )
                              : const SizedBox(),
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
            ),
            // SafeArea(
            //   top: false,
            //   right: false,
            //   left: false,
            //   child: AnimatedOpacity(
            //     opacity: widget.isReelsLongPressed ? 0.0 : 1.0,
            //     duration: const Duration(milliseconds: 100),
            //     child: Align(
            //       alignment: Alignment.bottomRight,
            //       child: Padding(
            //         padding: IsrDimens.edgeInsets(right: IsrDimens.sixteen).copyWith(
            //           bottom: widget.needBottomPadding == true ? IsrDimens.twentyFour : null,
            //         ),
            //         child: Column(
            //           mainAxisAlignment: MainAxisAlignment.end,
            //           children: [
            //             if (widget.onCreatePost != null) ...[
            //               InkWell(
            //                 borderRadius: BorderRadius.circular(
            //                   IsrDimens.hundred,
            //                 ),
            //                 onTap: widget.onCreatePost,
            //                 child: const AppImage.svg(
            //                   AssetConstants.icHomePlaceHolder,
            //                 ),
            //               ),
            //               IsrDimens.boxHeight(IsrDimens.twenty),
            //             ],
            //             InkWell(
            //               borderRadius: BorderRadius.circular(
            //                 IsrDimens.hundred,
            //               ),
            //               onTap: () {
            //                 if (widget.isReelsMuted == true) {
            //                   videoPlayerController?.setVolume(1.0);
            //                 } else {
            //                   videoPlayerController?.setVolume(0.0);
            //                 }
            //                 widget.onTapVolume();
            //                 mountUpdate();
            //               },
            //               child: AppImage.svg(
            //                 widget.isReelsMuted == true ? AssetConstants.muteRoundedSvg : AssetConstants.unmuteRoundedSvg,
            //               ),
            //             ),
            //           ],
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
            Container(
              alignment: Alignment.bottomCenter,
              padding: IsrDimens.edgeInsets(left: IsrDimens.ten, right: IsrDimens.ten, bottom: IsrDimens.ten),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              TapHandler(
                                onTap: widget.onTapUserProfilePic,
                                child: Text(
                                  '${widget.name}'.replaceAll('', '\u{200B}'),
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  style: IsrStyles.white16.copyWith(
                                      fontWeight: FontWeight.w600, fontFamily: AppConstants.secondaryFontFamily),
                                ),
                              ),
                              if (!widget.isSelfProfile) ...[
                                IsrDimens.boxWidth(IsrDimens.eight),
                                isFollowLoading
                                    ? Container(
                                        height: IsrDimens.forty,
                                        width: IsrDimens.forty,
                                        padding: IsrDimens.edgeInsetsAll(IsrDimens.eight),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: IsrColors.appColor,
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: IsrColors.white,
                                            strokeWidth: IsrDimens.two,
                                          ),
                                        ),
                                      )
                                    : CustomButton(
                                        height: IsrDimens.twentyFive,
                                        color: widget.isFollow == true ? IsrColors.white : IsrColors.appColor,
                                        titleWidget: Center(
                                          child: Text(
                                            widget.isFollow == true
                                                ? TranslationFile.following
                                                : TranslationFile.follow,
                                            style: IsrStyles.white12.copyWith(
                                                fontWeight: FontWeight.w500,
                                                color: widget.isFollow == true ? IsrColors.appColor : IsrColors.white),
                                          ),
                                        ),
                                        width: IsrDimens.eighty,
                                        onPress: () {
                                          if (widget.isFollow) {
                                          } else {
                                            callFollowingFunction();
                                          }
                                        },
                                      ),
                              ],
                            ],
                          ),
                          if (widget.hasTags.isEmptyOrNull == false)
                            Text(
                              widget.hasTags!.join(' '),
                              style: IsrStyles.white14.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: IsrColors.white,
                            width: IsrDimens.one,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                IsrDimens.ninety,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                  IsrDimens.hundred,
                                ),
                                onTap: widget.onTapUserProfilePic,
                                child: AppImage.network(
                                  widget.profilePhoto,
                                  isProfileImage: true,
                                  height: IsrDimens.forty,
                                  width: IsrDimens.forty,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (widget.productList.isEmptyOrNull == false) ...[
                    IsrDimens.boxHeight(IsrDimens.ten),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        spacing: IsrDimens.ten,
                        children: widget.productList!
                            .map((product) => FeatureProductWidget(productData: product))
                            .toList(), // Using map
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: playPausedAction ? 1.0 : 0.0,
              duration: const Duration(
                milliseconds: 500,
              ),
              child: GestureDetector(
                onTap: () {
                  if (isPlaying) {
                    videoPlayerController?.pause();
                    playPause();
                  } else {
                    videoPlayerController?.play();
                    playPause();
                  }
                  isPlaying = !isPlaying;
                  mountUpdate();
                },
                onDoubleTap: () async {
                  widget.onDoubleTap();
                  isDoubleTapped = true;
                  mountUpdate();
                  await Future<void>.delayed(
                    const Duration(milliseconds: 1000),
                  );
                  isDoubleTapped = false;
                  mountUpdate();
                },
                onLongPressStart: (details) {
                  videoPlayerController?.pause();
                  widget.onLongPressStart();
                  mountUpdate();
                },
                onLongPressEnd: (value) {
                  videoPlayerController?.play();
                  widget.onLongPressEnd();
                  mountUpdate();
                },
                child: AppImage.svg(
                  isPlaying ? AssetConstants.pausedRoundedSvg : AssetConstants.reelsPlaySvg,
                ),
              ),
            ),
            if (isDoubleTapped)
              Lottie.asset(
                AssetConstants.heartAnimation,
                width: IsrDimens.oneHundredFifty,
                height: IsrDimens.oneHundredFifty,
                animate: true,
              ),
          ],
        ),
      ),
    );
  }

  //calls api to follow and unfollow user
  void callFollowingFunction() async {
    isFollowLoading = true;
    mountUpdate();
    if (widget.onPressFollowFollowing != null) {
      await widget.onPressFollowFollowing!();
    }
    isFollowLoading = false;
    mountUpdate();
  }
}
