import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:video_player/video_player.dart';

class MediaPreviewWidget extends StatefulWidget {
  const MediaPreviewWidget({
    super.key,
    required this.mediaData,
    this.height,
    this.width,
  });

  final MediaData mediaData;
  final double? width;
  final double? height;

  @override
  State<MediaPreviewWidget> createState() => _MediaPreviewWidgetState();
}

class _MediaPreviewWidgetState extends State<MediaPreviewWidget> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  double _compressionProgress = 0.0;
  bool _isCompressing = false;
  late final String _mediaKey; // 🔑 unique identifier

  @override
  void initState() {
    super.initState();
    _mediaKey = widget.mediaData.localPath ??
        widget.mediaData.url ??
        UniqueKey().toString();
    _initializeVideoPlayer();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MediaPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaData != widget.mediaData) {
      _mediaKey = widget.mediaData.localPath ??
          widget.mediaData.url ??
          UniqueKey().toString();
      _initializeVideoPlayer();
    }
  }

  Future<void> _initializeVideoPlayer() async {
    if (widget.mediaData.mediaType?.mediaType == MediaType.video) {
      try {
        if (widget.mediaData.localPath?.isNotEmpty == true &&
            Utility.isLocalUrl(widget.mediaData.localPath!)) {
          _controller =
              VideoPlayerController.file(File(widget.mediaData.localPath!));
        } else if (widget.mediaData.url?.isNotEmpty == true) {
          _controller = VideoPlayerController.networkUrl(
              Uri.parse(widget.mediaData.url!));
        }
        await _controller?.initialize();
        setState(() {});

        _controller?.addListener(() {
          if (_controller?.value.isPlaying != _isPlaying) {
            setState(() => _isPlaying = _controller?.value.isPlaying ?? false);
          }
        });
      } catch (e) {
        debugPrint('Video init error: $e');
      }
    }
  }

  void _togglePlayPause() {
    if (_controller?.value.isInitialized != true) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller?.pause();
      } else {
        _controller?.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<CreatePostBloc, CreatePostState>(
        listenWhen: (previous, current) => current is CompressionProgressState,
        listener: (context, state) {
          if (state is CompressionProgressState &&
              state.mediaKey == _mediaKey) {
            // 🎯 Only update progress if this widget’s media matches
            setState(() {
              _compressionProgress = state.progress;
              _isCompressing = state.progress > 0 && state.progress < 100;
            });
          }
        },
        builder: (context, state) => Stack(
          children: [
            // Preview Box
            Container(
              width: widget.height ?? 60.responsiveDimension,
              height: widget.width ?? 60.responsiveDimension,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.responsiveDimension),
                border: Border.all(color: IsrColors.colorDBDBDB),
              ),
              clipBehavior: Clip.hardEdge,
              child: _buildMediaPreview(),
            ),

            // Compression Overlay
            if (_isCompressing)
              CustomPaint(
                size: Size(60.responsiveDimension, 60.responsiveDimension),
                painter: RectangularProgressBar(
                  progress: _compressionProgress / 100,
                  color: Colors.amber,
                  strokeWidth: 3.responsiveDimension,
                  borderRadius: 8.responsiveDimension,
                ),
              ),
          ],
        ),
      );

  Widget _buildMediaPreview() {
    if (widget.mediaData.mediaType?.mediaType == MediaType.video) {
      return _controller?.value.isInitialized == true
          ? Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_controller!),
                if (!_isCompressing)
                  TapHandler(
                    onTap: _togglePlayPause,
                    child: Container(
                      color: Colors.black26,
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: IsrColors.white,
                        size: IsrDimens.twentyFour,
                      ),
                    ),
                  ),
              ],
            )
          : AppImage.network(widget.mediaData.previewUrl ?? '',
              width: IsrDimens.sixty,
              height: IsrDimens.sixty,
              fit: BoxFit.cover);
    } else {
      return widget.mediaData.localPath?.isNotEmpty == true &&
              Utility.isLocalUrl(widget.mediaData.localPath!)
          ? AppImage.file(widget.mediaData.localPath!,
              width: IsrDimens.sixty,
              height: IsrDimens.sixty,
              fit: BoxFit.cover)
          : AppImage.network(widget.mediaData.url ?? '',
              width: IsrDimens.sixty,
              height: IsrDimens.sixty,
              fit: BoxFit.cover);
    }
  }
}
