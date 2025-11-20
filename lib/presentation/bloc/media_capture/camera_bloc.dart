import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/utils/enums.dart';
import 'package:video_player/video_player.dart';

part 'camera_event.dart';
part 'camera_state.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  CameraBloc() : super(CameraInitialState()) {
    on<CameraInitializeEvent>(_initializeCamera);
    on<CameraStartRecordingEvent>(_startRecording);
    on<CameraStopRecordingEvent>(_stopRecording);
    on<CameraCapturePhotoEvent>(_capturePhoto);
    on<CameraSwitchCameraEvent>(_switchCamera);
    on<CameraToggleFlashEvent>(_toggleFlash);
    on<CameraSetZoomEvent>(_setZoom);
    on<CameraSetDurationEvent>(_setDuration);
    on<CameraSetMediaTypeEvent>(_setMediaType);
    on<CameraConfirmRecordingEvent>(_confirmRecording);
    on<CameraDiscardRecordingEvent>(_discardRecording);
    on<CameraApplyFilterEvent>(_applyFilter);
    on<CameraNextStepEvent>(_nextStep);
    on<CameraResetEvent>(_resetCamera);
    on<CameraUpdateRecordingDurationEvent>(_updateRecordingDuration);
    on<CameraSetExternalMediaEvent>(_setExternalMedia);
  }

  CameraController? _cameraController;
  VideoPlayerController? _videoPlayerController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isRecording = false;
  bool _isStoppingRecording = false;
  bool _isFlashOn = false;
  double _currentZoom = 1.0;
  int _selectedDuration = 15; // 15 or 60 seconds
  String? _recordedVideoPath;
  String? _capturedPhotoPath;
  MediaType _selectedMediaType = MediaType.photo;
  String _selectedFilter = 'Normal';
  Timer? _recordingTimer;
  int _recordingDuration = 0;

  // Getters
  CameraController? get cameraController => _cameraController;
  VideoPlayerController? get videoPlayerController => _videoPlayerController;
  bool get isRecording => _isRecording;
  bool get isFlashOn => _isFlashOn;
  double get currentZoom => _currentZoom;
  int get selectedDuration => _selectedDuration;
  String? get recordedVideoPath => _recordedVideoPath;
  String? get capturedPhotoPath => _capturedPhotoPath;
  MediaType get selectedMediaType => _selectedMediaType;
  String get selectedFilter => _selectedFilter;
  int get recordingDuration => _recordingDuration;

  Future<void> _initializeCamera(
    CameraInitializeEvent event,
    Emitter<CameraState> emit,
  ) async {
    try {
      // If camera controller is already initialized and not disposed, just emit the state
      if (_cameraController != null &&
          _cameraController!.value.isInitialized &&
          !_cameraController!.value.hasError) {
        emit(CameraInitializedState(
          cameraController: _cameraController!,
          isFlashAvailable: true,
          maxZoom: 4.0,
        ));
        return;
      }

      emit(CameraLoadingState());

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        emit(CameraErrorState('No cameras available'));
        return;
      }

      // Safely dispose existing controller if it exists
      if (_cameraController != null) {
        try {
          await _cameraController!.dispose();
        } catch (e) {
          debugPrint('Error disposing camera controller: $e');
        }
        _cameraController = null;
      }

      _cameraController = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      // Verify controller is properly initialized and not disposed
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized ||
          _cameraController!.value.hasError) {
        emit(CameraErrorState('Camera controller failed to initialize'));
        return;
      }

      emit(CameraInitializedState(
        cameraController: _cameraController!,
        isFlashAvailable: true, // Default to true, can be checked later
        maxZoom: 4.0, // Default max zoom level
      ));
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      emit(CameraErrorState('Failed to initialize camera: $e'));
    }
  }

  Future<void> _startRecording(
    CameraStartRecordingEvent event,
    Emitter<CameraState> emit,
  ) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      if (_selectedMediaType == MediaType.video) {
        if (_isRecording) return;
        await _cameraController!.startVideoRecording();
        _isRecording = true;
        _isStoppingRecording = false;
        _recordingDuration = 0;

        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_isStoppingRecording) return;
          _recordingDuration++;
          if (_recordingDuration >= _selectedDuration) {
            _isStoppingRecording = true;
            add(CameraStopRecordingEvent());
            return;
          }
          add(CameraUpdateRecordingDurationEvent(_recordingDuration));
        });

        emit(CameraRecordingState(
          isRecording: true,
          recordingDuration: _recordingDuration,
          maxDuration: _selectedDuration,
        ));
      }
    } catch (e) {
      emit(CameraErrorState('Failed to start recording: $e'));
    }
  }

  Future<void> _stopRecording(
    CameraStopRecordingEvent event,
    Emitter<CameraState> emit,
  ) async {
    if (_cameraController == null || !_isRecording || _isStoppingRecording) {
      return;
    }

    try {
      _isStoppingRecording = true;
      final videoFile = await _cameraController!.stopVideoRecording();
      _isRecording = false;
      _recordingTimer?.cancel();
      _recordedVideoPath = videoFile.path;

      // Initialize video player for preview
      _videoPlayerController = VideoPlayerController.file(File(videoFile.path));
      await _videoPlayerController!.initialize();

      emit(CameraRecordingReadyState(
        videoPath: _recordedVideoPath!,
        videoController: _videoPlayerController!,
        recordingDuration: _recordingDuration,
      ));
    } catch (e) {
      _recordingTimer?.cancel();
      _isRecording = false;
      emit(CameraErrorState('Failed to stop recording: $e'));
    } finally {
      _isStoppingRecording = false;
    }
  }

  Future<void> _capturePhoto(
    CameraCapturePhotoEvent event,
    Emitter<CameraState> emit,
  ) async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _cameraController!.value.hasError) {
      emit(CameraErrorState('Camera not ready for photo capture'));
      return;
    }

    try {
      final photoFile = await _cameraController!.takePicture();
      _capturedPhotoPath = photoFile.path;

      emit(CameraPhotoCapturedState(photoPath: _capturedPhotoPath!));
    } catch (e) {
      debugPrint('Photo capture error: $e');
      emit(CameraErrorState('Failed to capture photo: $e'));
    }
  }

  Future<void> _switchCamera(
    CameraSwitchCameraEvent event,
    Emitter<CameraState> emit,
  ) async {
    if (_cameras.length < 2) return;

    try {
      // Safely dispose existing controller
      if (_cameraController != null) {
        try {
          await _cameraController!.dispose();
        } catch (e) {
          debugPrint('Error disposing camera controller during switch: $e');
        }
        _cameraController = null;
      }

      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;

      _cameraController = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      // Verify controller is properly initialized before emitting state
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized ||
          _cameraController!.value.hasError) {
        emit(CameraErrorState('Failed to initialize camera after switch'));
        return;
      }

      emit(CameraSwitchedState(
        cameraController: _cameraController!,
        isFlashAvailable: true,
        maxZoom: 4.0,
      ));
    } catch (e) {
      debugPrint('Camera switch error: $e');
      emit(CameraErrorState('Failed to switch camera: $e'));
    }
  }

  Future<void> _toggleFlash(
    CameraToggleFlashEvent event,
    Emitter<CameraState> emit,
  ) async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _cameraController!.value.hasError) {
      emit(CameraErrorState('Camera not ready for flash toggle'));
      return;
    }

    try {
      _isFlashOn = !_isFlashOn;
      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );

      emit(CameraFlashToggledState(isFlashOn: _isFlashOn));
    } catch (e) {
      debugPrint('Flash toggle error: $e');
      emit(CameraErrorState('Failed to toggle flash: $e'));
    }
  }

  Future<void> _setZoom(
    CameraSetZoomEvent event,
    Emitter<CameraState> emit,
  ) async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _cameraController!.value.hasError) {
      emit(CameraErrorState('Camera not ready for zoom'));
      return;
    }

    try {
      _currentZoom = event.zoomLevel;
      await _cameraController!.setZoomLevel(_currentZoom);

      emit(CameraZoomChangedState(zoomLevel: _currentZoom));
    } catch (e) {
      debugPrint('Zoom error: $e');
      emit(CameraErrorState('Failed to set zoom: $e'));
    }
  }

  Future<void> _setDuration(
    CameraSetDurationEvent event,
    Emitter<CameraState> emit,
  ) async {
    _selectedDuration = event.duration;
    emit(CameraDurationChangedState(duration: _selectedDuration));
  }

  Future<void> _setMediaType(
    CameraSetMediaTypeEvent event,
    Emitter<CameraState> emit,
  ) async {
    _selectedMediaType = event.mediaType;
    emit(CameraMediaTypeChangedState(mediaType: _selectedMediaType));
  }

  Future<void> _updateRecordingDuration(
    CameraUpdateRecordingDurationEvent event,
    Emitter<CameraState> emit,
  ) async {
    if (!_isRecording || _isStoppingRecording) {
      return;
    }
    _recordingDuration = event.duration;
    if (_isRecording && !_isStoppingRecording) {
      emit(CameraRecordingState(
        isRecording: true,
        recordingDuration: _recordingDuration,
        maxDuration: _selectedDuration,
      ));
    }
  }

  Future<void> _confirmRecording(
    CameraConfirmRecordingEvent event,
    Emitter<CameraState> emit,
  ) async {
    if (_recordedVideoPath != null || _capturedPhotoPath != null) {
      emit(CameraRecordingConfirmedState(
        mediaPath: _recordedVideoPath ?? _capturedPhotoPath!,
        mediaType: _selectedMediaType,
        filter: _selectedFilter,
      ));
    }
  }

  Future<void> _setExternalMedia(
    CameraSetExternalMediaEvent event,
    Emitter<CameraState> emit,
  ) async {
    // When media is chosen from gallery, set the appropriate path and media type
    _selectedMediaType = event.mediaType;
    if (event.mediaType == MediaType.video) {
      _recordedVideoPath = event.mediaPath;
      _capturedPhotoPath = null;
    } else {
      _capturedPhotoPath = event.mediaPath;
      _recordedVideoPath = null;
    }
    emit(CameraMediaTypeChangedState(mediaType: _selectedMediaType));
  }

  Future<void> _discardRecording(
    CameraDiscardRecordingEvent event,
    Emitter<CameraState> emit,
  ) async {
    _recordedVideoPath = null;
    _capturedPhotoPath = null;
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
    _recordingDuration = 0;

    // Return to camera view
    if (_cameraController != null) {
      emit(CameraInitializedState(
        cameraController: _cameraController!,
        isFlashAvailable: true,
        maxZoom: 4.0,
      ));
    } else {
      emit(CameraInitialState());
    }
  }

  Future<void> _applyFilter(
    CameraApplyFilterEvent event,
    Emitter<CameraState> emit,
  ) async {
    _selectedFilter = event.filterName;
    emit(CameraFilterAppliedState(filterName: _selectedFilter));
  }

  Future<void> _nextStep(
    CameraNextStepEvent event,
    Emitter<CameraState> emit,
  ) async {
    final path = _recordedVideoPath ?? _capturedPhotoPath;
    if (path == null || path.isEmpty) {
      emit(CameraErrorState(
          'No media to proceed. Please capture photo or video.'));
      return;
    }

    // Use filtered image path if provided, otherwise use original path
    final mediaPath = event.filteredImagePath ?? path;

    emit(CameraNextStepState(
      mediaPath: mediaPath,
      mediaType: _selectedMediaType,
      filter: _selectedFilter,
      filteredImagePath: event.filteredImagePath,
    ));
  }

  Future<void> _resetCamera(
    CameraResetEvent event,
    Emitter<CameraState> emit,
  ) async {
    // Only dispose video player controller, keep camera controller for reuse
    await _videoPlayerController?.dispose();
    _videoPlayerController = null;
    _isRecording = false;
    _isFlashOn = false;
    _currentZoom = 1.0;
    _selectedDuration = 15;
    _recordedVideoPath = null;
    _capturedPhotoPath = null;
    _selectedMediaType = MediaType.photo;
    _selectedFilter = 'Normal';
    _recordingDuration = 0;
    _recordingTimer?.cancel();

    // If camera controller exists and is initialized, emit initialized state
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      emit(CameraInitializedState(
        cameraController: _cameraController!,
        isFlashAvailable: true,
        maxZoom: 4.0,
      ));
    } else {
      emit(CameraInitialState());
    }
  }

  @override
  Future<void> close() async {
    // Cancel any ongoing recording timer
    _recordingTimer?.cancel();
    _recordingTimer = null;

    // Safely dispose video player controller
    if (_videoPlayerController != null) {
      try {
        await _videoPlayerController!.dispose();
      } catch (e) {
        debugPrint('Error disposing video player controller: $e');
      }
      _videoPlayerController = null;
    }

    // Safely dispose camera controller
    if (_cameraController != null) {
      try {
        await _cameraController!.dispose();
      } catch (e) {
        debugPrint('Error disposing camera controller: $e');
      }
      _cameraController = null;
    }

    return super.close();
  }
}
