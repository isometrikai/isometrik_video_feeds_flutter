import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_capture/camera.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class CameraCaptureView extends StatefulWidget {
  const CameraCaptureView({
    super.key,
    this.mediaType = MediaType.both,
    this.onGalleryClick,
  });

  final MediaType mediaType;
  final Future<String?> Function()? onGalleryClick;

  @override
  State<CameraCaptureView> createState() => _CameraCaptureViewState();
}

class _CameraCaptureViewState extends State<CameraCaptureView>
    with WidgetsBindingObserver {
  late final CameraBloc _cameraBloc;
  bool _isNavigatingToEdit = false;

  @override
  void initState() {
    super.initState();
    _cameraBloc = context.getOrCreateBloc();
    WidgetsBinding.instance.addObserver(this);
    // Lock orientation to portrait mode
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.portraitUp,
    // ]);
    _initializeCameraWithRetry();
  }

  Future<void> _initializeCameraWithRetry() async {
    _cameraBloc.add(CameraInitializeEvent());
    _cameraBloc.add(CameraSetMediaTypeEvent(
        mediaType: widget.mediaType == MediaType.both
            ? MediaType.video
            : widget.mediaType));
    // Auto-select 15 seconds duration by default
    _cameraBloc.add(CameraSetDurationEvent(duration: 15));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // // Unlock orientation when leaving camera screen
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.portraitUp,
    //   DeviceOrientation.portraitDown,
    //   DeviceOrientation.landscapeLeft,
    //   DeviceOrientation.landscapeRight,
    // ]);
    _cameraBloc.add(CameraDisposeEvent());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    final controller = _cameraBloc.cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
    } else if (state == AppLifecycleState.resumed) {
      if (controller.value.hasError || !controller.value.isInitialized) {
        _cameraBloc.add(CameraInitializeEvent());
      }
    }
  }

  @override
  Widget build(BuildContext context) => context.attachBlocIfNeeded<CameraBloc>(
        bloc: _cameraBloc,
        child: BlocConsumer<CameraBloc, CameraState>(
          bloc: _cameraBloc,
          listener: (context, state) {
            if (state is CameraErrorState) {
              Utility.showToastMessage(state.message);
            } else if (state is CameraPhotoCapturedState &&
                !_isNavigatingToEdit) {
              _isNavigatingToEdit = true;
              _navigateToEditScreen(state.photoPath, MediaType.photo);
            } else if (state is CameraRecordingConfirmedState) {
              if (!_isNavigatingToEdit) {
                _isNavigatingToEdit = true;
                // Pass segments if available (for segment recordings)
                final segments = state.segments != null
                    ? List<VideoSegment>.from(state.segments!)
                    : null;

                debugPrint(
                    'Navigating to edit with ${segments?.length ?? 0} segments');
                if (segments != null) {
                  debugPrint(
                      'Segment paths: ${segments.map((s) => s.path).toList()}');
                }

                _navigateToEditScreenWithSegments(
                  state.mediaPath,
                  MediaType.video,
                  segments,
                );
              }
              // // Always navigate when recording is confirmed (either manual or auto-stop)
              // debugPrint(
              //     'CameraRecordingConfirmedState received, mediaPath: ${state.mediaPath}');
              // if (!_isNavigatingToEdit) {
              //   _isNavigatingToEdit = true;
              //   debugPrint(
              //       'Navigating to edit screen with video: ${state.mediaPath}');
              //   _navigateToEditScreen(state.mediaPath, MediaType.video);
              // }
            } else if (state is CameraRecordingReadyState &&
                !_isNavigatingToEdit) {}
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
                backgroundColor: Colors.black,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error,
                          color: Colors.white, size: IsrDimens.sixtyFour),
                      IsrDimens.boxHeight(IsrDimens.sixteen),
                      Text(
                        state.message,
                        style: IsrStyles.white16,
                        textAlign: TextAlign.center,
                      ),
                      IsrDimens.boxHeight(IsrDimens.twentyFour),
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
                state is CameraFilterAppliedState ||
                state is CameraSpeedChangedState ||
                state is CameraSegmentRecordingState ||
                state is CameraBottomLoadingState) {
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

  Widget _buildCameraView(CameraState state) => AnnotatedRegion(
        value: const SystemUiOverlayStyle(
          statusBarColor: IsrColors.transparent,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: IsrColors.black,
          body: Stack(
            // fit: StackFit.expand,
            children: [
              CameraPreviewWidget(
                cameraBloc: _cameraBloc,
                state: state,
              ),
              CameraTopControls(cameraBloc: _cameraBloc),
              CameraBottomControls(
                cameraBloc: _cameraBloc,
                onGalleryClick: widget.onGalleryClick,
                state: state,
                onMediaPicked: (path, type) {
                  if (!_isNavigatingToEdit) {
                    _isNavigatingToEdit = true;
                    _navigateToEditScreen(path, type);
                  }
                },
              ),
              // if (_cameraBloc.isSegmentRecording) const CameraRecordingSplash(),
            ],
          ),
        ),
      );

  void _navigateToEditScreen(String mediaPath, MediaType mediaTypeOverride) {
    final segments =
        _cameraBloc.videoSegments.isNotEmpty ? _cameraBloc.videoSegments : null;

    _navigateToEditScreenWithSegments(mediaPath, mediaTypeOverride, segments);
  }

  void _navigateToEditScreenWithSegments(
    String mediaPath,
    MediaType mediaTypeOverride,
    List<VideoSegment>? segments,
  ) {
    Navigator.pop(context, mediaPath);
    _isNavigatingToEdit = false;

    _cameraBloc.add(CameraDiscardRecordingEvent());

    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        final controller = _cameraBloc.cameraController;

        if (controller == null ||
            !controller.value.isInitialized ||
            controller.value.hasError) {
          _cameraBloc.add(CameraInitializeEvent());
        } else {
          _cameraBloc.add(CameraSetMediaTypeEvent(
              mediaType: widget.mediaType == MediaType.both
                  ? MediaType.video
                  : widget.mediaType));
        }
      }
    });
  }
}
