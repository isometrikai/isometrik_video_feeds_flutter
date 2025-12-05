part of 'camera_bloc.dart';

abstract class CameraEvent {}

class CameraInitializeEvent extends CameraEvent {}

class CameraStartRecordingEvent extends CameraEvent {}

class CameraStopRecordingEvent extends CameraEvent {
  CameraStopRecordingEvent({this.isAutoStop = false});
  final bool isAutoStop;
}

class CameraCapturePhotoEvent extends CameraEvent {}

class CameraSwitchCameraEvent extends CameraEvent {}

class CameraToggleFlashEvent extends CameraEvent {}

class CameraSetZoomEvent extends CameraEvent {
  CameraSetZoomEvent({required this.zoomLevel});
  final double zoomLevel;
}

class CameraSetDurationEvent extends CameraEvent {
  CameraSetDurationEvent({required this.duration});
  final int duration;
}

class CameraConfirmRecordingEvent extends CameraEvent {}

class CameraDiscardRecordingEvent extends CameraEvent {}

class CameraApplyFilterEvent extends CameraEvent {
  CameraApplyFilterEvent({required this.filterName});
  final String filterName;
}

class CameraNextStepEvent extends CameraEvent {
  CameraNextStepEvent({this.filteredImagePath});
  final String? filteredImagePath;
}

class CameraResetEvent extends CameraEvent {}

class CameraPauseForEditEvent extends CameraEvent {}

class CameraDisposeEvent extends CameraEvent {}

class CameraUpdateRecordingDurationEvent extends CameraEvent {
  CameraUpdateRecordingDurationEvent(this.duration);
  final int duration;
}

class CameraSetMediaTypeEvent extends CameraEvent {
  CameraSetMediaTypeEvent({required this.mediaType});
  final MediaType mediaType;
}

class CameraSetExternalMediaEvent extends CameraEvent {
  CameraSetExternalMediaEvent(
      {required this.mediaPath, required this.mediaType});
  final String mediaPath;
  final MediaType mediaType;
}

class CameraSetMusicEvent extends CameraEvent {
  CameraSetMusicEvent({this.musicId, this.musicName, this.musicArtist});
  final String? musicId;
  final String? musicName;
  final String? musicArtist;
}

class CameraRemoveMusicEvent extends CameraEvent {}

class CameraSetSpeedEvent extends CameraEvent {
  CameraSetSpeedEvent({required this.speed});
  final double speed;
}

class CameraStartSegmentRecordingEvent extends CameraEvent {}

class CameraStopSegmentRecordingEvent extends CameraEvent {}

class CameraRemoveLastSegmentEvent extends CameraEvent {}

class CameraUpdateSegmentRecordingDurationEvent extends CameraEvent {
  CameraUpdateSegmentRecordingDurationEvent({
    required this.recordingDuration,
    required this.currentSegmentDuration,
  });
  final int recordingDuration;
  final int currentSegmentDuration;
}
