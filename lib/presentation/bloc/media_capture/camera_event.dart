part of 'camera_bloc.dart';

abstract class CameraEvent {}

class CameraInitializeEvent extends CameraEvent {}

class CameraStartRecordingEvent extends CameraEvent {}

class CameraStopRecordingEvent extends CameraEvent {}

class CameraCapturePhotoEvent extends CameraEvent {}

class CameraSwitchCameraEvent extends CameraEvent {}

class CameraToggleFlashEvent extends CameraEvent {}

class CameraSetZoomEvent extends CameraEvent {
  CameraSetZoomEvent({required this.zoomLevel});
  final double zoomLevel;
}

class CameraSetDurationEvent extends CameraEvent {
  CameraSetDurationEvent({required this.duration});
  final int duration; // 15 or 60 seconds
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
