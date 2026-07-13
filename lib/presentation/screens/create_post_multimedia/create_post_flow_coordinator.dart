import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/presentation/screens/create_post_multimedia/create_post_sound_flow.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/media_edit.dart'
    as me;
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/model/media_edit_audio_model.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_selection/media_selection.dart'
    as ms;
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Orchestrates the default create-post flow with a stacked navigation model.
///
/// Media Selector → Media Editor → Post Attribute stay on the stack until
/// post creation succeeds, then unwind with a result.
abstract final class CreatePostFlowCoordinator {
  CreatePostFlowCoordinator._();

  /// Default create-post entry: gallery/camera → edit → publish.
  ///
  /// Returns encoded post JSON on success, or `null` if the user cancels.
  static Future<dynamic> run(
    BuildContext context, {
    MediaEditSoundItem? initialSound,
    TransitionType? transitionType,
  }) =>
      IsrAppNavigator.pushCreatePostFlowRoute<dynamic>(
        context,
        page: IsrAppNavigator.wrapCreatePostFlowBlocs(
          child: _StackedCreatePostFlowHost(
            initialSound: initialSound,
            transitionType: transitionType,
          ),
        ),
        routeName: IsrRouteNames.createPostView,
        transitionType: transitionType,
      );

  /// Media selector Done — keep selector on stack, push editor on top.
  static Future<bool> onMediaSelectorComplete(
    BuildContext context, {
    required List<ms.MediaAssetData> selectedMedia,
    MediaEditSoundItem? initialSound,
    TransitionType? transitionType,
  }) async {
    if (selectedMedia.isEmpty) return false;

    final editItems = await prepareEditItemsFromSelection(
      context,
      selectedMedia: selectedMedia,
      initialSound: initialSound,
    );
    if (!context.mounted || editItems.isEmpty) return false;

    final editorResult = await _pushMediaEditorStacked(
      context,
      mediaItems: editItems,
      initialSound: initialSound,
      transitionType: transitionType,
    );
    if (!context.mounted) return false;

    if (editorResult.succeeded) {
      Navigator.of(context, rootNavigator: true).pop(editorResult.result);
      return false;
    }
    return false;
  }

  /// Media editor Done — keep editor on stack, push post attribute on top.
  static Future<bool> onMediaEditorComplete(
    BuildContext context, {
    required List<me.MediaEditItem> editedMedia,
    MediaEditSoundItem? initialSound,
    TransitionType? transitionType,
  }) async {
    if (editedMedia.isEmpty) return false;

    final selectedSound = _soundFromEditItems(editedMedia) ?? initialSound;
    final mediaDataList = mediaDataFromEditItems(editedMedia);

    final licenseAgreementAfterMediaEdit = await IsrVideoReelConfig.createEditPostConfig.createEditPostCallBackConfig?.licenseAgreementAfterMediaEdit?.call(mediaDataList, selectedSound);

    if (licenseAgreementAfterMediaEdit == false) {
      return false;
    }

    final postResult = await _pushPostAttributeStacked(
      context,
      mediaDataList: mediaDataList,
      selectedSound: selectedSound,
      transitionType: transitionType,
    );
    if (!context.mounted) return false;

    if (postResult.succeeded) {
      Navigator.of(context, rootNavigator: true).pop(postResult);
      return false;
    }
    return false;
  }

  static Future<CreatePostFlowResult> _pushMediaEditorStacked(
    BuildContext context, {
    required List<me.MediaEditItem> mediaItems,
    MediaEditSoundItem? initialSound,
    TransitionType? transitionType,
  }) async {
    final mediaEditConfig = GalleryVideoTrimUtil.defaultMediaEditConfig();
    final result =
        await IsrAppNavigator.pushCreatePostFlowRoute<CreatePostFlowResult>(
      context,
      page: Builder(
        builder: (editorContext) => me.MediaEditView(
          mediaDataList: mediaItems,
          mediaEditConfig: mediaEditConfig,
          onComplete: (edited) => onMediaEditorComplete(
            editorContext,
            editedMedia: edited,
            initialSound: initialSound,
            transitionType: transitionType,
          ),
          addMoreMedia: (editMedia) => addMoreMedia(
            context,
            editMedia: editMedia,
            selectedSound: initialSound,
          ),
          pickCoverPic: () => pickCoverPic(context),
          onSelectSound: CreatePostSoundFlow.isEnabled
              ? (_) => CreatePostSoundFlow.pickSound(context)
              : null,
        ),
      ),
      routeName: IsrRouteNames.mediaEditView,
      transitionType: transitionType,
    );
    return result ?? CreatePostFlowResult.cancelled;
  }

  static Future<CreatePostFlowResult> _pushPostAttributeStacked(
    BuildContext context, {
    required List<MediaData> mediaDataList,
    MediaEditSoundItem? selectedSound,
    TransitionType? transitionType,
  }) async {
    final result =
        await IsrAppNavigator.pushCreatePostFlowRoute<dynamic>(
      context,
      page: IsrAppNavigator.wrapCreatePostFlowBlocs(
        child: PostAttributeView(
          newMediaDataList: mediaDataList,
          selectedSound: selectedSound,
          isEditMode: false,
        ),
      ),
      routeName: IsrRouteNames.postAttributeView,
      transitionType: transitionType,
    );
    return result is TimeLineData? CreatePostFlowResult.success(result) : CreatePostFlowResult.cancelled;
  }

  /// Camera from selector — push editor on top without popping selector.
  static Future<dynamic> handleCaptureInStackedFlow(
    BuildContext context, {
    required String? mediaType,
    MediaEditSoundItem? initialSound,
    TransitionType? transitionType,
  }) async {
    final capture = await IsrAppNavigator.presentCameraCapture(
      context,
      mediaType: mediaType,
      initialSound: initialSound,
    );
    if (capture == null || capture.mediaPath.isEmpty) return null;

    final editItems = await prepareEditItemsFromCapture(
      context,
      capture: capture,
      initialSound: initialSound,
    );
    if (!context.mounted || editItems.isEmpty) return null;

    final editorResult = await _pushMediaEditorStacked(
      context,
      mediaItems: editItems,
      initialSound: initialSound,
      transitionType: transitionType,
    );
    if (!context.mounted) return null;

    if (editorResult.succeeded) {
      Navigator.of(context, rootNavigator: true).pop(editorResult.result);
    }
    return null;
  }

  /// Standalone selector capture — pops selector with captured assets.
  static Future<dynamic> handleCaptureFromSelector(
    BuildContext context, {
    required String? mediaType,
    MediaEditSoundItem? initialSound,
  }) async {
    final capture = await IsrAppNavigator.presentCameraCapture(
      context,
      mediaType: mediaType,
      initialSound: initialSound,
    );
    if (capture == null || capture.mediaPath.isEmpty) return null;

    final assets = await captureToMediaAssets(
      context,
      capture: capture,
      initialSound: initialSound,
    );
    if (!context.mounted) return null;

    Navigator.of(context, rootNavigator: true).pop<List<ms.MediaAssetData>>(assets);
    return null;
  }

  static ms.MediaSelectionConfig defaultMediaSelectionConfig({
    String? selectMediaTitle,
    String? doneButtonText,
    ms.MediaListType? mediaListType,
    bool? isMultiSelect,
    int? imageMediaLimit,
    int? videoMediaLimit,
    int? mediaLimit,
  }) =>
      ms.MediaSelectionConfig(
        isMultiSelect: isMultiSelect ?? true,
        imageMediaLimit: imageMediaLimit ?? AppConstants.imageMediaLimit,
        videoMediaLimit: videoMediaLimit ?? AppConstants.videoMediaLimit,
        mediaLimit: mediaLimit ?? AppConstants.totalMediaLimit,
        singleSelectModeIcon:
            const AppImage.svg(AssetConstants.icMediaSelectSingle),
        multiSelectModeIcon:
            const AppImage.svg(AssetConstants.icMediaSelectMultiple),
        doneButtonText: doneButtonText ?? IsrTranslationFile.next,
        selectMediaTitle: selectMediaTitle ?? IsrTranslationFile.newReel,
        primaryColor: IsrColors.appColor,
        primaryTextColor: IsrColors.primaryTextColor,
        backgroundColor: Colors.white,
        appBarColor: Colors.white,
        primaryFontFamily: AppConstants.primaryFontFamily,
        mediaListType: mediaListType ?? ms.MediaListType.imageVideo,
      );

  static Future<List<ms.MediaAssetData>> captureToMediaAssets(
    BuildContext context, {
    required CameraCaptureResult capture,
    MediaEditSoundItem? initialSound,
  }) async {
    final filePath = capture.mediaPath;
    final isVideo = filePath.isVideoFile;
    String? thumbnailPath;
    int? duration;

    if (isVideo) {
      thumbnailPath = await _generateVideoThumbnail(filePath);
      duration = await GalleryVideoTrimUtil.durationSeconds(filePath);
    }

    return [
      ms.MediaAssetData(
        localPath: filePath,
        file: File(filePath),
        mediaType: isVideo
            ? ms.SelectedMediaType.video
            : ms.SelectedMediaType.image,
        duration: duration,
        thumbnailPath: thumbnailPath ?? (isVideo ? null : filePath),
        isCaptured: true,
        sound: capture.sound ?? initialSound,
        soundAppliedToVideo: capture.soundAppliedToVideo,
      ),
    ];
  }

  static Future<List<me.MediaEditItem>> prepareEditItemsFromSelection(
    BuildContext context, {
    required List<ms.MediaAssetData> selectedMedia,
    MediaEditSoundItem? initialSound,
  }) async {
    for (final media in selectedMedia) {
      if (media.mediaType == ms.SelectedMediaType.video) {
        final videoPath = media.localPath;
        if (videoPath != null && videoPath.isNotEmpty) {
          final trimmedPath = await GalleryVideoTrimUtil.trimVideo(
            context,
            videoPath: videoPath,
          );
          if (!context.mounted) return [];
          if (trimmedPath == null) return [];
          media.localPath = trimmedPath;
          media.file = File(trimmedPath);
          final trimmedDuration =
              await GalleryVideoTrimUtil.durationSeconds(trimmedPath);
          if (trimmedDuration != null) {
            media.duration = trimmedDuration;
          }
        }
      }

      if (media.mediaType == ms.SelectedMediaType.video &&
          (media.thumbnailPath == null || media.thumbnailPath!.isEmpty)) {
        final thumbnailPath = await _generateVideoThumbnail(media.localPath);
        if (thumbnailPath != null) {
          media.thumbnailPath = thumbnailPath;
        }
      }
    }

    final mediaEditItems = <me.MediaEditItem>[];
    for (final media in selectedMedia) {
      if (media.mediaType == ms.SelectedMediaType.video &&
          media.sound?.soundUrl?.isNotEmpty == true &&
          !media.soundAppliedToVideo &&
          media.localPath?.isNotEmpty == true) {
        final muxed = await PostSoundUtil.muxVideoWithSound(
          videoPath: media.localPath!,
          sound: media.sound!,
        );
        if (!context.mounted) return [];
        media.localPath = muxed;
        media.file = File(muxed);
        media.soundAppliedToVideo = true;
      }
      mediaEditItems.add(
        mapSelectedToEditMedia(media, initialSound: initialSound),
      );
    }

    final preselectedSound = initialSound;
    if (preselectedSound != null &&
        preselectedSound.soundId?.isNotEmpty == true) {
      for (var i = 0; i < mediaEditItems.length; i++) {
        final item = mediaEditItems[i];
        if (item.mediaType == me.EditMediaType.video) {
          var editedPath = item.editedPath ?? item.originalPath;
          if (preselectedSound.soundUrl?.isNotEmpty == true) {
            editedPath = await PostSoundUtil.muxVideoWithSound(
              videoPath: editedPath,
              sound: preselectedSound,
            );
          }
          if (!context.mounted) return [];
          mediaEditItems[i] = item.copyWith(
            editedPath: editedPath,
            sound: item.sound ?? preselectedSound,
          );
        } else if (item.mediaType == me.EditMediaType.image &&
            item.sound?.soundId?.isNotEmpty != true) {
          mediaEditItems[i] = item.copyWith(sound: preselectedSound);
        }
      }
    }

    return mediaEditItems;
  }

  static me.MediaEditItem mapSelectedToEditMedia(
    ms.MediaAssetData media, {
    MediaEditSoundItem? initialSound,
  }) =>
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
        sound: media.sound ?? initialSound,
        metaData: media.toJson(),
      );

  static Future<List<me.MediaEditItem>?> addMoreMedia(
    BuildContext context, {
    required List<me.MediaEditItem> editMedia,
    MediaEditSoundItem? selectedSound,
  }) async {
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

    final res = await IsrAppNavigator.presentCreatePostMediaSelector(
      context,
      initialSound: selectedSound,
      config: defaultMediaSelectionConfig(
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
      transitionType: TransitionType.rightToLeft,
    );
    if (res == null || res.isEmpty) return null;

    final prepared = await prepareEditItemsFromSelection(
      context,
      selectedMedia: res,
      initialSound: selectedSound,
    );
    return prepared;
  }

  static Future<String?> pickCoverPic(BuildContext context) async {
    final res = await IsrAppNavigator.presentCreatePostMediaSelector(
      context,
      config: defaultMediaSelectionConfig(
        mediaListType: ms.MediaListType.image,
        isMultiSelect: false,
        selectMediaTitle: IsrTranslationFile.addCover,
      ),
      transitionType: TransitionType.rightToLeft,
    );
    return res?.firstOrNull?.localPath;
  }

  static List<MediaData> mediaDataFromEditItems(
    List<me.MediaEditItem> editedMedia,
  ) =>
      editedMedia
          .map(
            (editItem) => MediaData(
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
              fileExtension: path.extension(
                editItem.editedPath ?? editItem.originalPath,
              ),
            ),
          )
          .toList();

  static Future<List<me.MediaEditItem>> prepareEditItemsFromCapture(
    BuildContext context, {
    required CameraCaptureResult capture,
    MediaEditSoundItem? initialSound,
  }) async {
    final filePath = capture.mediaPath;
    if (filePath.isVideoFile) {
      final thumb = await _generateVideoThumbnail(filePath);
      final duration = await GalleryVideoTrimUtil.durationSeconds(filePath);
      return [
        await CreatePostSoundFlow.buildEditItemFromCapture(
          videoPath: filePath,
          durationSeconds: duration,
          thumbnailPath: thumb,
          sound: capture.sound ?? initialSound,
          soundAlreadyAppliedToVideo: capture.soundAppliedToVideo,
        ),
      ];
    }

    return [
      CreatePostSoundFlow.buildEditItemFromPhotoCapture(
        imagePath: filePath,
        sound: capture.sound ?? initialSound,
      ),
    ];
  }

  static MediaEditSoundItem? _soundFromEditItems(
    List<me.MediaEditItem> editedMedia,
  ) =>
      editedMedia
          .where((e) => e.sound?.soundId?.isNotEmpty == true)
          .map((e) => e.sound)
          .firstOrNull;

  static Future<String?> _generateVideoThumbnail(String? videoPath) async {
    if (videoPath == null || videoPath.isEmpty) return null;

    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final thumbDir = path.join(documentsDir.path, 'media', 'import_thumbs');
      return MediaUtil.pickBestVideoThumbnailPath(
        videoPath: videoPath,
        thumbnailPath: thumbDir,
        quality: 75,
      );
    } catch (e) {
      debugPrint('Error generating thumbnail for $videoPath: $e');
      return null;
    }
  }
}

/// Root screen for the stacked default create-post flow.
class _StackedCreatePostFlowHost extends StatelessWidget {
  const _StackedCreatePostFlowHost({
    this.initialSound,
    this.transitionType,
  });

  final MediaEditSoundItem? initialSound;
  final TransitionType? transitionType;

  @override
  Widget build(BuildContext context) => ms.MediaSelectionView(
        mediaSelectionConfig:
            CreatePostFlowCoordinator.defaultMediaSelectionConfig(),
        onComplete: (selectedMedia) => CreatePostFlowCoordinator.onMediaSelectorComplete(
          context,
          selectedMedia: selectedMedia,
          initialSound: initialSound,
          transitionType: transitionType,
        ),
        onCaptureMedia: (mediaType) =>
            CreatePostFlowCoordinator.handleCaptureInStackedFlow(
          context,
          mediaType: mediaType,
          initialSound: initialSound,
          transitionType: transitionType,
        ),
      );
}
