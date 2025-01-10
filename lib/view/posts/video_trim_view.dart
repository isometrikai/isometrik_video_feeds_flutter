import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ism_video_reel_player/export.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_trimmer/video_trimmer.dart';

class VideoTrimView extends StatefulWidget {
  const VideoTrimView({super.key, this.postAttributeClass});

  final PostAttributeClass? postAttributeClass;

  @override
  State<VideoTrimView> createState() => _VideoTrimViewState();
}

class _VideoTrimViewState extends State<VideoTrimView> {
  final Trimmer trimmer = Trimmer();
  var _startValue = 0.0;
  var _endValue = 0.0;
  var _isMuted = false;
  var _playPausedAction = true;
  late PostAttributeClass _newPostAttributeClass;

  /// Method For Update Tree Carefully
  void mountUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    _newPostAttributeClass = widget.postAttributeClass ?? PostAttributeClass();
    _endValue = _newPostAttributeClass.duration?.toDouble() ?? 0;
    loadVideo();
    super.initState();
  }

  void loadVideo() async {
    try {
      await trimmer.loadVideo(videoFile: _newPostAttributeClass.file!);
    } catch (e) {
      Utility.debugCatchLog(error: e);
    }
    mountUpdate();
    trimmer.videoPlayerController?.addListener(checkVideo);
  }

  void checkVideo() {
    if (trimmer.videoPlayerController?.value.isPlaying == false) {
      _playPausedAction = true;
      debugPrint('trimmed video duration...${trimmer.videoPlayerController?.value.duration}');
      mountUpdate();
    }
  }

  @override
  void dispose() {
    trimmer.videoPlayerController?.dispose();
    trimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(context) => Scaffold(
        backgroundColor: AppColors.blackColor,
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(
            Dimens.oneHundredForty + Dimens.three,
          ),
          child: Padding(
            padding: Dimens.edgeInsets(
              left: Dimens.twenty,
              top: Dimens.fifty,
              right: Dimens.twenty,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(Dimens.hundred),
                      onTap: () async {
                        await trimmer.videoPlayerController?.setVolume(
                          _isMuted ? 1.0 : 0.0,
                        );
                        _isMuted = !_isMuted;
                        mountUpdate();
                      },
                      child: Container(
                        width: Dimens.thirtySix,
                        height: Dimens.thirtySix,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white.applyOpacity(.1),
                        ),
                        child: Icon(
                          !_isMuted ? Icons.volume_up_rounded : Icons.volume_off,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(Dimens.hundred),
                      onTap: context.pop,
                      child: Container(
                        width: Dimens.thirtySix,
                        height: Dimens.thirtySix,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white.applyOpacity(.1),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                Dimens.boxHeight(Dimens.eight),
                SizedBox(
                  width: Dimens.percentWidth(.95),
                  child: TrimViewer(
                    showDuration: true,
                    trimmer: trimmer,
                    viewerWidth: Dimens.percentWidth(.95),
                    maxVideoLength: const Duration(seconds: 60),
                    onChangeStart: (value) {
                      _startValue = value;
                    },
                    onChangeEnd: (value) {
                      _endValue = value;
                    },
                    onChangePlaybackState: (value) {},
                  ),
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              InkWell(
                onTap: () async {
                  var playBackState = await trimmer.videoPlaybackControl(
                    startValue: _startValue,
                    endValue: _endValue,
                  );
                  mountUpdate();
                  _playPausedAction = true;
                  mountUpdate();
                  if (playBackState == false) return;
                  await Future<void>.delayed(const Duration(milliseconds: 1000));
                  _playPausedAction = false;
                  mountUpdate();
                },
                child: Center(
                  child: AspectRatio(
                    aspectRatio: trimmer.videoPlayerController?.value.aspectRatio ?? 1,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoViewer(
                          trimmer: trimmer,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.blackColor.applyOpacity(.6),
                                AppColors.blackColor.applyOpacity(.0),
                                AppColors.blackColor.applyOpacity(.0),
                                AppColors.blackColor.applyOpacity(.4),
                              ],
                            ),
                          ),
                        ),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 250),
                          opacity: _playPausedAction ? 1 : 0,
                          child: AppImage.svg(
                            trimmer.videoPlayerController?.value.isPlaying == true
                                ? AssetConstants.pausedRoundedSvg
                                : AssetConstants.reelsPlaySvg,
                            height: Dimens.thirty,
                            width: Dimens.thirty,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (trimmer.videoPlayerController?.value.isInitialized == true)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: Dimens.edgeInsetsSymmetric(horizontal: Dimens.sixteen).copyWith(
                      bottom: Dimens.twenty,
                    ),
                    child: AppButton(
                      title: TranslationFile.continues,
                      onPress: () async {
                        await trimmer.saveTrimmedVideo(
                          startValue: _startValue,
                          endValue: _endValue,
                          onSave: (value) async {
                            if (value == null || value.isEmpty) return;
                            _handleTrimmedVideo(value);
                          },
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

  void _handleTrimmedVideo(String path) async {
    _newPostAttributeClass.thumbnailUrl = await VideoThumbnail.thumbnailFile(video: path);
    _newPostAttributeClass.url = path;
    // final _videoController = VideoPlayerController.file(File(path));
    // await _videoController.initialize();
    final duration = _endValue ~/ 1000 - _startValue ~/ 1000;
    _newPostAttributeClass.duration = duration;
    _newPostAttributeClass.thumbnailBytes = await File(_newPostAttributeClass.thumbnailUrl ?? '').readAsBytes();
    context.pop(_newPostAttributeClass);
  }
}
