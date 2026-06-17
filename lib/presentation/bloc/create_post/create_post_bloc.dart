import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ism_video_reel_player/core/api_result.dart';
import 'package:ism_video_reel_player/core/errors/app_error.dart';
import 'package:ism_video_reel_player/core/errors/error_handler.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/model/media_edit_audio_model.dart';
import 'package:ism_video_reel_player/utils/post_sound_util.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

part 'create_post_event.dart';
part 'create_post_state.dart';

class MediaUploadProgress {
  MediaUploadProgress({
    required this.currentFileIndex,
    required this.totalFiles,
    required this.currentFileName,
    required this.progress,
    required this.mediaType,
    required this.fileSize,
  });

  final int currentFileIndex;
  final int totalFiles;
  final String currentFileName;
  final double progress;
  final MediaType? mediaType;
  final int fileSize;

  String get progressText => '$currentFileIndex of $totalFiles';

  String get mediaTypeText => mediaType == MediaType.photo ? 'Image' : 'Video';

  String get fileSizeText =>
      '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
}

class CreatePostBloc extends Bloc<CreatePostEvent, CreatePostState> {
  CreatePostBloc(
    this._createPostUseCase,
    // this._getAlgoliaSearchSuggestionUseCase,
    this._getPostDetailsUseCase,
    this._localDataUseCase,
    this.googleCloudStorageUploaderUseCase,
    this.mediaProcessingUseCase,
  ) : super(CreatePostInitialState()) {
    on<CreatePostInitialEvent>(_initState);
    on<PostCreateEvent>(_createPost);
    // on<PostAttributeNavigationEvent>(_goToPostAttributeView);
    on<ChangeCoverImageEvent>(_changeCoverImage);
    on<MediaSourceEvent>(_openMediaSource);
    on<GetProductsEvent>(_getProducts);
    on<GetSocialPostDetailsEvent>(_getPostDetails);
    on<EditPostEvent>(_editPost);
    on<MediaUploadEvent>(_uploadMedia);
    on<MediaProcessingEvent>(_processMedia);
    on<RemoveMediaEvent>(_removeSelectedMedia);
  }

  final CreatePostUseCase _createPostUseCase;
  // final GetAlgoliaSearchSuggestionUseCase _getAlgoliaSearchSuggestionUseCase;
  final GetSocialProductsUseCase _getPostDetailsUseCase;
  final IsmLocalDataUseCase _localDataUseCase;
  final GoogleCloudStorageUploaderUseCase googleCloudStorageUploaderUseCase;
  final MediaProcessingUseCase mediaProcessingUseCase;

  var _createPostRequest = CreatePostRequest();
  var descriptionText = '';
  List<ProductDataModel> linkedProducts = [];
  final List<ProductDataModel> _linkedSocialProducts = [];

  var _isDataLoading = false;
  final DeBouncer _deBouncer = DeBouncer();
  var _isCompressionRunning = false;

  CloudDetailsData? cloudDetailsData;
  TimeLineData? _postData;

  PostAttributeClass _postAttributeClass = PostAttributeClass();
  MediaEditSoundItem? _selectedPostSound;
  String? _pendingCreatePostSoundId;
  Map<String, dynamic>? _pendingCreatePostSoundSnapshot;
  final List<MediaData> _mediaDataList = [];
  var _selectedMediaIndex = 0;
  var _tags = Tags();
  var _isForEdit = false;

  var mentionedUserData = <MentionData>[];
  var mediaMentionUserData = <MentionData>[];
  var hashTagDataList = <MentionData>[];
  var locationTagDataList = <TaggedPlace>[];
  var _coverImage = '';
  var _coverImageExtension = '';
  var _coverFileName = '';

  PostCreateEvent? _lastPostCreateEventForRetry;

  bool get _usesBackgroundPostUi =>
      IsrVideoReelConfig.createEditPostConfig.createEditPostCallBackConfig
          ?.onBackgroundPostOperation !=
      null;

  void _retryBackgroundPost() {
    final ev = _lastPostCreateEventForRetry;
    if (ev != null) add(ev);
  }

  void _emitOrBackgroundUploadProgress(
      Emitter<CreatePostState> emit, ShowProgressDialogState state) {
    if (_usesBackgroundPostUi) {
      _notifyBackgroundUploadProgress(state);
    } else {
      emit(state);
    }
  }

  void _notifyBackgroundUploadProgress(ShowProgressDialogState s) {
    final cb = IsrVideoReelConfig.createEditPostConfig
        .createEditPostCallBackConfig?.onBackgroundPostOperation;
    if (cb == null) return;
    cb(BackgroundPostOperationUpdate(
      phase: s.isErrorUploading
          ? BackgroundPostOperationPhase.failure
          : BackgroundPostOperationPhase.uploading,
      overallProgressPercent: (s.progress ?? 0).clamp(0, 100),
      title: s.title,
      subtitle: s.subTitle,
      currentFileIndex: s.currentFileIndex,
      totalFiles: s.totalFiles,
      currentFileName: s.currentFileName,
      isUploadError: s.isErrorUploading,
      isAllFilesUploaded: s.isAllFilesUploaded,
      failureKind: s.isErrorUploading ? BackgroundPostFailureKind.upload : null,
      failureMessage: s.isErrorUploading ? (s.subTitle ?? s.title) : null,
      isEditMode: _isForEdit,
      retry: s.isErrorUploading ? _retryBackgroundPost : null,
    ));
  }

  void _notifyBackgroundCreatingPost() {
    final cb = IsrVideoReelConfig.createEditPostConfig
        .createEditPostCallBackConfig?.onBackgroundPostOperation;
    if (cb == null) return;
    cb(BackgroundPostOperationUpdate(
      phase: BackgroundPostOperationPhase.creatingPost,
      overallProgressPercent: 100,
      title: _isForEdit
          ? IsrTranslationFile.savingPost
          : IsrTranslationFile.posting,
      isEditMode: _isForEdit,
      retry: _retryBackgroundPost,
    ));
  }

  void _notifyBackgroundProcessingMedia() {
    final cb = IsrVideoReelConfig.createEditPostConfig
        .createEditPostCallBackConfig?.onBackgroundPostOperation;
    if (cb == null) return;
    cb(BackgroundPostOperationUpdate(
      phase: BackgroundPostOperationPhase.processingMedia,
      overallProgressPercent: 0,
      title: IsrTranslationFile.postingPost,
      isEditMode: _isForEdit,
      retry: _retryBackgroundPost,
    ));
  }

  void _notifyBackgroundApiFailure(AppError? error, {required bool isEdit}) {
    final cb = IsrVideoReelConfig.createEditPostConfig
        .createEditPostCallBackConfig?.onBackgroundPostOperation;
    if (cb == null) return;
    cb(BackgroundPostOperationUpdate(
      phase: BackgroundPostOperationPhase.failure,
      failureKind: BackgroundPostFailureKind.createOrEditApi,
      failureMessage: error?.message ?? 'Unknown error',
      httpStatusCode: error?.statusCode,
      isEditMode: isEdit,
      retry: _retryBackgroundPost,
    ));
  }

  void _notifyBackgroundMediaProcessingFailure(AppError? error) {
    final cb = IsrVideoReelConfig.createEditPostConfig
        .createEditPostCallBackConfig?.onBackgroundPostOperation;
    if (cb == null) return;
    cb(BackgroundPostOperationUpdate(
      phase: BackgroundPostOperationPhase.failure,
      failureKind: BackgroundPostFailureKind.mediaProcessing,
      failureMessage: error?.message ?? 'Unknown error',
      httpStatusCode: error?.statusCode,
      isEditMode: _isForEdit,
      retry: _retryBackgroundPost,
    ));
  }

  void _afterEmitPostCreated(PostCreatedState state, {String? resolvedPostId}) {
    if (!_usesBackgroundPostUi) return;
    final postId = state.postDataModel?.id ?? resolvedPostId;
    if (_isForEdit) {
      IsrVideoReelConfig.socialActionCubit
          .onPostEdited(postId: postId, postData: state.postDataModel);
    } else {
      IsrVideoReelConfig.socialActionCubit.onPostCreated(postId: postId);
    }
    IsrVideoReelConfig.createEditPostConfig.createEditPostCallBackConfig
        ?.onBackgroundPostOperation
        ?.call(
      BackgroundPostOperationUpdate(
        phase: BackgroundPostOperationPhase.success,
        overallProgressPercent: 100,
        postId: postId,
        postData: state.postDataModel ?? _postData,
        successTitle: state.postSuccessTitle,
        successMessage: state.postSuccessMessage,
        mediaDataList: state.mediaDataList,
        isEditMode: _isForEdit,
      ),
    );
  }

  FutureOr<void> _initState(
      CreatePostInitialEvent event, Emitter<CreatePostState> emit) async {
    _resetData();
    _selectedPostSound = event.selectedSound;
    if (event.selectedSound != null) {
      _postAttributeClass.selectedSound = event.selectedSound;
    }
    _cacheSoundForCreateApi(
      sound: event.selectedSound,
      request: _createPostRequest,
    );
    final postAttribution =
        await preparePostAttribution(newMediaDataList: event.newMediaDataList);
    emit(PostAttributionUpdatedState(postAttributeClass: postAttribution));
  }

  void resetApiCall() {
    // _listOfProducts.clear();
    _isDataLoading = false;
  }

  // Reset all variables after successful post creation
  void _resetData() {
    // Dismiss keyboard
    _postAttributeClass = PostAttributeClass();
    FocusManager.instance.primaryFocus?.unfocus();
    _cancelCompression();
    _createPostRequest = CreatePostRequest();
    _postData = null;
    mentionedUserData.clear();
    mediaMentionUserData.clear();
    hashTagDataList.clear();
    locationTagDataList.clear();
    _mediaDataList.clear();
    _selectedMediaIndex = 0;
    _isForEdit = false;
    descriptionText = '';
    linkedProducts.clear();
    _linkedSocialProducts.clear();
    _coverImage = '';
    _coverImageExtension = '';
    _coverFileName = '';
    _tags = _createPostRequest.tags ?? Tags();
    _tags.products = [];
    _selectedPostSound = null;
    _pendingCreatePostSoundId = null;
    _pendingCreatePostSoundSnapshot = null;
    resetApiCall();
  }

  String _applyConvertToGumletUrl(String mediaUrl) {
    if (mediaUrl.isEmpty) return mediaUrl;
    final convert = IsrVideoReelConfig
        .socialConfig.socialCallBackConfig?.convertToGumletUrl;
    if (convert == null) return mediaUrl;
    try {
      final converted = convert(mediaUrl);
      if (converted.isNotEmpty) return converted;
    } catch (e) {
      debugPrint('convertToGumletUrl error: $e');
    }
    return mediaUrl;
  }

  Future<String> _uploadMediaToGoogleCloud(
    File? file,
    String fileName,
    MediaType? mediaType,
    Function(double) progressCallBackFunction,
    String folderName,
    String fileExtension,
  ) async {
    final customUpload = IsrVideoReelConfig
        .socialConfig.socialCallBackConfig?.uploadMediaToCloud;
    String result;

    if (customUpload != null) {
      try {
        result = await customUpload(
          file,
          fileName,
          mediaType,
          progressCallBackFunction,
          folderName,
          fileExtension,
        );
        debugPrint('_uploadMediaToGoogleCloud (custom): $result');
      } catch (e) {
        debugPrint('_uploadMediaToGoogleCloud custom error: $e');
        result = '';
      }
    } else {
      final myUserId = await _localDataUseCase.getUserId();
      var mainProgress = 0;
      try {
        final response = await googleCloudStorageUploaderUseCase
            .executeGoogleCloudStorageUploader(
                file: file!,
                fileName: fileName,
                fileExtension: fileExtension,
                userId: myUserId,
                onProgress: (_) {
                  final progress = (_ * 100).toInt();
                  if (mainProgress != progress) {
                    mainProgress = progress;
                    debugPrint(
                        '_uploadMediaToGoogleCloud......progress: $progress');
                    progressCallBackFunction.call(progress.toDouble());
                  }
                });
        debugPrint('_uploadMediaToGoogleCloud: $response');
        result = response ?? '';
      } catch (e) {
        debugPrint('_uploadMediaToGoogleCloud error: $e');
        result = '';
      }
    }

    return _applyConvertToGumletUrl(result);
  }

  String _getFileName(String? file, String fileType) {
    final fileName = '${fileType}_media';
    return fileName;
  }

  String _getFileExtension(String filePath) => path.extension(filePath);

  FutureOr<void> _openMediaSource(
      MediaSourceEvent event, Emitter<CreatePostState> emit) async {
    var mediaInfoClass = <MediaInfoClass>[];
    if (event.mediaSource == MediaSource.camera) {
      final mediaInfo = await _pickFromFromCamera(
          event.context, event.mediaType, event.mediaSource);
      if (mediaInfo != null) {
        mediaInfoClass.add(mediaInfo);
      }
    }

    if (event.mediaSource == MediaSource.gallery && event.context.mounted) {
      if (AppConstants.isMultipleMediaSelectionEnabled &&
          event.mediaData == null) {
        final mediaList = await _pickMultipleMedia(
            event.context, event.mediaSource, event.mediaType);
        mediaInfoClass = mediaList;
      } else {
        final mediaInfo = await _pickFromGallery(
            event.context, event.mediaType, event.mediaSource);
        if (mediaInfo != null) {
          mediaInfoClass.add(mediaInfo);
        }
      }
    }

    if (mediaInfoClass.isListEmptyOrNull == false) {
      for (var i = 0; i < mediaInfoClass.length; i++) {
        final mediaData = await _processMediaInfo(
            event.context,
            mediaInfoClass[i],
            emit,
            event.isCoverImage,
            i,
            event.mediaData) as MediaData;

        final index = _mediaDataList.indexWhere(
            (element) => event.mediaData?.localPath == element.localPath);
        if (index == -1) {
          _mediaDataList.add(mediaData);
        } else {
          _mediaDataList[index] = mediaData;
        }
      }

      // Emit initial state before compression
      emit(
        event.isCoverImage
            ? CoverImageSelected(
                coverImage: _mediaDataList[_selectedMediaIndex].previewUrl,
                isPostButtonEnable: _isPostButtonEnabled(_mediaDataList),
              )
            : MediaSelectedState(
                mediaDataList: _mediaDataList,
                isPostButtonEnable: _isPostButtonEnabled(_mediaDataList),
              ),
      );

      // 🔥 Compress media files one by one
      if (AppConstants.isCompressionEnable) {
        // Store the length to avoid concurrent modification during compression
        final mediaListLength = _mediaDataList.length;
        for (var i = 0; i < mediaListLength; i++) {
          final mediaData = _mediaDataList[i];
          // Skip if already compressed
          if (!mediaData.isCompressed &&
              mediaData.localPath.isEmptyOrNull == false) {
            final compressedFile = await _compressFile(
              File(mediaData.localPath ?? ''),
              event.mediaType,
              emit,
            );

            if (compressedFile != null) {
              final persisted = await _ensurePersistentUploadFile(
                compressedFile,
                fileNamePrefix: mediaData.mediaType?.mediaType ==
                        MediaType.video
                    ? 'upload_video'
                    : 'upload_image',
              );
              _mediaDataList[i].localPath =
                  persisted?.path ?? compressedFile.path;
              _mediaDataList[i].isCompressed = true;
            }
          }
        }
        // Emit state after each compression so UI updates progressively
        emit(
          event.isCoverImage
              ? CoverImageSelected(
                  coverImage: _mediaDataList[_selectedMediaIndex].previewUrl,
                  isPostButtonEnable: _isPostButtonEnabled(_mediaDataList),
                )
              : MediaSelectedState(
                  mediaDataList: _mediaDataList,
                  isPostButtonEnable: _isPostButtonEnabled(_mediaDataList),
                ),
        );
      }

      // Create a copy to avoid concurrent modification during map operation
      final mediaListCopy = List<MediaData>.from(_mediaDataList);
      debugPrint(
          'postAttribute list: ${jsonEncode(mediaListCopy.map((e) => e.toMap()).toList())}');
    }
  }

  bool _isPostButtonEnabled(List<MediaData>? mediaList) {
    var isPostButtonEnable = false;
    if (mediaList.isListEmptyOrNull) return false;

    // Check if at least one media has valid localPath & previewUrl
    for (final media in mediaList!) {
      if (media.localPath.isEmptyOrNull == false &&
          media.previewUrl.isEmptyOrNull == false) {
        isPostButtonEnable = true;
        break;
      }
    }
    return isPostButtonEnable;
  }

  Future<List<MediaInfoClass>> _pickMultipleMedia(
    BuildContext context,
    MediaSource mediaSource,
    MediaType mediaType,
  ) async {
    final pickedMedia = <MediaInfoClass>[];

    try {
      var result = <XFile>[];
      if (mediaType == MediaType.photo) {
        result = await ImagePicker().pickMultiImage(limit: 4);
      } else if (mediaType == MediaType.video) {
        result = await ImagePicker().pickMultiVideo(limit: 2);
      }

      if (result.isNotEmpty) {
        for (final file in result) {
          var path = file.path;

          final isVideo = path.isVideoFile;
          var duration = 0;

          var isMinResolution = true;
          if (isVideo) {
            isMinResolution = await path.hasMinResolution();
          }
          if (isMinResolution) {
            if (isVideo) {
              if (context.mounted) {
                final trimmed = await GalleryVideoTrimUtil.trimVideo(
                  context,
                  videoPath: path,
                );
                if (!context.mounted) continue;
                if (trimmed == null) continue;
                path = trimmed;
              }
              final mediaInfo = await VideoCompress.getMediaInfo(path);
              duration = (mediaInfo.duration ?? 0).toInt();
            }

            pickedMedia.add(
              MediaInfoClass(
                duration: (duration / 1000).toInt(),
                mediaType: isVideo ? MediaType.video : MediaType.photo,
                mediaSource: mediaSource,
                mediaFile: XFile(path),
              ),
            );
          } else {
            ErrorHandler.showAppError(
              appError: null,
              isNeedToShowError: true,
              message: IsrTranslationFile.pleaseSelectMinimumResolution,
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        Utility.showInSnackBar('Error picking media', context);
      }
    }
    return pickedMedia;
  }

  Future<MediaInfoClass?> _pickFromFromCamera(
    BuildContext context,
    MediaType mediaType,
    MediaSource mediaSource,
  ) async {
    final picker = ImagePicker();
    try {
      XFile? file;
      var duration = 0;

      if (mediaType == MediaType.video) {
        file = await picker.pickVideo(
          source: ImageSource.camera,
          maxDuration: const Duration(seconds: 30),
        );
        if (file != null) {
          final mediaInfo = await VideoCompress.getMediaInfo(file.path);
          duration = (mediaInfo.duration ?? 0).toInt();
        }
      } else if (mediaType == MediaType.photo) {
        file = await picker.pickImage(source: ImageSource.camera);
      }

      if (file != null && file.path.isEmptyOrNull == false) {
        final mediaInfoClass = MediaInfoClass(
          duration: (duration / 1000).toInt(),
          mediaType: mediaType,
          mediaSource: mediaSource,
          mediaFile: file,
        );
        return mediaInfoClass;
      }
    } catch (e) {
      if (context.mounted) {
        Utility.showInSnackBar('Error picking video from gallery', context);
      }
    }
    return null;
  }

  Future<MediaInfoClass?> _pickFromGallery(BuildContext context,
      MediaType mediaType, MediaSource mediaSource) async {
    final picker = ImagePicker();
    try {
      XFile? file;
      var duration = 0;

      if (mediaType == MediaType.video) {
        file = await picker.pickVideo(source: ImageSource.gallery);
        final isMinResolution = await file?.path.hasMinResolution();
        if (isMinResolution == false) {
          ErrorHandler.showAppError(
            appError: null,
            isNeedToShowError: true,
            message: IsrTranslationFile.pleaseSelectMinimumResolution,
          );
          return null;
        }
        if (file != null) {
          if (context.mounted) {
            final trimmed = await GalleryVideoTrimUtil.trimVideo(
              context,
              videoPath: file.path,
            );
            if (!context.mounted) return null;
            if (trimmed == null) return null;
            file = XFile(trimmed);
          }
          final mediaInfo = await VideoCompress.getMediaInfo(file.path);
          duration = (mediaInfo.duration ?? 0).toInt();
        }
      } else if (mediaType == MediaType.photo) {
        file = await picker.pickImage(source: ImageSource.gallery);
      }

      if (file != null && file.path.isEmptyOrNull == false) {
        final mediaInfoClass = MediaInfoClass(
          duration: (duration / 1000).toInt(),
          mediaType: mediaType,
          mediaSource: mediaSource,
          mediaFile: file,
        );
        return mediaInfoClass;
      }
    } catch (e, stackTrace) {
      AppLog.error(
          'Error picking video from gallery...${e.toString()}', stackTrace);
      if (context.mounted) {
        Utility.showInSnackBar('Error picking video from gallery', context);
      }
    }
    return null;
  }

  Future<MediaData?> _processMediaInfo(
    BuildContext context,
    MediaInfoClass mediaInfoClass,
    Emitter<CreatePostState> emit,
    bool isForCoverImage,
    int position,
    MediaData? mediaData,
  ) async {
    final newMediaData = mediaData ?? MediaData();
    final mediaType = mediaInfoClass.mediaType;
    final originalMediaFile = File(mediaInfoClass.mediaFile?.path ?? '');

    if (originalMediaFile.path.isEmptyOrNull == false) {
      // Create a permanent copy of the media file to avoid it being cleaned up
      final permanentMediaFile =
          await _createPermanentMediaCopy(originalMediaFile, mediaType);
      if (permanentMediaFile == null) {
        debugPrint('Failed to create permanent copy of media file');
        return null;
      }

      newMediaData.previewUrl = permanentMediaFile.path;
      if (isForCoverImage == false) {
        newMediaData.assetId = '';
        newMediaData.size = await _safeGetFileSize(permanentMediaFile.path);
        newMediaData.localPath = permanentMediaFile.path;
        newMediaData.duration = mediaInfoClass.duration;
        newMediaData.mediaType =
            mediaType == MediaType.video ? 'video' : 'image';
        if (mediaType == MediaType.video) {
          final videoThumbnailFile =
              await _safeCreateVideoThumbnail(permanentMediaFile.path);
          newMediaData.previewUrl =
              videoThumbnailFile?.path.isEmptyOrNull == false
                  ? videoThumbnailFile!.path
                  : '';
          newMediaData.coverFileLocalPath = newMediaData.previewUrl;
        }

        newMediaData.fileName = _getFileName(
          permanentMediaFile.path,
          mediaType == MediaType.video ? 'video' : 'image',
        );
        newMediaData.fileExtension = _getFileExtension(permanentMediaFile.path);
        newMediaData.coverFileName =
            _getFileName(newMediaData.previewUrl, 'thumbnail');
        newMediaData.coverFileExtension =
            _getFileExtension(newMediaData.previewUrl ?? '');
        if (_coverImage.isEmptyOrNull) {
          _coverImage = newMediaData.previewUrl ?? '';
          _coverImageExtension = _getFileExtension(_coverImage);
          _coverFileName = _getFileName(_coverImage, 'thumbnail');
        }
      } else {
        final coverFileName =
            _getFileName(permanentMediaFile.path, 'thumbnail');
        newMediaData.coverFileName = coverFileName;
        newMediaData.coverFileExtension =
            _getFileExtension(newMediaData.previewUrl ?? '');
        _coverImage = permanentMediaFile.path;
        _coverImageExtension = _getFileExtension(_coverImage);
        _coverFileName = coverFileName;
      }
    }
    newMediaData.position = position + 1;
    return newMediaData;
  }

  FutureOr<void> _createPost(
      PostCreateEvent event, Emitter<CreatePostState> emit) async {
    _lastPostCreateEventForRetry = event;
    _createPostRequest = event.createPostRequest;
    if (event.isForEdit != true &&
        _createPostRequest.isTextPost &&
        event.attachedMedia?.isNotEmpty == true) {
      _mediaDataList.clear();
      for (var i = 0; i < event.attachedMedia!.length; i++) {
        final processed = await _processMediaData(event.attachedMedia![i], i);
        if (processed != null) {
          _mediaDataList.add(processed);
        }
      }
      if (_mediaDataList.isNotEmpty) {
        await _ensureUniqueUploadNamesForMedia();
        await _prepareCoverForLocalUpload();
        _createPostRequest.media = _mediaDataList;
      }
    }
    if (event.selectedSound != null) {
      _selectedPostSound = event.selectedSound;
      _postAttributeClass.selectedSound = event.selectedSound;
    }
    _cacheSoundForCreateApi(
      sound: event.selectedSound ?? _selectedPostSound,
      request: _createPostRequest,
    );

    if (event.isForEdit != true &&
        !_createPostRequest.isTextPost &&
        IsrVideoReelConfig.postConfig.isCaptionRequired &&
        (_createPostRequest.caption?.trim().isEmpty ?? true)) {
      Utility.showAppDialog(
        message: 'Please enter caption',
      );
      return;
    }

    if (event.isForEdit != true) {
      if (_usesBackgroundPostUi) {
        emit(DismissCreatePostFlowForBackgroundState());
      }
      final uploadSuccess = await _runLocalMediaUploads(emit);
      if (!uploadSuccess) return;
      _createPostRequest.media = _mediaDataList;
      final createPayload = _buildCreatePostPayload();
      debugPrint(
        'createPost API payload: ${jsonEncode(createPayload)}',
      );

      if (_usesBackgroundPostUi) {
        _notifyBackgroundCreatingPost();
      }

      final apiResult = await _createPostUseCase.executeCreatePost(
        isLoading: !_usesBackgroundPostUi,
        createPostRequest: createPayload,
      );
      if (apiResult.isSuccess) {
        _postData = null;
        final createPostData = apiResult.data?.data;
        final postId = createPostData?.id ?? '';
        // Text posts may include media; the backend still creates them in a
        // pending state and relies on `start-processing` to approve/publish.
        final isTextPost =
            (_createPostRequest.type ?? '').trim().toLowerCase() ==
                SocialPostType.text;
        final needsProcessing =
            isTextPost || _isMediaChanged(includeCoverChange: false);
        if (needsProcessing) {
          add(MediaProcessingEvent(postId: postId));
        } else {
          await _createPostData(postId);
          final createdState = PostCreatedState(
            postDataModel: null,
            postSuccessMessage: _createPostRequest.scheduleTime != null
                ? IsrTranslationFile.postScheduledSuccessfully
                : IsrTranslationFile.socialPostCreatedSuccessfully,
            postSuccessTitle: _createPostRequest.scheduleTime != null
                ? IsrTranslationFile.successfullyScheduled
                : IsrTranslationFile.successfullyPosted,
            mediaDataList: _createPostRequest.media,
          );
          emit(createdState);
          _afterEmitPostCreated(createdState, resolvedPostId: postId);
        }
      } else {
        if (_usesBackgroundPostUi) {
          _notifyBackgroundApiFailure(apiResult.error, isEdit: false);
        } else {
          ErrorHandler.showAppError(
              appError: apiResult.error, isNeedToShowError: true);
        }
      }
      return;
    }

    if (_usesBackgroundPostUi) {
      emit(DismissCreatePostFlowForBackgroundState());
      _notifyBackgroundCreatingPost();
    }

    late ApiResult<CreatePostResponse?> apiResult;
    apiResult = await _createPostUseCase.executeEditPost(
      isLoading: !_usesBackgroundPostUi,
      postId: _postData?.id ?? '',
      editPostRequest: _createPostRequest.toJson().run((body) {
        body.remove('media'); // non editable
        body.remove('previews'); // non editable
        return body;
      }),
    );
    if (apiResult.isSuccess) {
      if (_postData != null) {
        _updatePostData();
      }
      final isMediaChanged = _isMediaChanged();
      if (!_isForEdit || isMediaChanged) {
        add(MediaUploadEvent(
            mediaDataList: _mediaDataList, postId: _postData?.id ?? ''));
      } else {
        if (_isForEdit) {
          _updatePostData();
        }
        final editCreatedState = PostCreatedState(
          postDataModel: _isForEdit ? _postData : null,
          postSuccessMessage: _isForEdit
              ? IsrTranslationFile.postUpdatedSuccessfully
              : _createPostRequest.scheduleTime != null
                  ? IsrTranslationFile.postScheduledSuccessfully
                  : IsrTranslationFile.socialPostCreatedSuccessfully,
          postSuccessTitle: _isForEdit
              ? IsrTranslationFile.successfullyEdited
              : _createPostRequest.scheduleTime != null
                  ? IsrTranslationFile.successfullyScheduled
                  : IsrTranslationFile.successfullyPosted,
          mediaDataList: _createPostRequest.media,
        );
        emit(editCreatedState);
        _afterEmitPostCreated(editCreatedState);
      }
    } else {
      if (_usesBackgroundPostUi) {
        _notifyBackgroundApiFailure(apiResult.error, isEdit: true);
      } else {
        ErrorHandler.showAppError(
            appError: apiResult.error, isNeedToShowError: true);
      }
    }
  }

  void _updatePostData() {
    _postData?.tags = _createPostRequest.tags;
    _postData?.caption = _createPostRequest.caption;
    _postData?.media = _createPostRequest.media?.toList();
    final settings = _postData?.settings;
    if (settings != null) {
      if (_postAttributeClass.allowComment != settings.commentsEnabled) {
        settings.commentsEnabled = _postAttributeClass.allowComment;
      }

      if (_postAttributeClass.allowSave != settings.saveEnabled) {
        settings.saveEnabled = _postAttributeClass.allowSave;
      }

      if (_postAttributeClass.allowDownload != settings.downloadEnabled) {
        settings.downloadEnabled = _postAttributeClass.allowDownload;
      }
      _postData?.settings = settings;
    }
  }

  void _getProducts(
      GetProductsEvent event, Emitter<CreatePostState> emit) async {
    // if (_isDataLoading) return;
    // _isDataLoading = true;
    // var totalProductsCount = 0;
    // _pageCount = event.isFromPagination == true ? _pageCount + 1 : 0;
    // if (_pageCount == 0) {
    //   _listOfProducts.clear();
    // }
    // emit(GetProductsLoadingState(isLoading: _pageCount == 0));
    // final response = await _getAlgoliaSearchSuggestionUseCase.executeSearchProducts(
    //   page: _pageCount,
    //   query: _searchQuery,
    //   sortOption: '',
    //   filterQueries: {},
    // );
    // if (response.isSuccess) {
    //   final algoliaPlpPageResponse = response.data;
    //   if (algoliaPlpPageResponse != null) {
    //     final listOfSearchedProducts = List<ProductDataModel>.from(
    //       ((response.data?.results ?? []).toList()[0]['hits'] as List)
    //           .map((x) => ProductDataModel.fromJson(x as Map<String, dynamic>))
    //           .toList(),
    //     );
    //
    //     _listOfProducts.addAll(listOfSearchedProducts as Iterable<ProductDataModel>);
    //     totalProductsCount = response.data?.results.toList()[0]['nbHits'] as int;
    //   }
    // }
    //
    // emit(
    //   GetProductsState(
    //     productList: _listOfProducts,
    //     totalProductsCount: totalProductsCount,
    //   ),
    // );
    // _isDataLoading = false;
  }

  /// search product
  void searchProduct(String query) {
    resetApiCall();
    _deBouncer.run(() => add(GetProductsEvent()));
  }

  List<SocialProductData> getSocialProductList(
      List<ProductDataModel> linkedProducts) {
    if (linkedProducts.isListEmptyOrNull == true) return [];
    return linkedProducts.map((item) {
      final index = linkedProducts.indexOf(item);
      final dynamic productImages = item.images ?? item.modelImage;
      var imageUrl = productImages == null
          ? ''
          : (productImages is List<ImageData> &&
                  (productImages).isListEmptyOrNull == false)
              ? (productImages[0].small?.isEmpty == true
                  ? productImages[0].medium ?? ''
                  : productImages[0].small ?? '')
              : (productImages is ImageData)
                  ? (productImages.small?.isEmpty == true
                      ? productImages.medium ?? ''
                      : productImages.small ?? '')
                  : productImages.toString();
      if (imageUrl.isEmpty) {
        imageUrl = item.productImage ?? '';
      }
      return SocialProductData(
        productId: item.childProductId,
        productName: item.productName,
        category: item.categoryList.isListEmptyOrNull == true
            ? ''
            : item.categoryList?.first.categoryName,
        productImage: imageUrl,
        price: item.finalPriceList?.finalPrice,
        brand: item.brandTitle,
        discountPrice: item.finalPriceList?.discountPrice,
        currency: Currency(code: item.currency, symbol: item.currencySymbol),
        productUrl: item.slug?.takeIfNotEmpty() ?? item.productSeo?.slug,
        mediaPosition: ProductPosition(
          mediaPosition: index + 1,
          x: 0.3,
          y: 0.8,
        ),
        productSlug: item.slug?.takeIfNotEmpty() ?? item.productSeo?.slug,
      );
    }).toList();
  }

  List<ProductDataModel> _getProductDataModel(
      List<SocialProductData> linkedProducts) {
    if (linkedProducts.isListEmptyOrNull == true) return [];
    return linkedProducts
        .map((item) => ProductDataModel(
              childProductId: item.productId,
              productName: item.productName,
              productImage: item.productImage ?? '',
              finalPriceList: FinalPriceList(
                basePrice: item.price,
                finalPrice: item.price,
                discountPrice: item.discountPrice,
              ),
              brandTitle: item.brand,
              currency: item.currency?.code,
              currencySymbol: item.currency?.symbol,
            ))
        .toList();
  }

  FutureOr<void> _getPostDetails(
      GetSocialPostDetailsEvent event, Emitter<CreatePostState> emit) async {
    var totalProductsCount = 0;
    if (_isDataLoading) return;
    _isDataLoading = true;
    final apiResult = await _getPostDetailsUseCase.executeGetSocialProducts(
      isLoading: false,
      postId: event.postId,
      page: 1,
      limit: 20,
    );
    if (apiResult.isSuccess) {
      totalProductsCount = apiResult.data?.count?.toInt() ?? 0;
      _linkedSocialProducts.clear();
      _linkedSocialProducts
          .addAll(apiResult.data?.data as Iterable<ProductDataModel>);
      _tags.products = getSocialProductList(_linkedSocialProducts);
    } else {
      ErrorHandler.showAppError(appError: apiResult.error);
    }
    emit(
      LoadLinkedProductsState(
        productList: _linkedSocialProducts,
        totalProductsCount: totalProductsCount,
      ),
    );
    _isDataLoading = false;
  }

  /// load post data to edit post
  FutureOr<void> _editPost(
      EditPostEvent event, Emitter<CreatePostState> emit) async {
    _resetData();
    emit(CreatePostInitialState(isLoading: true));
    _postData = event.postData;
    _mediaDataList.clear();
    _mediaDataList.addAll(_postData?.media ?? []);
    // Create a copy of the list to avoid concurrent modification
    final mediaListCopy = List<MediaData>.from(_mediaDataList);
    for (var i = 0; i < mediaListCopy.length; i++) {
      final element = mediaListCopy[i];
      element.fileName = _extractFileName(element.url ?? '');
      element.localPath = element.url ?? '';
      element.previewUrl = element.mediaType?.mediaType == MediaType.photo
          ? (element.url ?? '')
          : element.previewUrl ?? '';
      // Update the original list element
      _mediaDataList[i] = element;
    }
    final socialProductList = _postData?.tags?.products;
    linkedProducts = socialProductList.isListEmptyOrNull
        ? []
        : _getProductDataModel(socialProductList!);
    _linkedSocialProducts
      ..clear()
      ..addAll(linkedProducts);
    emit(
      LoadLinkedProductsState(
        productList: linkedProducts,
        totalProductsCount: linkedProducts.length,
      ),
    );
    _isForEdit = true;
    _makePostRequest();
    // emit(MediaSelectedState(
    //     mediaDataList: _mediaDataList, isPostButtonEnable: false));
    final postAttribution = await preparePostAttribution();
    emit(PostAttributionUpdatedState(postAttributeClass: postAttribution));
  }

  String _extractFileName(String url) {
    final uri = Uri.parse(url);
    final fullName = uri.pathSegments.last;
    final nameWithoutExt = fullName.split('.').first;
    return nameWithoutExt;
  }

  void _makePostRequest() {
    descriptionText = _postData?.caption ?? '';

    // Clear existing data first
    mentionedUserData.clear();
    mediaMentionUserData.clear();
    hashTagDataList.clear();
    locationTagDataList.clear();
    debugPrint('CreatePostBloc: _makePostRequest => ${_postData?.toMap()}');
    final mentionList = _postData?.tags?.mentions ?? [];
    if (mentionList.isListEmptyOrNull == false) {
      for (final mentionItem in mentionList) {
        if (mentionItem.mediaPosition == null) {
          mentionedUserData.add(mentionItem);
        } else {
          mediaMentionUserData.add(mentionItem);
        }
      }
    }
    debugPrint(
        'CreatePostBloc: _makePostRequest => mentionedUserData => ${mentionedUserData.map((e) => e.toJson())}');
    debugPrint(
        'CreatePostBloc: _makePostRequest => mediaMentionUserData => ${mediaMentionUserData.map((e) => e.toJson())}');
    hashTagDataList = _postData?.tags?.hashtags ?? [];
    locationTagDataList = _postData?.tags?.places ?? [];
    _postAttributeClass.postLink = _postData?.tags?.primaryLink;

    // Update postAttributeClass with the loaded data
    _postAttributeClass.mentionedUserList = [
      ...mentionedUserData,
      ...mediaMentionUserData
    ];
    _postAttributeClass.hashTagDataList = hashTagDataList;
    _postAttributeClass.taggedPlaces = locationTagDataList;
    _postAttributeClass.allowSave = _postData?.settings?.saveEnabled;
    _postAttributeClass.allowComment = _postData?.settings?.commentsEnabled;
    _postAttributeClass.allowDownload = _postData?.settings?.downloadEnabled;
    final postSettings = _postData?.settings;
    if (postSettings != null) {
      _createPostRequest.settings = PostSettingModel(
        advanceInterval: postSettings.advanceInterval,
        ageRestriction: postSettings.ageRestriction,
        autoAdvance: postSettings.autoAdvance,
        commentsEnabled: postSettings.commentsEnabled,
        duetEnabled: postSettings.duetEnabled,
        saveEnabled: postSettings.saveEnabled,
        downloadEnabled: postSettings.downloadEnabled,
        stitchEnabled: postSettings.stitchEnabled,
        isPaid: postSettings.isPaid,
        priceAmount: postSettings.priceAmount,
        priceCurrency: postSettings.priceCurrency,
      );
    }
  }

  bool checkForChangesInLinkedProducts(List<ProductDataModel> linkedProducts) {
    debugPrint('=== checkForChangesInLinkedProducts BLOC DEBUG ===');
    debugPrint('Current linkedProducts count: ${linkedProducts.length}');
    debugPrint(
        'Current linkedProducts: ${linkedProducts.map((p) => p.productName).toList()}');
    debugPrint(
        'Original _linkedSocialProducts count: ${_linkedSocialProducts.length}');
    debugPrint(
        'Original _linkedSocialProducts: ${_linkedSocialProducts.map((p) => p.productName).toList()}');

    final lengthChanged = linkedProducts.length != _linkedSocialProducts.length;
    debugPrint('Length changed: $lengthChanged');

    final anyProductNotInOriginal = linkedProducts.any((product) =>
        !_linkedSocialProducts.any((existingProduct) =>
            existingProduct.childProductId == product.childProductId));
    debugPrint('Any product not in original: $anyProductNotInOriginal');

    final hasChanges = lengthChanged || anyProductNotInOriginal;
    _tags.products = getSocialProductList(linkedProducts);
    debugPrint('Final hasChanges: $hasChanges');
    debugPrint('=== END checkForChangesInLinkedProducts BLOC DEBUG ===');
    return hasChanges;
  }

  // Add a getter to access original linked products for debugging
  List<ProductDataModel> get originalLinkedProducts => _linkedSocialProducts;

  Future<File?> _compressFile(
      File? file, MediaType mediaType, Emitter<CreatePostState>? emit) async {
    final fileLength = await file?.length();
    final fileSizeBeforeCompression = fileLength ?? 0 / (1024 * 1024);
    _isCompressionRunning = true;
    debugPrint(
        '_compressFile......File size before compression: $fileSizeBeforeCompression mb');

    final compressedFile = await MediaCompressor.compressMedia(
      file!,
      isVideo: mediaType == MediaType.video,
      onProgress: (progress) {
        debugPrint('Compression progress: $progress');
        if (_isCompressionRunning && emit != null) {
          emit(CompressionProgressState(
              mediaKey: file.path, progress: progress));
        }
      },
    );
    if (compressedFile == null) {
      return file;
    }
    final fileSizeAfterCompression =
        (await compressedFile.length()) / (1024 * 1024);
    debugPrint(
        '_compressFile......File size after compression: $fileSizeAfterCompression mb');
    return compressedFile;
  }

  void _cancelCompression() {
    _isCompressionRunning = false;
  }

  DateTime getBufferedDate() {
    final now = DateTime.now();
    final bufferedDate = now.add(const Duration(minutes: 15));
    return bufferedDate;
  }

  /// Uploads local media + cover previews to cloud. Updates [_mediaDataList] and
  /// preview URLs on [_createPostRequest]. Used for new posts before create API,
  /// and for edit flow via [MediaUploadEvent].
  Future<bool> _runLocalMediaUploads(Emitter<CreatePostState> emit) async {
    _removeDuplicateMedia(_mediaDataList);
    final uploadingMedia = _mediaDataList.where((mediaData) {
      final hasLocalPath = mediaData.localPath.isEmptyOrNull == false &&
          Utility.isLocalUrl(mediaData.localPath ?? '');
      if (!hasLocalPath) return false;
      // Upload only pending items; skip already uploaded remote URLs.
      return mediaData.url.isEmptyOrNull == true ||
          Utility.isLocalUrl(mediaData.url ?? '');
    }).toList();
    final uploadingCover = _createPostRequest.previews?.where((mediaData) {
          final hasLocalPath = mediaData.localFilePath.isEmptyOrNull == false &&
              Utility.isLocalUrl(mediaData.localFilePath ?? '');
          if (!hasLocalPath) return false;
          // Upload only pending items; skip already uploaded remote URLs.
          return mediaData.url.isEmptyOrNull == true ||
              Utility.isLocalUrl(mediaData.url ?? '');
        }).toList() ??
        [];

    // Calculate total files including cover media if present
    final hasCoverMedia = uploadingCover.isNotEmpty;

    if (uploadingMedia.isListEmptyOrNull == false) {
      // Create a copy to avoid concurrent modification during iteration
      final mediaListLength = _mediaDataList.length;
      final filesToUpload = uploadingMedia
          .where((media) =>
              media.localPath.isEmptyOrNull == false &&
              Utility.isLocalUrl(media.localPath ?? ''))
          .toList();

      // Calculate total upload units (each photo = 1, each video = 2 for video + thumbnail)
      var totalUploadUnits = 0;
      for (final media in filesToUpload) {
        if (media.mediaType?.mediaType == MediaType.video) {
          // Video has 2 uploads: video file + thumbnail
          totalUploadUnits += 2;
        } else {
          totalUploadUnits += 1;
        }
      }
      // Add cover media if present
      if (hasCoverMedia) {
        totalUploadUnits += 1;
      }

      final totalFiles = filesToUpload.length;

      // Show initial upload state with first file
      final firstFile = filesToUpload[0];
      final fileName = path.basename(firstFile.localPath ?? '');

      // Initial state will be handled by the view

      _emitOrBackgroundUploadProgress(
          emit,
          ShowProgressDialogState(
            progress: 0,
            title: IsrTranslationFile.uploadingMediaFiles,
            subTitle: '$fileName (1/$totalFiles)',
            currentFileIndex: 1,
            totalFiles: totalFiles,
            currentFileName: fileName,
          ));

      var uploadIndex = 0;
      var completedUploadUnits = 0.0;
      for (var index = 0; index < mediaListLength; index++) {
        final mediaData = _mediaDataList[index];
        if (mediaData.localPath.isEmptyOrNull == false &&
            Utility.isLocalUrl(mediaData.localPath ?? '')) {
          uploadIndex++;
          File? compressedFile;
          if (AppConstants.isCompressionEnable && !mediaData.isCompressed) {
            compressedFile = await _compressFile(
              File(mediaData.localPath ?? ''),
              mediaData.mediaType?.mediaType ?? MediaType.photo,
              null,
            );
          }

          final mainPrefix = mediaData.mediaType?.mediaType == MediaType.video
              ? 'upload_video'
              : 'upload_image';
          var fileToUpload = compressedFile ?? File(mediaData.localPath ?? '');
          if (compressedFile != null) {
            final persistedMain =
                await _ensurePersistentUploadFile(compressedFile,
                    fileNamePrefix: mainPrefix);
            if (persistedMain != null) {
              fileToUpload = persistedMain;
              mediaData.localPath = persistedMain.path;
              mediaData.isCompressed = true;
            }
          } else {
            final src = File(mediaData.localPath ?? '');
            final persistedMain =
                await _ensurePersistentUploadFile(src, fileNamePrefix: mainPrefix);
            if (persistedMain != null) {
              fileToUpload = persistedMain;
              mediaData.localPath = persistedMain.path;
            }
          }

          final baseProgress = completedUploadUnits / totalUploadUnits * 100;

          final uploadedMediaUrl = await _uploadMediaToGoogleCloud(
            fileToUpload,
            mediaData.fileName ?? '',
            mediaData.mediaType?.mediaType,
            (uploadProgress) {
              // uploadProgress is 0-100
              // Each upload unit contributes equally to total progress
              final currentFileProgress = uploadProgress / totalUploadUnits;
              final totalProgress = baseProgress + currentFileProgress;

              // Show current file name with count
              final fileName = path.basename(mediaData.localPath ?? '');
              final fileInfo = '$fileName ($uploadIndex/$totalFiles)';

              debugPrint(
                  'file information ....$fileInfo, progress: $totalProgress');

              // Check if emit is still valid before calling
              if (!emit.isDone) {
                _emitOrBackgroundUploadProgress(
                    emit,
                    ShowProgressDialogState(
                      progress: totalProgress.clamp(0.0, 100.0),
                      title: IsrTranslationFile.uploadingMediaFiles,
                      subTitle: fileInfo,
                      currentFileIndex: uploadIndex,
                      totalFiles: totalFiles,
                      currentFileName: mediaData.fileName ?? '',
                    ));
              }
            },
            _mediaDataList[_selectedMediaIndex].mediaType?.mediaType ==
                    MediaType.photo
                ? AppConstants.cloudinaryImageFolder
                : AppConstants.cloudinaryVideoFolder,
            mediaData.fileExtension ?? '',
          );
          if (uploadedMediaUrl.isEmpty) {
            _emitOrBackgroundUploadProgress(
                emit,
                ShowProgressDialogState(
                  progress: 0,
                  title: IsrTranslationFile.uploadingMediaFiles,
                  subTitle: IsrTranslationFile.uploadFailed,
                  currentFileIndex: uploadIndex,
                  totalFiles: totalFiles,
                  currentFileName: mediaData.fileName ?? '',
                  isErrorUploading: true,
                ));
            return false;
          }
          mediaData.url = uploadedMediaUrl;

          // Update completed units after file upload
          completedUploadUnits += 1.0;

          if (mediaData.mediaType?.mediaType == MediaType.video) {
            final previewLocalPath =
                mediaData.coverFileLocalPath ?? mediaData.previewUrl;
            if (previewLocalPath.isEmptyOrNull == false &&
                Utility.isLocalUrl(previewLocalPath ?? '')) {
              File? thumbCompressed;
              if (AppConstants.isCompressionEnable) {
                thumbCompressed = await _compressFile(
                  File(previewLocalPath ?? ''),
                  MediaType.photo,
                  null,
                );
              }

              var thumbFile = thumbCompressed ?? File(previewLocalPath ?? '');
              if (thumbCompressed != null) {
                final persistedThumb = await _ensurePersistentUploadFile(
                    thumbCompressed,
                    fileNamePrefix: 'thumb_upload');
                if (persistedThumb != null) {
                  thumbFile = persistedThumb;
                }
              } else {
                final persistedThumb = await _ensurePersistentUploadFile(
                    thumbFile,
                    fileNamePrefix: 'thumb_upload');
                if (persistedThumb != null) {
                  thumbFile = persistedThumb;
                }
              }

              final thumbnailBaseProgress =
                  completedUploadUnits / totalUploadUnits * 100;

              final uploadedPreviewUrl = await _uploadMediaToGoogleCloud(
                thumbFile,
                mediaData.coverFileName ?? '',
                MediaType.photo,
                (uploadProgress) {
                  // uploadProgress is 0-100
                  // Each upload unit contributes equally to total progress
                  final currentFileProgress = uploadProgress / totalUploadUnits;
                  final totalProgress =
                      thumbnailBaseProgress + currentFileProgress;

                  // Show current file name with count
                  final fileName = path.basename(previewLocalPath ?? '');
                  final fileInfo =
                      '$fileName(${IsrTranslationFile.cover}) ($uploadIndex/$totalFiles)';

                  debugPrint(
                      'file information ....$fileInfo, progress: $totalProgress');

                  // Check if emit is still valid before calling
                  if (!emit.isDone) {
                    _emitOrBackgroundUploadProgress(
                        emit,
                        ShowProgressDialogState(
                          progress: totalProgress.clamp(0.0, 100.0),
                          title: IsrTranslationFile.uploadingMediaFiles,
                          subTitle: fileInfo,
                          currentFileIndex: uploadIndex,
                          totalFiles: totalFiles,
                          currentFileName: mediaData.fileName ?? '',
                        ));
                  }
                },
                AppConstants.cloudinaryImageFolder,
                mediaData.coverFileExtension ?? '',
              );
              if (uploadedPreviewUrl.isEmpty) {
                _emitOrBackgroundUploadProgress(
                    emit,
                    ShowProgressDialogState(
                      progress: 0,
                      title: IsrTranslationFile.uploadingMediaFiles,
                      subTitle: IsrTranslationFile.uploadFailed,
                      currentFileIndex: uploadIndex,
                      totalFiles: totalFiles,
                      currentFileName: mediaData.fileName ?? '',
                      isErrorUploading: true,
                    ));
                return false;
              }
              mediaData.previewUrl = uploadedPreviewUrl;

              // Update completed units after thumbnail upload
              completedUploadUnits += 1.0;
            }
          }
        }
        _mediaDataList[index] = mediaData;
      }

      // Emit final state to indicate all files are uploaded
      // Final state will be handled by the view
      if (!emit.isDone && !hasCoverMedia) {
        _emitOrBackgroundUploadProgress(
            emit,
            ShowProgressDialogState(
              progress: 100,
              title: IsrTranslationFile.uploadComplete,
              subTitle: IsrTranslationFile.allFilesUploadedSuccessfully,
              currentFileIndex: totalFiles,
              totalFiles: totalFiles,
              currentFileName: '',
              isAllFilesUploaded: true,
            ));
      }
    }

    // Upload cover media separately if it exists
    if (hasCoverMedia) {
      // Recalculate total upload units for cover media progress
      var totalUploadUnits = 0;
      final filesToUpload = _mediaDataList
          .where((media) =>
              media.localPath.isEmptyOrNull == false &&
              Utility.isLocalUrl(media.localPath ?? ''))
          .toList();
      for (final media in filesToUpload) {
        if (media.mediaType?.mediaType == MediaType.video) {
          totalUploadUnits += 2;
        } else {
          totalUploadUnits += 1;
        }
      }
      totalUploadUnits += 1; // Add cover media

      final baseProgress = totalUploadUnits > 1
          ? (totalUploadUnits - 1) / totalUploadUnits * 100
          : 0.0;

      for (final previewItem in _createPostRequest.previews!) {
        if (Utility.isLocalUrl(previewItem.localFilePath ?? '') &&
            (previewItem.url.isEmptyOrNull == true ||
                Utility.isLocalUrl(previewItem.url ?? ''))) {
          final coverFileName = previewItem.fileName ?? 'cover_image';
          final uploadIndex = _mediaDataList.length + 1;
          final totalFiles = _mediaDataList.length + 1;
          File? compressedFile;
          if (AppConstants.isCompressionEnable) {
            compressedFile = await _compressFile(
              File(previewItem.localFilePath ?? ''),
              MediaType.photo,
              null,
            );
          }
          var coverFileToUpload =
              compressedFile ?? File(previewItem.localFilePath ?? '');
          if (compressedFile != null) {
            final persistedCover = await _ensurePersistentUploadFile(
                compressedFile,
                fileNamePrefix: 'cover_upload');
            if (persistedCover != null) {
              coverFileToUpload = persistedCover;
              previewItem.localFilePath = persistedCover.path;
            }
          } else {
            final src = File(previewItem.localFilePath ?? '');
            final persistedCover =
                await _ensurePersistentUploadFile(src, fileNamePrefix: 'cover_upload');
            if (persistedCover != null) {
              coverFileToUpload = persistedCover;
              previewItem.localFilePath = persistedCover.path;
            }
          }
          final uploadedUrl = await _uploadMediaToGoogleCloud(
            coverFileToUpload,
            coverFileName,
            previewItem.mediaType?.mediaType,
            (uploadProgress) {
              // uploadProgress is 0-100
              // Each upload unit contributes equally to total progress
              final currentFileProgress = uploadProgress / totalUploadUnits;
              final totalProgress = baseProgress + currentFileProgress;

              if (!emit.isDone) {
                _emitOrBackgroundUploadProgress(
                    emit,
                    ShowProgressDialogState(
                      progress: totalProgress.clamp(0.0, 100.0),
                      title: IsrTranslationFile.uploadingPreviewFiles,
                      subTitle: '$coverFileName',
                      currentFileIndex: uploadIndex,
                      totalFiles: totalFiles,
                      currentFileName: coverFileName,
                    ));
              }
            },
            previewItem.mediaType?.mediaType == MediaType.photo
                ? AppConstants.cloudinaryImageFolder
                : AppConstants.cloudinaryVideoFolder,
            _coverImageExtension,
          );
          if (uploadedUrl.isEmpty) {
            _emitOrBackgroundUploadProgress(
                emit,
                ShowProgressDialogState(
                  progress: 0,
                  title: IsrTranslationFile.uploadingPreviewFiles,
                  subTitle: IsrTranslationFile.uploadFailed,
                  currentFileIndex: uploadIndex,
                  totalFiles: totalFiles,
                  currentFileName: coverFileName,
                  isErrorUploading: true,
                ));
            return false;
          }

          // Update the preview item with uploaded URL
          previewItem.url = uploadedUrl;

          if (!emit.isDone) {
            _emitOrBackgroundUploadProgress(
                emit,
                ShowProgressDialogState(
                  progress: 100,
                  title: IsrTranslationFile.uploadComplete,
                  subTitle: IsrTranslationFile.allFilesUploadedSuccessfully,
                  currentFileIndex: totalFiles,
                  totalFiles: totalFiles,
                  currentFileName: '',
                  isAllFilesUploaded: true,
                ));
          }
        }
      }
    }
    return true;
  }

  FutureOr<void> _uploadMedia(
      MediaUploadEvent event, Emitter<CreatePostState> emit) async {
    final uploadSuccess = await _runLocalMediaUploads(emit);
    if (!uploadSuccess) return;
    final isMediaChanged = _isMediaChanged(includeCoverChange: false);
    if (isMediaChanged) {
      add(MediaProcessingEvent(postId: event.postId));
    } else {
      if (_isForEdit) {
        _updatePostData();
      } else {
        await _createPostData(event.postId);
      }
      final uploadDoneState = PostCreatedState(
        postDataModel: _postData,
        postSuccessMessage: _isForEdit
            ? IsrTranslationFile.postUpdatedSuccessfully
            : _createPostRequest.scheduleTime != null
                ? IsrTranslationFile.postScheduledSuccessfully
                : IsrTranslationFile.socialPostCreatedSuccessfully,
        postSuccessTitle: _isForEdit
            ? IsrTranslationFile.successfullyEdited
            : _createPostRequest.scheduleTime != null
                ? IsrTranslationFile.successfullyScheduled
                : IsrTranslationFile.successfullyPosted,
        mediaDataList: _createPostRequest.media,
      );
      emit(uploadDoneState);
      _afterEmitPostCreated(uploadDoneState);
    }
  }

  bool _isMediaChanged({bool includeCoverChange = true}) {
    // Create a copy to avoid concurrent modification during iteration
    final mediaListCopy = List<MediaData>.from(_mediaDataList);
    final mediaChanged = mediaListCopy.any((mediaData) =>
        mediaData.localPath.isEmptyOrNull == false &&
        Utility.isLocalUrl(mediaData.localPath ?? ''));
    // Create a copy to avoid concurrent modification during iteration
    final coverChanged = Utility.isLocalUrl(_coverImage);
    return mediaChanged || (includeCoverChange && coverChanged);
  }

  FutureOr<void> _processMedia(
      MediaProcessingEvent event, Emitter<CreatePostState> emit) async {
    if (_usesBackgroundPostUi) {
      _notifyBackgroundProcessingMedia();
    }
    final apiResult = await mediaProcessingUseCase.executeMediaProcessing(
      isLoading: !_usesBackgroundPostUi,
      postId: event.postId,
    );
    if (apiResult.isSuccess) {
      if (_isForEdit) {
        _updatePostData();
      } else {
        await _createPostData(event.postId);
      }
      final processedState = PostCreatedState(
        postDataModel: _postData,
        postSuccessMessage: _isForEdit
            ? IsrTranslationFile.postUpdatedSuccessfully
            : _createPostRequest.scheduleTime != null
                ? IsrTranslationFile.postScheduledSuccessfully
                : IsrTranslationFile.socialPostCreatedSuccessfully,
        postSuccessTitle: _isForEdit
            ? IsrTranslationFile.successfullyEdited
            : _createPostRequest.scheduleTime != null
                ? IsrTranslationFile.successfullyScheduled
                : IsrTranslationFile.successfullyPosted,
        mediaDataList: _createPostRequest.media,
      );
      emit(processedState);
      _afterEmitPostCreated(processedState, resolvedPostId: event.postId);
      _resetData();
    } else {
      if (_usesBackgroundPostUi) {
        _notifyBackgroundMediaProcessingFailure(apiResult.error);
      } else {
        ErrorHandler.showAppError(
            appError: apiResult.error, isNeedToShowError: true);
      }
    }
  }

  Future<void> _createMediaUrls() async {
    if (_mediaDataList.isListEmptyOrNull == false) {
      final userId = await _localDataUseCase.getUserId();
      // Create a copy to avoid concurrent modification during iteration
      final mediaListLength = _mediaDataList.length;
      for (var index = 0; index < mediaListLength; index++) {
        final mediaData = _mediaDataList[index];
        if (mediaData.localPath.isEmptyOrNull == false &&
            Utility.isLocalUrl(mediaData.localPath ?? '')) {
          final finalFileName =
              '${mediaData.fileName}_${index}_${DateTime.now().millisecondsSinceEpoch}';

          mediaData.fileName = finalFileName;
          final normalizedFolder =
              '${AppConstants.tenantId}/${AppConstants.projectId}/user_$userId/posts/$finalFileName${mediaData.fileExtension}';
          final uploadUrl = '${AppUrl.gumletUrl}/$normalizedFolder';
          mediaData.url = uploadUrl;
          if (mediaData.mediaType?.mediaType == MediaType.video) {
            final previewLocalPath =
                mediaData.previewUrl ?? mediaData.coverFileLocalPath;
            if (previewLocalPath.isEmptyOrNull == false &&
                Utility.isLocalUrl(previewLocalPath ?? '')) {
              final finalFileName =
                  '${mediaData.coverFileName}_${index}_${DateTime.now().millisecondsSinceEpoch}';
              mediaData.coverFileName = finalFileName;
              final normalizedFolder =
                  '${AppConstants.tenantId}/${AppConstants.projectId}/user_$userId/posts/$finalFileName${mediaData.coverFileExtension}';
              final uploadUrl = '${AppUrl.gumletUrl}/$normalizedFolder';
              mediaData.previewUrl = uploadUrl;
            }
          }
        }
        _mediaDataList[index] = mediaData;
      }
    }
  }

  /// Unique upload file names for new posts without pre-assigning Gumlet URLs (URLs are set after upload).
  Future<void> _ensureUniqueUploadNamesForMedia() async {
    if (_mediaDataList.isListEmptyOrNull == false) {
      // Create a copy to avoid concurrent modification during iteration
      final mediaListLength = _mediaDataList.length;
      for (var index = 0; index < mediaListLength; index++) {
        final mediaData = _mediaDataList[index];
        if (mediaData.localPath.isEmptyOrNull == false &&
            Utility.isLocalUrl(mediaData.localPath ?? '')) {
          final finalFileName =
              '${mediaData.fileName}_${index}_${DateTime.now().millisecondsSinceEpoch}';
          mediaData.fileName = finalFileName;
          if (mediaData.mediaType?.mediaType == MediaType.video) {
            final previewLocalPath =
                mediaData.previewUrl ?? mediaData.coverFileLocalPath;
            if (previewLocalPath.isEmptyOrNull == false &&
                Utility.isLocalUrl(previewLocalPath ?? '')) {
              final thumbName =
                  '${mediaData.coverFileName}_${index}_${DateTime.now().millisecondsSinceEpoch}';
              mediaData.coverFileName = thumbName;
            }
          }
        }
        _mediaDataList[index] = mediaData;
      }
    }
  }

  /// Cover preview metadata for create flow; [PreviewMedia.url] is filled after cloud upload.
  Future<void> _prepareCoverForLocalUpload() async {
    if (_coverImage.trim().isNotEmpty) {
      if (Utility.isLocalUrl(_coverImage)) {
        final f = File(_coverImage);
        if (await f.exists()) {
          final persisted =
              await _ensurePersistentUploadFile(f, fileNamePrefix: 'cover_local');
          if (persisted != null) {
            _coverImage = persisted.path;
          }
        }
      }
      debugPrint('cover file : $_coverImage');
      debugPrint('cover image extension : $_coverImageExtension');
      debugPrint('cover file name : $_coverFileName');
      final finalFileName =
          '${_coverFileName}_${0}_${DateTime.now().millisecondsSinceEpoch}';
      _createPostRequest.previews = [
        PreviewMedia(
          mediaType: MediaType.photo.mediaTypeString,
          url: '',
          fileName: finalFileName,
          localFilePath: _coverImage,
          position: 1,
        )
      ];
      debugPrint('create post request : ${_createPostRequest.toJson()}');
    } else {
      _createPostRequest.previews = _postData?.previews;
    }
  }

  FutureOr<void> _changeCoverImage(
      ChangeCoverImageEvent event, Emitter<CreatePostState> emit) async {
    final picked = File(event.coverImage.path);
    if (await picked.exists()) {
      final persisted = await _ensurePersistentUploadFile(picked,
          fileNamePrefix: 'cover_pick');
      _coverImage = persisted?.path ?? event.coverImage.path;
    } else {
      _coverImage = event.coverImage.path;
    }
    _coverImageExtension = _getFileExtension(_coverImage);
    _coverFileName = _getFileName(_coverImage, 'thumbnail');
    if (_isForEdit) {
      await _createCoverUrl();
    } else {
      await _prepareCoverForLocalUpload();
    }
    event.onComplete?.call();
  }

  Future<void> _createCoverUrl() async {
    if (_coverImage.trim().isNotEmpty) {
      final userId = await _localDataUseCase.getUserId();
      debugPrint('cover file : $_coverImage');
      debugPrint('cover image extension : $_coverImageExtension');
      debugPrint('cover file name : $_coverFileName');
      final finalFileName =
          '${_coverFileName}_${0}_${DateTime.now().millisecondsSinceEpoch}';
      final normalizedFolder =
          '${AppConstants.tenantId}/${AppConstants.projectId}/user_$userId/posts/$finalFileName$_coverImageExtension';
      final uploadUrl = '${AppUrl.gumletUrl}/$normalizedFolder';
      _createPostRequest.previews = [
        PreviewMedia(
          mediaType: MediaType.photo.mediaTypeString,
          url: uploadUrl,
          fileName: finalFileName,
          localFilePath: _coverImage,
          position: 1,
        )
      ];
      debugPrint('create post request : ${_createPostRequest.toJson()}');
    } else {
      _createPostRequest.previews = _postData?.previews;
    }
  }

  Future<void> _createPostData(String postId) async {
    final myUserId = await _localDataUseCase.getUserId();
    final userName = await _localDataUseCase.getUserName();
    final firstName = await _localDataUseCase.getFirstName();
    final lastName = await _localDataUseCase.getLastName();
    final avatarUrl = await _localDataUseCase.getProfilePic();
    _createPostRequest.media?.forEach((element) {
      element.url = element.localPath ?? '';
    });
    _postData = TimeLineData(
      id: postId,
      caption: _createPostRequest.caption,
      media: _createPostRequest.media,
      tags: _createPostRequest.tags,
      type: _createPostRequest.type,
      user: SocialUserData(
        id: myUserId,
        username: userName,
        avatarUrl: avatarUrl,
        fullName: '$firstName $lastName',
      ),
      visibility: _createPostRequest.visibility,
      isLiked: false,
      isSaved: false,
    );
  }

  Future<File> saveWithShortName(File originalFile) async {
    final appDir = await getTemporaryDirectory();

    // short safe name
    final newPath = path.join(
      appDir.path,
      'thumb_${DateTime.now().millisecondsSinceEpoch}${path.extension(originalFile.path)}',
    );

    return await originalFile.copy(newPath);
  }

  FutureOr<void> _removeSelectedMedia(
      RemoveMediaEvent event, Emitter<CreatePostState> emit) {
    _mediaDataList.remove(event.mediaData);
    CoverImageSelected(
      coverImage: _mediaDataList.isListEmptyOrNull
          ? ''
          : _mediaDataList[_selectedMediaIndex].previewUrl,
      isPostButtonEnable: _isPostButtonEnabled(_mediaDataList),
    );
    emit(MediaSelectedState(
        mediaDataList: _mediaDataList,
        isPostButtonEnable: _isPostButtonEnabled(_mediaDataList)));
  }

  Future<MediaInfoClass> _getMediaInfo(String path) async {
    final isVideo = path.isVideoFile;
    var duration = 0;
    if (isVideo) {
      final mediaInfo = await VideoCompress.getMediaInfo(path);
      duration = (mediaInfo.duration ?? 0).toInt();
    }
    return MediaInfoClass(
      duration: (duration / 1000).toInt(),
      mediaType: isVideo ? MediaType.video : MediaType.photo,
      mediaFile: XFile(path),
    );
  }

  Future<MediaData?> _processMediaData(
    MediaData mediaData,
    int position,
  ) async {
    final newMediaData = mediaData;
    final mediaInfoClass = await _getMediaInfo(mediaData.localPath ?? '');
    final mediaType = mediaInfoClass.mediaType;
    final originalMediaFile = File(mediaInfoClass.mediaFile?.path ?? '');

    if (originalMediaFile.path.isEmptyOrNull == false) {
      // Create a permanent copy of the media file to avoid it being cleaned up
      final permanentMediaFile =
          await _createPermanentMediaCopy(originalMediaFile, mediaType);
      if (permanentMediaFile == null) {
        debugPrint('Failed to create permanent copy of media file');
        return null;
      }

      newMediaData.assetId = '';
      newMediaData.size = await _safeGetFileSize(permanentMediaFile.path);
      newMediaData.localPath = permanentMediaFile.path;
      newMediaData.duration = mediaInfoClass.duration;
      newMediaData.mediaType = mediaType == MediaType.video ? 'video' : 'image';

      newMediaData.fileName = _getFileName(
        permanentMediaFile.path,
        mediaType == MediaType.video ? 'video' : 'image',
      );
      newMediaData.fileExtension = _getFileExtension(permanentMediaFile.path);
      if (mediaType == MediaType.video) {
        final persistedCover = await _persistLocalCoverImage(
          mediaData.coverFileLocalPath ?? mediaData.previewUrl,
        );
        if (persistedCover != null) {
          newMediaData.previewUrl = persistedCover;
          newMediaData.coverFileLocalPath = persistedCover;
        } else {
          final videoThumbnailFile =
              await _safeCreateVideoThumbnail(permanentMediaFile.path);
          newMediaData.previewUrl =
              videoThumbnailFile?.path.isEmptyOrNull == false
                  ? videoThumbnailFile!.path
                  : '';
          newMediaData.coverFileLocalPath = newMediaData.previewUrl;
        }
        newMediaData.coverFileName =
            _getFileName(newMediaData.previewUrl, 'thumbnail');
        newMediaData.coverFileExtension =
            _getFileExtension(newMediaData.previewUrl ?? '');
      } else {
        newMediaData.previewUrl = permanentMediaFile.path;
        newMediaData.coverFileName = _getFileName(
            newMediaData.previewUrl ?? newMediaData.coverFileLocalPath,
            'thumbnail');
        newMediaData.coverFileExtension = _getFileExtension(
            newMediaData.previewUrl ?? newMediaData.coverFileLocalPath ?? '');
      }
    }
    newMediaData.position = position + 1;
    return newMediaData;
  }

  FutureOr<PostAttributeClass?> preparePostAttribution({
    List<MediaData>? newMediaDataList,
  }) async {
    debugPrint('=== _goToPostAttributeView START ===');
    debugPrint('mentionedUserData count: ${mentionedUserData.length}');
    debugPrint('mediaMentionUserData count: ${mediaMentionUserData.length}');
    debugPrint('hashTagDataList count: ${hashTagDataList.length}');
    debugPrint('locationTagDataList count: ${locationTagDataList.length}');
    if (newMediaDataList?.isNotEmpty == true) {
      final newMedia = <MediaData>[];
      for (var i = 0; i < (newMediaDataList?.length ?? 0); i++) {
        final processedMedia = await _processMediaData(newMediaDataList![i], i);
        if (processedMedia != null) {
          newMedia.add(processedMedia);
        }
      }
      _mediaDataList.clear();
      _mediaDataList.addAll(newMedia);
      _mediaDataList.firstOrNull?.let((media) {
        _coverFileName = media.coverFileName ?? '';
        _coverImageExtension = media.coverFileExtension ?? '';
        _coverImage =
            media.coverFileLocalPath ?? media.previewUrl ?? '';
      });
    }

    if (_mediaDataList.isEmpty) {
      return null;
    }
    if (_isForEdit) {
      await _createMediaUrls();
      await _createCoverUrl();
    } else {
      await _ensureUniqueUploadNamesForMedia();
      await _prepareCoverForLocalUpload();
    }

    _createPostRequest.media = _mediaDataList;

    _createPostRequest.type = _mediaDataList.length > 1
        ? SocialPostType.carousel
        : _mediaDataList[_selectedMediaIndex].mediaType?.mediaType ==
                MediaType.video
            ? SocialPostType.video
            : SocialPostType.image;
    _createPostRequest.caption = descriptionText;

    _postAttributeClass.taggedPlaces = locationTagDataList;
    _postAttributeClass.mentionedUserList = [
      ...mentionedUserData,
      ...mediaMentionUserData
    ];
    _postAttributeClass.hashTagDataList = hashTagDataList;
    _postAttributeClass.mediaDataList = _mediaDataList;
    _postAttributeClass.linkedProducts = linkedProducts;
    if (_postAttributeClass.postLink?.isValid == true) {
      _tags.links = [_postAttributeClass.postLink!];
    }
    _postAttributeClass.selectedSound = _resolveSelectedSound();
    _postAttributeClass.createPostRequest = _createPostRequest;
    _applySelectedSoundToCreatePostRequest(_postAttributeClass.selectedSound);
    _cacheSoundForCreateApi(
      sound: _postAttributeClass.selectedSound,
      request: _createPostRequest,
    );
    return _postAttributeClass;
  }

  MediaEditSoundItem? _soundItemFromCreatePostRequest() {
    if (!PostSoundUtil.isLibrarySoundId(_createPostRequest.soundId)) {
      return null;
    }
    final snapshot = _createPostRequest.soundSnapshot;
    return MediaEditSoundItem(
      soundId: _createPostRequest.soundId,
      soundMetadata:
          snapshot == null ? null : Map<String, dynamic>.from(snapshot),
      soundDuration: snapshot?['segment_duration']?.toString(),
      soundArtist: snapshot?['artist'] as String?,
    );
  }

  MediaEditSoundItem? _resolveSelectedSound() =>
      _selectedPostSound ??
      _postAttributeClass.selectedSound ??
      _soundItemFromCreatePostRequest();

  void _cacheSoundForCreateApi({
    MediaEditSoundItem? sound,
    CreatePostRequest? request,
  }) {
    final resolved = sound ?? _soundItemFromRequest(request);
    if (!PostSoundUtil.isLibrarySoundId(resolved?.soundId)) return;

    final hasVideo = _mediaDataList.any(
      (m) => m.mediaType == 'video' || m.postType == PostType.video,
    );
    final isImageOnly = _mediaDataList.isNotEmpty && !hasVideo;
    final videoDuration = _mediaDataList
        .where((m) => m.mediaType == 'video' || m.postType == PostType.video)
        .map((m) => m.duration?.toInt())
        .whereType<int>()
        .firstOrNull;

    _pendingCreatePostSoundId = resolved!.soundId!.trim();
    _pendingCreatePostSoundSnapshot = PostSoundUtil.buildSoundSnapshot(
      sound: resolved,
      videoDurationSeconds: isImageOnly
          ? PostSoundUtil.photoSoundClipMaxSeconds
          : videoDuration,
      maxClipSec: isImageOnly ? PostSoundUtil.photoSoundClipMaxSeconds : 60,
    );
    _createPostRequest.soundId = _pendingCreatePostSoundId;
    _createPostRequest.soundSnapshot = _pendingCreatePostSoundSnapshot;
  }

  MediaEditSoundItem? _soundItemFromRequest(CreatePostRequest? request) {
    if (request == null ||
        !PostSoundUtil.isLibrarySoundId(request.soundId)) {
      return null;
    }
    final snapshot = request.soundSnapshot;
    return MediaEditSoundItem(
      soundId: request.soundId,
      soundMetadata:
          snapshot == null ? null : Map<String, dynamic>.from(snapshot),
      soundDuration: snapshot?['segment_duration']?.toString(),
      soundArtist: snapshot?['artist'] as String?,
    );
  }

  void _applyPendingSoundToPayload(Map<String, dynamic> payload) {
    final soundId = _pendingCreatePostSoundId?.trim();
    if (!PostSoundUtil.isLibrarySoundId(soundId)) return;
    payload['sound_id'] = soundId;
    final snapshot = _pendingCreatePostSoundSnapshot;
    if (snapshot != null && snapshot.isNotEmpty) {
      payload['sound_snapshot'] = Map<String, dynamic>.from(snapshot);
    }
  }

  Map<String, dynamic> _buildCreatePostPayload() {
    final sound = _resolveSelectedSound();
    _cacheSoundForCreateApi(sound: sound, request: _createPostRequest);
    _applySelectedSoundToCreatePostRequest(sound);
    final payload = Map<String, dynamic>.from(_createPostRequest.toJson());
    PostSoundUtil.mergeSoundIntoCreatePostJson(
      body: payload,
      sound: sound,
      media: _mediaDataList,
    );
    _applyPendingSoundToPayload(payload);
    return payload;
  }

  void _applySelectedSoundToCreatePostRequest(MediaEditSoundItem? sound) {
    final resolved = sound ?? _soundItemFromCreatePostRequest();
    if (!PostSoundUtil.isLibrarySoundId(resolved?.soundId)) {
      if (!PostSoundUtil.isLibrarySoundId(_createPostRequest.soundId)) {
        _createPostRequest.soundId = null;
        _createPostRequest.soundSnapshot = null;
      }
      return;
    }
    sound = resolved;
    final hasVideo = _mediaDataList.any(
      (m) => m.mediaType == 'video' || m.postType == PostType.video,
    );
    final isImageOnly = _mediaDataList.isNotEmpty && !hasVideo;
    final videoDuration = _mediaDataList
        .where((m) => m.mediaType == 'video' || m.postType == PostType.video)
        .map((m) => m.duration?.toInt())
        .whereType<int>()
        .firstOrNull;
    _createPostRequest.soundId = sound!.soundId!.trim();
    _createPostRequest.soundSnapshot = PostSoundUtil.buildSoundSnapshot(
      sound: sound,
      videoDurationSeconds: isImageOnly
          ? PostSoundUtil.photoSoundClipMaxSeconds
          : videoDuration,
      maxClipSec: isImageOnly ? PostSoundUtil.photoSoundClipMaxSeconds : 60,
    );
  }

  /// Creates a permanent copy of media file to prevent system cleanup
  Future<File?> _createPermanentMediaCopy(
      File originalFile, MediaType? mediaType) async {
    try {
      // Check if original file exists
      if (!await originalFile.exists()) {
        return null;
      }

      // Create a permanent location in the app's documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory(path.join(documentsDir.path, 'media'));

      // Ensure media directory exists
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }

      // Create a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = path.extension(originalFile.path);
      final mediaTypePrefix = mediaType == MediaType.video ? 'video' : 'image';
      final permanentPath = path.join(
          mediaDir.path, '${mediaTypePrefix}_$timestamp$fileExtension');

      // Copy to permanent location
      final permanentFile = await originalFile.copy(permanentPath);
      return permanentFile;
    } catch (e) {
      // If copy fails due to long filename, try with shortened path
      if (e is FileSystemException && e.osError?.errorCode == 63) {
        try {
          final documentsDir = await getApplicationDocumentsDirectory();
          final mediaDir = Directory(path.join(documentsDir.path, 'media'));

          if (!await mediaDir.exists()) {
            await mediaDir.create(recursive: true);
          }

          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileExtension = path.extension(originalFile.path);
          final mediaTypePrefix = mediaType == MediaType.video ? 'vid' : 'img';
          final shortPath = path.join(
              mediaDir.path, '${mediaTypePrefix}_$timestamp$fileExtension');
          final permanentFile = await originalFile.copy(shortPath);
          return permanentFile;
        } catch (retryError) {
          return null;
        }
      }

      return null;
    }
  }

  /// Copies [source] into app `Documents/.../media/` when it is not already there
  /// (e.g. temp output from compression or thumbnails). Required before upload/background.
  Future<File?> _ensurePersistentUploadFile(
    File source, {
    required String fileNamePrefix,
  }) async {
    try {
      if (!await source.exists()) return null;
      final documentsDir = await getApplicationDocumentsDirectory();
      final mediaDirPath = path.join(documentsDir.path, 'media');
      final normSource = path.normalize(source.path);
      final normMedia = path.normalize(mediaDirPath);
      final mediaPrefix = '$normMedia${path.separator}';
      if (normSource.startsWith(mediaPrefix)) {
        return source;
      }
      final mediaDir = Directory(mediaDirPath);
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = path.extension(source.path);
      final destPath = path.join(
        mediaDirPath,
        '${fileNamePrefix}_$timestamp$fileExtension',
      );
      return await source.copy(destPath);
    } catch (e) {
      debugPrint('_ensurePersistentUploadFile: $e');
      return null;
    }
  }

  /// Moves a generated video thumbnail into [Documents/.../media/] when needed.
  Future<XFile?> _finalizeThumbnailForStorage(XFile? thumbnail) async {
    if (thumbnail == null || thumbnail.path.isEmpty) return null;
    final f = File(thumbnail.path);
    if (!await f.exists()) return null;
    final documentsDir = await getApplicationDocumentsDirectory();
    final mediaDirPath = path.join(documentsDir.path, 'media');
    final normSource = path.normalize(f.path);
    final normMedia = path.normalize(mediaDirPath);
    final mediaPrefix = '$normMedia${path.separator}';
    if (normSource.startsWith(mediaPrefix)) {
      return thumbnail;
    }
    try {
      final mediaDir = Directory(mediaDirPath);
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }
      final ext = path.extension(f.path).isEmpty ? '.jpg' : path.extension(f.path);
      final destPath = path.join(
        mediaDirPath,
        'thumb_${DateTime.now().millisecondsSinceEpoch}$ext',
      );
      final copied = await f.copy(destPath);
      try {
        final tempRoot = path.normalize((await getTemporaryDirectory()).path);
        if (normSource.startsWith('$tempRoot${path.separator}')) {
          await f.delete();
        }
      } catch (_) {}
      return XFile(copied.path);
    } catch (e) {
      debugPrint('_finalizeThumbnailForStorage: $e');
      return thumbnail;
    }
  }

  /// Safely gets file size, handling long filename issues by copying to temp file first
  Future<int> _safeGetFileSize(String filePath) async {
    final file = File(filePath);

    // First check if file exists
    if (!await file.exists()) {
      return 0;
    }

    try {
      return file.lengthSync();
    } catch (e) {
      if (e is FileSystemException &&
          (e.osError?.errorCode == 63 || e.osError?.errorCode == 2)) {
        final tempDir = await getTemporaryDirectory();
        final fileExtension = path.extension(filePath);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final tempFilePath =
            path.join(tempDir.path, 'temp_size_$timestamp$fileExtension');

        try {
          // Double-check file exists before copying
          if (!await file.exists()) {
            return 0;
          }

          // Copy the original file to temp location
          final tempFile = await file.copy(tempFilePath);

          // Get size from temporary file
          final size = tempFile.lengthSync();

          // Clean up temp file
          try {
            await tempFile.delete();
          } catch (_) {
            debugPrint('Failed to cleanup temp size file: $tempFilePath');
          }

          return size;
        } catch (copyError) {
          debugPrint('Error copying file for size check: $copyError');
          // If copy fails, try to clean up and return 0 as fallback
          try {
            await File(tempFilePath).delete();
          } catch (_) {
            debugPrint(
                'Failed to cleanup failed temp size file: $tempFilePath');
          }
          return 0; // Fallback size
        }
      } else {
        return 0; // Return 0 instead of crashing for other errors
      }
    }
  }

  Future<String?> _persistLocalCoverImage(String? coverPath) async {
    if (coverPath.isEmptyOrNull || !Utility.isLocalUrl(coverPath!)) {
      return null;
    }
    final file = File(coverPath);
    if (!await file.exists()) return null;
    final permanent = await _createPermanentMediaCopy(file, MediaType.photo);
    return permanent?.path;
  }

  /// Safely creates video thumbnail, handling long filename issues by copying to temp file first
  Future<XFile?> _safeCreateVideoThumbnail(String videoPath) async {
    // First check if the video file exists
    final videoFile = File(videoPath);
    if (!await videoFile.exists()) {
      return null;
    }

    try {
      final thumbPath = await MediaUtil.pickBestVideoThumbnailPath(
        videoPath: videoPath,
        thumbnailPath: (await getTemporaryDirectory()).path,
        quality: 50,
      );
      if (thumbPath == null || thumbPath.isEmpty) {
        return null;
      }

      final safe = await _ensureSafeThumbnailPath(XFile(thumbPath));
      return await _finalizeThumbnailForStorage(safe);
    } catch (e) {
      if (e is FileSystemException && e.osError?.errorCode == 63) {
        // Handle "File name too long" error
        final tempDir = await getTemporaryDirectory();
        final fileExtension = path.extension(videoPath);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final tempVideoPath =
            path.join(tempDir.path, 'temp_video_$timestamp$fileExtension');

        try {
          // Verify original file exists before copying
          if (!await videoFile.exists()) {
            return null;
          }

          // Copy the original video to temp location
          final tempFile = await videoFile.copy(tempVideoPath);

          final thumbPath = await MediaUtil.pickBestVideoThumbnailPath(
            videoPath: tempFile.path,
            thumbnailPath: tempDir.path,
            quality: 50,
          );

          // Clean up temp video file
          try {
            await tempFile.delete();
          } catch (_) {
            debugPrint('Failed to cleanup temp video file: $tempVideoPath');
          }

          if (thumbPath == null || thumbPath.isEmpty) {
            return null;
          }

          final safe = await _ensureSafeThumbnailPath(XFile(thumbPath));
          return await _finalizeThumbnailForStorage(safe);
        } catch (copyError) {
          debugPrint('Error copying video to temp location: $copyError');
          // If copy fails, try to clean up and return null
          try {
            await File(tempVideoPath).delete();
          } catch (_) {
            debugPrint(
                'Failed to cleanup failed temp video file: $tempVideoPath');
          }
          return null; // Return null instead of rethrowing
        }
      } else {
        // For other errors, return null instead of crashing
        return null;
      }
    }
  }

  /// Ensures thumbnail has a safe path for Image.file() by copying to temp location if needed
  Future<XFile?> _ensureSafeThumbnailPath(XFile originalThumbnail) async {
    final originalPath = originalThumbnail.path;
    final originalFile = File(originalPath);

    // First check if the original thumbnail file exists
    if (!await originalFile.exists()) {
      return null; // Return null instead of throwing
    }

    // Check if path might cause issues (length check or try to access file)
    try {
      // Test if we can access the file without issues
      await originalFile.length(); // This will fail if filename is too long

      // If we get here, the path is safe
      return originalThumbnail;
    } catch (e) {
      if (e is FileSystemException &&
          (e.osError?.errorCode == 63 || e.osError?.errorCode == 2)) {
        // Handle both "File name too long" (63) and "No such file" (2) errors
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileExtension = path.extension(originalPath);
        final safeThumbnailPath =
            path.join(tempDir.path, 'safe_thumb_$timestamp$fileExtension');

        try {
          // Double-check file exists before copying
          if (!await originalFile.exists()) {
            return null; // Return null instead of throwing
          }

          // Copy to safe location
          final safeThumbnailFile = await originalFile.copy(safeThumbnailPath);

          // Clean up original thumbnail with problematic name
          try {
            await originalFile.delete();
          } catch (_) {
            debugPrint(
                'Failed to delete original thumbnail file: $originalPath');
          }

          return XFile(safeThumbnailFile.path);
        } catch (copyError) {
          debugPrint('Error copying thumbnail to safe location: $copyError');
          // Try to clean up failed safe file
          try {
            await File(safeThumbnailPath).delete();
          } catch (_) {
            debugPrint(
                'Failed to cleanup failed safe thumbnail: $safeThumbnailPath');
          }
          return null; // Return null instead of rethrowing
        }
      } else {
        debugPrint('Unhandled error in thumbnail processing: $e');
        return null; // Return null for any other errors
      }
    }
  }

  void _removeDuplicateMedia(List<MediaData> mediaDataList) {
    final uniqueMediaDataList = mediaDataList.toSet().toList();
    _mediaDataList.clear();
    _mediaDataList.addAll(uniqueMediaDataList);
  }
}
