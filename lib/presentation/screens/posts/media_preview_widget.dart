import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:video_player/video_player.dart';

class MediaPreviewWidget extends StatefulWidget {
  const MediaPreviewWidget({
    super.key,
    required this.postAttributeClass,
  });

  final PostAttributeClass? postAttributeClass;

  @override
  State<MediaPreviewWidget> createState() => _MediaPreviewWidgetState();
}

class _MediaPreviewWidgetState extends State<MediaPreviewWidget> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
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
    // Check if the postAttributeClass has changed
    if (widget.postAttributeClass != oldWidget.postAttributeClass) {
      _initializeVideoPlayer();
    }
  }

  Future<void> _initializeVideoPlayer() async {
    if (widget.postAttributeClass?.postType == MediaType.video) {
      _controller =
          VideoPlayerController.file(widget.postAttributeClass!.file!);
      await _controller?.initialize().then((_) {
        setState(() {});
        // setState(() {
        //   _isPlaying = false;
        // });
        // _controller?.play();
        // _controller?.setLooping(true);
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

  void _togglePlayPause() {
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
  Widget build(BuildContext context) {
    if (widget.postAttributeClass?.postType == MediaType.video) {
      return Container(
        width: IsrDimens.sixty,
        height: IsrDimens.sixty,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: IsrColors.colorDBDBDB),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video Player
              _controller?.value.isInitialized ?? false
                  ? VideoPlayer(_controller!)
                  : const Center(
                      child: CircularProgressIndicator(),
                    ),

              // Play/Pause Button Overlay
              if (_controller?.value.isInitialized ?? false)
                TapHandler(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: IsrDimens.sixty,
                    height: IsrDimens.sixty,
                    color: Colors.black26, // Semi-transparent overlay
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: IsrColors.white,
                      size: IsrDimens.twentyFour,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // For image type
    return Container(
      width: IsrDimens.sixty,
      height: IsrDimens.sixty,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: FileImage(widget.postAttributeClass!.file!),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
