import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/domain/models/sound_library_models.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_capture/camera.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class CameraCaptureView extends StatefulWidget {
  const CameraCaptureView({
    super.key,
    this.mediaType = MediaType.both,
    this.onGalleryClick,
    this.onAddSoundTap,
    this.onDismissEntireFlow,
    this.dubWithAudioMode = false,
    this.initialCameraMusic,
    this.dubSoundPickerTracks,
  });

  final MediaType mediaType;
  final Future<String?> Function()? onGalleryClick;
  final void Function(BuildContext context)? onAddSoundTap;
  final VoidCallback? onDismissEntireFlow;
  final bool dubWithAudioMode;
  final CameraSetMusicEvent? initialCameraMusic;
  final List<SoundTrack>? dubSoundPickerTracks;

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
    _initializeCameraWithRetry();
  }

  Future<void> _initializeCameraWithRetry() async {
    if (widget.dubWithAudioMode) {
      _cameraBloc.add(CameraSetMediaTypeEvent(mediaType: MediaType.video));
      _cameraBloc.add(CameraSetDurationEvent(duration: 15));
      if (widget.initialCameraMusic != null) {
        _cameraBloc.add(widget.initialCameraMusic!);
      }
      _cameraBloc.add(CameraInitializeEvent());
    } else {
      _cameraBloc.add(CameraInitializeEvent());
      _cameraBloc.add(CameraSetMediaTypeEvent(
          mediaType: widget.mediaType == MediaType.both
              ? MediaType.photo
              : widget.mediaType));
      _cameraBloc.add(CameraSetDurationEvent(duration: 15));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
      _cameraBloc.add(CameraFramingMusicAppPausedEvent(true));
    } else if (state == AppLifecycleState.resumed) {
      _cameraBloc.add(CameraFramingMusicAppPausedEvent(false));
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
                final segments = state.segments != null
                    ? List<VideoSegment>.from(state.segments!)
                    : null;

                _navigateToEditScreenWithSegments(
                  state.mediaPath,
                  MediaType.video,
                  segments,
                );
              }
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
                state is CameraBottomLoadingState ||
                state is CameraMusicSelectedState) {
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
            children: [
              CameraPreviewWidget(
                cameraBloc: _cameraBloc,
                state: state,
              ),
              CameraTopControls(
                cameraBloc: _cameraBloc,
                onAddSoundTap: widget.onAddSoundTap,
                onDismissEntireFlow: widget.onDismissEntireFlow,
                dubSoundPickerTracks: widget.dubSoundPickerTracks,
                dubWithAudioMode: widget.dubWithAudioMode,
              ),
              CameraBottomControls(
                cameraBloc: _cameraBloc,
                dubWithAudioMode: widget.dubWithAudioMode,
                onGalleryClick: widget.onGalleryClick,
                state: state,
                onMediaPicked: (path, type) {
                  if (!_isNavigatingToEdit) {
                    _isNavigatingToEdit = true;
                    _navigateToEditScreen(path, type);
                  }
                },
              ),
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
