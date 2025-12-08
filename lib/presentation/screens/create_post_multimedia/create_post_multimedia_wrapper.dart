import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_capture/camera.dart'
    as mc;
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/media_edit.dart'
    as me;
import 'package:ism_video_reel_player/presentation/screens/media/media_selection/media_selection.dart'
    as ms;
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/extensions.dart';
import 'package:path/path.dart' as path;

class CreatePostMultimediaWrapper extends StatefulWidget {
  const CreatePostMultimediaWrapper({super.key, this.onTagProduct});
  final Future<List<ProductDataModel>?> Function(List<ProductDataModel>)?
      onTagProduct;
  @override
  State<CreatePostMultimediaWrapper> createState() =>
      _CreatePostMultimediaWrapperState();
}

class _CreatePostMultimediaWrapperState
    extends State<CreatePostMultimediaWrapper> {
  final mediaSelectionConfig = ms.MediaSelectionConfig(
    isMultiSelect: true,
    imageMediaLimit: AppConstants.imageMediaLimit,
    videoMediaLimit: AppConstants.videoMediaLimit,
    mediaLimit: AppConstants.totalMediaLimit,
    singleSelectModeIcon:
        const AppImage.svg(AssetConstants.icMediaSelectSingle),
    multiSelectModeIcon:
        const AppImage.svg(AssetConstants.icMediaSelectMultiple),
    doneButtonText: IsrTranslationFile.next,
    selectMediaTitle: IsrTranslationFile.newReel,
    primaryColor: IsrColors.appColor,
    primaryTextColor: IsrColors.primaryTextColor,
    backgroundColor: Colors.white,
    appBarColor: Colors.white,
    primaryFontFamily: AppConstants.primaryFontFamily,
    mediaListType: ms.MediaListType.imageVideo,
  );

  late final mediaEditConfig = me.MediaEditConfig(
    primaryColor: IsrColors.appColor,
    primaryTextColor: IsrColors.primaryTextColor,
    backgroundColor: Colors.white,
    appBarColor: Colors.white,
    primaryFontFamily: AppConstants.primaryFontFamily,
  );

  Future<bool> _onMediaSelectionComplete(
      List<ms.MediaAssetData> selectedMedia) async {
    // Ensure all video thumbnails are generated before proceeding
    for (final media in selectedMedia) {
      if (media.mediaType == ms.SelectedMediaType.video &&
          (media.thumbnailPath == null || media.thumbnailPath!.isEmpty)) {
        // Generate thumbnail if not already available
        final thumbnailPath = await _generateVideoThumbnail(media.localPath);
        if (thumbnailPath != null) {
          media.thumbnailPath = thumbnailPath;
        }
      }
    }

    // Convert to MediaEditItem and navigate to edit view
    final mediaEditItems = selectedMedia.map(mapSelectedToEditMedia).toList();

    if (mediaEditItems.isNotEmpty) {
      // Navigate to media edit view with the result
      await Navigator.push<List<me.MediaEditItem>>(
        context,
        MaterialPageRoute(
          builder: (context) => me.MediaEditView(
            mediaDataList: mediaEditItems,
            onComplete: _onMediaEditComplete,
            addMoreMedia: _onAddMoreMedia,
            mediaEditConfig: mediaEditConfig,
            pickCoverPic: _pickCoverPic,
            // onSelectSound: _onSelectSound,
          ),
        ),
      );
    }

    return false;
  }

  me.MediaEditItem mapSelectedToEditMedia(ms.MediaAssetData media) =>
      me.MediaEditItem(
        originalPath: media.localPath ?? '',
        mediaType: media.mediaType == ms.SelectedMediaType.video
            ? me.EditMediaType.video
            : me.EditMediaType.image,
        width: (media.width ?? 0).toDouble(),
        height: (media.height ?? 0).toDouble(),
        duration: media.duration?.toInt(),
        thumbnailPath: media.mediaType == ms.SelectedMediaType.video
            ? media.thumbnailPath
            : media.localPath,
        metaData: media.toJson(),
      );

  Future<List<me.MediaEditItem>?> _onAddMoreMedia(
      List<me.MediaEditItem> editMedia) async {
    final presentVideoCount = editMedia
        .where((item) => item.mediaType == me.EditMediaType.video)
        .length;
    final presentImageCount = editMedia
        .where((item) => item.mediaType == me.EditMediaType.image)
        .length;

    final imageLimit = AppConstants.imageMediaLimit - presentImageCount;
    final videoLimit = AppConstants.videoMediaLimit - presentVideoCount;
    final mediaLimit =
        AppConstants.totalMediaLimit - (presentImageCount + presentVideoCount);

    final res = await Navigator.push<List<ms.MediaAssetData>>(
      context,
      MaterialPageRoute(
        builder: (context) => ms.MediaSelectionView(
          mediaSelectionConfig: mediaSelectionConfig.copyWith(
            mediaListType: (videoLimit > 0 && imageLimit > 0)
                ? ms.MediaListType.imageVideo
                : (videoLimit > 0)
                    ? ms.MediaListType.video
                    : ms.MediaListType.image,
            isMultiSelect: mediaLimit > 1,
            imageMediaLimit: imageLimit,
            videoMediaLimit: videoLimit,
            mediaLimit: mediaLimit,
          ),
          onCaptureMedia: _captureMedia,
        ),
      ),
    );
    return res?.map(mapSelectedToEditMedia).toList();
  }

  Future<String?> _pickCoverPic() async {
    final res = await Navigator.push<List<ms.MediaAssetData>>(
      context,
      MaterialPageRoute(
        builder: (context) => ms.MediaSelectionView(
          mediaSelectionConfig: mediaSelectionConfig.copyWith(
              mediaListType: ms.MediaListType.image,
              isMultiSelect: false,
              selectMediaTitle: IsrTranslationFile.addCover),
          onCaptureMedia: _captureMedia,
        ),
      ),
    );
    return res?.first.localPath;
  }

  Future<bool> _onMediaEditComplete(List<me.MediaEditItem> editedMedia) async {
    if (editedMedia.isNotEmpty) {
      final _mediaDataList = editedMedia
          .toList()
          .map((editItem) => MediaData(
              assetId: '',
              mediaType: editItem.mediaType.toJson(),
              url: editItem.editedPath ?? editItem.originalPath,
              localPath: editItem.editedPath ?? editItem.originalPath,
              previewUrl: editItem.thumbnailPath ??
                  editItem.editedPath ??
                  editItem.originalPath,
              coverFileLocalPath: editItem.thumbnailPath ??
                  editItem.editedPath ??
                  editItem.originalPath,
              width: editItem.width,
              height: editItem.height,
              duration: editItem.duration,
              fileName: '',
              postType: editItem.mediaType == me.EditMediaType.video
                  ? PostType.video
                  : PostType.photo,
              position: editedMedia.indexOf(editItem) + 1,
              fileExtension: _getFileExtension(
                  editItem.editedPath ?? editItem.originalPath)))
          .toList();
      await IsrAppNavigator.goToCreatePostAttributionView(context,
          onTagProduct: widget.onTagProduct, newMediaDataList: _mediaDataList);
      // _createPostBloc.goToPostAttributeView(context,
      //     newMediaDataList: _mediaDataList, onTagProduct: widget.onTagProduct);
      return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => ms.MediaSelectionView(
        mediaSelectionConfig: mediaSelectionConfig,
        onComplete: _onMediaSelectionComplete,
        onCaptureMedia: _captureMedia,
      );

  Future<String?> _captureMedia(String? mediaType) async =>
      await Navigator.push<String?>(
        context,
        MaterialPageRoute(
          builder: (context) => mc.CameraCaptureView(
            mediaType: mediaType?.mediaType ?? MediaType.both,
            onGalleryClick: () async {
              Navigator.pop(context);
              return null;
            },
          ),
        ),
      );

  Future<String?> _generateVideoThumbnail(String? videoPath) async {
    if (videoPath == null || videoPath.isEmpty) return null;

    try {
      final thumbnailFile = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: (await Directory.systemTemp.createTemp()).path,
        quality: 75,
      );

      return thumbnailFile.path;
    } catch (e) {
      debugPrint('Error generating thumbnail for $videoPath: $e');
      return null;
    }
  }

  String _getFileExtension(String filePath) => path.extension(filePath);
}
