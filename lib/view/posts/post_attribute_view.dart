import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/export.dart';
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
  final _createPostRequest = CreatePostRequest();
  VideoPlayerController? _videoPlayerController;
  var _isVideoInitializing = false;

  @override
  void initState() {
    super.initState();
    initializeVideoPlayer(widget.postAttributeClass?.url ?? '');
    setRequest();
  }

  /// Method For Initialize Video Player
  Future<void> initializeVideoPlayer(
    String path,
  ) async {
    if (widget.postAttributeClass?.postType == PostType.video) {
      _isVideoInitializing = true;
      setState(() {});
      _videoPlayerController = VideoPlayerController.file(File(path));
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
        // appBar: const CustomAppBar(
        //   titleText: TranslationFile.newPost,
        //   centerTitle: true,
        // ),
        bottomNavigationBar: SafeArea(
          child: AppButton(
            margin: Dimens.edgeInsetsSymmetric(horizontal: Dimens.fifteen, vertical: Dimens.ten),
            title: TranslationFile.post,
            onPress: () {
              isrGetIt<PostBloc>().add(CreatePostEvent(createPostRequest: _createPostRequest));
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
                  padding: Dimens.edgeInsetsSymmetric(horizontal: Dimens.twenty, vertical: Dimens.ten),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: SizedBox(
                          width: Dimens.seventy,
                          height: Dimens.hundred,
                          child: widget.postAttributeClass?.postType == PostType.photo
                              ? AppImage.file(
                                  widget.postAttributeClass?.url ?? '',
                                  fit: BoxFit.cover,
                                  width: Dimens.seventy,
                                  height: Dimens.hundred,
                                )
                              : _isVideoInitializing
                                  ? AppImage.file(
                                      widget.postAttributeClass?.thumbnailUrl ?? '',
                                      fit: BoxFit.cover,
                                      width: Dimens.seventy,
                                      height: Dimens.hundred,
                                    )
                                  : TapHandler(
                                      onTap: () async {
                                        FocusManager.instance.primaryFocus?.unfocus();
                                        _playPause();
                                      },
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          _videoPlayerController?.value.isInitialized == true &&
                                                  _videoPlayerController != null &&
                                                  _videoPlayerController?.value.isPlaying == true
                                              ? Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    VideoPlayer(_videoPlayerController!),
                                                    if (_videoPlayerController?.value.isBuffering == true)
                                                      const UnconstrainedBox(
                                                        child: CircularProgressIndicator(),
                                                      ),
                                                  ],
                                                )
                                              : Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    Container(
                                                      height: Dimens.hundred,
                                                      width: Dimens.seventy,
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          begin: Alignment.topCenter,
                                                          end: Alignment.bottomCenter,
                                                          colors: [
                                                            AppColors.blackColor.applyOpacity(.25),
                                                            AppColors.blackColor.applyOpacity(.1),
                                                            AppColors.blackColor.applyOpacity(.1),
                                                            AppColors.blackColor.applyOpacity(.1),
                                                            AppColors.blackColor.applyOpacity(.1),
                                                            AppColors.blackColor.applyOpacity(.1),
                                                            AppColors.blackColor.applyOpacity(.1),
                                                            AppColors.blackColor.applyOpacity(.25),
                                                          ],
                                                        ),
                                                        image: DecorationImage(
                                                          image: FileImage(
                                                              File(widget.postAttributeClass?.thumbnailUrl ?? '')),
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                    ),
                                                    if (_videoPlayerController?.value.isInitialized == true &&
                                                        _videoPlayerController?.value.isPlaying == false)
                                                      Container(
                                                        padding: Dimens.edgeInsetsAll(Dimens.five),
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          gradient: LinearGradient(
                                                            begin: Alignment.topCenter,
                                                            end: Alignment.bottomCenter,
                                                            colors: [
                                                              AppColors.white.applyOpacity(.7),
                                                              AppColors.white.applyOpacity(.9),
                                                              AppColors.white.applyOpacity(.9),
                                                            ],
                                                          ),
                                                        ),
                                                        child: const Icon(
                                                          Icons.play_arrow,
                                                          color: AppColors.black,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                        ],
                                      ),
                                    ),
                        ),
                      ),
                      Dimens.boxWidth(Dimens.ten),
                      Expanded(
                        child: TextFormField(
                          maxLines: 5,
                          onChanged: (value) {
                            _createPostRequest.description = value;
                          },
                          decoration: InputDecoration(
                            hintText: TranslationFile.writeCaption,
                            hintStyle: Styles.primaryText12,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                CustomDivider(thickness: Dimens.five),
                TapHandler(
                  onTap: () {},
                  child: Padding(
                    padding: Dimens.edgeInsetsSymmetric(horizontal: Dimens.twenty, vertical: Dimens.ten),
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
                      _createPostRequest.allowComment = _createPostRequest.allowComment == false;
                    });
                  },
                  child: Padding(
                    padding: Dimens.edgeInsetsSymmetric(horizontal: Dimens.twenty, vertical: Dimens.ten),
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
                          value: _createPostRequest.allowComment == true,
                          onChanged: (value) {
                            setState(() {
                              _createPostRequest.allowComment = value;
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
                      _createPostRequest.allowDownload = _createPostRequest.allowDownload == false;
                    });
                  },
                  child: Padding(
                    padding: Dimens.edgeInsetsSymmetric(horizontal: Dimens.twenty, vertical: Dimens.ten),
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
                          value: _createPostRequest.allowDownload == true,
                          onChanged: (value) {
                            setState(() {
                              _createPostRequest.allowComment = value;
                            });
                          },
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
    _createPostRequest.description = widget.postAttributeClass?.description;
    _createPostRequest.url = widget.postAttributeClass?.url;
    _createPostRequest.thumbnailUrl = widget.postAttributeClass?.thumbnailUrl;
    _createPostRequest.mediaType = widget.postAttributeClass?.postType == PostType.video ? 2 : 1;
    _createPostRequest.imageUrl = widget.postAttributeClass?.url;
    _createPostRequest.duration = widget.postAttributeClass?.duration;
    _createPostRequest.mediaType = widget.postAttributeClass?.postType?.mediaType;
  }
}
