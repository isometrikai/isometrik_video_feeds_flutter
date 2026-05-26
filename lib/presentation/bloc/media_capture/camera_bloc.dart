import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
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
    on<CameraSetMusicEvent>(_setMusic);
    on<CameraRemoveMusicEvent>(_removeMusic);
    on<CameraFramingMusicRouteObscuredEvent>(_onFramingMusicRouteObscured);
    on<CameraFramingMusicAppPausedEvent>(_onFramingMusicAppPaused);

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
  bool _cameraBuiltWithEnableAudio = true;
  String? _selectedMusicId;
  String? _selectedMusicName;
  String? _selectedMusicArtist;
  String? _selectedMusicThumbnailUrl;
  int? _selectedMusicDurationSeconds;
  String? _selectedMusicPreviewUrl;

  AudioPlayer? _framingMusicPlayer;
  String? _framingMusicLoadedUrl;
  bool _framingMusicRouteObscured = false;
  bool _framingMusicAppPaused = false;

  final List<VideoSegment> _videoSegments = [];
  bool _isSegmentRecording = false;
  int _currentSegmentDuration = 0;
  Timer? _segmentTimer;

  bool _isClosed = false;

  Future<void>? _cameraOpInFlight;

  Future<void>? _pendingMicReinit;

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
  String? get selectedMusicThumbnailUrl => _selectedMusicThumbnailUrl;
  int? get selectedMusicDurationSeconds => _selectedMusicDurationSeconds;
  String? get selectedMusicPreviewUrl => _selectedMusicPreviewUrl;
  bool get hasMusicSelected =>
      _selectedMusicId != null && _selectedMusicId!.isNotEmpty;
  bool get isSegmentRecording => _isSegmentRecording;
  List<VideoSegment> get videoSegments => _videoSegments;
  bool get isFlashAvailable {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return false;
    }
    // Back cameras typically have flash, front cameras don't
    return _cameraController!.description.lensDirection ==
        CameraLensDirection.back;
  }

  bool get _wantsCameraMicEnabled => true;

  bool get _shouldPlayFramingMusic =>
      _selectedMediaType == MediaType.video &&
      _videoPlayerController == null &&
      hasMusicSelected &&
      (_selectedMusicPreviewUrl?.isNotEmpty ?? false) &&
      !_framingMusicRouteObscured &&
      !_framingMusicAppPaused &&
      _isSegmentRecording;

  int get totalRecordingDuration {
    final segmentsDuration = _videoSegments.fold<int>(
      0,
      (sum, segment) => sum + segment.duration,
    );
    return segmentsDuration + _recordingDuration;
  }

  Future<void> _disposeFramingMusicPlayer() async {
    final p = _framingMusicPlayer;
    _framingMusicPlayer = null;
    _framingMusicLoadedUrl = null;
    if (p != null) {
      try {
        await p.dispose();
      } catch (e) {
        AppLog.error('Framing music dispose: $e');
      }
    }
  }

  Future<void> _pauseFramingMusicOnly() async {
    final p = _framingMusicPlayer;
    if (p == null) return;
    try {
      await p.pause();
    } catch (e) {
      AppLog.error('Framing music pause: $e');
    }
  }

  Future<void> _syncFramingMusicPlayback() async {
    if (!_shouldPlayFramingMusic) {
      if (!hasMusicSelected ||
          _selectedMediaType != MediaType.video ||
          (_selectedMusicPreviewUrl?.isEmpty ?? true)) {
        await _disposeFramingMusicPlayer();
      } else {
        await _pauseFramingMusicOnly();
      }
      return;
    }

    final url = _selectedMusicPreviewUrl!;
    try {
      _framingMusicPlayer ??= AudioPlayer();
      final p = _framingMusicPlayer!;
      await p.setReleaseMode(ReleaseMode.loop);

      if (_framingMusicLoadedUrl != url) {
        await p.stop();
        _framingMusicLoadedUrl = url;
        await p.play(audioSourceFromUrlOrPath(url));
        return;
      }

      if (p.state != PlayerState.playing) {
        await p.resume();
      }
    } catch (e) {
      AppLog.error('Framing music playback: $e');
    }
  }

  Future<void> _initializeCamera(
    CameraInitializeEvent event,
    Emitter<CameraState> emit,
  ) async {
    final previous = _cameraOpInFlight;
    if (previous != null) {
      try {
        await previous;
      } catch (_) {}
    }
    if (_isClosed) {
      event.completion?.complete();
      return;
    }

    final completer = Completer<void>();
    _cameraOpInFlight = completer.future;
    try {
      await _initializeCameraImpl(event, emit);
    } finally {
      completer.complete();
      if (identical(_cameraOpInFlight, completer.future)) {
        _cameraOpInFlight = null;
      }
      event.completion?.complete();
    }
  }

  Future<void> _initializeCameraImpl(
    CameraInitializeEvent event,
    Emitter<CameraState> emit,
  ) async {
    try {
      if (!event.preserveCapturePaths) {
        _recordedVideoPath = null;
        _capturedPhotoPath = null;
      }

      final wantEnableAudio = _wantsCameraMicEnabled;

      if (_cameraController != null &&
          _cameraController!.value.isInitialized &&
          !_cameraController!.value.hasError &&
          _cameraBuiltWithEnableAudio == wantEnableAudio) {
        final hasFlash = _cameraController!.description.lensDirection ==
            CameraLensDirection.back;
        if (_isClosed) return;
        emit(CameraInitializedState(
          cameraController: _cameraController!,
          isFlashAvailable: hasFlash,
          maxZoom: 4.0,
        ));
        unawaited(_syncFramingMusicPlayback());
        return;
      }

      emit(CameraLoadingState());

      _cameras = await availableCameras();
      if (_isClosed) return;
      if (_cameras.isEmpty) {
        emit(CameraErrorState('No cameras available'));
        return;
      }

      await _releaseCamera();
      if (_isClosed) return;

      _cameraBuiltWithEnableAudio = wantEnableAudio;
      final controller = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.high,
        enableAudio: wantEnableAudio,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _cameraController = controller;

      final initCompleted = Completer<bool>();
      runZonedGuarded<void>(
        () async {
          try {
            await controller.initialize();
            if (!initCompleted.isCompleted) initCompleted.complete(true);
          } catch (e) {
            AppLog.error('CameraController.initialize: $e');
            if (!initCompleted.isCompleted) initCompleted.complete(false);
          }
        },
        (error, stack) {
          AppLog.error(
            'Suppressed camera zone error (post-dispose listener): $error',
          );
        },
      );
      final initOk = await initCompleted.future;
      if (!initOk) {
        if (_isClosed || !identical(controller, _cameraController)) return;
        emit(CameraErrorState('Failed to initialize camera'));
        return;
      }

      if (_isClosed || !identical(controller, _cameraController)) return;
      if (!controller.value.isInitialized || controller.value.hasError) {
        emit(CameraErrorState('Camera controller failed to initialize'));
        return;
      }

      try {
        await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      } catch (e) {
        AppLog.error('lockCaptureOrientation: $e');
      }
      if (!_canUseController(controller)) return;

      if (_selectedMediaType == MediaType.photo) {
        await prepareCameraForPhoto();
      } else {
        await prepareCameraForVideoRecording();
      }
      if (!_canUseController(controller)) return;

      final hasFlash =
          controller.description.lensDirection == CameraLensDirection.back;
      if (!hasFlash) {
        _isFlashOn = false;
      }
      try {
        await controller.setFlashMode(
          _isFlashOn ? FlashMode.always : FlashMode.off,
        );
      } catch (e) {
        AppLog.error('setFlashMode: $e');
      }
      if (!_canUseController(controller)) return;

      emit(CameraInitializedState(
        cameraController: controller,
        isFlashAvailable: hasFlash,
        maxZoom: 4.0,
      ));
      if (hasMusicSelected && _selectedMediaType == MediaType.video) {
        unawaited(_preloadFramingMusic());
      }
      unawaited(_syncFramingMusicPlayback());
    } catch (e) {
      AppLog.error('Camera initialization error: $e');
      if (!_isClosed) emit(CameraErrorState('Failed to initialize camera: $e'));
    }
  }

  Future<void> _preloadFramingMusic() async {
    final url = _selectedMusicPreviewUrl;
    if (url == null || url.isEmpty) return;
    try {
      _framingMusicPlayer ??= AudioPlayer();
      final player = _framingMusicPlayer!;
      await player.setReleaseMode(ReleaseMode.loop);
      if (_framingMusicLoadedUrl != url) {
        await player.stop();
        _framingMusicLoadedUrl = url;
        await player.play(audioSourceFromUrlOrPath(url));
      }
      await player.pause();
    } catch (e) {
      AppLog.error('Framing music preload: $e');
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
    await _waitForPendingMicReinit();
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _cameraController!.value.hasError) {
      emit(CameraErrorState('Camera not ready for photo capture'));
      return;
    }

    try {
      emit(CameraBottomLoadingState());
      final photoFile = await _cameraController!.takePicture();
      if (_cameraController?.description.lensDirection ==
          CameraLensDirection.front) {
        _capturedPhotoPath = await MediaUtil.mirrorMedia(File(photoFile.path))
            .then((value) => value.path);
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
      final wantEnableAudio = _wantsCameraMicEnabled;
      _cameraBuiltWithEnableAudio = wantEnableAudio;
      _cameraController = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.high,
        enableAudio: wantEnableAudio,
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

      await _cameraController
          ?.lockCaptureOrientation(DeviceOrientation.portraitUp);

      if (_selectedMediaType == MediaType.photo) {
        await prepareCameraForPhoto();
      } else {
        await prepareCameraForVideoRecording();
      }

      final hasFlash = _cameraController!.description.lensDirection ==
          CameraLensDirection.back;
      if (!hasFlash) {
        _isFlashOn = false;
      }
      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.always : FlashMode.off,
      );
      emit(CameraSwitchedState(
        cameraController: _cameraController!,
        isFlashAvailable: hasFlash,
        maxZoom: 4.0,
      ));
    } catch (e) {
      emit(CameraErrorState('Failed to switch camera: $e'));
    } finally {
      _isSwitchingCamera = false;
      unawaited(_syncFramingMusicPlayback());
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
        _isFlashOn ? FlashMode.always : FlashMode.off,
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

  Future<void> _setMusic(
    CameraSetMusicEvent event,
    Emitter<CameraState> emit,
  ) async {
    final prevPreview = _selectedMusicPreviewUrl;
    _selectedMusicId = event.musicId;
    _selectedMusicName = event.musicName;
    _selectedMusicArtist = event.musicArtist;
    _selectedMusicThumbnailUrl = event.musicThumbnailUrl;
    _selectedMusicDurationSeconds = event.musicDurationSeconds;
    _selectedMusicPreviewUrl = event.musicPreviewUrl;
    if (prevPreview != _selectedMusicPreviewUrl) {
      try {
        await _framingMusicPlayer?.stop();
      } catch (_) {}
      _framingMusicLoadedUrl = null;
    }
    emit(CameraMusicSelectedState(
      musicId: _selectedMusicId,
      musicName: _selectedMusicName,
      musicArtist: _selectedMusicArtist,
    ));
    // Mic-policy re-init can rebuild the camera controller on Android, which
    // takes ~300-700ms. Dispatch as a fresh event so the handler gets its
    // own valid `emit`; any record / capture event must
    // `await _waitForPendingMicReinit()` before touching the controller.
    _scheduleMicReinit();
    unawaited(_syncFramingMusicPlayback());
  }

  void _scheduleMicReinit() {
    if (_isClosed) return;
    if (_selectedMediaType != MediaType.video) return;
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _cameraController!.value.hasError) {
      return;
    }
    if (_cameraBuiltWithEnableAudio == _wantsCameraMicEnabled) return;
    if (_pendingMicReinit != null) return;

    final completer = Completer<void>();
    _pendingMicReinit = completer.future;
    completer.future.whenComplete(() {
      if (identical(_pendingMicReinit, completer.future)) {
        _pendingMicReinit = null;
      }
    });
    add(CameraInitializeEvent(
      preserveCapturePaths: true,
      completion: completer,
    ));
  }

  /// Awaits any pending mic-policy re-init. Recording / capture handlers
  /// should call this before touching the camera controller so they don't
  /// hit a controller that's about to be torn down.
  Future<void> _waitForPendingMicReinit() async {
    final pending = _pendingMicReinit;
    if (pending == null) return;
    try {
      await pending;
    } catch (_) {}
  }

  Future<void> _onFramingMusicRouteObscured(
    CameraFramingMusicRouteObscuredEvent event,
    Emitter<CameraState> emit,
  ) async {
    _framingMusicRouteObscured = event.obscured;
    await _syncFramingMusicPlayback();
  }

  Future<void> _onFramingMusicAppPaused(
    CameraFramingMusicAppPausedEvent event,
    Emitter<CameraState> emit,
  ) async {
    _framingMusicAppPaused = event.paused;
    await _syncFramingMusicPlayback();
  }

  Future<void> _removeMusic(
    CameraRemoveMusicEvent event,
    Emitter<CameraState> emit,
  ) async {
    _selectedMusicId = null;
    _selectedMusicName = null;
    _selectedMusicArtist = null;
    _selectedMusicThumbnailUrl = null;
    _selectedMusicDurationSeconds = null;
    _selectedMusicPreviewUrl = null;
    await _disposeFramingMusicPlayer();
    if (_isClosed) return;
    emit(CameraMusicSelectedState(
      musicId: null,
      musicName: null,
      musicArtist: null,
    ));
  }

  Future<void> _setMediaType(
    CameraSetMediaTypeEvent event,
    Emitter<CameraState> emit,
  ) async {
    _selectedMediaType = event.mediaType;
    await _waitForPendingMicReinit();
    if (_isClosed) return;
    if (_selectedMediaType == MediaType.photo) {
      await prepareCameraForPhoto();
    } else {
      await prepareCameraForVideoRecording();
    }
    if (_isClosed) return;
    emit(CameraMediaTypeChangedState(mediaType: _selectedMediaType));
    unawaited(_syncFramingMusicPlayback());
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
      await _disposeFramingMusicPlayer();
      var finalVideoPath = _recordedVideoPath ?? _capturedPhotoPath;

      emit(CameraBottomLoadingState());
      if (_videoSegments.isNotEmpty) {
        if (_videoSegments.length == 1) {
          finalVideoPath = _videoSegments.first.path;
        } else {
          final mergedPath = await MediaUtil.mergeVideoSegments(
            _videoSegments.map((s) => s.path).toList(),
          );
          if (mergedPath != null && await File(mergedPath).exists()) {
            finalVideoPath = mergedPath;
            _recordedVideoPath = mergedPath;
          } else {
            finalVideoPath = _videoSegments.first.path;
          }
        }
      }

      if (_selectedMediaType == MediaType.video &&
          hasMusicSelected &&
          (_selectedMusicPreviewUrl?.isNotEmpty ?? false) &&
          finalVideoPath != null) {
        final videoIn = finalVideoPath;
        final musicIn = _selectedMusicPreviewUrl!;
        final muxed = await MediaUtil.muxVideoWithMusicFromUrl(
          videoPath: videoIn,
          musicUrlOrPath: musicIn,
        );
        if (muxed != null && await File(muxed).exists()) {
          if (muxed != videoIn) {
            try {
              await File(videoIn).delete();
            } catch (_) {}
          }
          finalVideoPath = muxed;
          _recordedVideoPath = muxed;
        }
      }

      emit(CameraRecordingConfirmedState(
        mediaPath: finalVideoPath!,
        mediaType: _selectedMediaType,
        filter: _selectedFilter,
        segments: _videoSegments.isNotEmpty
            ? List<VideoSegment>.from(_videoSegments)
            : null,
      ));
    }
  }

  Future<void> _setExternalMedia(
    CameraSetExternalMediaEvent event,
    Emitter<CameraState> emit,
  ) async {
    await _disposeFramingMusicPlayer();
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
      emit(CameraRecordingReadyState(
        videoPath: _recordedVideoPath!,
        videoController: _videoPlayerController!,
        recordingDuration: 0,
      ));
    } else {
      _capturedPhotoPath = event.mediaPath;
      _recordedVideoPath = null;
    }
    unawaited(_syncFramingMusicPlayback());
  }

  Future<void> _discardRecording(
    CameraDiscardRecordingEvent event,
    Emitter<CameraState> emit,
  ) async {
    await _disposeFramingMusicPlayer();
    _recordedVideoPath = null;
    _capturedPhotoPath = null;
    await _videoPlayerController?.dispose();
    _videoPlayerController = null;
    _recordingDuration = 0;
    _selectedMusicId = null;
    _selectedMusicName = null;
    _selectedMusicArtist = null;
    _selectedMusicThumbnailUrl = null;
    _selectedMusicDurationSeconds = null;
    _selectedMusicPreviewUrl = null;
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

      final hasFlash = _cameraController!.description.lensDirection ==
          CameraLensDirection.back;
      emit(CameraInitializedState(
        cameraController: _cameraController!,
        isFlashAvailable: hasFlash,
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
    await _disposeFramingMusicPlayer();
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
    _selectedMusicThumbnailUrl = null;
    _selectedMusicDurationSeconds = null;
    _selectedMusicPreviewUrl = null;

    if (_cameraController != null && _cameraController!.value.isInitialized) {
      final hasFlash = _cameraController!.description.lensDirection ==
          CameraLensDirection.back;
      emit(CameraInitializedState(
        cameraController: _cameraController!,
        isFlashAvailable: hasFlash,
        maxZoom: 4.0,
      ));
    } else {
      emit(CameraInitialState());
    }
  }

  @override
  Future<void> close() async {
    _isClosed = true;

    final inFlight = _cameraOpInFlight;
    if (inFlight != null) {
      try {
        await inFlight;
      } catch (_) {}
    }
    final pendingMic = _pendingMicReinit;
    if (pendingMic != null) {
      try {
        await pendingMic;
      } catch (_) {}
    }

    await _disposeFramingMusicPlayer();
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
    final controller = _cameraController;
    if (controller == null) return;
    _cameraController = null;

    try {
      if (controller.value.isRecordingVideo) {
        await controller.stopVideoRecording();
      }
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (_) {}

    try {
      await controller.dispose();
    } catch (e) {
      AppLog.error('CameraController.dispose: $e');
    }

    // Critical on Android — give the camera HAL time to release before
    // the next controller is built.
    if (!_isClosed) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
  }

  Future<void> _disposeAll(
    CameraDisposeEvent event,
    Emitter<CameraState> emit,
  ) async {
    final inFlight = _cameraOpInFlight;
    if (inFlight != null) {
      try {
        await inFlight;
      } catch (_) {}
    }
    final pendingMic = _pendingMicReinit;
    if (pendingMic != null) {
      try {
        await pendingMic;
      } catch (_) {}
    }

    await _disposeFramingMusicPlayer();
    _framingMusicRouteObscured = false;
    _framingMusicAppPaused = false;
    _recordingTimer?.cancel();
    _recordingTimer = null;
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
    _selectedMusicThumbnailUrl = null;
    _selectedMusicDurationSeconds = null;
    _selectedMusicPreviewUrl = null;

    emit(CameraInitialState());
  }

  Future<void> _pauseForEdit(
    CameraPauseForEditEvent event,
    Emitter<CameraState> emit,
  ) async {
    await _disposeFramingMusicPlayer();
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
    await _waitForPendingMicReinit();
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (_isSegmentRecording) return;

    try {
      // Mic is now always enabled - audio replacement happens at mux time.
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

      await _syncFramingMusicPlayback();

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

  Future<void> prepareCameraForVideoRecording() async {
    final controller = _cameraController;
    if (!_canUseController(controller)) return;
    try {
      await controller!.setFocusMode(FocusMode.auto);
      if (!_canUseController(controller)) return;
      await controller.setExposureMode(ExposureMode.auto);
      if (!_canUseController(controller)) return;
      await controller.setExposureOffset(0.0);
      if (!_canUseController(controller)) return;
      // Lock exposure so it doesn't drift during recording.
      await controller.setExposureMode(ExposureMode.locked);
    } catch (e) {
      AppLog.error('prepareCameraForVideoRecording: $e');
    }
  }

  Future<void> prepareCameraForPhoto() async {
    final controller = _cameraController;
    if (!_canUseController(controller)) return;
    try {
      await controller!.setFocusMode(FocusMode.auto);
      if (!_canUseController(controller)) return;
      await controller.setExposureMode(ExposureMode.auto);
      if (!_canUseController(controller)) return;
      await controller.setExposureOffset(0.0);
    } catch (e) {
      AppLog.error('prepareCameraForPhoto: $e');
    }
  }

  bool _canUseController(CameraController? controller) {
    if (_isClosed) return false;
    if (controller == null) return false;
    if (!identical(controller, _cameraController)) return false;
    final value = controller.value;
    return value.isInitialized && !value.hasError;
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
      if (_cameraController?.description.lensDirection ==
          CameraLensDirection.front) {
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
      unawaited(_syncFramingMusicPlayback());
    } catch (e) {
      _isSegmentRecording = false;
      _segmentTimer?.cancel();
      emit(CameraErrorState('Failed to stop segment recording: $e'));
      unawaited(_syncFramingMusicPlayback());
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
    unawaited(_syncFramingMusicPlayback());
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
