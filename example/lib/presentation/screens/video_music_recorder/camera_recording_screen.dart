import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraRecordingScreen extends StatefulWidget {
  const CameraRecordingScreen({super.key});

  @override
  State<CameraRecordingScreen> createState() => _CameraRecordingScreenState();
}

class _CameraRecordingScreenState extends State<CameraRecordingScreen> {
  CameraController? _controller;
  final _cameras = <CameraDescription>[];
  var _isRecording = false;
  var _isInitialized = false;
  var _flashEnabled = false;
  var _currentCameraIndex = 0; // Start with front camera

  // Music and audio
  MusicTrack? _selectedMusic;
  AudioPlayer? _musicPlayer;

  // Recording state
  Timer? _recordingTimer;
  var _recordingDuration = Duration.zero;
  var _recordedVideoPath = '';

  @override
  void initState() {
    super.initState();
    _initializeCameras();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ].request();
  }

  Future<void> _initializeCameras() async {
    try {
      _cameras.clear();
      _cameras.addAll(await availableCameras());
      if (_cameras.isEmpty) return;
      await _initializeCamera();
    } catch (_) {}
  }

  Future<void> _initializeCamera() async {
    if (_cameras.isEmpty) return;

    // Find front camera first (default)
    final frontCameraIndex = _cameras.indexWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    _currentCameraIndex = frontCameraIndex != -1 ? frontCameraIndex : 0;

    _controller = CameraController(
      _cameras[_currentCameraIndex],
      ResolutionPreset.high,
      enableAudio: true,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        _isInitialized = true;
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    await _controller?.dispose();
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;

    _controller = CameraController(
      _cameras[_currentCameraIndex],
      ResolutionPreset.high,
      enableAudio: true,
    );

    try {
      await _controller!.initialize();
      setState(() {});
    } catch (_) {}
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;

    try {
      await _controller!.setFlashMode(
        _flashEnabled ? FlashMode.off : FlashMode.torch,
      );
      setState(() {
        _flashEnabled = !_flashEnabled;
      });
    } catch (_) {}
  }

  bool get _hasFlash {
    if (_cameras.isEmpty) return false;
    return _cameras[_currentCameraIndex].lensDirection ==
        CameraLensDirection.back;
  }

  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      // Discard previous recording if exists
      if (_recordedVideoPath.isNotEmpty) {
        final file = File(_recordedVideoPath);
        Utility.showLoader();
        if (await file.exists()) await file.delete();
        Utility.closeProgressDialog();
        _recordedVideoPath = '';
      }
      Utility.showLoader();
      await _controller!.startVideoRecording();
      Utility.closeProgressDialog();

      // Determine recording duration
      var maxRecordingDuration = const Duration(seconds: 60);

      // Start music if selected
      if (_selectedMusic != null && _musicPlayer != null) {
        Utility.showLoader();
        await _musicPlayer!.play(UrlSource(_selectedMusic!.url));
        Utility.closeProgressDialog();

        // If music duration is less than 60 seconds, use music duration
        // If music duration is more than 60 seconds, limit to 60 seconds
        maxRecordingDuration =
            _selectedMusic!.duration > const Duration(seconds: 60)
                ? const Duration(seconds: 60)
                : _selectedMusic!.duration;
      }

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      // Auto-stop recording after max duration
      Timer(maxRecordingDuration, () {
        if (_isRecording) {
          _stopRecording();
        }
      });

      // Start recording timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration = Duration(seconds: timer.tick);
        });

        // Stop if reached max duration
        if (_recordingDuration >= maxRecordingDuration) {
          _stopRecording();
        }
      });
    } catch (_) {}
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_isRecording) return;

    try {
      Utility.showLoader();
      final videoFile = await _controller!.stopVideoRecording();
      Utility.closeProgressDialog();
      _recordedVideoPath = videoFile.path;

      // Stop music
      await _musicPlayer?.stop();

      // Stop timer
      _recordingTimer?.cancel();
      _recordingTimer = null;

      setState(() {
        _isRecording = false;
      });

      // Show save/discard dialog
      _showSaveDialog();
    } catch (_) {}
  }

  void _showSaveDialog() => showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Recording Complete'),
          content: const Text('What would you like to do with your recording?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _discardRecording();
              },
              child: const Text('Discard'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveRecording();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );

  Future<void> _saveRecording() async {
    if (_recordedVideoPath.isEmpty) return;

    try {
      var finalVideoPath = _recordedVideoPath;
      if (_selectedMusic != null) {
        Utility.showLoader();
        finalVideoPath = await _mergeVideoWithMusic();
        Utility.closeOpenDialog();
      }
      _resetRecording();
      Navigator.of(context).pop(XFile(finalVideoPath));
    } catch (e) {
      Utility.closeOpenDialog();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error saving video'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String> _mergeVideoWithMusic() async {
    if (_recordedVideoPath.isEmpty || _selectedMusic == null) {
      throw Exception('Video path or music not available');
    }

    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${directory.path}/final_video_$timestamp.mp4';

      // Download music file to local storage
      final musicDirectory = await getTemporaryDirectory();
      final musicPath = '${musicDirectory.path}/music_$timestamp.mp3';

      // Download music file
      final musicFile = File(musicPath);
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(_selectedMusic!.url));
      final response = await request.close();
      await response.pipe(musicFile.openWrite());
      client.close();

      // FFmpeg command to merge video with music
      // This removes original audio and replaces it with selected music
      final ffmpegCommand = '''
        -i "$_recordedVideoPath" 
        -i "$musicPath" 
        -c:v copy 
        -c:a aac 
        -map 0:v:0 
        -map 1:a:0 
        -shortest 
        -y 
        "$outputPath"
      '''
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      // Execute FFmpeg command
      final session = await FFmpegKit.execute(ffmpegCommand);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        // Clean up temporary music file
        if (await musicFile.exists()) await musicFile.delete();

        // Verify output file exists
        final outputFile = File(outputPath);
        if (await outputFile.exists()) {
          return outputPath;
        } else {
          throw Exception('Output file not created');
        }
      } else {
        await session.getFailStackTrace();
        final logs = await session.getAllLogsAsString();
        throw Exception('FFmpeg processing failed: $logs');
      }
    } catch (e) {
      throw Exception('Failed to merge video with music: $e');
    }
  }

  void _discardRecording() {
    if (_recordedVideoPath.isNotEmpty) {
      File(_recordedVideoPath).delete();
      _recordedVideoPath = '';
    }
    _resetRecording();
  }

  void _resetRecording() {
    _recordingDuration = Duration.zero;
    _isRecording = false;
    _recordedVideoPath = '';
    setState(() {});
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _musicPlayer?.stop();
  }

  void _openMusicSelection() async {
    if (_recordedVideoPath.isNotEmpty) _discardRecording();
    final result = await Navigator.of(context).push<MusicTrack>(
      MaterialPageRoute(
        builder: (context) => const MusicSelectionScreen(),
      ),
    );
    if (result == null) return;
    _selectedMusic = result;
    setState(() {});
    await _musicPlayer?.dispose();
    _musicPlayer = AudioPlayer();
  }

  void _removeMusic() {
    _selectedMusic = null;
    setState(() {});
    _musicPlayer?.dispose();
    _musicPlayer = null;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _controller?.dispose();
    _musicPlayer?.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _cameras.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(
                _cameras.isEmpty
                    ? 'No cameras available'
                    : 'Initializing camera...',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: CameraPreview(_controller!)),
          // Top Controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            right: 20,
            child: Column(
              children: [
                // Flash Toggle (only for back camera)
                if (_hasFlash) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.applyOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      onPressed: _toggleFlash,
                      icon: Icon(
                        _flashEnabled ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],

                // Camera Switch
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.applyOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: _cameras.length > 1 ? _switchCamera : null,
                    icon: const Icon(
                      Icons.flip_camera_android,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Recording Timer
          if (_isRecording) ...[
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.applyOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(_recordingDuration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Selected Music Info
          if (_selectedMusic != null) ...[
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.applyOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.music_note, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_selectedMusic!.title} - ${_selectedMusic!.artist}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Bottom Controls
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Music Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Add Music Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.applyOpacity(0.5),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: IconButton(
                        onPressed: _isRecording ? null : _openMusicSelection,
                        icon: Icon(
                          Icons.music_note,
                          color: _isRecording ? Colors.grey : Colors.white,
                          size: 28,
                        ),
                      ),
                    ),

                    // Record Button
                    GestureDetector(
                      onTap: _isRecording ? _stopRecording : _startRecording,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _isRecording ? Colors.red : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop : Icons.videocam,
                          color: _isRecording ? Colors.white : Colors.red,
                          size: 32,
                        ),
                      ),
                    ),

                    // Remove Music Button (visible only when music selected)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.applyOpacity(0.5),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: IconButton(
                        onPressed: _selectedMusic != null && !_isRecording
                            ? _removeMusic
                            : null,
                        icon: Icon(
                          Icons.music_off,
                          color: _selectedMusic != null && !_isRecording
                              ? Colors.white
                              : Colors.transparent,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Discard Button
                if (_recordedVideoPath.isNotEmpty) ...[
                  TextButton(
                    onPressed: _discardRecording,
                    child: const Text(
                      'Discard Recording',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
