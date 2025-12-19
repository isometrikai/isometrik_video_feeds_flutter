part of 'camera_bloc.dart';

abstract class CameraState {}

class CameraInitialState extends CameraState {}

class CameraLoadingState extends CameraState {}
class CameraBottomLoadingState extends CameraState {}

class CameraInitializedState extends CameraState {
  CameraInitializedState({
    required this.cameraController,
    required this.isFlashAvailable,
    required this.maxZoom,
  });

  final CameraController cameraController;
  final bool isFlashAvailable;
  final double maxZoom;
}

class CameraRecordingState extends CameraState {
  CameraRecordingState({
    required this.isRecording,
    required this.recordingDuration,
    required this.maxDuration,
  });

  final bool isRecording;
  final int recordingDuration;
  final int maxDuration;
}

class CameraRecordingStoppedState extends CameraState {
  CameraRecordingStoppedState({
    required this.videoPath,
    required this.videoController,
    required this.recordingDuration,
  });

  final String videoPath;
  final VideoPlayerController videoController;
  final int recordingDuration;
}

class CameraRecordingReadyState extends CameraState {
  CameraRecordingReadyState({
    required this.videoPath,
    required this.videoController,
    required this.recordingDuration,
  });

  final String videoPath;
  final VideoPlayerController videoController;
  final int recordingDuration;
}

class CameraPhotoCapturedState extends CameraState {
  CameraPhotoCapturedState({required this.photoPath});
  final String photoPath;
}

class CameraSwitchedState extends CameraState {
  CameraSwitchedState({
    required this.cameraController,
    required this.isFlashAvailable,
    required this.maxZoom,
  });

  final CameraController cameraController;
  final bool isFlashAvailable;
  final double maxZoom;
}

class CameraFlashToggledState extends CameraState {
  CameraFlashToggledState({required this.isFlashOn});
  final bool isFlashOn;
}

class CameraZoomChangedState extends CameraState {
  CameraZoomChangedState({required this.zoomLevel});
  final double zoomLevel;
}

class CameraDurationChangedState extends CameraState {
  CameraDurationChangedState({required this.duration});
  final int duration;
}

class CameraMediaTypeChangedState extends CameraState {
  CameraMediaTypeChangedState({required this.mediaType});
  final MediaType mediaType;
}

class CameraRecordingConfirmedState extends CameraState {
  CameraRecordingConfirmedState({
    required this.mediaPath,
    required this.mediaType,
    required this.filter,
    this.segments,
  });

  final String mediaPath;
  final MediaType mediaType;
  final String filter;
  final List<VideoSegment>? segments;
}

class CameraRecordingDiscardedState extends CameraState {}

class CameraFilterAppliedState extends CameraState {
  CameraFilterAppliedState({required this.filterName});
  final String filterName;
}

class CameraNextStepState extends CameraState {
  CameraNextStepState({
    required this.mediaPath,
    required this.mediaType,
    required this.filter,
    this.filteredImagePath,
  });

  final String mediaPath;
  final MediaType mediaType;
  final String filter;
  final String? filteredImagePath;
}

class CameraErrorState extends CameraState {
  CameraErrorState(this.message);
  final String message;
}

class CameraSpeedChangedState extends CameraState {
  CameraSpeedChangedState({required this.speed});
  final double speed;
}

class CameraSegmentRecordingState extends CameraState {
  CameraSegmentRecordingState({
    required this.isRecording,
    required this.recordingDuration,
    required this.maxDuration,
    required this.segments,
    required this.currentSegmentDuration,
  });

  final bool isRecording;
  final int recordingDuration;
  final int maxDuration;
  final List<VideoSegment> segments;
  final int currentSegmentDuration;
}

class VideoSegment {
  VideoSegment({
    required this.path,
    required this.duration,
  });

  final String path;
  final int duration;
}
