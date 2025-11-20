part of 'media_selection_bloc.dart';

abstract class MediaSelectionState {}

class MediaSelectionInitialState extends MediaSelectionState {
  MediaSelectionInitialState({
    this.isLoading = true,
    this.hasPermission = false,
  });

  final bool isLoading;
  final bool hasPermission;
}

class MediaSelectionLoadingState extends MediaSelectionState {
  MediaSelectionLoadingState({this.isLoadingMore = false});

  final bool isLoadingMore;
}

class MediaSelectionLoadedState extends MediaSelectionState {
  MediaSelectionLoadedState({
    required this.media,
    required this.albums,
    required this.currentAlbum,
    required this.selectedMedia,
    required this.isMultiSelectMode,
    this.isLoadingMore = false,
    this.hasMore = true,
  });

  final List<MediaAssetData> media;
  final List<pm.AssetPathEntity> albums;
  final pm.AssetPathEntity? currentAlbum;
  final List<MediaAssetData> selectedMedia;
  final bool isMultiSelectMode;
  final bool isLoadingMore;
  final bool hasMore;
}

class MediaSelectionErrorState extends MediaSelectionState {
  MediaSelectionErrorState({required this.message});

  final String message;
}

class MediaSelectionPermissionDeniedState extends MediaSelectionState {}

class MediaSelectionCompletedState extends MediaSelectionState {
  MediaSelectionCompletedState({required this.selectedMedia});

  final List<MediaAssetData> selectedMedia;
}

