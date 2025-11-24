import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart' as pm;
import 'package:video_compress/video_compress.dart';

import '../../screens/media/media_selection/media_selection_config.dart';
import '../../screens/media/media_selection/model/media_asset_data.dart';

part 'media_selection_event.dart';
part 'media_selection_state.dart';

class MediaSelectionBloc
    extends Bloc<MediaSelectionEvent, MediaSelectionState> {
  MediaSelectionBloc() : super(MediaSelectionInitialState()) {
    on<MediaSelectionInitialEvent>(_onInitial);
    on<RequestPermissionEvent>(_onRequestPermission);
    on<LoadAlbumsEvent>(_onLoadAlbums);
    on<LoadMediaEvent>(_onLoadMedia);
    on<SelectAlbumEvent>(_onSelectAlbum);
    on<SelectMediaEvent>(_onSelectMedia);
    on<DeselectMediaEvent>(_onDeselectMedia);
    on<ToggleSelectModeEvent>(_onToggleSelectMode);
    on<LoadMoreMediaEvent>(_onLoadMoreMedia);
    on<CaptureMediaEvent>(_onCaptureMedia);
    on<ProcessCapturedMediaEvent>(_onProcessCapturedMedia);
    on<ProceedToEditFilterEvent>(_onProceedToEditFilter);
  }

  // State variables
  MediaSelectionConfig? _config;
  final List<MediaAssetData> _selectedMedia = [];
  final List<MediaAssetData> _media = [];
  final List<pm.AssetPathEntity> _albums = [];
  pm.AssetPathEntity? _currentAlbum;
  bool _isMultiSelectMode = false;
  int _currentPage = 0;
  bool _isProcessingSelection = false;
  bool _hasMore = true;

  // Thumbnail cache
  final Map<String, String> _thumbnailCache = {};
  final Set<String> _thumbnailGenerationInProgress = {};
  final int _maxConcurrentThumbnails = 3;

  Future<void> _onInitial(
    MediaSelectionInitialEvent event,
    Emitter<MediaSelectionState> emit,
  ) async {
    _config = event.config;
    if (event.selectedMedia != null) {
      _selectedMedia.addAll(event.selectedMedia!);
    }
    add(RequestPermissionEvent());
  }

  Future<void> _onRequestPermission(
    RequestPermissionEvent event,
    Emitter<MediaSelectionState> emit,
  ) async {
    emit(MediaSelectionLoadingState());
    final ps = await pm.PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      emit(MediaSelectionLoadedState(
        media: _media,
        albums: _albums,
        currentAlbum: _currentAlbum,
        selectedMedia: _selectedMedia,
        isMultiSelectMode: _isMultiSelectMode,
        hasMore: _hasMore,
      ));
      add(LoadAlbumsEvent());
    } else {
      emit(MediaSelectionPermissionDeniedState());
    }
  }

  Future<void> _onLoadAlbums(
    LoadAlbumsEvent event,
    Emitter<MediaSelectionState> emit,
  ) async {
    if (_config == null) return;

    try {
      _albums.clear();

      // 1. Recent Album - All images and videos sorted by recent date
      final recentAlbum = await pm.PhotoManager.getAssetPathList(
        type: pm.RequestType.common,
        hasAll: true,
        onlyAll: true,
        filterOption: pm.FilterOptionGroup(
          orders: [
            const pm.OrderOption(
              type: pm.OrderOptionType.updateDate,
              asc: false, // false = NEW → OLD
            )
          ],
        ),
      );

      // 2. Images Album
      final imagesAlbum = await pm.PhotoManager.getAssetPathList(
        type: pm.RequestType.image,
        hasAll: true,
        onlyAll: true,
        filterOption: pm.FilterOptionGroup(
          orders: [
            const pm.OrderOption(
              type: pm.OrderOptionType.updateDate,
              asc: false, // false = NEW → OLD
            )
          ],
        ),
      );

      // 3. Videos Album
      final videosAlbum = await pm.PhotoManager.getAssetPathList(
        type: pm.RequestType.video,
        hasAll: true,
        onlyAll: true,
        filterOption: pm.FilterOptionGroup(
          orders: [
            const pm.OrderOption(
              type: pm.OrderOptionType.updateDate,
              asc: false, // false = NEW → OLD
            )
          ],
        ),
      );

      // Add albums if they have content
      if (recentAlbum.isNotEmpty &&
          _config!.mediaListType == MediaListType.imageVideo) {
        final recentCount = await recentAlbum.first.assetCountAsync;
        if (recentCount > 0) {
          log('load local media -> recent album ${recentAlbum.length}');
          for (final album in recentAlbum) {
            final count = await album.assetCountAsync;
            log('load local media -> album ${album.name} -> count $count');
          }
          _albums.add(recentAlbum.first);
        }
      }

      if (imagesAlbum.isNotEmpty &&
          (_config!.mediaListType == MediaListType.imageVideo ||
              _config!.mediaListType == MediaListType.image)) {
        final imagesCount = await imagesAlbum.first.assetCountAsync;
        if (imagesCount > 0) {
          _albums.add(imagesAlbum.first);
        }
      }

      if (videosAlbum.isNotEmpty &&
          (_config!.mediaListType == MediaListType.imageVideo ||
              _config!.mediaListType == MediaListType.video)) {
        final videosCount = await videosAlbum.first.assetCountAsync;
        if (videosCount > 0) {
          _albums.add(videosAlbum.first);
        }
      }

      // Set the first available album as current
      if (_albums.isNotEmpty) {
        _currentAlbum = _albums.first;
        _currentPage = 0;
        _hasMore = true;
        add(LoadMediaEvent(loadMore: false));
      } else {
        emit(MediaSelectionLoadedState(
          media: _media,
          albums: _albums,
          currentAlbum: _currentAlbum,
          selectedMedia: _selectedMedia,
          isMultiSelectMode: _isMultiSelectMode,
          hasMore: false,
        ));
      }
    } catch (e) {
      debugPrint('Error loading albums: $e');
      emit(MediaSelectionErrorState(message: 'Error loading albums: $e'));
    }
  }

  Future<void> _onLoadMedia(
    LoadMediaEvent event,
    Emitter<MediaSelectionState> emit,
  ) async {
    if (_currentAlbum == null || _config == null) return;

    try {
      if (!event.loadMore) {
        _currentPage = 0;
        _media.clear();
        _hasMore = true;
      }

      if (!_hasMore && event.loadMore) {
        return;
      }

      emit(MediaSelectionLoadedState(
        media: _media,
        albums: _albums,
        currentAlbum: _currentAlbum,
        selectedMedia: _selectedMedia,
        isMultiSelectMode: _isMultiSelectMode,
        isLoadingMore: event.loadMore,
        hasMore: _hasMore,
      ));
      log('load local media -> current page: $_currentPage');
      final count = await _currentAlbum?.assetCountAsync;
      final assets = await _currentAlbum!.getAssetListPaged(
        page: _currentPage,
        size: _config!.pageSize,
      );
      log('load local media -> assets ${assets.length} -> count $count  ');
      // Check if we have more items
      if (assets.length < _config!.pageSize) {
        _hasMore = false;
      }

      // Convert assets to MediaAssetData
      final mediaDataList =
          await Future.wait(assets.map(_convertAssetToMediaAssetData));

      final newMedia = mediaDataList
          .where((media) => media != null)
          .cast<MediaAssetData>()
          .toList();

      if (event.loadMore) {
        _media.addAll(newMedia);
        // Increment page after successful load more
        if (newMedia.isNotEmpty) {
          _currentPage++;
        }
      } else {
        _media.clear();
        _media.addAll(newMedia);
        // After initial load, set page to 1 for next load more
        if (newMedia.isNotEmpty) {
          _currentPage = 1;
        }
      }

      emit(MediaSelectionLoadedState(
        media: List.from(_media),
        albums: _albums,
        currentAlbum: _currentAlbum,
        selectedMedia: List.from(_selectedMedia),
        isMultiSelectMode: _isMultiSelectMode,
        isLoadingMore: false,
        hasMore: _hasMore,
      ));
    } catch (e) {
      debugPrint('Error loading media: $e');
      emit(MediaSelectionErrorState(message: 'Error loading media: $e'));
    }
  }

  Future<void> _onLoadMoreMedia(
    LoadMoreMediaEvent event,
    Emitter<MediaSelectionState> emit,
  ) async {
    if (state is MediaSelectionLoadedState) {
      final currentState = state as MediaSelectionLoadedState;
      if (!currentState.isLoadingMore) {
        // Don't increment _currentPage here, it's incremented in _onLoadMedia after successful load
        add(LoadMediaEvent(loadMore: true));
      }
    }
  }

  Future<void> _onSelectAlbum(
    SelectAlbumEvent event,
    Emitter<MediaSelectionState> emit,
  ) async {
    _currentAlbum = event.album;
    _currentPage = 0;
    _hasMore = true;
    add(LoadMediaEvent(loadMore: false));
  }

  Future<void> _onSelectMedia(
    SelectMediaEvent event,
    Emitter<MediaSelectionState> emit,
  ) async {
    if (_config == null) return;

    // Prevent rapid successive selections
    if (_isProcessingSelection) {
      return;
    }

    if (_selectedMedia.contains(event.mediaData)) {
      add(DeselectMediaEvent(mediaData: event.mediaData));
      return;
    }

    _isProcessingSelection = true;

    try {
      // Check limits
      final isVideo = event.mediaData.mediaType == SelectedMediaType.video;

      // Check overall media limit
      if (_selectedMedia.length >= _config!.mediaLimit) {
        _isProcessingSelection = false;
        emit(MediaSelectionErrorState(message: getLimitMessage('media')));
        return;
      }

      // Check specific media type limits
      final videoCount = _selectedMedia
          .where((media) => media.mediaType == SelectedMediaType.video)
          .length;
      final imageCount = _selectedMedia
          .where((media) => media.mediaType == SelectedMediaType.image)
          .length;

      if (isVideo && videoCount >= _config!.videoMediaLimit) {
        _isProcessingSelection = false;
        emit(MediaSelectionErrorState(message: getLimitMessage('video')));
        return;
      } else if (!isVideo && imageCount >= _config!.imageMediaLimit) {
        _isProcessingSelection = false;
        emit(MediaSelectionErrorState(message: getLimitMessage('image')));
        return;
      }

      // Check multi-select mode limits
      if (_isMultiSelectMode) {
        if (_selectedMedia.length >= _config!.mediaLimit) {
          _isProcessingSelection = false;
          emit(MediaSelectionErrorState(message: getLimitMessage('media')));
          return;
        }
      }

      if (!_isMultiSelectMode) {
        _selectedMedia.clear();
      }
      _selectedMedia.add(event.mediaData);

      final newState = MediaSelectionLoadedState(
        media: List.from(_media),
        albums: _albums,
        currentAlbum: _currentAlbum,
        selectedMedia: List.from(_selectedMedia),
        isMultiSelectMode: _isMultiSelectMode,
        hasMore: _hasMore,
      );
      emit(newState);

      // If single select mode, proceed immediately
      if (!_isMultiSelectMode) {
        add(ProceedToEditFilterEvent());
      }
    } finally {
      _isProcessingSelection = false;
    }
  }

  Future<void> _onDeselectMedia(
    DeselectMediaEvent event,
    Emitter<MediaSelectionState> emit,
  ) async {
    if (state is MediaSelectionLoadedState) {
      _selectedMedia.remove(event.mediaData);
      emit(MediaSelectionLoadedState(
        media: List.from(_media),
        albums: _albums,
        currentAlbum: _currentAlbum,
        selectedMedia: List.from(_selectedMedia),
        isMultiSelectMode: _isMultiSelectMode,
        hasMore: _hasMore,
      ));
    }
  }

  Future<void> _onToggleSelectMode(
    ToggleSelectModeEvent event,
    Emitter<MediaSelectionState> emit,
  ) async {
    if (_config == null || !_config!.isMultiSelect) {
      return;
    }

    if (state is MediaSelectionLoadedState) {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode && _selectedMedia.length > 1) {
        final lastMedia = _selectedMedia.last;
        _selectedMedia.clear();
        _selectedMedia.add(lastMedia);
      }

      emit(MediaSelectionLoadedState(
        media: List.from(_media),
        albums: _albums,
        currentAlbum: _currentAlbum,
        selectedMedia: List.from(_selectedMedia),
        isMultiSelectMode: _isMultiSelectMode,
        hasMore: _hasMore,
      ));
    }
  }

  Future<void> _onCaptureMedia(
    CaptureMediaEvent event,
    Emitter<MediaSelectionState> emit,
  ) async {
    try {
      final status = await Permission.camera.status;

      if (status.isDenied) {
        final result = await Permission.camera.request();
        if (!result.isGranted) {
          emit(MediaSelectionErrorState(
              message: 'Camera permission is required to capture media.'));
          return;
        }
      } else if (status.isPermanentlyDenied) {
        emit(MediaSelectionErrorState(
            message:
                'Camera access is permanently denied. Please enable it from settings.'));
        await openAppSettings();
        return;
      }

      final picker = ImagePicker();
      XFile? file;
      var duration = 0;

      if (event.mediaType == SelectedMediaType.video) {
        if (_config == null) return;
        file = await picker.pickVideo(
          source: ImageSource.camera,
          maxDuration: _config!.videoMaxDuration,
        );
        if (file != null) {
          final mediaInfo = await VideoCompress.getMediaInfo(file.path);
          duration = ((mediaInfo.duration ?? 0) / 1000).toInt();
        }
      } else {
        file = await picker.pickImage(source: ImageSource.camera);
      }

      if (file != null && file.path.isNotEmpty) {
        add(ProcessCapturedMediaEvent(
          file: File(file.path),
          mediaType: event.mediaType,
          duration: duration,
        ));
      }
    } catch (e) {
      emit(MediaSelectionErrorState(
          message: 'Error capturing media: ${e.toString()}'));
    }
  }

  Future<void> _onProcessCapturedMedia(
    ProcessCapturedMediaEvent event,
    Emitter<MediaSelectionState> emit,
  ) async {
    try {
      final filePath = event.file.path;
      final isVideo = event.mediaType == SelectedMediaType.video;

      final mediaData = MediaAssetData(
        assetId: 'camera_${DateTime.now().millisecondsSinceEpoch}',
        mediaType: isVideo ? SelectedMediaType.video : SelectedMediaType.image,
        localPath: filePath,
        file: event.file,
        width: 1080,
        height: 1920,
        duration: event.duration,
        extension: filePath.split('.').last,
        isTemp: 'true',
        isCaptured: true,
      );

      add(ProceedToEditFilterEvent(media: [mediaData]));
    } catch (e) {
      emit(MediaSelectionErrorState(
          message: 'Error processing captured media: ${e.toString()}'));
    }
  }

  Future<void> _onProceedToEditFilter(
    ProceedToEditFilterEvent event,
    Emitter<MediaSelectionState> emit,
  ) async {
    final mediaToEdit = event.media ?? _selectedMedia;
    if (mediaToEdit.isEmpty) {
      emit(MediaSelectionErrorState(
          message: 'Please select at least one media item'));
      return;
    }

    emit(MediaSelectionCompletedState(selectedMedia: mediaToEdit));
  }

  Future<MediaAssetData?> _convertAssetToMediaAssetData(
      pm.AssetEntity asset) async {
    try {
      final file = await asset.file;
      if (file == null) return null;

      final isVideo = asset.type == pm.AssetType.video;

      return MediaAssetData(
        assetId: asset.id,
        localPath: file.path,
        file: file,
        mediaType: isVideo ? SelectedMediaType.video : SelectedMediaType.image,
        width: asset.width,
        height: asset.height,
        duration: asset.duration,
        extension: file.path.split('.').last,
      );
    } catch (e) {
      debugPrint('Error converting asset to MediaAssetData: $e');
      return null;
    }
  }

  // Helper methods for limit validation
  int getCurrentVideoCount() => _selectedMedia
      .where((media) => media.mediaType == SelectedMediaType.video)
      .length;

  int getCurrentImageCount() => _selectedMedia
      .where((media) => media.mediaType == SelectedMediaType.image)
      .length;

  bool canAddVideo() {
    if (_config == null) return false;
    return getCurrentVideoCount() < _config!.videoMediaLimit;
  }

  bool canAddImage() {
    if (_config == null) return false;
    return getCurrentImageCount() < _config!.imageMediaLimit;
  }

  bool canAddMedia() {
    if (_config == null) return false;
    return _selectedMedia.length < _config!.mediaLimit;
  }

  String getLimitMessage(String mediaType) {
    if (_config == null) return '';
    switch (mediaType) {
      case 'video':
        return 'Maximum ${_config!.videoMediaLimit} video${_config!.videoMediaLimit > 1 ? 's' : ''} allowed';
      case 'image':
        return 'Maximum ${_config!.imageMediaLimit} image${_config!.imageMediaLimit > 1 ? 's' : ''} allowed';
      default:
        return 'Maximum ${_config!.mediaLimit} media item${_config!.mediaLimit > 1 ? 's' : ''} allowed';
    }
  }

  // Thumbnail methods
  Future<String?> getVideoThumbnail(String videoPath) async {
    // Check cache first
    if (_thumbnailCache.containsKey(videoPath)) {
      return _thumbnailCache[videoPath];
    }

    // Check if already generating for this video
    if (_thumbnailGenerationInProgress.contains(videoPath)) {
      await Future.delayed(const Duration(milliseconds: 100));
      return _thumbnailCache[videoPath];
    }

    // Limit concurrent thumbnail generation
    if (_thumbnailGenerationInProgress.length >= _maxConcurrentThumbnails) {
      while (
          _thumbnailGenerationInProgress.length >= _maxConcurrentThumbnails) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    _thumbnailGenerationInProgress.add(videoPath);

    try {
      if (_config == null) return null;
      final thumbnailFile = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: (await Directory.systemTemp.createTemp()).path,
        quality: _config!.thumbnailQuality,
      );

      final thumbnailPath = thumbnailFile.path;
      _thumbnailCache[videoPath] = thumbnailPath;
      return thumbnailPath;
    } catch (e) {
      debugPrint('Error generating thumbnail for $videoPath: $e');
      return null;
    } finally {
      _thumbnailGenerationInProgress.remove(videoPath);
    }
  }

  void cleanupThumbnailCache() {
    for (final thumbnailPath in _thumbnailCache.values) {
      try {
        final file = File(thumbnailPath);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        debugPrint('Error cleaning up thumbnail: $e');
      }
    }
    _thumbnailCache.clear();
    _thumbnailGenerationInProgress.clear();
  }
}
