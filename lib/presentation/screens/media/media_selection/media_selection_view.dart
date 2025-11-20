import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart' as pm;
import 'package:video_compress/video_compress.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'media_selection.dart';
import 'widgets/media_selection_widgets.dart';

class MediaSelectionView extends StatefulWidget {
  const MediaSelectionView({
    super.key,
    required this.mediaSelectionConfig,
    this.selectedMedia,
    this.onComplete,
    this.onCaptureMedia,
  });

  final MediaSelectionConfig mediaSelectionConfig;
  final List<MediaAssetData>? selectedMedia;
  final Future<bool> Function(List<MediaAssetData> selectedMedia)? onComplete;
  final Future<String?> Function()? onCaptureMedia;

  @override
  State<MediaSelectionView> createState() => _MediaSelectionViewState();
}

class _MediaSelectionViewState extends State<MediaSelectionView>
    with TickerProviderStateMixin {
  late final MediaSelectionBloc _bloc;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _bloc = MediaSelectionBloc();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _bloc.add(MediaSelectionInitialEvent(
      selectedMedia: widget.selectedMedia,
      config: widget.mediaSelectionConfig,
    ));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _bloc.cleanupThumbnailCache();
    _bloc.close();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _bloc.add(LoadMoreMediaEvent());
    }
  }


  void _showCameraOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Take Photo or Video',
                style: TextStyle(
                  color: widget.mediaSelectionConfig.primaryTextColor,
                  fontSize: 18.responsiveDimension,
                  fontFamily: widget.mediaSelectionConfig.primaryFontFamily,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCameraOption(
                  icon: widget.mediaSelectionConfig.cameraIcon,
                  label: 'Photo',
                  onTap: () {
                    Navigator.pop(context);
                    _bloc.add(CaptureMediaEvent(mediaType: SelectedMediaType.image));
                  },
                ),
                _buildCameraOption(
                  icon: widget.mediaSelectionConfig.videoIcon,
                  label: 'Video',
                  onTap: () {
                    Navigator.pop(context);
                    _bloc.add(CaptureMediaEvent(mediaType: SelectedMediaType.video));
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraOption({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color:
                widget.mediaSelectionConfig.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              icon,
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: widget.mediaSelectionConfig.primaryColor,
                  fontSize: 14.responsiveDimension,
                  fontFamily: widget.mediaSelectionConfig.primaryFontFamily,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );


  /// Determines if the file is a video or image based on file extension
  Future<SelectedMediaType> _getMediaType(File file) async {
    final filePath = file.path;
    if (filePath.isVideoFile) {
      return SelectedMediaType.video;
    } else if (filePath.isImageFile) {
      return SelectedMediaType.image;
    } else {
      // Default to image if extension is not recognized
      return SelectedMediaType.image;
    }
  }

  /// Gets video duration in seconds, returns 0 for images
  Future<int> _getVideoDuration(File file, SelectedMediaType mediaType) async {
    if (mediaType == SelectedMediaType.video) {
      try {
        final mediaInfo = await VideoCompress.getMediaInfo(file.path);
        return (mediaInfo.duration ?? 0).toInt() ~/ 1000; // Convert from milliseconds to seconds
      } catch (e) {
        debugPrint('Error getting video duration: $e');
        return 0;
      }
    }
    return 0; // Images don't have duration
  }

  Widget _buildOptimizedMediaContent(MediaAssetData mediaData) {
    if (mediaData.mediaType == SelectedMediaType.video) {
      // Use cached thumbnail if available
      if (mediaData.thumbnailPath?.isNotEmpty == true) {
        return _buildCachedImage(mediaData.thumbnailPath!);
      }

      // Generate thumbnail with throttling
      return _buildThumbnailWithThrottling(mediaData);
    } else {
      // For images, use direct file loading with error handling
      return _buildCachedImage(mediaData.localPath ?? '');
    }
  }

  Widget _buildThumbnailWithThrottling(MediaAssetData mediaData) =>
      FutureBuilder<String?>(
        future: _bloc.getVideoThumbnail(mediaData.localPath ?? ''),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            mediaData.thumbnailPath = snapshot.data;
            return _buildCachedImage(snapshot.data!);
          }
          return _buildVideoPlaceholder();
        },
      );

  Widget _buildCachedImage(String imagePath) => AppImage.file(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );

  void _onAlbumSelected(pm.AssetPathEntity album) {
    _bloc.add(SelectAlbumEvent(album: album));
  }

  String _getAlbumDisplayName(pm.AssetPathEntity? album) {
    if (album == null) return 'Recent';

    if (album.isAll && album.type == pm.RequestType.image) {
      return 'Images';
    } else if (album.isAll && album.type == pm.RequestType.video) {
      return 'Videos';
    } else if (album.isAll) {
      return 'Recent';
    }

    // For specific type albums, we'll determine based on the album name
    final albumName = album.name.toLowerCase();
    if (albumName.contains('image')) {
      return 'Images';
    } else if (albumName.contains('video')) {
      return 'Videos';
    }

    return album.name;
  }

  PopupMenuEntry<pm.AssetPathEntity> _buildAlbumMenuItem(
      pm.AssetPathEntity album, pm.AssetPathEntity? currentAlbum) {
    final isSelected = album == currentAlbum;

    // Get display name based on album type
    final displayName = _getAlbumDisplayName(album);

    return PopupMenuItem<pm.AssetPathEntity>(
      value: album,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                displayName,
                style: TextStyle(
                  color: isSelected
                      ? widget.mediaSelectionConfig.primaryColor
                      : Colors.black,
                  fontSize: 14,
                  fontFamily: widget.mediaSelectionConfig.primaryFontFamily,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: widget.mediaSelectionConfig.primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => BlocProvider<MediaSelectionBloc>.value(
        value: _bloc,
        child: BlocListener<MediaSelectionBloc, MediaSelectionState>(
          listener: (context, state) {
            if (state is MediaSelectionErrorState) {
              MediaSelectionUtility.showInSnackBar(state.message, context);
            } else if (state is MediaSelectionCompletedState) {
              _handleMediaSelectionComplete(state.selectedMedia);
            }
          },
          child: Scaffold(
            backgroundColor: widget.mediaSelectionConfig.backgroundColor,
            appBar: AppBar(
              backgroundColor: widget.mediaSelectionConfig.appBarColor,
              elevation: 1,
              leading: IconButton(
                icon: widget.mediaSelectionConfig.closeIcon,
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                widget.mediaSelectionConfig.selectMediaTitle,
                style: TextStyle(
                  color: widget.mediaSelectionConfig.primaryTextColor,
                  fontSize: 18.responsiveDimension,
                  fontFamily: widget.mediaSelectionConfig.primaryFontFamily,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              centerTitle: true,
            ),
            body: BlocBuilder<MediaSelectionBloc, MediaSelectionState>(
              buildWhen: (previous, current) =>
              current is MediaSelectionLoadingState
              || current is MediaSelectionPermissionDeniedState
              || current is MediaSelectionLoadedState
              || current is MediaSelectionErrorState,
              builder: (context, state) {
                if (state is MediaSelectionInitialState ||
                    state is MediaSelectionLoadingState) {
                  return Center(
                    child: CircularProgressIndicator(
                        color: widget.mediaSelectionConfig.primaryColor),
                  );
                } else if (state is MediaSelectionPermissionDeniedState) {
                  return _buildPermissionDenied();
                } else if (state is MediaSelectionLoadedState) {
                  return _buildBody(state);
                } else if (state is MediaSelectionErrorState) {
                  return Center(
                    child: Text(
                      state.message,
                      style: TextStyle(
                        color: widget.mediaSelectionConfig.primaryTextColor,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

  Future<void> _handleMediaSelectionComplete(
      List<MediaAssetData> selectedMedia) async {
    final isPop = await widget.onComplete?.call(selectedMedia) ?? true;
    if (isPop && mounted) {
      Navigator.pop(context, selectedMedia);
    }
  }

  Widget _buildBody(MediaSelectionLoadedState state) => Stack(
        children: [
          _buildSliverBody(state),
          if (state.selectedMedia.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildSelectedMediaBottomSheet(state),
            ),
        ],
      );

  Widget _buildSelectedMediaBottomSheet(MediaSelectionLoadedState state) =>
      Container(
        height: 100.responsiveDimension,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Selected media list
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.selectedMedia.length,
                  itemBuilder: (context, index) {
                    final media = state.selectedMedia[index];
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          // Media thumbnail
                          SizedBox(
                            width: 70.responsiveDimension *
                                widget.mediaSelectionConfig.gridItemAspectRatio,
                            height: 70.responsiveDimension,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Stack(
                                children: [
                                  _buildOptimizedMediaContent(media),
                                  // Video duration indicator
                                  if (media.mediaType == SelectedMediaType.video)
                                    Positioned(
                                      bottom: 1,
                                      right: 1,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              Colors.black.withValues(alpha: 0.7),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _formatDuration((media.duration ?? 0).toInt()),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          // Remove button
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () =>
                                  _bloc.add(DeselectMediaEvent(mediaData: media)),
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Next button
              Container(
                margin: const EdgeInsets.only(left: 12),
                child: ElevatedButton(
                  onPressed: () => _bloc.add(ProceedToEditFilterEvent()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.mediaSelectionConfig.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Next (${state.selectedMedia.length})',
                    style: TextStyle(
                      fontSize: 14.responsiveDimension,
                      fontFamily: widget.mediaSelectionConfig.primaryFontFamily,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildSliverBody(MediaSelectionLoadedState state) => Column(
        children: [
          // Album selector and controls
          Container(
            height: 50,
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: PopupMenuButton<pm.AssetPathEntity>(
                    onSelected: _onAlbumSelected,
                    position: PopupMenuPosition.under,
                    color: Colors.white.withValues(alpha: 0.9),
                    itemBuilder: (context) => state.albums
                        .map((album) => _buildAlbumMenuItem(album, state.currentAlbum))
                        .toList(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            _getAlbumDisplayName(state.currentAlbum),
                            style: TextStyle(
                              color:
                                  widget.mediaSelectionConfig.primaryTextColor,
                              fontSize: 16.responsiveDimension,
                              fontFamily:
                                  widget.mediaSelectionConfig.primaryFontFamily,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.keyboard_arrow_down,
                              color: Colors.black),
                        ],
                      ),
                    ),
                  ),
                ),
                // Select mode indicator and toggle (only show if isMultiSelect is true)
                if (widget.mediaSelectionConfig.isMultiSelect) ...[
                  // Select mode toggle
                  IconButton(
                    icon: state.isMultiSelectMode
                        ? widget.mediaSelectionConfig.multiSelectModeIcon
                        : widget.mediaSelectionConfig.singleSelectModeIcon,
                    onPressed: () => _bloc.add(ToggleSelectModeEvent()),
                    tooltip: state.isMultiSelectMode
                        ? 'Switch to single select'
                        : 'Switch to multi select',
                  ),
                ],
              ],
            ),
          ),

          // Media grid as scrollable widget
          Expanded(
            child: _buildScrollableMediaGrid(state),
          ),
        ],
      );


  Widget _buildScrollableMediaGrid(MediaSelectionLoadedState state) {
    // Calculate total items: camera button + gallery media
    final totalItems = 1 + state.media.length;

    // Calculate aspect ratio for reels-like layout
    final screenSize = MediaQuery.of(context).size;

    // For reels-like layout, we want items to be taller than wide
    // Calculate crossAxisCount based on screen width and desired item width
    final desiredItemWidth = widget.mediaSelectionConfig.gridItemMaxWidth;
    final crossAxisCount =
        (screenSize.width / desiredItemWidth).floor().clamp(2, 6);

    // Use 9:16 aspect ratio as default (9/16 = 0.5625)
    final itemAspectRatio = widget.mediaSelectionConfig.gridItemAspectRatio;

    return GridView.builder(
      controller: _scrollController,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: (crossAxisCount > 2) ? crossAxisCount : 2,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: itemAspectRatio,
      ),
      itemCount: totalItems + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Camera button as first item
        if (index == 0) {
          return CameraButtonWidget(
              mediaSelectionConfig: widget.mediaSelectionConfig,
              onTap: _captureMedia);
        }

        // Gallery media items
        final galleryIndex = index - 1;

        // Show loading indicator at the end when loading more
        if (galleryIndex == state.media.length && state.isLoadingMore) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

        // Return empty container if index is beyond available media
        if (galleryIndex >= state.media.length) {
          return const SizedBox.shrink();
        }

        final mediaData = state.media[galleryIndex];
        final isSelected = state.selectedMedia.contains(mediaData);
        final selectedIndex = state.selectedMedia.indexOf(mediaData);

        return _buildMediaItem(mediaData, isSelected, selectedIndex, state);
      },
    );
  }

  void _captureMedia() async {
    if (widget.onCaptureMedia != null) {
      final filePath = await widget.onCaptureMedia!();
      if (filePath?.isNotEmpty == true) {
        final file = File(filePath!);
        final mediaType = await _getMediaType(file);
        final duration = await _getVideoDuration(file, mediaType);
        _bloc.add(ProcessCapturedMediaEvent(
          file: file,
          mediaType: mediaType,
          duration: duration,
        ));
      }
    } else {
      switch (widget.mediaSelectionConfig.mediaListType) {
        case MediaListType.image:
          _bloc.add(CaptureMediaEvent(mediaType: SelectedMediaType.image));
          break;
        case MediaListType.video:
          _bloc.add(CaptureMediaEvent(mediaType: SelectedMediaType.video));
          break;
        case MediaListType.imageVideo:
          _showCameraOptions();
          break;
        case MediaListType.audio:
          break;
      }
    }
  }

  Widget _buildMediaItem(MediaAssetData mediaData, bool isSelected,
          int selectedIndex, MediaSelectionLoadedState state) =>
      Stack(
        fit: StackFit.expand,
        children: [
          // Main media content
          GestureDetector(
            onTap: () {
              _bloc.add(SelectMediaEvent(mediaData: mediaData));
            },
            onLongPress: () {
              _bloc.add(ToggleSelectModeEvent());
              _bloc.add(SelectMediaEvent(mediaData: mediaData));
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildOptimizedMediaContent(mediaData),
                if (mediaData.mediaType == SelectedMediaType.video)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatDuration((mediaData.duration ?? 0).toInt()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Selection indicator (checkbox/counter)
          if (isSelected)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _bloc.add(DeselectMediaEvent(mediaData: mediaData)),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: widget.mediaSelectionConfig.primaryColor,
                    shape: state.isMultiSelectMode
                        ? BoxShape.circle
                        : BoxShape.rectangle,
                    borderRadius: state.isMultiSelectMode
                        ? null
                        : BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: state.isMultiSelectMode
                        ? Text(
                            '${selectedIndex + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                  ),
                ),
              ),
            ),
        ],
      );

  Widget _buildPermissionDenied() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: widget.mediaSelectionConfig.primaryTextColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Permission Required',
              style: TextStyle(
                color: widget.mediaSelectionConfig.primaryTextColor,
                fontSize: 18.responsiveDimension,
                fontFamily: widget.mediaSelectionConfig.primaryFontFamily,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please allow access to your photos to select media',
              style: TextStyle(
                color: widget.mediaSelectionConfig.primaryTextColor,
                fontSize: 14.responsiveDimension,
                fontFamily: widget.mediaSelectionConfig.primaryFontFamily,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _bloc.add(RequestPermissionEvent()),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.mediaSelectionConfig.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      );

  String _formatDuration(int duration) {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildVideoPlaceholder() => Container(
        color: Colors.grey[800],
        child: const Center(
          child: Icon(Icons.video_library, color: Colors.white),
        ),
      );
}
