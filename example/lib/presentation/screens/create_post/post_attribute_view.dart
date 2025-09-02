import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';
import 'package:video_player/video_player.dart';

class PostAttributeView extends StatefulWidget {
  const PostAttributeView({
    super.key,
    required this.postAttributeClass,
  });

  final PostAttributeClass? postAttributeClass;

  @override
  State<PostAttributeView> createState() => _PostAttributeViewState();
}

class _PostAttributeViewState extends State<PostAttributeView> {
  // var _createPostRequest = CreatePostRequest();
  VideoPlayerController? _videoPlayerController;
  var _isVideoInitializing = false;
  var _mediaDataList = <MediaData>[];
  PostAttributeClass? _postAttributeClass;

  @override
  void initState() {
    _onStartInit();
    super.initState();
  }

  void _onStartInit() {
    _postAttributeClass = widget.postAttributeClass;
    _mediaDataList = _postAttributeClass?.mediaDataList ?? [];
    for (var mediaData in _mediaDataList) {
      if (mediaData.mediaType?.mediaType == MediaType.video) {
        initializeVideoPlayer(mediaData);
      }
    }
    setRequest();
  }

  /// Method For Initialize Video Player
  Future<void> initializeVideoPlayer(
    MediaData mediaData,
  ) async {
    if (mediaData.mediaType?.mediaType == MediaType.video) {
      _isVideoInitializing = true;
      setState(() {});
      _videoPlayerController = VideoPlayerController.file(File(mediaData.localPath ?? ''));
      await _videoPlayerController?.initialize();
      await _videoPlayerController?.setLooping(true);
      await _videoPlayerController?.setVolume(1.0);
      _isVideoInitializing = false;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('New Post'),
          centerTitle: true,
        ),
        bottomNavigationBar: SafeArea(
          child: AppButton(
            margin: Dimens.edgeInsetsSymmetric(horizontal: Dimens.fifteen, vertical: Dimens.ten),
            title: TranslationFile.post,
            onPress: () {
              InjectionUtils.getBloc<CreatePostBloc>().add(PostCreateEvent());
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: Dimens.edgeInsetsSymmetric(vertical: Dimens.twenty),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      Dimens.edgeInsetsSymmetric(horizontal: Dimens.twenty, vertical: Dimens.ten),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Center(
                      //   child: SizedBox(
                      //     width: Dimens.seventy,
                      //     height: Dimens.hundred,
                      //     child: _postAttributeClass?.postType == MediaType.photo
                      //         ? AppImage.file(
                      //             _postAttributeClass?.url ?? '',
                      //             fit: BoxFit.cover,
                      //             width: Dimens.seventy,
                      //             height: Dimens.hundred,
                      //           )
                      //         : _isVideoInitializing
                      //             ? AppImage.file(
                      //                 _postAttributeClass?.thumbnailUrl ?? '',
                      //                 fit: BoxFit.cover,
                      //                 width: Dimens.seventy,
                      //                 height: Dimens.hundred,
                      //               )
                      //             : TapHandler(
                      //                 onTap: () async {
                      //                   FocusManager.instance.primaryFocus?.unfocus();
                      //                   _playPause();
                      //                 },
                      //                 child: Stack(
                      //                   alignment: Alignment.center,
                      //                   children: [
                      //                     _videoPlayerController?.value.isInitialized == true &&
                      //                             _videoPlayerController != null &&
                      //                             _videoPlayerController?.value.isPlaying == true
                      //                         ? Stack(
                      //                             alignment: Alignment.center,
                      //                             children: [
                      //                               VideoPlayer(_videoPlayerController!),
                      //                               if (_videoPlayerController?.value.isBuffering ==
                      //                                   true)
                      //                                 const UnconstrainedBox(
                      //                                   child: CircularProgressIndicator(),
                      //                                 ),
                      //                             ],
                      //                           )
                      //                         : Stack(
                      //                             alignment: Alignment.center,
                      //                             children: [
                      //                               Container(
                      //                                 height: Dimens.hundred,
                      //                                 width: Dimens.seventy,
                      //                                 decoration: BoxDecoration(
                      //                                   gradient: LinearGradient(
                      //                                     begin: Alignment.topCenter,
                      //                                     end: Alignment.bottomCenter,
                      //                                     colors: [
                      //                                       AppColors.blackColor.applyOpacity(.25),
                      //                                       AppColors.blackColor.applyOpacity(.1),
                      //                                       AppColors.blackColor.applyOpacity(.1),
                      //                                       AppColors.blackColor.applyOpacity(.1),
                      //                                       AppColors.blackColor.applyOpacity(.1),
                      //                                       AppColors.blackColor.applyOpacity(.1),
                      //                                       AppColors.blackColor.applyOpacity(.1),
                      //                                       AppColors.blackColor.applyOpacity(.25),
                      //                                     ],
                      //                                   ),
                      //                                   image: DecorationImage(
                      //                                     image: FileImage(File(widget
                      //                                             .postAttributeClass
                      //                                             ?.thumbnailUrl ??
                      //                                         '')),
                      //                                     fit: BoxFit.cover,
                      //                                   ),
                      //                                 ),
                      //                               ),
                      //                               if (_videoPlayerController
                      //                                           ?.value.isInitialized ==
                      //                                       true &&
                      //                                   _videoPlayerController?.value.isPlaying ==
                      //                                       false)
                      //                                 Container(
                      //                                   padding: Dimens.edgeInsetsAll(Dimens.five),
                      //                                   decoration: BoxDecoration(
                      //                                     shape: BoxShape.circle,
                      //                                     gradient: LinearGradient(
                      //                                       begin: Alignment.topCenter,
                      //                                       end: Alignment.bottomCenter,
                      //                                       colors: [
                      //                                         AppColors.white.applyOpacity(.7),
                      //                                         AppColors.white.applyOpacity(.9),
                      //                                         AppColors.white.applyOpacity(.9),
                      //                                       ],
                      //                                     ),
                      //                                   ),
                      //                                   child: const Icon(
                      //                                     Icons.play_arrow,
                      //                                     color: AppColors.black,
                      //                                   ),
                      //                                 ),
                      //                             ],
                      //                           ),
                      //                   ],
                      //                 ),
                      //               ),
                      //   ),
                      // ),
                      if (_mediaDataList.isNotEmpty)
                        Container(
                          alignment: Alignment.center,
                          height: 120.scaledValue, // Adjust as needed
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _mediaDataList.length,
                            itemBuilder: (context, index) {
                              final media = _mediaDataList[index];
                              return Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: MediaPreviewWidget(
                                  mediaData: media,
                                  height: 100.scaledValue,
                                  width: 100.scaledValue,
                                ),
                              );
                            },
                          ),
                        ),
                      Dimens.boxHeight(Dimens.ten),
                      TextFormField(
                        maxLines: 5,
                        onChanged: (value) {
                          _postAttributeClass?.caption = value;
                        },
                        decoration: InputDecoration(
                          hintText: TranslationFile.writeCaption,
                          hintStyle: Styles.primaryText12,
                          border: InputBorder.none,
                        ),
                      ),
                    ],
                  ),
                ),
                CustomDivider(thickness: Dimens.five),
                TapHandler(
                  onTap: () {},
                  child: Padding(
                    padding:
                        Dimens.edgeInsetsSymmetric(horizontal: Dimens.twenty, vertical: Dimens.ten),
                    child: Row(
                      children: [
                        Text(
                          TranslationFile.category,
                          style: Styles.primaryText14.copyWith(
                            color: AppColors.color2783FB,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          TranslationFile.selectCategory,
                          style: Styles.primaryText14.copyWith(
                            color: AppColors.color2783FB,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.color2783FB,
                        ),
                      ],
                    ),
                  ),
                ),
                const CustomDivider(),
                TapHandler(
                  onTap: () {
                    setState(() {
                      _postAttributeClass?.allowComment =
                          _postAttributeClass?.allowComment == false;
                    });
                  },
                  child: Padding(
                    padding:
                        Dimens.edgeInsetsSymmetric(horizontal: Dimens.twenty, vertical: Dimens.ten),
                    child: Row(
                      children: [
                        Text(
                          TranslationFile.allowComments,
                          style: Styles.primaryText14.copyWith(
                            color: AppColors.color2783FB,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: _postAttributeClass?.allowComment == true,
                          onChanged: (value) {
                            setState(() {
                              _postAttributeClass?.allowComment = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const CustomDivider(),
                TapHandler(
                  onTap: () {
                    setState(() {
                      // _createPostRequest.allowDownload = _createPostRequest.allowDownload == false;
                    });
                  },
                  child: Padding(
                    padding:
                        Dimens.edgeInsetsSymmetric(horizontal: Dimens.twenty, vertical: Dimens.ten),
                    child: Row(
                      children: [
                        Text(
                          TranslationFile.allowDownloads,
                          style: Styles.primaryText14.copyWith(
                            color: AppColors.color2783FB,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: _postAttributeClass?.allowDownload == true,
                          onChanged: (value) {
                            setState(() {
                              _postAttributeClass?.allowDownload = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const CustomDivider(),
                TapHandler(
                  onTap: () {
                    InjectionUtils.getRouteManagement().goToSearchUserScreen();
                  },
                  child: Padding(
                    padding:
                        Dimens.edgeInsetsSymmetric(horizontal: Dimens.twenty, vertical: Dimens.ten),
                    child: Row(
                      children: [
                        Text(
                          TranslationFile.tagPeople,
                          style: Styles.primaryText14.copyWith(
                            color: AppColors.color2783FB,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        TapHandler(
                          onTap: () {},
                          child: AppImage.svg(AssetConstants.icChevronRight),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  void _playPause() async {
    if (_videoPlayerController?.value.isPlaying == true) {
      await _videoPlayerController?.pause();
    } else {
      await _videoPlayerController?.play();
    }
    setState(() {});
  }

  void setRequest() {
    // _createPostRequest.url = _postAttributeClass?.url;
    // _createPostRequest.thumbnailUrl = _postAttributeClass?.thumbnailUrl;
    // _createPostRequest.mediaType = _postAttributeClass?.postType == MediaType.video ? 2 : 1;
    // _createPostRequest.imageUrl = _postAttributeClass?.url;
    // _createPostRequest.duration = _postAttributeClass?.duration;
    // _createPostRequest.mediaType = _postAttributeClass?.postType?.mediaType;
  }
}
