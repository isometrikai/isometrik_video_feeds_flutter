import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class CameraView extends StatefulWidget {
  const CameraView({super.key, this.mediaType = MediaType.photo});

  final MediaType mediaType;

  @override
  CameraViewState createState() => CameraViewState();
}

class CameraViewState extends State<CameraView> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No camera found'),
          ),
        );
        Navigator.pop(context);
        return;
      }

      // Use a lower resolution to prevent buffer overflow
      _cameraController = CameraController(
        _cameras!.first,
        ResolutionPreset.high, // Changed from max to high
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg, // Explicitly set format
      );

      await _cameraController!.initialize();
      await _cameraController?.unlockCaptureOrientation();

      setState(() {});
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Camera initialization failed: $e'),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _cameraController = null;
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_cameraController != null && !_isRecording) {
      final image = await _cameraController!.takePicture();
      // Create MediaInfoClass object with the captured image
      final mediaInfo = MediaInfoClass(
        mediaType: MediaType.photo,
        mediaFile: image,
      );
      // Pop the MediaInfoClass object back to the previous screen
      Navigator.pop(context, mediaInfo);
    }
  }

  Future<void> _startRecording() async {
    if (_cameraController != null && !_isRecording) {
      await _cameraController!.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    }
  }

  Future<void> _stopRecording() async {
    if (_cameraController != null && _isRecording) {
      final video = await _cameraController!.stopVideoRecording();
      setState(() {
        _isRecording = false;
      });
      // Create MediaInfoClass object with the recorded video
      final mediaInfo = MediaInfoClass(
        mediaType: MediaType.video,
        mediaFile: video,
      );
      // Pop the MediaInfoClass object back to the previous screen
      Navigator.pop(context, mediaInfo);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: _cameraController == null
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                fit: StackFit.expand,
                children: [
                  // Full-screen camera preview
                  Positioned.fill(
                    child: AspectRatio(
                      aspectRatio: _cameraController!.value.aspectRatio,
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                  // Overlay with close button
                  Positioned(
                    top: 50,
                    left: 16,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle, // Make the container round
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  // Floating action button for taking picture or recording
                  Positioned(
                    bottom: 50, // Adjust as needed
                    left: MediaQuery.of(context).size.width / 2 -
                        28, // Center the button
                    child: FloatingActionButton(
                      onPressed: widget.mediaType == MediaType.photo
                          ? _takePicture
                          : (_isRecording ? _stopRecording : _startRecording),
                      child: Icon(
                        widget.mediaType == MediaType.photo
                            ? Icons.camera
                            : (_isRecording ? Icons.stop : Icons.videocam),
                      ),
                    ),
                  ),
                ],
              ),
      );
}
