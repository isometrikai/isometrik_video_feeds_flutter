import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ism_video_reel_player/export.dart';

class IsmCameraView extends StatefulWidget {
  @override
  State<IsmCameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<IsmCameraView> {
  CameraController? _cameraController;
  late List<CameraDescription> _cameras;
  bool _isRecording = false;
  var _mediaSource = MediaSource.camera;
  var _selectedDuration = 5; // Default duration in seconds
  final _selectedMediaType = PostType.video;
  double _recordingProgress = 0.0;
  final _durationList = [15, 60];
  FlashState _currentFlashState = FlashState.off;

  @override
  void initState() {
    super.initState();
    _selectedDuration = _durationList.first;
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(
      _cameras[0],
      ResolutionPreset.high,
      enableAudio: true,
    );
    await _cameraController?.initialize();
    await _cameraController?.setFlashMode(FlashMode.off);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController?.value.isInitialized == false) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          if (_cameraController != null) CameraPreview(_cameraController!),

          // Recording Progress Indicator
          if (_isRecording)
            Positioned(
              top: IsrDimens.sixty,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _recordingProgress,
                backgroundColor: Colors.grey.applyOpacity(0.5),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
              ),
            ),

          // Top Controls
          Positioned(
            top: _isRecording ? IsrDimens.seventy : IsrDimens.sixty,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: IsrColors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                TapHandler(
                  onTap: () {},
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: IsrDimens.sixteen,
                      vertical: IsrDimens.eight,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(IsrDimens.ten),
                    ),
                    child: Text(
                      IsrTranslationFile.addASound,
                      style: TextStyle(
                        color: IsrColors.white,
                        fontSize: IsrDimens.sixteen,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),

          // Right Side Controls
          Positioned(
            right: IsrDimens.sixteen,
            top: MediaQuery.of(context).size.height * 0.3,
            child: Column(
              children: [
                TapHandler(
                  onTap: _switchCamera,
                  child: Container(
                    child: const Icon(Icons.refresh_rounded, color: IsrColors.white),
                    padding: IsrDimens.edgeInsetsAll(IsrDimens.ten),
                    decoration: const BoxDecoration(
                      color: Colors.black12,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                IsrDimens.boxHeight(IsrDimens.twenty),
                TapHandler(
                  onTap: _toggleFlash,
                  child: Container(
                    alignment: Alignment.center,
                    child: _getFlashIcon(),
                    padding: IsrDimens.edgeInsetsAll(IsrDimens.ten),
                    decoration: const BoxDecoration(
                      color: Colors.black12,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: IsrDimens.twenty),
              color: Colors.black12,
              child: Column(
                children: [
                  // Camera Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.photo_library, color: IsrColors.white),
                        onPressed: _pickFromGallery,
                      ),
                      GestureDetector(
                        onTap: _isRecording ? _stopRecording : _startRecording,
                        child: Container(
                          width: IsrDimens.eighty,
                          height: IsrDimens.eighty,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.red, width: 4),
                            color: _isRecording ? Colors.red : Colors.transparent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IsrDimens.boxHeight(IsrDimens.twenty),
                  // Duration Options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: IsrDimens.twenty,
                    children: List.generate(
                      _durationList.length,
                      (index) =>
                          _buildDurationOption('${_durationList[index]}s', _selectedDuration == _durationList[index]),
                    ),
                  ),
                  IsrDimens.boxHeight(IsrDimens.fifteen),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationOption(String text, bool isSelected) => TapHandler(
        onTap: () {
          setState(() {
            _selectedDuration = int.parse(text.replaceAll('s', ''));
            if (_isRecording) {
              _stopRecording();
            }
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: IsrDimens.twenty, vertical: IsrDimens.eight),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? IsrColors.white : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            text,
            style: IsrStyles.white16.copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
          ),
        ),
      );

  Future<void> _startRecording() async {
    _mediaSource = MediaSource.camera;
    if (_cameraController?.value.isRecordingVideo == false) {
      try {
        await _cameraController?.startVideoRecording();
        setState(() {
          _isRecording = true;
          _recordingProgress = 0.0;
        });
        _startRecordingTimer();
      } catch (e) {
        debugPrint('Error starting video recording: $e');
      }
    }
  }

  Future<void> _stopRecording() async {
    if (_cameraController?.value.isRecordingVideo == true) {
      try {
        final file = await _cameraController?.stopVideoRecording();
        setState(() {
          _isRecording = false;
          _recordingProgress = 0.0;
        });
        _handleSelectedMedia(file);
      } catch (e) {
        debugPrint('Error stopping video recording: $e');
      }
    }
  }

  Future<void> _switchCamera() async {
    final lensDirection = _cameraController?.description.lensDirection;
    final currentFlashMode = _cameraController?.value.flashMode;

    CameraDescription newCamera;
    if (lensDirection == CameraLensDirection.back) {
      newCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
    } else {
      newCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
    }

    await _cameraController?.dispose();
    _cameraController = CameraController(
      newCamera,
      ResolutionPreset.high,
      enableAudio: true,
    );

    await _cameraController?.initialize();
    // Restore flash mode after switching camera
    await _cameraController?.setFlashMode(currentFlashMode!);

    if (mounted) setState(() {});
  }

  // Optional: Add a method to handle recording progress
  void _startRecordingTimer() {
    var elapsed = 0;
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRecording || elapsed >= _selectedDuration) {
        timer.cancel();
        if (_isRecording) {
          _stopRecording();
        }
        return;
      }
      setState(() {
        elapsed++;
        _recordingProgress = elapsed / _selectedDuration;
      });
    });
  }

  Future<void> _toggleFlash() async {
    try {
      switch (_currentFlashState) {
        case FlashState.off:
          await _cameraController?.setFlashMode(FlashMode.auto);
          _currentFlashState = FlashState.auto;
          break;
        case FlashState.auto:
          await _cameraController?.setFlashMode(FlashMode.torch);
          _currentFlashState = FlashState.always;
          break;
        case FlashState.always:
          await _cameraController?.setFlashMode(FlashMode.off);
          _currentFlashState = FlashState.off;
          break;
      }
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error toggling flash'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Icon _getFlashIcon() {
    switch (_currentFlashState) {
      case FlashState.auto:
        return const Icon(Icons.flash_auto, color: IsrColors.white);
      case FlashState.always:
        return const Icon(Icons.flash_on, color: IsrColors.white);
      case FlashState.off:
        return const Icon(Icons.flash_off, color: IsrColors.white);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

// Add this method in _CameraViewState
  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    try {
      final file = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: Duration(seconds: _selectedDuration),
      );

      if (file != null) {
        // Handle the selected video file
        _mediaSource = MediaSource.gallery;
        _handleSelectedMedia(file);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error picking video from gallery'),
          duration: Duration(seconds: 2),
        ),
      );
      debugPrint('Error picking video: $e');
    }
  }

  /// handle selected media file
  void _handleSelectedMedia(XFile? file) {
    if (file != null && file.path.isEmptyOrNull == false) {
      debugPrint('Selected video path: ${file.path}');
      final resultMap = {
        'mediaFile': file,
        'duration': _selectedDuration,
        'mediaType': _selectedMediaType,
        'mediaSource': _mediaSource,
      };
      context.pop(resultMap);
    }
  }
}

enum FlashState {
  auto,
  always,
  off,
}
