part of 'media_selection_bloc.dart';

abstract class MediaSelectionEvent {
  const MediaSelectionEvent();
}

class MediaSelectionInitialEvent extends MediaSelectionEvent {
  MediaSelectionInitialEvent({
    this.selectedMedia,
    required this.config,
  });

  final List<MediaAssetData>? selectedMedia;
  final MediaSelectionConfig config;
}

class RequestPermissionEvent extends MediaSelectionEvent {
  const RequestPermissionEvent({required this.openSettingsIfDenied});
  final bool openSettingsIfDenied;
}

class LoadAlbumsEvent extends MediaSelectionEvent {}

class LoadMediaEvent extends MediaSelectionEvent {
  LoadMediaEvent({this.loadMore = false});

  final bool loadMore;
}

class SelectAlbumEvent extends MediaSelectionEvent {
  SelectAlbumEvent({required this.album});

  final pm.AssetPathEntity album;
}

class SelectMediaEvent extends MediaSelectionEvent {
  SelectMediaEvent({required this.mediaData});

  final MediaAssetData mediaData;
}

class DeselectMediaEvent extends MediaSelectionEvent {
  DeselectMediaEvent({required this.mediaData});

  final MediaAssetData mediaData;
}

class ToggleSelectModeEvent extends MediaSelectionEvent {}

class LoadMoreMediaEvent extends MediaSelectionEvent {}

class CaptureMediaEvent extends MediaSelectionEvent {
  CaptureMediaEvent({required this.mediaType});

  final SelectedMediaType mediaType;
}

class ProcessCapturedMediaEvent extends MediaSelectionEvent {
  ProcessCapturedMediaEvent({
    required this.file,
    required this.mediaType,
    required this.duration,
  });

  final File file;
  final SelectedMediaType mediaType;
  final int duration;
}

class ProceedToEditFilterEvent extends MediaSelectionEvent {
  ProceedToEditFilterEvent({this.media});

  final List<MediaAssetData>? media;
}
