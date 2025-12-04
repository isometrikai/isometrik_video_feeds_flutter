import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:video_player/video_player.dart';

class CameraCaptureView extends StatefulWidget {
  const CameraCaptureView({
    super.key,
    this.mediaType = MediaType.both,
    this.onPickMedia,
  });

  final MediaType mediaType;
  final Future<String?> Function()? onPickMedia;

  @override
  State<CameraCaptureView> createState() => _CameraCaptureViewState();
}

class _CameraCaptureViewState extends State<CameraCaptureView> with WidgetsBindingObserver {
  late final CameraBloc _cameraBloc; //IsmInjectionUtils.getBloc<CameraBloc>();
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _cameraBloc = CameraBloc();
    WidgetsBinding.instance.addObserver(this);
    _initializeCameraWithRetry();
  }

  Future<void> _initializeCameraWithRetry() async {
    _cameraBloc.add(CameraInitializeEvent());
    _cameraBloc.add(CameraSetMediaTypeEvent(
        mediaType: widget.mediaType == MediaType.both ? MediaType.photo : widget.mediaType));
    _cameraBloc.add(CameraSetDurationEvent(duration: 60));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraBloc.add(CameraResetEvent());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    final controller = _cameraBloc.cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
    } else if (state == AppLifecycleState.resumed) {
      if (controller.value.hasError || !controller.value.isInitialized) {
        _cameraBloc.add(CameraInitializeEvent());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return BlocProvider(
      create: (context) => _cameraBloc,
      child: BlocConsumer<CameraBloc, CameraState>(
        listener: (context, state) {
          if (state is CameraErrorState) {
            Utility.showToastMessage(state.message);
          } else if (state is CameraPhotoCapturedState) {
            _onCompleteCapture(state.photoPath, MediaType.photo);
          } else if (state is CameraRecordingConfirmedState) {
            _onCompleteCapture(state.mediaPath, MediaType.video);
          } else if (state is CameraRecordingReadyState) {
            _onCompleteCapture(state.videoPath, MediaType.video);
          }
        },
        builder: (context, state) {
          if (state is CameraLoadingState) {
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }

          if (state is CameraErrorState) {
            return Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.white, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: IsrStyles.white16,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      title: 'Retry',
                      onPress: () => _cameraBloc.add(CameraInitializeEvent()),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is CameraInitializedState ||
              state is CameraSwitchedState ||
              state is CameraFlashToggledState ||
              state is CameraZoomChangedState ||
              state is CameraDurationChangedState ||
              state is CameraRecordingState ||
              state is CameraMediaTypeChangedState ||
              state is CameraRecordingReadyState ||
              state is CameraRecordingDiscardedState ||
              state is CameraFilterAppliedState) {
            if (mounted && context.mounted) {
              return _buildCameraView(state);
            }
          }

          if (state is CameraInitialState) {
            final controller = _cameraBloc.cameraController;
            if (controller != null &&
                controller.value.isInitialized &&
                !controller.value.hasError &&
                mounted &&
                context.mounted) {
              return _buildCameraView(state);
            }
          }

          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCameraView(CameraState state) => Scaffold(
        backgroundColor: IsrColors.white,
        extendBodyBehindAppBar: true, // body can go under app bar intentionally
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: true,
          leading: IconButton(
            icon: Icon(
              Icons.close,
              color: Colors.white,
              size: 24.responsiveDimension,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions:
              (_cameraBloc.selectedMediaType == MediaType.video) ? _buildDurationSelection() : [],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    state is CameraRecordingReadyState
                        ? Positioned.fill(child: _buildVideoPreview(state))
                        : Positioned.fill(child: _buildCameraPreview(state)),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          _buildBottomControls(),
                          16.responsiveVerticalSpace,
                          if (_cameraBloc.isRecording)
                            _buildRecordingProgressBar(state)
                          else
                            4.responsiveVerticalSpace,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_cameraBloc.recordedVideoPath == null || _cameraBloc.isRecording) ...[
                _buildModeSelection(),
              ],
            ],
          ),
        ),
      );

  Widget _buildCameraPreview(CameraState state) {
    CameraController? controller;

    if (state is CameraInitializedState) {
      controller = state.cameraController;
    } else if (state is CameraSwitchedState) {
      controller = state.cameraController;
    } else {
      controller = _cameraBloc.cameraController;
    }

    if (controller != null &&
        !controller.value.hasError &&
        controller.value.isInitialized &&
        mounted &&
        context.mounted) {
      return CameraPreview(controller);
    } else {
      if (mounted) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildBottomControls() => SafeArea(
        child: Padding(
          padding: IsrDimens.edgeInsetsAll(IsrDimens.sixteen).copyWith(bottom: 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildZoomControls(),

              IsrDimens.boxHeight(IsrDimens.twenty),

              // Main Controls Row
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (_cameraBloc.recordedVideoPath != null && !_cameraBloc.isRecording) ...[
                          _buildDiscardButton(),
                          16.responsiveVerticalSpace,
                        ],
                        _buildFlashButton(),
                      ],
                    ),
                  ),
                  _buildRecordButton(),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _cameraBloc.recordedVideoPath != null && !_cameraBloc.isRecording
                            ? _buildRetakeButton()
                            : _buildCameraSwitchButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildZoomControls() => Container(
        width: IsrDimens.percentWidth(0.5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          // color: Colors.black54,
          borderRadius: BorderRadius.circular(IsrDimens.sixteen),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildZoomButton('2x', 2.0),
            IsrDimens.boxWidth(IsrDimens.sixteen),
            _buildZoomButton('1x', 1.0),
            IsrDimens.boxWidth(IsrDimens.sixteen),
            _buildZoomButton('3x', 3.0),
          ],
        ),
      );

  Widget _buildZoomButton(String label, double zoomLevel) {
    final isSelected = _cameraBloc.currentZoom == zoomLevel;
    return InkWell(
      onTap: () {
        final controller = _cameraBloc.cameraController;
        if (controller != null && controller.value.isInitialized && !controller.value.hasError) {
          _cameraBloc.add(CameraSetZoomEvent(zoomLevel: zoomLevel));
        } else {
          Utility.showToastMessage('Camera not ready');
        }
      },
      child: Container(
        padding: IsrDimens.edgeInsetsSymmetric(
          horizontal: IsrDimens.twelve,
          vertical: IsrDimens.six,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.black54,
          borderRadius: BorderRadius.circular(IsrDimens.sixteen),
        ),
        child: Text(
          label,
          style: IsrStyles.white14.copyWith(
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildFlashButton() => GestureDetector(
        onTap: () {
          final controller = _cameraBloc.cameraController;
          if (controller != null && controller.value.isInitialized && !controller.value.hasError) {
            _cameraBloc.add(CameraToggleFlashEvent());
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
            _cameraBloc.isFlashOn ? Icons.flash_on : Icons.flash_off,
            color: Colors.white,
            size: IsrDimens.twentyFour,
          ),
        ),
      );

  Widget _buildRecordButton() {
    final isRecording = _cameraBloc.isRecording;
    final hasRecordedVideo = _cameraBloc.recordedVideoPath != null;
    final controller = _cameraBloc.cameraController;
    final isControllerReady =
        controller != null && controller.value.isInitialized && !controller.value.hasError;

    return GestureDetector(
        onTap: () {
          if (!isControllerReady) {
            Utility.showToastMessage('Camera not ready');
            return;
          }

          if (_cameraBloc.selectedMediaType == MediaType.photo) {
            _cameraBloc.add(CameraCapturePhotoEvent());
          } else if (_cameraBloc.selectedMediaType == MediaType.video) {
            if (isRecording) {
              _cameraBloc.add(CameraStopRecordingEvent());
            } else if (hasRecordedVideo) {
              _cameraBloc.add(CameraConfirmRecordingEvent());
            } else {
              _cameraBloc.add(CameraStartRecordingEvent());
            }
          }
        },
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
              color: isRecording
                  ? Colors.red
                  : hasRecordedVideo
                      ? Colors.green
                      : IsrColors.white,
            ),
            child: hasRecordedVideo && !isRecording
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 32,
                  )
                : null,
          ),
        ));
  }

  Widget _buildCameraSwitchButton() => GestureDetector(
        onTap: () {
          final controller = _cameraBloc.cameraController;
          if (controller != null && controller.value.isInitialized && !controller.value.hasError) {
            _cameraBloc.add(CameraSwitchCameraEvent());
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
            Icons.flip_camera_ios,
            color: Colors.white,
            size: IsrDimens.twentyFour,
          ),
        ),
      );

  Widget _buildModeSelection() => Column(
        children: [
          16.responsiveVerticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (!_cameraBloc.isRecording) ...[
                _buildModeButton('Gallery', Icons.photo_library, null),
                _buildModeButton('Photo', Icons.camera_alt, MediaType.photo),
              ],
              _buildModeButton('Video', Icons.videocam, MediaType.video),
            ],
          ),
        ],
      );

  Widget _buildModeButton(String label, IconData icon, MediaType? mediaType) {
    final isSelected = mediaType == null ? false : _cameraBloc.selectedMediaType == mediaType;

    return GestureDetector(
      onTap: () {
        if (mediaType != null) {
          _cameraBloc.add(CameraSetMediaTypeEvent(mediaType: mediaType));
        } else {
          // Gallery functionality
          if (widget.onPickMedia != null) {
            widget.onPickMedia!();
          } else {
            _pickFromGallery();
          }
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.black,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2,
              width: 20,
              color: Colors.black,
            ),
        ],
      ),
    );
  }

  List<Widget> _buildDurationSelection() => [
        _buildDurationButton('15s', 15),
        IsrDimens.boxWidth(IsrDimens.sixteen),
        _buildDurationButton('60s', 60),
        IsrDimens.boxWidth(IsrDimens.sixteen),
      ];

  Widget _buildDurationButton(String label, int duration) {
    final isSelected = _cameraBloc.selectedDuration == duration;
    return GestureDetector(
      onTap: () {
        _cameraBloc.add(CameraSetDurationEvent(duration: duration));
      },
      child: Text(
        label,
        style: IsrStyles.white16.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? Colors.red : Colors.white,
        ),
      ),
    );
  }

  Widget _buildRecordingProgressBar(CameraState state) {
    var recordingDuration = 0;
    var maxDuration = _cameraBloc.selectedDuration;

    if (state is CameraRecordingState) {
      recordingDuration = state.recordingDuration;
      maxDuration = state.maxDuration;
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SizedBox(
        height: IsrDimens.four,
        child: LinearProgressIndicator(
          value: maxDuration > 0 ? recordingDuration / maxDuration : 0.0,
          backgroundColor: IsrColors.transparent,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
        ),
      ),
    );
  }

  void _onCompleteCapture(String mediaPath, MediaType mediaTypeOverride) {
    Navigator.pop(context, mediaPath);
  }

  Widget _buildVideoPreview(CameraRecordingReadyState state) {
    // Check if video controller is properly initialized
    if (!state.videoController.value.isInitialized) {
      return Container(
        color: IsrColors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Auto-play the video when preview is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.videoController.value.isInitialized && !state.videoController.value.isPlaying) {
        state.videoController.play();
      }
    });

    return Center(
      child: AspectRatio(
        aspectRatio: state.videoController.value.aspectRatio,
        child: VideoPlayer(state.videoController),
      ),
    );
  }

  Widget _buildDiscardButton() => GestureDetector(
        onTap: () => _cameraBloc.add(CameraDiscardRecordingEvent()),
        child: Container(
          padding: IsrDimens.edgeInsetsAll(IsrDimens.twelve),
          decoration: const BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.close,
            color: Colors.red,
            size: IsrDimens.twentyFour,
          ),
        ),
      );

  Widget _buildRetakeButton() => GestureDetector(
        onTap: () => _cameraBloc.add(CameraDiscardRecordingEvent()),
        child: Container(
          padding: IsrDimens.edgeInsetsAll(IsrDimens.twelve),
          decoration: const BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.refresh,
            color: Colors.white,
            size: IsrDimens.twentyFour,
          ),
        ),
      );

  Future<void> _pickFromGallery() async {
    try {
      // Show bottom sheet to choose between photo and video
      await Utility.showBottomSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IsrDimens.boxHeight(IsrDimens.twenty),
            Text(
              'Choose from Gallery',
              style: IsrStyles.primaryText18.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            IsrDimens.boxHeight(IsrDimens.thirty),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildGalleryOption(
                  icon: Icons.photo_library,
                  title: 'Photo',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromGallery();
                  },
                ),
                _buildGalleryOption(
                  icon: Icons.video_library,
                  title: 'Video',
                  onTap: () {
                    Navigator.pop(context);
                    _pickVideoFromGallery();
                  },
                ),
              ],
            ),
            IsrDimens.boxHeight(IsrDimens.thirty),
          ],
        ),
        isScrollControlled: true,
      );
    } catch (e) {
      Utility.showToastMessage('Error opening gallery: $e');
    }
  }

  Widget _buildGalleryOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: IsrDimens.edgeInsetsAll(IsrDimens.twentyFour),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: IsrDimens.thirtyTwo,
              ),
            ),
            IsrDimens.boxHeight(IsrDimens.twelve),
            Text(
              title,
              style: IsrStyles.white14.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
        _cameraBloc
            .add(CameraSetExternalMediaEvent(mediaPath: image.path, mediaType: MediaType.photo));
        _onCompleteCapture(image.path, MediaType.photo);
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
        _cameraBloc
            .add(CameraSetExternalMediaEvent(mediaPath: video.path, mediaType: MediaType.video));
        _onCompleteCapture(video.path, MediaType.video);
      }
    } catch (e) {
      Utility.showToastMessage('Error picking video: $e');
    }
  }
}
