import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/presentation/screens/create_post_multimedia/create_post_sound_flow.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_capture/camera.dart'
    as mc;
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/media_edit.dart'
    as me;
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/model/media_edit_audio_model.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_selection/media_selection.dart'
    as ms;
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class CreatePostMultimediaWrapper extends StatefulWidget {
  const CreatePostMultimediaWrapper({super.key, this.initialSound});

  /// Sound preselected when entering this flow (e.g. via the post sound pill).
  final MediaEditSoundItem? initialSound;

  @override
  State<CreatePostMultimediaWrapper> createState() =>
      _CreatePostMultimediaWrapperState();
}

class _CreatePostMultimediaWrapperState
    extends State<CreatePostMultimediaWrapper> {
  @override
  void initState() {
    super.initState();
    _selectedPostSound = widget.initialSound;
  }

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

  late final mediaEditConfig = GalleryVideoTrimUtil.defaultMediaEditConfig();

  MediaEditSoundItem? _selectedPostSound;

  Future<bool> _onMediaSelectionComplete(
      List<ms.MediaAssetData> selectedMedia) async {
    for (final media in selectedMedia) {
      if (media.mediaType == ms.SelectedMediaType.video) {
        final path = media.localPath;
        if (path != null && path.isNotEmpty) {
          final trimmedPath = await GalleryVideoTrimUtil.trimVideo(
            context,
            videoPath: path,
          );
          if (!mounted) return false;
          if (trimmedPath == null) return false;
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
        if (!mounted) return false;
        media.localPath = muxed;
        media.file = File(muxed);
        media.soundAppliedToVideo = true;
      }
      mediaEditItems.add(mapSelectedToEditMedia(media));
    }

    // If a sound was preselected (e.g. "Use this sound" from a post), mux it
    // onto every gallery video so the final upload carries the audio AND the
    // create-post request includes `sound_id` / `sound_snapshot`.
    final librarySound =
        PostSoundUtil.isLibrarySoundId(_selectedPostSound?.soundId)
            ? _selectedPostSound
            : null;
    if (librarySound != null) {
      for (var i = 0; i < mediaEditItems.length; i++) {
        final item = mediaEditItems[i];
        if (item.mediaType == me.EditMediaType.video) {
          var path = item.editedPath ?? item.originalPath;
          if (librarySound.soundUrl?.isNotEmpty == true) {
            path = await PostSoundUtil.muxVideoWithSound(
              videoPath: path,
              sound: librarySound,
            );
          }
          if (!mounted) return false;
          mediaEditItems[i] = item.copyWith(
            editedPath: path,
            sound: item.sound ?? librarySound,
          );
        } else if (item.mediaType == me.EditMediaType.image &&
            item.sound?.soundId?.isNotEmpty != true) {
          mediaEditItems[i] = item.copyWith(sound: librarySound);
        }
      }
    }

    if (mediaEditItems.isNotEmpty) {
      await _pushMediaEditPreview(mediaEditItems);
    }

    return false;
  }

  Future<void> _pushMediaEditPreview(
      List<me.MediaEditItem> mediaEditItems) async {
    if (!mounted) return;
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    await Navigator.of(context, rootNavigator: true)
        .push<List<me.MediaEditItem>>(
      MaterialPageRoute(
        builder: (context) => me.MediaEditView(
          mediaDataList: mediaEditItems,
          onComplete: _onMediaEditComplete,
          addMoreMedia: _onAddMoreMedia,
          mediaEditConfig: mediaEditConfig,
          pickCoverPic: _pickCoverPic,
          onSelectSound: CreatePostSoundFlow.isEnabled
              ? (current) => _onSelectSoundInMediaEdit(context, current)
              : null,
        ),
      ),
    );
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
        sound: media.sound ?? _selectedPostSound,
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

  List<MediaData> _mediaDataFromEditItems(List<me.MediaEditItem> editedMedia) =>
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
              fileExtension: _getFileExtension(
                editItem.editedPath ?? editItem.originalPath,
              ),
            ),
          )
          .toList();

  Future<MediaEditSoundItem?> _onSelectSoundInMediaEdit(
    BuildContext context,
    MediaEditSoundItem? current,
  ) async =>
      CreatePostSoundFlow.pickSound(context);

  Future<bool> _onMediaEditComplete(List<me.MediaEditItem> editedMedia) async {
    if (editedMedia.isEmpty) {
      return false;
    }
    final soundFromEdits = editedMedia
        .map((e) => e.sound)
        .where((s) => PostSoundUtil.isLibrarySoundId(s?.soundId))
        .map((s) => s!)
        .firstOrNull;
    // Keep the preselected sound (e.g. from "Use this sound") if the user
    // didn't change it inside the media editor.
    _selectedPostSound =
        soundFromEdits ?? _selectedPostSound ?? widget.initialSound;
    final mediaDataList = _mediaDataFromEditItems(editedMedia);
    await IsrAppNavigator.goToCreatePostAttributionView(
      context,
      newMediaDataList: mediaDataList,
      selectedSound: _selectedPostSound,
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return ms.MediaSelectionView(
      mediaSelectionConfig: mediaSelectionConfig,
      onComplete: _onMediaSelectionComplete,
      onCaptureMedia: _captureMedia,
    );
  }

  Future<CameraCaptureResult?> _captureMedia(String? mediaType) async {
    final result = await Navigator.of(context, rootNavigator: true)
        .push<CameraCaptureResult>(
      MaterialPageRoute(
        builder: (context) => mc.CameraCaptureView(
          mediaType: mediaType?.mediaType ?? MediaType.both,
          initialCameraMusic: _initialCameraMusicEvent(),
          onAddSoundTap: IsrVideoReelConfig.createEditPostConfig
              .createEditPostCallBackConfig?.onAddSoundFromCamera,
        ),
      ),
    );
    if (result == null || result.mediaPath.isEmpty) return null;

    if (result.mediaPath.isVideoFile) {
      final thumb = await _generateVideoThumbnail(result.mediaPath);
      final duration =
          await GalleryVideoTrimUtil.durationSeconds(result.mediaPath);
      final editItem = await CreatePostSoundFlow.buildEditItemFromCapture(
        videoPath: result.mediaPath,
        durationSeconds: duration,
        thumbnailPath: thumb,
        sound: result.sound,
        soundAlreadyAppliedToVideo: result.soundAppliedToVideo,
      );
      if (!mounted) return null;
      _selectedPostSound = editItem.sound ?? result.sound;
      await Navigator.of(context, rootNavigator: true)
          .push<List<me.MediaEditItem>>(
        MaterialPageRoute(
          builder: (context) => me.MediaEditView(
            mediaDataList: [editItem],
            onComplete: _onMediaEditComplete,
            addMoreMedia: (_) async => null,
            mediaEditConfig: mediaEditConfig,
            pickCoverPic: _pickCoverPic,
            onSelectSound: CreatePostSoundFlow.isEnabled
                ? (current) => _onSelectSoundInMediaEdit(context, current)
                : null,
          ),
        ),
      );
      return null;
    }

    final photoSound = result.sound;
    final editItem = CreatePostSoundFlow.buildEditItemFromPhotoCapture(
      imagePath: result.mediaPath,
      sound: photoSound,
    );
    if (!mounted) return null;
    _selectedPostSound = editItem.sound ?? photoSound;
    await Navigator.of(context, rootNavigator: true)
        .push<List<me.MediaEditItem>>(
      MaterialPageRoute(
        builder: (context) => me.MediaEditView(
          mediaDataList: [editItem],
          onComplete: _onMediaEditComplete,
          addMoreMedia: (_) async => null,
          mediaEditConfig: mediaEditConfig,
          pickCoverPic: _pickCoverPic,
          onSelectSound: CreatePostSoundFlow.isEnabled
              ? (current) => _onSelectSoundInMediaEdit(context, current)
              : null,
        ),
      ),
    );
    return null;
  }

  Future<String?> _generateVideoThumbnail(String? videoPath) async {
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

  String _getFileExtension(String filePath) => path.extension(filePath);

  CameraSetMusicEvent? _initialCameraMusicEvent() {
    final sound = _selectedPostSound;
    if (sound == null || sound.soundId == null || sound.soundId!.isEmpty) {
      return null;
    }
    final durationSeconds = int.tryParse(sound.soundDuration ?? '');
    return CameraSetMusicEvent(
      musicId: sound.soundId!,
      musicName: sound.soundMetadata?['title'] as String?,
      musicArtist: sound.soundArtist,
      musicThumbnailUrl: sound.soundImage,
      musicDurationSeconds: durationSeconds,
      musicPreviewUrl: sound.soundUrl ?? '',
    );
  }
}
