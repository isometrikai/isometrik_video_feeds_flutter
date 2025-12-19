import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
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
    on<CameraPauseForEditEvent>(_pauseForEdit);
    on<CameraDisposeEvent>(_disposeAll);
    on<CameraUpdateRecordingDurationEvent>(_updateRecordingDuration);
    on<CameraSetExternalMediaEvent>(_setExternalMedia);

    on<CameraSetSpeedEvent>(_setSpeed);
    on<CameraStartSegmentRecordingEvent>(_startSegmentRecording);
    on<CameraStopSegmentRecordingEvent>(_stopSegmentRecording);
    on<CameraRemoveLastSegmentEvent>(_removeLastSegment);
    on<CameraUpdateSegmentRecordingDurationEvent>(
        _updateSegmentRecordingDuration);
  }

  CameraController? _cameraController;
  VideoPlayerController? _videoPlayerController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isFlashOn = false;
  double _currentZoom = 1.0;
  int _selectedDuration = 0;
  double _selectedSpeed = 1.0;
  String? _recordedVideoPath;
  String? _capturedPhotoPath;
  MediaType _selectedMediaType = MediaType.photo;
  String _selectedFilter = 'Normal';
  Timer? _recordingTimer;
  int _recordingDuration = 0;
  bool _isSwitchingCamera = false;
  String? _selectedMusicId;
  String? _selectedMusicName;
  String? _selectedMusicArtist;

  final List<VideoSegment> _videoSegments = [];
  bool _isSegmentRecording = false;
  int _currentSegmentDuration = 0;
  Timer? _segmentTimer;

  CameraController? get cameraController => _cameraController;
  VideoPlayerController? get videoPlayerController => _videoPlayerController;
  // Use segment recording flag for backward compatibility
  bool get isRecording => _isSegmentRecording;
  bool get isFlashOn => _isFlashOn;
  double get currentZoom => _currentZoom;
  int get selectedDuration => _selectedDuration;
  double get selectedSpeed => _selectedSpeed;
  String? get recordedVideoPath => _recordedVideoPath;
  String? get capturedPhotoPath => _capturedPhotoPath;
  MediaType get selectedMediaType => _selectedMediaType;
  String get selectedFilter => _selectedFilter;
  int get recordingDuration => _recordingDuration;
  String? get selectedMusicId => _selectedMusicId;
  String? get selectedMusicName => _selectedMusicName;
  String? get selectedMusicArtist => _selectedMusicArtist;
  bool get hasMusicSelected =>
      _selectedMusicId != null && _selectedMusicId!.isNotEmpty;
  bool get isSegmentRecording => _isSegmentRecording;
  List<VideoSegment> get videoSegments => _videoSegments;
  int get totalRecordingDuration {
    final segmentsDuration = _videoSegments.fold<int>(
      0,
      (sum, segment) => sum + segment.duration,
    );
    return segmentsDuration + _recordingDuration;
  }

  Future<void> _initializeCamera(
    CameraInitializeEvent event,
    Emitter<CameraState> emit,
  ) async {
    try {
      _recordedVideoPath = null;
      _capturedPhotoPath = null;

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

      await _releaseCamera();

      _cameraController = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (_cameraController == null ||
          !_cameraController!.value.isInitialized ||
          _cameraController!.value.hasError) {
        emit(CameraErrorState('Camera controller failed to initialize'));
        return;
      }

      emit(CameraInitializedState(
          cameraController: _cameraController!,
          isFlashAvailable: true,
          maxZoom: 4.0));
    } catch (e) {
      AppLog.error('Camera initialization error: $e');
      emit(CameraErrorState('Failed to initialize camera: $e'));
    }
  }

  Future<void> _startRecording(
    CameraStartRecordingEvent event,
    Emitter<CameraState> emit,
  ) async {
    // Delegate to segment recording for unified behavior
    await _startSegmentRecording(
      CameraStartSegmentRecordingEvent(),
      emit,
    );
  }

  Future<void> _stopRecording(
    CameraStopRecordingEvent event,
    Emitter<CameraState> emit,
  ) async {
    // Delegate to segment recording for unified behavior
    await _stopSegmentRecording(
      CameraStopSegmentRecordingEvent(),
      emit,
    );
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
      emit(CameraBottomLoadingState());
      final photoFile = await _cameraController!.takePicture();
      if (_cameraController?.description.lensDirection == CameraLensDirection.front) {
        _capturedPhotoPath = await MediaUtil.mirrorMedia(File(photoFile.path)).then((value) => value.path);
      } else {
        _capturedPhotoPath = photoFile.path;
      }

      emit(CameraPhotoCapturedState(photoPath: _capturedPhotoPath!));
    } catch (e) {
      AppLog.error('Photo capture error: $e');
      emit(CameraErrorState('Failed to capture photo: $e'));
    }
  }

  Future<void> _switchCamera(
    CameraSwitchCameraEvent event,
    Emitter<CameraState> emit,
  ) async {
    if (_cameras.length < 2) return;
    if (_isSwitchingCamera) return;

    _isSwitchingCamera = true;

    try {
      emit(CameraLoadingState());

      await _releaseCamera();

      final currentLens = _cameras.isNotEmpty
          ? _cameras[_selectedCameraIndex].lensDirection
          : CameraLensDirection.back;
      final targetLens = (currentLens == CameraLensDirection.front)
          ? CameraLensDirection.back
          : CameraLensDirection.front;

      int? targetIndex;
      for (var i = 0; i < _cameras.length; i++) {
        if (_cameras[i].lensDirection == targetLens) {
          targetIndex = i;
          break;
        }
      }
      _selectedCameraIndex =
          targetIndex ?? ((_selectedCameraIndex + 1) % _cameras.length);

      // Create new controller with the new camera
      _cameraController = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (_cameraController == null ||
          !_cameraController!.value.isInitialized ||
          _cameraController!.value.hasError) {
        _isSwitchingCamera = false;
        emit(CameraErrorState('Failed to initialize camera after switch'));
        return;
      }

      emit(CameraSwitchedState(
        cameraController: _cameraController!,
        isFlashAvailable: true,
        maxZoom: 4.0,
      ));
    } catch (e) {
      emit(CameraErrorState('Failed to switch camera: $e'));
    } finally {
      _isSwitchingCamera = false;
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
      AppLog.error('Zoom error: $e');
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
    // Delegate to segment recording duration update for unified behavior
    await _updateSegmentRecordingDuration(
      CameraUpdateSegmentRecordingDurationEvent(
        recordingDuration: event.duration,
        currentSegmentDuration: event.duration,
      ),
      emit,
    );
  }

  Future<void> _confirmRecording(
    CameraConfirmRecordingEvent event,
    Emitter<CameraState> emit,
  ) async {
    if (_videoSegments.isNotEmpty ||
        _recordedVideoPath != null ||
        _capturedPhotoPath != null) {
      var finalVideoPath = _recordedVideoPath ?? _capturedPhotoPath;

      try {
        emit(CameraBottomLoadingState());
        if (_videoSegments.isNotEmpty) {
          if (_videoSegments.length == 1) {
            finalVideoPath = _videoSegments.first.path;
            AppLog.error(
                '_confirmRecording: Only one segment, using: $finalVideoPath');
          } else {
            AppLog.error(
                '_confirmRecording: Merging ${_videoSegments.length} segments');
            final segmentPaths = _videoSegments.map((s) => s.path).toList();

            try {
              final mergedPath =
                  await MediaUtil.mergeVideoSegments(segmentPaths);
              if (mergedPath != null && await File(mergedPath).exists()) {
                finalVideoPath = mergedPath;
                _recordedVideoPath = mergedPath;
              } else {
                throw Exception('Merge returned null or file missing');
              }
            } catch (e) {
              finalVideoPath = _videoSegments.first.path;
            }
          }
        }
      } catch (e) {
        AppLog.error('_confirmRecording: Error merging segments: $e');
      }

      emit(CameraRecordingConfirmedState(
        mediaPath: finalVideoPath!,
        mediaType: _selectedMediaType,
        filter: _selectedFilter,
        segments: null,
      ));
    }
  }

  Future<void> _setExternalMedia(
    CameraSetExternalMediaEvent event,
    Emitter<CameraState> emit,
  ) async {
    _selectedMediaType = event.mediaType;
    if (event.mediaType == MediaType.video) {
      _recordedVideoPath = event.mediaPath;
      _capturedPhotoPath = null;

      try {
        if (_cameraController != null) {
          if (_cameraController!.value.isStreamingImages) {
            await _cameraController!.stopImageStream();
          }
          await _cameraController!.pausePreview();
        }
      } catch (_) {}

      try {
        await _videoPlayerController?.dispose();
      } catch (_) {}
      _videoPlayerController =
          VideoPlayerController.file(File(_recordedVideoPath!));
      await _videoPlayerController!.initialize();
    } else {
      _capturedPhotoPath = event.mediaPath;
      _recordedVideoPath = null;
    }
  }

  Future<void> _discardRecording(
    CameraDiscardRecordingEvent event,
    Emitter<CameraState> emit,
  ) async {
    _recordedVideoPath = null;
    _capturedPhotoPath = null;
    await _videoPlayerController?.dispose();
    _videoPlayerController = null;
    _recordingDuration = 0;
    _selectedMusicId = null;
    _selectedMusicName = null;
    _selectedMusicArtist = null;
    _videoSegments.clear();
    _isSegmentRecording = false;
    _currentSegmentDuration = 0;
    _segmentTimer?.cancel();
    _segmentTimer = null;

    if (_cameraController != null &&
        _cameraController!.value.isInitialized &&
        !_cameraController!.value.hasError) {
      try {
        if (!_cameraController!.value.isPreviewPaused) {
        } else {
          await _cameraController!.resumePreview();
        }
      } catch (e) {
        AppLog.error('Error resuming preview: $e');
      }

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
    await _videoPlayerController?.dispose();
    _videoPlayerController = null;
    _isSegmentRecording = false;
    _isFlashOn = false;
    _currentZoom = 1.0;
    _selectedDuration = 0;
    _recordedVideoPath = null;
    _capturedPhotoPath = null;
    _selectedMediaType = MediaType.photo;
    _selectedFilter = 'Normal';
    _recordingDuration = 0;
    _recordingTimer?.cancel();
    _selectedMusicId = null;
    _selectedMusicName = null;
    _selectedMusicArtist = null;

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
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _segmentTimer?.cancel();
    _segmentTimer = null;
    _videoSegments.clear();

    if (_videoPlayerController != null) {
      try {
        await _videoPlayerController!.dispose();
      } catch (e) {
        AppLog.error('Error disposing video player controller: $e');
      }
      _videoPlayerController = null;
    }

    await _releaseCamera();

    _recordingTimer?.cancel();
    _segmentTimer?.cancel();
    _videoSegments.clear();
    return super.close();
  }

  Future<void> _releaseCamera() async {
    if (_cameraController == null) return;

    try {
      if (_cameraController!.value.isRecordingVideo) {
        await _cameraController!.stopVideoRecording();
      }

      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
    } catch (_) {}

    await _cameraController!.dispose();
    _cameraController = null;

    // 🔥 Critical on Android
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _disposeAll(
    CameraDisposeEvent event,
    Emitter<CameraState> emit,
  ) async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _recordingTimer?.cancel();
    _segmentTimer?.cancel();
    _videoSegments.clear();

    if (_videoPlayerController != null) {
      try {
        await _videoPlayerController!.dispose();
      } catch (_) {}
      _videoPlayerController = null;
    }

    await _releaseCamera();

    _isSegmentRecording = false;
    _isFlashOn = false;
    _currentZoom = 1.0;
    _selectedDuration = 0;
    _selectedSpeed = 1.0;
    _recordedVideoPath = null;
    _capturedPhotoPath = null;
    _selectedMediaType = MediaType.photo;
    _selectedFilter = 'Normal';
    _recordingDuration = 0;
    _selectedMusicId = null;
    _selectedMusicName = null;
    _selectedMusicArtist = null;

    emit(CameraInitialState());
  }

  Future<void> _pauseForEdit(
    CameraPauseForEditEvent event,
    Emitter<CameraState> emit,
  ) async {
    _recordingTimer?.cancel();
    _recordingTimer = null;

    if (_videoPlayerController != null) {
      try {
        await _videoPlayerController!.pause();
      } catch (_) {}
    }

    if (_cameraController != null) {
      try {
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
      } catch (_) {}
      try {
        await _cameraController!.pausePreview();
      } catch (_) {}
    }
    _isSegmentRecording = false;
    emit(CameraInitialState());
    if (_videoPlayerController != null) {
      try {
        await _videoPlayerController!.dispose();
      } catch (_) {}
      _videoPlayerController = null;
    }
  }

  Future<void> _setSpeed(
    CameraSetSpeedEvent event,
    Emitter<CameraState> emit,
  ) async {
    _selectedSpeed = event.speed;
    emit(CameraSpeedChangedState(speed: _selectedSpeed));
  }

  Future<void> _startSegmentRecording(
    CameraStartSegmentRecordingEvent event,
    Emitter<CameraState> emit,
  ) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (_isSegmentRecording) return;

    try {
      await _cameraController!.startVideoRecording();
      _isSegmentRecording = true;
      _currentSegmentDuration = 0;

      _segmentTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_isSegmentRecording) {
          timer.cancel();
          return;
        }
        _currentSegmentDuration++;
        _recordingDuration++;

        if (_selectedDuration > 0 && _recordingDuration >= _selectedDuration) {
          timer.cancel();
          add(CameraStopSegmentRecordingEvent());
          return;
        }

        add(CameraUpdateSegmentRecordingDurationEvent(
          recordingDuration: _recordingDuration,
          currentSegmentDuration: _currentSegmentDuration,
        ));
      });

      emit(CameraSegmentRecordingState(
        isRecording: true,
        recordingDuration: _recordingDuration,
        maxDuration: _selectedDuration,
        segments: List.from(_videoSegments),
        currentSegmentDuration: 0,
      ));
    } catch (e) {
      emit(CameraErrorState('Failed to start segment recording: $e'));
    }
  }

  Future<void> _stopSegmentRecording(
    CameraStopSegmentRecordingEvent event,
    Emitter<CameraState> emit,
  ) async {
    if (_cameraController == null || !_isSegmentRecording) {
      return;
    }

    try {
      _isSegmentRecording = false;
      _segmentTimer?.cancel();
      emit(CameraBottomLoadingState());
      final videoFile = await _cameraController!.stopVideoRecording();

      final File confirmedVideo;
      if (_cameraController?.description.lensDirection == CameraLensDirection.front) {
        confirmedVideo = await MediaUtil.mirrorMedia(File(videoFile.path));
      } else {
        confirmedVideo = File(videoFile.path);
      }

      _videoSegments.add(VideoSegment(
        path: confirmedVideo.path,
        duration: _currentSegmentDuration,
      ));

      _currentSegmentDuration = 0;

      if (_recordingDuration >= _selectedDuration &&
          _videoSegments.isNotEmpty) {
        add(CameraConfirmRecordingEvent());
        return;
      }

      emit(CameraSegmentRecordingState(
        isRecording: false,
        recordingDuration: _recordingDuration,
        maxDuration: _selectedDuration,
        segments: List.from(_videoSegments),
        currentSegmentDuration: 0,
      ));
    } catch (e) {
      _isSegmentRecording = false;
      _segmentTimer?.cancel();
      emit(CameraErrorState('Failed to stop segment recording: $e'));
    }
  }

  Future<void> _removeLastSegment(
    CameraRemoveLastSegmentEvent event,
    Emitter<CameraState> emit,
  ) async {
    if (_videoSegments.isEmpty) return;

    final removedSegment = _videoSegments.removeLast();
    _recordingDuration -= removedSegment.duration;

    try {
      final file = File(removedSegment.path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      AppLog.error('Error deleting segment file: $e');
    }

    emit(CameraSegmentRecordingState(
      isRecording: false,
      recordingDuration: _recordingDuration,
      maxDuration: _selectedDuration,
      segments: List.from(_videoSegments),
      currentSegmentDuration: 0,
    ));
  }

  Future<void> _updateSegmentRecordingDuration(
    CameraUpdateSegmentRecordingDurationEvent event,
    Emitter<CameraState> emit,
  ) async {
    if (!_isSegmentRecording) {
      return;
    }

    _recordingDuration = event.recordingDuration;
    _currentSegmentDuration = event.currentSegmentDuration;

    emit(CameraSegmentRecordingState(
      isRecording: true,
      recordingDuration: _recordingDuration,
      maxDuration: _selectedDuration,
      segments: List.from(_videoSegments),
      currentSegmentDuration: _currentSegmentDuration,
    ));
  }
}
