import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:video_player/video_player.dart';

class IsrPostAttributeView extends StatefulWidget {
  const IsrPostAttributeView({
    super.key,
    required this.postAttributeClass,
  });

  final PostAttributeClass? postAttributeClass;

  @override
  State<IsrPostAttributeView> createState() => _IsrPostAttributeViewState();
}

class _IsrPostAttributeViewState extends State<IsrPostAttributeView> {
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
        appBar: AppBar(
          title: const Text('New Post'),
          centerTitle: true,
        ),
        bottomNavigationBar: SafeArea(
          child: AppButton(
            margin: IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.fifteen, vertical: IsrDimens.ten),
            title: IsrTranslationFile.post,
            onPress: () {
              isrGetIt<PostBloc>().add(CreatePostEvent(createPostRequest: _createPostRequest));
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: IsrDimens.edgeInsetsSymmetric(vertical: IsrDimens.twenty),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.twenty, vertical: IsrDimens.ten),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: SizedBox(
                          width: IsrDimens.seventy,
                          height: IsrDimens.hundred,
                          child: widget.postAttributeClass?.postType == PostType.photo
                              ? AppImage.file(
                                  widget.postAttributeClass?.url ?? '',
                                  fit: BoxFit.cover,
                                  width: IsrDimens.seventy,
                                  height: IsrDimens.hundred,
                                )
                              : _isVideoInitializing
                                  ? AppImage.file(
                                      widget.postAttributeClass?.thumbnailUrl ?? '',
                                      fit: BoxFit.cover,
                                      width: IsrDimens.seventy,
                                      height: IsrDimens.hundred,
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
                                                      height: IsrDimens.hundred,
                                                      width: IsrDimens.seventy,
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          begin: Alignment.topCenter,
                                                          end: Alignment.bottomCenter,
                                                          colors: [
                                                            IsrColors.blackColor.applyOpacity(.25),
                                                            IsrColors.blackColor.applyOpacity(.1),
                                                            IsrColors.blackColor.applyOpacity(.1),
                                                            IsrColors.blackColor.applyOpacity(.1),
                                                            IsrColors.blackColor.applyOpacity(.1),
                                                            IsrColors.blackColor.applyOpacity(.1),
                                                            IsrColors.blackColor.applyOpacity(.1),
                                                            IsrColors.blackColor.applyOpacity(.25),
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
                                                        padding: IsrDimens.edgeInsetsAll(IsrDimens.five),
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          gradient: LinearGradient(
                                                            begin: Alignment.topCenter,
                                                            end: Alignment.bottomCenter,
                                                            colors: [
                                                              IsrColors.white.applyOpacity(.7),
                                                              IsrColors.white.applyOpacity(.9),
                                                              IsrColors.white.applyOpacity(.9),
                                                            ],
                                                          ),
                                                        ),
                                                        child: const Icon(
                                                          Icons.play_arrow,
                                                          color: IsrColors.black,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                        ],
                                      ),
                                    ),
                        ),
                      ),
                      IsrDimens.boxWidth(IsrDimens.ten),
                      Expanded(
                        child: TextFormField(
                          maxLines: 5,
                          onChanged: (value) {
                            _createPostRequest.description = value;
                          },
                          decoration: InputDecoration(
                            hintText: IsrTranslationFile.writeCaption,
                            hintStyle: IsrStyles.primaryText12,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                CustomDivider(thickness: IsrDimens.five),
                TapHandler(
                  onTap: () {},
                  child: Padding(
                    padding: IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.twenty, vertical: IsrDimens.ten),
                    child: Row(
                      children: [
                        Text(
                          IsrTranslationFile.category,
                          style: IsrStyles.primaryText14.copyWith(
                            color: IsrColors.color2783FB,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          IsrTranslationFile.selectCategory,
                          style: IsrStyles.primaryText14.copyWith(
                            color: IsrColors.color2783FB,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: IsrColors.color2783FB,
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
                    padding: IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.twenty, vertical: IsrDimens.ten),
                    child: Row(
                      children: [
                        Text(
                          IsrTranslationFile.allowComments,
                          style: IsrStyles.primaryText14.copyWith(
                            color: IsrColors.color2783FB,
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
                    padding: IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.twenty, vertical: IsrDimens.ten),
                    child: Row(
                      children: [
                        Text(
                          IsrTranslationFile.allowDownloads,
                          style: IsrStyles.primaryText14.copyWith(
                            color: IsrColors.color2783FB,
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
