import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';
import 'package:video_player/video_player.dart';

class MediaPreviewWidget extends StatefulWidget {
  const MediaPreviewWidget({
    super.key,
    required this.mediaData,
  });

  final MediaData? mediaData;

  @override
  State<MediaPreviewWidget> createState() => _MediaPreviewWidgetState();
}

class _MediaPreviewWidgetState extends State<MediaPreviewWidget> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  final ValueNotifier<double> _compressionProgress = ValueNotifier(60.0);
  bool _isCompressing = false;
  MediaData? _mediaData;

  @override
  void initState() {
    super.initState();
    _onStartInit();
    _initializeVideoPlayer();
  }

  void _onStartInit() {
    _mediaData = widget.mediaData;
    _initializeVideoPlayer();
  }

  @override
  void dispose() {
    _compressionProgress.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MediaPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if the mediaData has changed
    if (_mediaData != oldWidget.mediaData) {
      _initializeVideoPlayer();
    }
  }

  Future<void> _initializeVideoPlayer() async {
    if (_mediaData == null) return;
    if (_mediaData?.mediaType?.mediaType == MediaType.video) {
      if (_mediaData!.localPath.isEmptyOrNull == false &&
          Utility.isLocalUrl(_mediaData!.localPath ?? '') == false) {
        _initializedLocalVideoPlayer(File(_mediaData!.localPath!));
      } else {
        _initializedVideoPlayer(_mediaData!.url!);
      }
      await _controller?.initialize().then((_) {
        setState(() {});
      });

      // Add listener to update play state
      _controller?.addListener(() {
        if (_controller?.value.isPlaying != _isPlaying) {
          setState(() {
            _isPlaying = _controller?.value.isPlaying ?? false;
          });
        }
      });
    }
  }

  void _initializedLocalVideoPlayer(File file) {
    _controller = VideoPlayerController.file(file);
  }

  void _initializedVideoPlayer(String videoUrl) {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(_mediaData!.url!));
    } catch (e) {
      debugPrint('Error initializing video player: $e');
    }
  }

  void _togglePlayPause() {
    if (_controller?.value.isInitialized == false) return;
    setState(() {
      if (_controller?.value.isPlaying ?? false) {
        _controller?.pause();
      } else {
        _controller?.play();
      }
      _isPlaying = _controller?.value.isPlaying ?? false;
    });
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<CreatePostBloc, CreatePostState>(
        listenWhen: (previous, current) => current is CompressionProgressState,
        listener: (context, state) {
          if (state is CompressionProgressState) {
            _compressionProgress.value = state.progress;
            _isCompressing = state.progress > 0 && state.progress < 100;
          }
        },
        builder: (context, state) => ValueListenableBuilder<double>(
          valueListenable: _compressionProgress,
          builder: (context, progress, _) => Stack(
            children: [
              // Media Preview Container
              Container(
                width: 60.scaledValue,
                height: 60.scaledValue,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.scaledValue),
                  border: Border.all(color: AppColors.colorDBDBDB),
                ),
                clipBehavior: Clip.hardEdge,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.scaledValue),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_mediaData?.mediaType?.mediaType == MediaType.video)
                        _controller?.value.isInitialized ?? false
                            ? VideoPlayer(_controller!)
                            : AppImage.network(
                                _mediaData!.previewUrl!,
                                width: Dimens.sixty,
                                height: Dimens.sixty,
                                borderRadius: Dimens.borderRadiusAll(4.scaledValue),
                                fit: BoxFit.cover,
                              )
                      else if (_mediaData?.localPath.isEmptyOrNull == false &&
                          Utility.isLocalUrl(_mediaData?.localPath ?? '') == true)
                        AppImage.file(
                          _mediaData!.localPath!,
                          width: Dimens.sixty,
                          height: Dimens.sixty,
                          fit: BoxFit.cover,
                        )
                      else
                        AppImage.network(
                          _mediaData?.url ?? '',
                          width: Dimens.sixty,
                          height: Dimens.sixty,
                          borderRadius: Dimens.borderRadiusAll(4.scaledValue),
                          fit: BoxFit.cover,
                        ),
                      if (_mediaData?.mediaType?.mediaType == MediaType.video && !_isCompressing)
                        TapHandler(
                          onTap: _togglePlayPause,
                          child: Container(
                            width: Dimens.sixty,
                            height: Dimens.sixty,
                            color: Colors.black26,
                            child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: AppColors.white,
                              size: Dimens.twentyFour,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 🔵 Progress Border - Top
              if (_isCompressing)
                // Rectangular border progress overlay
                CustomPaint(
                  size: Size(60.scaledValue, 60.scaledValue),
                  painter: RectangularProgressBar(
                    progress: progress / 100,
                    color: Colors.amber,
                    strokeWidth: 3.scaledValue,
                    borderRadius: 8.scaledValue,
                  ),
                ),
            ],
          ),
        ),
      );
}
