import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_capture/camera.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class CameraBottomControls extends StatefulWidget {
  const CameraBottomControls({
    super.key,
    required this.cameraBloc,
    required this.onMediaPicked,
    this.onGalleryClick,
    required this.state,
  });

  final CameraBloc cameraBloc;
  final Function(String path, MediaType type) onMediaPicked;
  final Future<String?> Function()? onGalleryClick;
  final CameraState state;

  @override
  State<CameraBottomControls> createState() => _CameraBottomControlsState();
}

class _CameraBottomControlsState extends State<CameraBottomControls>
    with TickerProviderStateMixin {
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;
  final _imagePicker = ImagePicker();
  bool _isHoldRecording = false;

  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.cameraBloc.selectedMediaType == MediaType.video)
                CameraRecordingProgressBar(
                  cameraBloc: widget.cameraBloc,
                  state: widget.state,
                ),
              Container(
                height: 180.responsiveDimension,
                color: Colors.black.withValues(alpha: 0.25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Padding(
                            padding: EdgeInsets.only(
                                left: 16.responsiveDimension,
                                right: 8.responsiveDimension),
                            child: Row(
                              children: [
                                if (widget.cameraBloc.selectedMediaType ==
                                    MediaType.photo)
                                  _buildFlashButton(),
                              ],
                            ),
                          )),
                          Padding(
                            padding: EdgeInsets.only(
                                left: 8.responsiveDimension,
                                right: 8.responsiveDimension),
                            child: _buildRecordButton(),
                          ),
                          Expanded(
                              child: Padding(
                            padding: EdgeInsets.only(
                                left: 8.responsiveDimension,
                                right: 16.responsiveDimension),
                            child: Row(
                              spacing: 10.responsiveDimension,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (widget
                                        .cameraBloc.videoSegments.isNotEmpty &&
                                    !widget.cameraBloc.isSegmentRecording &&
                                    widget.cameraBloc.recordedVideoPath == null)
                                  CameraSegmentDeleteButton(
                                      cameraBloc: widget.cameraBloc),
                                if (!widget.cameraBloc.isRecording)
                                  _buildCameraSwitchButton(),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                    if ((widget.cameraBloc.recordedVideoPath == null ||
                            widget.cameraBloc.isRecording) &&
                        !widget.cameraBloc.isSegmentRecording)
                      _buildModeSelection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Timer? _holdTimer;
  bool _isHolding = false;

  Widget _buildRecordButton() {
    final isRecording = widget.cameraBloc.isRecording;
    final isSegmentRecording = widget.cameraBloc.isSegmentRecording;
    final hasRecordedVideo = widget.cameraBloc.recordedVideoPath != null;
    final controller = widget.cameraBloc.cameraController;
    final isControllerReady = controller != null &&
        controller.value.isInitialized &&
        !controller.value.hasError;
    final isVideoMode = widget.cameraBloc.selectedMediaType == MediaType.video;

    if (_isHoldRecording &&
        isSegmentRecording &&
        !_buttonAnimationController.isAnimating) {
      _buttonAnimationController.repeat(reverse: true);
    } else if ((!_isHoldRecording || !isSegmentRecording) &&
        _buttonAnimationController.isAnimating) {
      _buttonAnimationController.stop();
      _buttonAnimationController.reset();
    }

    return Listener(
      onPointerDown: (details) {
        // Only handle hold gesture for video mode
        if (!isVideoMode || !isControllerReady) return;

        if (isSegmentRecording && !_isHoldRecording) return;

        _isHolding = true;
        _holdTimer = Timer(const Duration(milliseconds: 300), () {
          if (_isHolding) {
            setState(() {
              _isHoldRecording = true;
            });
            widget.cameraBloc.add(CameraStartSegmentRecordingEvent());
          }
        });
      },
      onPointerUp: (details) {
        // Check camera readiness
        if (!isControllerReady) {
          Utility.showToastMessage('Camera not ready');
          return;
        }

        // Handle video mode with hold/tap logic
        if (isVideoMode) {
          _isHolding = false;
          _holdTimer?.cancel();

          if (_isHoldRecording) {
            setState(() {
              _isHoldRecording = false;
            });
            widget.cameraBloc.add(CameraStopSegmentRecordingEvent());
          } else {
            _handleTap(isRecording, isSegmentRecording, hasRecordedVideo);
          }
        } else {
          // Photo mode - just handle tap
          _handleTap(isRecording, isSegmentRecording, hasRecordedVideo);
        }
      },
      onPointerCancel: (details) {
        _isHolding = false;
        _holdTimer?.cancel();
        if (_isHoldRecording) {
          setState(() {
            _isHoldRecording = false;
          });
          widget.cameraBloc.add(CameraStopSegmentRecordingEvent());
        }
      },
      child: AnimatedBuilder(
        animation: _buttonScaleAnimation,
        builder: (context, child) {
          final scale = (_isHoldRecording && isSegmentRecording)
              ? _buttonAnimationController.value
              : 1.0;
          return Transform.scale(
            scale: scale,
            child: Container(
              padding: IsrDimens.edgeInsetsAll(IsrDimens.four),
              width: IsrDimens.sixtyFour,
              height: IsrDimens.sixtyFour,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: IsrColors.white,
                  width: IsrDimens.four,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRecording || isSegmentRecording
                      ? Colors.red
                      :
                      // : hasRecordedVideo
                      //     ? Colors.green
                      //     :
                      IsrColors.white,
                ),
                child: hasRecordedVideo && !isRecording && !isSegmentRecording
                    ? Icon(
                        Icons.check,
                        color: IsrColors.white,
                        size: IsrDimens.thirtyTwo,
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleTap(
      bool isRecording, bool isSegmentRecording, bool hasRecordedVideo) {
    if (widget.cameraBloc.selectedMediaType == MediaType.photo) {
      widget.cameraBloc.add(CameraCapturePhotoEvent());
    } else {
      if (isRecording || isSegmentRecording) {
        widget.cameraBloc.add(CameraStopSegmentRecordingEvent());
      } else if (hasRecordedVideo) {
        widget.cameraBloc.add(CameraConfirmRecordingEvent());
      } else {
        if (widget.cameraBloc.selectedDuration == 0) {
          Utility.showToastMessage('Please choose video duration');
          return;
        }
        setState(() {
          _isHoldRecording = false;
        });
        widget.cameraBloc.add(CameraStartSegmentRecordingEvent());
      }
    }
  }

  Widget _buildCameraSwitchButton() {
    final controller = widget.cameraBloc.cameraController;
    final isReady = controller != null &&
        controller.value.isInitialized &&
        !controller.value.hasError;

    return TapHandler(
      onTap: isReady
          ? () {
              widget.cameraBloc.add(CameraSwitchCameraEvent());
            }
          : null,
      child: Container(
        padding: IsrDimens.edgeInsetsAll(IsrDimens.twelve),
        decoration: BoxDecoration(
          color: isReady ? Colors.black54 : Colors.black26,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.flip_camera_ios,
          color: isReady ? Colors.white : Colors.white54,
          size: IsrDimens.twentyFour,
        ),
      ),
    );
  }

  Widget _buildFlashButton() => GestureDetector(
        onTap: () {
          final controller = widget.cameraBloc.cameraController;
          if (controller != null &&
              controller.value.isInitialized &&
              !controller.value.hasError) {
            widget.cameraBloc.add(CameraToggleFlashEvent());
          } else {
            Utility.showToastMessage('Camera not ready');
          }
        },
        child: Container(
          padding: IsrDimens.edgeInsetsAll(IsrDimens.twelve),
          decoration: const BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.cameraBloc.isFlashOn ? Icons.flash_on : Icons.flash_off,
            color: Colors.white,
            size: IsrDimens.twentyFour,
          ),
        ),
      );

  // Widget _buildDiscardButton() => GestureDetector(
  //       onTap: () => widget.cameraBloc.add(CameraDiscardRecordingEvent()),
  //       child: Container(
  //         padding: IsrDimens.edgeInsetsAll(IsrDimens.twelve),
  //         decoration: const BoxDecoration(
  //           color: Colors.black54,
  //           shape: BoxShape.circle,
  //         ),
  //         child: Icon(
  //           Icons.close,
  //           color: Colors.red,
  //           size: IsrDimens.twentyFour,
  //         ),
  //       ),
  //     );

  // Widget _buildRetakeButton() => GestureDetector(
  //       onTap: () => widget.cameraBloc.add(CameraDiscardRecordingEvent()),
  //       child: Container(
  //         padding: IsrDimens.edgeInsetsAll(IsrDimens.twelve),
  //         decoration: const BoxDecoration(
  //           color: Colors.black54,
  //           shape: BoxShape.circle,
  //         ),
  //         child: Icon(
  //           Icons.refresh,
  //           color: Colors.white,
  //           size: IsrDimens.twentyFour,
  //         ),
  //       ),
  //     );

  Widget _buildModeSelection() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (!widget.cameraBloc.isRecording ||
              !widget.cameraBloc.isSegmentRecording ||
              widget.cameraBloc.videoSegments.isEmpty) ...[
            _buildModeButton('Gallery', Icons.photo_library, null),
            _buildModeButton('Photo', Icons.camera_alt, MediaType.photo),
            // _buildModeButton('Video', Icons.videocam, MediaType.video),
            _buildDurationButton('15', 'Sec', 15),
            _buildDurationButton('60', 'Sec', 60),
          ],
        ],
      );

  Widget _buildModeButton(String label, IconData icon, MediaType? mediaType) {
    final isSelected = mediaType == null
        ? false
        : widget.cameraBloc.selectedMediaType == mediaType;

    return GestureDetector(
      onTap: () {
        if (mediaType != null) {
          widget.cameraBloc.add(CameraSetMediaTypeEvent(mediaType: mediaType));
        } else {
          _galleryClick();
        }
      },
      child: Column(
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : Colors.white70,
            size: 24.responsiveDimension,
          ),
          5.responsiveVerticalSpace,
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 14.responsiveDimension,
              fontWeight: FontWeight.w500,
            ),
          ),
          3.responsiveVerticalSpace,
          Container(
            height: IsrDimens.three,
            width: IsrDimens.twentyFive,
            color: isSelected ? IsrColors.white : Colors.transparent,
          ),
          10.responsiveVerticalSpace,
        ],
      ),
    );
  }

  void _galleryClick() async {
    if (widget.onGalleryClick != null) {
      try {
        final path = await widget.onGalleryClick!();
        if (path != null && Utility.isLocalUrl(path)) {
          final mediaType = await _getMediaType(File(path));
          widget.cameraBloc.add(CameraSetExternalMediaEvent(
              mediaPath: path, mediaType: mediaType));
          widget.onMediaPicked(path, mediaType);
        }
      } catch (e) {
        debugPrint('$e');
      }
    } else {
      await _showImageSourceBottomSheet();
    }
  }

  /// Determines if the file is a video or image based on file extension
  Future<MediaType> _getMediaType(File file) async {
    final filePath = file.path;
    if (filePath.isVideoFile) {
      return MediaType.video;
    } else if (filePath.isImageFile) {
      return MediaType.photo;
    } else {
      // Default to image if extension is not recognized
      return MediaType.photo;
    }
  }

  Widget _buildDurationButton(String value, String label, int duration) {
    final isSelected = widget.cameraBloc.selectedDuration == duration &&
        widget.cameraBloc.selectedMediaType == MediaType.video;
    return GestureDetector(
      onTap: () {
        // Auto-switch to video mode when duration is selected
        if (widget.cameraBloc.selectedMediaType != MediaType.video) {
          widget.cameraBloc
              .add(CameraSetMediaTypeEvent(mediaType: MediaType.video));
        }
        widget.cameraBloc.add(CameraSetDurationEvent(duration: duration));
      },
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 18.responsiveDimension,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 14.responsiveDimension,
              fontWeight: FontWeight.w500,
            ),
          ),
          3.responsiveVerticalSpace,
          Container(
            height: IsrDimens.three,
            width: IsrDimens.twentyFive,
            color: isSelected ? IsrColors.white : Colors.transparent,
          ),
          10.responsiveVerticalSpace,
        ],
      ),
    );
  }

  Future<void> _showImageSourceBottomSheet() async {
    await Utility.showBottomSheet(
      child: Container(
        decoration: BoxDecoration(
          color: IsrColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(IsrDimens.sixteen),
            topRight: Radius.circular(IsrDimens.sixteen),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IsrDimens.boxHeight(IsrDimens.twelve),
            Container(
              width: IsrDimens.thirtySix,
              height: IsrDimens.four,
              decoration: BoxDecoration(
                color: IsrColors.black,
                borderRadius: BorderRadius.circular(IsrDimens.two),
              ),
            ),
            IsrDimens.boxHeight(IsrDimens.sixteen),
            Padding(
              padding:
                  IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.sixteen),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(width: IsrDimens.twentyFour),
                  TapHandler(
                    onTap: () => context.pop(),
                    child: AppImage.svg(
                      AssetConstants.icClose,
                      width: IsrDimens.twentyFour,
                      height: IsrDimens.twentyFour,
                      color: IsrColors.black,
                    ),
                  ),
                ],
              ),
            ),
            IsrDimens.boxHeight(IsrDimens.twentyFour),
            Padding(
              padding:
                  IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.sixteen),
              child: Column(
                children: [
                  _buildImageSourceOption(
                    icon: AssetConstants.icMediaPhotos,
                    title: 'Choose image from gallery',
                    onTap: () {
                      context.pop();
                      _pickImageFromGallery();
                    },
                  ),
                  IsrDimens.boxHeight(IsrDimens.sixteen),
                  _buildImageSourceOption(
                    color: IsrColors.black,
                    icon: AssetConstants.icMediaVideos,
                    title: 'Choose video from gallery',
                    onTap: () {
                      context.pop();
                      _pickVideoFromGallery();
                    },
                  ),
                ],
              ),
            ),
            IsrDimens.boxHeight(IsrDimens.twentyFour),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildImageSourceOption({
    required String icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) =>
      TapHandler(
        onTap: onTap,
        child: Container(
          padding: IsrDimens.edgeInsetsSymmetric(
            vertical: IsrDimens.sixteen,
            horizontal: IsrDimens.sixteen,
          ),
          decoration: BoxDecoration(
            color: IsrColors.transparent,
            borderRadius: BorderRadius.circular(IsrDimens.eight),
          ),
          child: Row(
            children: [
              AppImage.svg(
                icon,
                width: IsrDimens.twentyFour,
                height: IsrDimens.twentyFour,
                color: color,
              ),
              IsrDimens.boxWidth(IsrDimens.sixteen),
              Text(
                title,
                style: IsrStyles.primaryText16.copyWith(
                  fontWeight: FontWeight.w500,
                  color: IsrColors.black,
                ),
              ),
            ],
          ),
        ),
      );

  Future<void> _pickImageFromGallery() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        widget.cameraBloc.add(CameraSetExternalMediaEvent(
            mediaPath: image.path, mediaType: MediaType.photo));
        widget.onMediaPicked(image.path, MediaType.photo);
      }
    } catch (e) {
      Utility.showToastMessage('Error picking image: $e');
    }
  }

  Future<void> _pickVideoFromGallery() async {
    try {
      final video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60),
      );

      if (video != null) {
        widget.cameraBloc.add(CameraSetExternalMediaEvent(
            mediaPath: video.path, mediaType: MediaType.video));
        widget.onMediaPicked(video.path, MediaType.video);
      }
    } catch (e) {
      Utility.showToastMessage('Error picking video: $e');
    }
  }
}
