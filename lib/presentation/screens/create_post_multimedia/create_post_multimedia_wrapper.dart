import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_capture/camera.dart' as mc;
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/media_edit.dart' as me;
import 'package:ism_video_reel_player/presentation/screens/media/media_selection/media_selection.dart' as ms;
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:path/path.dart' as path;

class CreatePostMultimediaWrapper extends StatefulWidget {
  const CreatePostMultimediaWrapper({super.key, this.onTagProduct});
  final Future<List<ProductDataModel>?> Function(List<ProductDataModel>)? onTagProduct;
  @override
  State<CreatePostMultimediaWrapper> createState() =>
      _CreatePostMultimediaWrapperState();
}

class _CreatePostMultimediaWrapperState
    extends State<CreatePostMultimediaWrapper> {
  CreatePostBloc get _createPostBloc =>
      BlocProvider.of<CreatePostBloc>(context);
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
    selectMediaTitle: IsrTranslationFile.newPost,
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
    // Convert to MediaEditItem and navigate to edit view
    final mediaEditItems = selectedMedia
        .map(mapSelectedToEditMedia)
        .toList();

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

    final res = await Navigator.push<List<ms.MediaAssetData>>(
      context,
      MaterialPageRoute(
        builder: (context) => ms.MediaSelectionView(
          mediaSelectionConfig: mediaSelectionConfig.copyWith(
            mediaListType: ms.MediaListType.imageVideo,
            isMultiSelect: true,
            selectMediaTitle: IsrTranslationFile.addCover,
            imageMediaLimit: AppConstants.imageMediaLimit - presentImageCount,
            videoMediaLimit: AppConstants.videoMediaLimit - presentVideoCount,
            mediaLimit: AppConstants.totalMediaLimit - (presentImageCount + presentVideoCount),
          ),
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
              mediaListType: ms.MediaListType.image, isMultiSelect: false, selectMediaTitle: IsrTranslationFile.addCover),
        ),
      ),
    );
    return res?.first.localPath;
  }

  /// Merges all media items into a single video
  // Future<me.MediaEditItem?> _mergeAllMediaIntoOne(List<me.MediaEditItem> mediaItems) async {
  //   if (mediaItems.length <= 1 && mediaItems.firstOrNull?.mediaType == me.EditMediaType.video) {
  //     // No need to merge if there's only one or no items
  //     return mediaItems.firstOrNull;
  //   }
  //
  //   try {
  //     // Show progress dialog
  //     _showMergingProgressDialog();
  //
  //     // Process and merge all media
  //     final mergedVideoPath = await MediaMerger.processAndMergeMedia(
  //       mediaItems: mediaItems,
  //       onProgress: (progress) {
  //         // Update progress in the dialog
  //         _updateMergingProgress(progress);
  //       },
  //     );
  //
  //     // Hide progress dialog
  //     _hideMergingProgressDialog();
  //
  //     if (mergedVideoPath != null) {
  //       // Replace all media items with the single merged video
  //       final mergedMediaItem = me.MediaEditItem(
  //         originalPath: mergedVideoPath,
  //         editedPath: mergedVideoPath,
  //         mediaType: me.EditMediaType.video,
  //         width: mediaItems.first.width,
  //         height: mediaItems.first.height,
  //         duration: mediaItems.length * 5, // 5 seconds per media item
  //         thumbnailPath: mediaItems.first.thumbnailPath,
  //       );
  //
  //       debugPrint('Successfully merged ${mediaItems.length} media items into one video: $mergedVideoPath');
  //       return mergedMediaItem;
  //     } else {
  //       // Show error message
  //       _showMergingErrorDialog();
  //       debugPrint('Failed to merge media items');
  //     }
  //   } catch (e) {
  //     _hideMergingProgressDialog();
  //     _showMergingErrorDialog();
  //     debugPrint('Error merging media items: $e');
  //   }
  //   return null;
  // }

  bool _isMergingDialogOpen = false;

  void _showMergingProgressDialog() {
    if (!_isMergingDialogOpen) {
      _isMergingDialogOpen = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Merging media...',
                style: IsrStyles.primaryText16,
              ),
              const SizedBox(height: 8),
              Text(
                'Converting images to videos and merging all media',
                style: IsrStyles.primaryText14.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }

  void _updateMergingProgress(double progress) {
    // You can implement progress updates here if needed
    debugPrint('Merging progress: ${(progress * 100).toInt()}%');
  }

  void _hideMergingProgressDialog() {
    if (_isMergingDialogOpen) {
      _isMergingDialogOpen = false;
      Navigator.of(context).pop();
    }
  }

  void _showMergingErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: const Text('Failed to merge media items. Please try again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
      _createPostBloc
          .add(PostAttributeNavigationEvent(newMediaDataList: _mediaDataList, context: context, onTagProduct: widget.onTagProduct));
      return false;
    }
    return false;
  }

  bool _isDialogOpen = false;
  UploadProgressCubit get _progressCubit => BlocProvider.of<UploadProgressCubit>(context);

  @override
  Widget build(BuildContext context) =>
      BlocListener<CreatePostBloc, CreatePostState>(
        listenWhen: (previousState, currentState) =>
            currentState is PostCreatedState ||
            currentState is ShowProgressDialogState,
        listener: (context, state) {
          if (state is PostCreatedState) {
            Utility.showBottomSheet(
              child: _buildSuccessBottomSheet(
                onTapBack: () {
                  Navigator.pop(context, state.postDataModel);
                  Navigator.pop(context, state.postDataModel);
                  Navigator.pop(context, state.postDataModel);
                },
                title: state.postSuccessTitle ?? '',
                message: state.postSuccessMessage ?? '',
              ),
              isDismissible: false,
            );
            _doMediaCaching(state.mediaDataList);
            Future.delayed(const Duration(seconds: 2), () async {
              Navigator.pop(context);
              Navigator.pop(context, state.postDataModel);
              Navigator.pop(context, state.postDataModel);
              Navigator.pop(context, state.postDataModel);
            });
          }
          if (state is ShowProgressDialogState) {
            if (!_isDialogOpen) {
              _isDialogOpen = true;
              _showProgressDialog(state.title ?? '', state.subTitle ?? '');
            } else {
              if (state.isAllFilesUploaded) {
                // Show success animation
                // _progressCubit.showSuccess();
                // Dismiss after 3 seconds
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (_isDialogOpen) {
                    _isDialogOpen = false;
                    Navigator.pop(context);
                  }
                });
              }
            }
            // Update all cubit state values
            _progressCubit.updateProgress(state.progress ?? 0);
            _progressCubit.updateTitle(
                state.title ?? IsrTranslationFile.uploadingMediaFiles);
            _progressCubit.updateSubtitle(state.subTitle ?? '');
          }
        },
        child: ms.MediaSelectionView(
          mediaSelectionConfig: mediaSelectionConfig,
          onComplete: _onMediaSelectionComplete,
          onCaptureMedia: _captureMedia,
        ),
      );

  Future<String?> _captureMedia() async => await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (context) => mc.CameraCaptureView(
          onPickMedia: () async {
            Navigator.pop(context);
            return null;
          },
        ),
      ),
    );

  Widget _buildSuccessBottomSheet({
    required Function() onTapBack,
    required String title,
    required String message,
  }) =>
      Container(
        width:IsrDimens.getScreenWidth(context),
        padding:IsrDimens.edgeInsetsAll(IsrDimens.sixteen),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: TapHandler(
                onTap: () {
                  Navigator.pop(context);
                  onTapBack();
                },
                child: const AppImage.svg(
                  AssetConstants.icCrossIcon,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Lottie.asset(
                  AssetConstants.postUploadedAnimation,
                  animate: true,
                  height:IsrDimens.seventy,
                  width:IsrDimens.seventy,
                  repeat: false,
                ),
                24.verticalSpace,
                Text(
                  message,
                  style: IsrStyles.primaryText16.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize:IsrDimens.eighteen,
                  ),
                  textAlign: TextAlign.center,
                ),
                8.verticalSpace,
                Text(
                  IsrTranslationFile.yourPostHasBeenSuccessfullyPosted,
                  style: IsrStyles.primaryText14.copyWith(
                    color: Colors.grey,
                    fontSize:IsrDimens.fifteen,
                  ),
                  textAlign: TextAlign.center,
                ),
                16.verticalSpace,
              ],
            ),
          ],
        ),
      );

  void _doMediaCaching(List<MediaData>? mediaDataList) async {
    if (mediaDataList.isEmptyOrNull) return;
    final urls = <String>[];
    for (var media in mediaDataList!) {
      if (media.url.isEmptyOrNull == false) {
        urls.add(media.url!);
      }
      if (media.previewUrl.isEmptyOrNull == false) {
        urls.add(media.previewUrl!);
      }
    }
    if (!mounted) return;

    // Use compute for background processing if needed
    await compute((List<String> urls) => urls, urls).then((processedUrls) {
      if (!mounted) return;
      Utility.preCacheImages(urls, context);
    });
  }

  void _showProgressDialog(String title, String message) async {
    await Utility.showBottomSheet(
        child: BlocProvider(
          create: (context) => _progressCubit,
          child: UploadProgressBottomSheet(message: message),
        ),
        isDismissible: false);
    _isDialogOpen = false;
  }

  String _getFileExtension(String filePath) => path.extension(filePath);
}
