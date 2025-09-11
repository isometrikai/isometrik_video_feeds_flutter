import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ism_video_reel_player_example/core/core.dart';
import 'package:ism_video_reel_player_example/di/injection_utils.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

part 'create_post_event.dart';
part 'create_post_state.dart';

class CreatePostBloc extends Bloc<CreatePostEvent, CreatePostState> {
  CreatePostBloc(
    this._createPostUseCase,
    this._getPostDetailsUseCase,
    this._localDataUseCase,
    this.googleCloudStorageUploaderUseCase,
    this.mediaProcessingUseCase,
  ) : super(CreatePostInitialState()) {
    on<CreatePostInitialEvent>(_initState);
    on<PostCreateEvent>(_createPost);
    on<PostAttributeNavigationEvent>(_goToPostAttributeView);
    on<MediaSourceEvent>(_openMediaSource);
    on<GetSocialPostDetailsEvent>(_getPostDetails);
    on<EditPostEvent>(_editPost);
    on<MediaUploadEvent>(_uploadMedia);
    on<MediaProcessingEvent>(_processMedia);
    on<RemoveMediaEvent>(_removeSelectedMedia);
  }

  final CreatePostUseCase _createPostUseCase;
  final GetPostDetailsUseCase _getPostDetailsUseCase;
  final LocalDataUseCase _localDataUseCase;
  final GoogleCloudStorageUploaderUseCase googleCloudStorageUploaderUseCase;
  final MediaProcessingUseCase mediaProcessingUseCase;

  var _createPostRequest = CreatePostRequest();
  var descriptionText = '';
  DateTime? selectedDate = DateTime.now().add(const Duration(hours: 1));
  var isScheduledPost = false;
  var _pageCount = 0;
  final List<ProductDataModel> _listOfProducts = [];
  List<ProductDataModel> linkedProducts = [];
  final List<ProductDataModel> _linkedSocialProducts = [];

  var _isDataLoading = false;
  var _searchQuery = '';
  final DeBouncer _deBouncer = DeBouncer();
  var _isCompressionRunning = false;

  CloudDetailsData? cloudDetailsData;
  TimeLineData? _postData;

  PostAttributeClass _postAttributeClass = PostAttributeClass();
  final List<MediaData> _mediaDataList = [];
  var _selectedMediaIndex = 0;
  var _tags = Tags();
  var _isForEdit = false;

  final List<MentionData> mentionedUserData = [];
  final List<MentionData> hashTagDataList = [];

  FutureOr<void> _initState(CreatePostInitialEvent event, Emitter<CreatePostState> emit) {
    _resetData();
    selectedDate = getBufferedDate();
    emit(CreatePostInitialState());
  }

  void resetApiCall() {
    isScheduledPost = false;
    _listOfProducts.clear();
    _pageCount = 0;
    _isDataLoading = false;
    _searchQuery = '';
  }

  // Reset all variables after successful post creation
  void _resetData() {
    // Dismiss keyboard
    _postAttributeClass = PostAttributeClass();
    FocusManager.instance.primaryFocus?.unfocus();
    _cancelCompression();
    _createPostRequest = CreatePostRequest();
    _mediaDataList.clear();
    _selectedMediaIndex = 0;
    isScheduledPost = false;
    _isForEdit = false;
    descriptionText = '';
    selectedDate = DateTime.now().add(const Duration(hours: 1));
    linkedProducts.clear();
    _linkedSocialProducts.clear();
    _tags = _createPostRequest.tags ?? Tags();
    _tags.products = [];
    resetApiCall();
  }

  Future<String> _uploadMediaToGoogleCloud(
    File? file,
    String fileName,
    MediaType? mediaType,
    Function(double) progressCallBackFunction,
    String folderName,
    String fileExtension,
  ) async {
    final myUserId = await _localDataUseCase.getUserId();
    final response = await googleCloudStorageUploaderUseCase.executeGoogleCloudStorageUploader(
        file: file!,
        fileName: fileName,
        fileExtension: fileExtension,
        userId: myUserId,
        onProgress: (progress) {
          debugPrint('_uploadMediaToGoogleCloud......progress: ${progress * 100}');
          progressCallBackFunction.call(progress * 100);
        });
    debugPrint('_uploadMediaToGoogleCloud: $response');
    return response ?? '';
  }

  String _getFileName(String? file, String fileType) {
    // Extract the file name
    // final fileName = path.basename(file!);
    // final fileName = path.basenameWithoutExtension(file!);
    final fileName = '${fileType}_media';

    // Combine the file type, timestamp, and modified file name
    // final newFileName = '${fileType}_$modifiedFileName';
    final newFileName = fileName;
    return newFileName;
  }

  String _getFileExtension(String filePath) {
    final extension = path.extension(filePath); // ".mp4"
    debugPrint('_getFileExtension: $extension');
    return extension;
  }

  FutureOr<void> _openMediaSource(MediaSourceEvent event, Emitter<CreatePostState> emit) async {
    var mediaInfoClass = <MediaInfoClass>[];

    if (event.mediaSource == MediaSource.camera) {
      final mediaInfo =
          await _pickFromFromCamera(event.context, event.mediaType, event.mediaSource);
      if (mediaInfo != null) {
        mediaInfoClass.add(mediaInfo);
      }
    }

    if (event.mediaSource == MediaSource.gallery && event.context.mounted) {
      if (AppConstants.isMultipleMediaSelectionEnabled) {
        final mediaList = await _pickMultipleMedia(event.context, event.mediaSource);
        mediaInfoClass = mediaList;
      } else {
        final mediaInfo = await _pickFromGallery(event.context, event.mediaType, event.mediaSource);
        if (mediaInfo != null) {
          mediaInfoClass.add(mediaInfo);
        }
      }
    }

    if (mediaInfoClass.isEmptyOrNull == false) {
      for (var i = 0; i < mediaInfoClass.length; i++) {
        // var mediaData = _mediaDataList.isEmptyOrNull == false ? _mediaDataList[i] : null;

        final mediaData =
            await _processMediaInfo(event.context, mediaInfoClass[i], emit, event.isCoverImage, i)
                as MediaData;

        final index =
            _mediaDataList.indexWhere((element) => event.mediaData?.localPath == element.localPath);
        if (index == -1) {
          _mediaDataList.add(mediaData);
        } else {
          _mediaDataList[i] = mediaData;
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
        for (var i = 0; i < _mediaDataList.length; i++) {
          final mediaData = _mediaDataList[i];
          if (mediaData.localPath.isEmptyOrNull == false) {
            final compressedFile = await _compressFile(
              File(mediaData.localPath ?? ''),
              event.mediaType,
              emit,
            );

            if (compressedFile != null) {
              _mediaDataList[i].localPath = compressedFile.path;
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

      debugPrint(
          'postAttribute list: ${jsonEncode(_mediaDataList.map((e) => e.toMap()).toList())}');
    }
  }

  bool _isPostButtonEnabled(List<MediaData>? mediaList) {
    var isPostButtonEnable = false;
    if (mediaList.isEmptyOrNull) return false;

    // Check if at least one media has valid localPath & previewUrl
    for (final media in mediaList!) {
      if (media.localPath.isEmptyOrNull == false && media.previewUrl.isEmptyOrNull == false) {
        isPostButtonEnable = true;
        break;
      }
    }
    return isPostButtonEnable;
  }

  Future<List<MediaInfoClass>> _pickMultipleMedia(
      BuildContext context, MediaSource mediaSource) async {
    final pickedMedia = <MediaInfoClass>[];

    try {
      final result = await ImagePicker().pickMultipleMedia();

      if (result.isNotEmpty) {
        for (final file in result) {
          final path = file.path;

          final isVideo = path.endsWith('.mp4') || path.endsWith('.mov');
          var duration = 0;

          if (isVideo) {
            final mediaInfo = await VideoCompress.getMediaInfo(path);
            duration = (mediaInfo.duration ?? 0).toInt();
          }

          pickedMedia.add(MediaInfoClass(
            duration: (duration / 1000).toInt(),
            mediaType: isVideo ? MediaType.video : MediaType.photo,
            mediaSource: mediaSource,
            mediaFile: XFile(path),
          ));
        }
      }
    } catch (e) {
      if (context.mounted) {
        Utility.showInSnackBar('Error picking media', context);
      }
    }
    return pickedMedia;
  }

  // Add this method in _CameraViewState
  Future<MediaInfoClass?> _pickFromFromCamera(
      BuildContext context, MediaType mediaType, MediaSource mediaSource) async {
    final picker = ImagePicker();
    try {
      XFile? file;
      var duration = 0;

      if (mediaType == MediaType.video) {
        file = await picker.pickVideo(
            source: ImageSource.camera, maxDuration: const Duration(seconds: 30));
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

  // Add this method in _CameraViewState
  Future<MediaInfoClass?> _pickFromGallery(
      BuildContext context, MediaType mediaType, MediaSource mediaSource) async {
    final picker = ImagePicker();
    try {
      XFile? file;
      var duration = 0;

      if (mediaType == MediaType.video) {
        file = await picker.pickVideo(
            source: ImageSource.gallery, maxDuration: const Duration(seconds: 30));
        if (file != null) {
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
      AppLog.error('Error picking video from gallery...${e.toString()}', stackTrace);
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
    // MediaData? mediaData,
  ) async {
    final newMediaData = MediaData();
    final mediaType = mediaInfoClass.mediaType;
    final mediaFile = File(mediaInfoClass.mediaFile?.path ?? '');

    if (mediaFile.path.isEmptyOrNull == false) {
      newMediaData.previewUrl = mediaFile.path;
      if (isForCoverImage == false) {
        newMediaData.assetId = '';
        newMediaData.size = mediaFile.lengthSync();
        newMediaData.localPath = mediaFile.path;
        newMediaData.duration = mediaInfoClass.duration;
        newMediaData.mediaType = mediaType == MediaType.video ? 'video' : 'image';
        if (mediaType == MediaType.video) {
          final videoThumbnailFile = await VideoThumbnail.thumbnailFile(
            video: mediaFile.path,
            quality: 50,
            thumbnailPath: (await getTemporaryDirectory()).path,
          );
          newMediaData.previewUrl =
              videoThumbnailFile.path.isEmptyOrNull ? '' : videoThumbnailFile.path;
        }

        final videoThumbnailFileBytes = await File(newMediaData.previewUrl ?? '').readAsBytes();
        newMediaData.videoThumbnailFileBytes = videoThumbnailFileBytes;
        newMediaData.fileName = _getFileName(
          mediaFile.path,
          mediaType == MediaType.video ? 'video' : 'image',
        );
        newMediaData.fileExtension = _getFileExtension(mediaFile.path);
        newMediaData.coverFileName = _getFileName(newMediaData.previewUrl, 'thumbnail');
        newMediaData.coverFileExtension = _getFileExtension(newMediaData.previewUrl ?? '');
      } else {
        final coverFileName = _getFileName(mediaFile.path, 'thumbnail');
        newMediaData.coverFileName = coverFileName;
        newMediaData.coverFileExtension = _getFileExtension(newMediaData.previewUrl ?? '');
      }
    }
    newMediaData.position = position + 1;
    return newMediaData;
  }

  FutureOr<void> _createPost(PostCreateEvent event, Emitter<CreatePostState> emit) async {
    if (event.createPostRequest == null) {
      _setPostRequest();
    }

    debugPrint('_createPostRequest....${jsonEncode(_createPostRequest)}');

    late ApiResult<CreatePostResponse?> apiResult;
    if (event.isForEdit == true) {
      apiResult = await _createPostUseCase.executeEditPost(
        isLoading: true,
        postId: _postData?.id ?? '',
        editPostRequest: _createPostRequest.toJson(),
      );
    } else {
      apiResult = await _createPostUseCase.executeCreatePost(
        isLoading: true,
        createPostRequest: _createPostRequest.toJson(),
      );
    }
    if (apiResult.isSuccess) {
      if (event.isForEdit == false) {
        _postData = null;
      }
      if (_postData != null) {
        _updatePostData();
      }
      final createPostData = apiResult.data?.data;
      add(MediaUploadEvent(mediaDataList: _mediaDataList, postId: createPostData?.id ?? ''));
    } else {
      ErrorHandler.showAppError(appError: apiResult.error, isNeedToShowError: true);
    }
  }

  void _updatePostData() {
    _postData?.tags = _createPostRequest.tags;
    _postData?.caption = _createPostRequest.caption;
    _postData?.media = _createPostRequest.media;
  }

  List<SocialProductData> _getSocialProductList(List<ProductDataModel> linkedProducts) {
    if (linkedProducts.isEmptyOrNull == true) return [];
    return linkedProducts.map((item) {
      final index = linkedProducts.indexOf(item);
      final dynamic productImages = item.images ?? item.modelImage;
      var imageUrl = productImages == null
          ? ''
          : (productImages is List<ImageData> && (productImages).isEmptyOrNull == false)
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
        id: item.childProductId,
        name: item.productName,
        imageUrl: imageUrl,
        price: item.finalPriceList?.finalPrice,
        brandName: item.brandTitle,
        discountPrice: item.finalPriceList?.discountPrice,
        currency: Currency(code: item.currency, symbol: item.currencySymbol),
        url: '',
        position: ProductPosition(
          mediaPosition: index + 1,
          x: 0.3,
          y: 0.8,
        ),
      );
    }).toList();
  }

  List<ProductDataModel> _getProductDataModel(List<SocialProductData> linkedProducts) {
    if (linkedProducts.isEmptyOrNull == true) return [];
    return linkedProducts
        .map((item) => ProductDataModel(
              childProductId: item.id,
              productName: item.name,
              productImage: item.imageUrl ?? '',
              finalPriceList: FinalPriceList(
                basePrice: item.price,
                finalPrice: item.price,
                discountPrice: item.discountPrice,
              ),
              brandTitle: item.brandName,
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
    final apiResult = await _getPostDetailsUseCase.executeGetPostDetails(
      isLoading: false,
      postId: event.postId,
      page: 1,
      limit: 20,
    );
    if (apiResult.isSuccess) {
      totalProductsCount = apiResult.data?.count?.toInt() ?? 0;
      _linkedSocialProducts.clear();
      _linkedSocialProducts.addAll(apiResult.data?.data as Iterable<ProductDataModel>);
      _tags.products = _getSocialProductList(_linkedSocialProducts);
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
  FutureOr<void> _editPost(EditPostEvent event, Emitter<CreatePostState> emit) async {
    emit(CreatePostInitialState(isLoading: true));
    _postData = event.postData;
    _mediaDataList.clear();
    _mediaDataList.addAll(_postData?.media ?? []);
    for (var element in _mediaDataList) {
      element.fileName = _extractFileName(element.url ?? '');
      element.localPath = element.url ?? '';
      element.previewUrl = element.mediaType?.mediaType == MediaType.photo
          ? (element.url ?? '')
          : element.previewUrl ?? '';
    }
    if (_postData?.tags?.products.isEmptyOrNull == false) {
      final socialProductList = _postData?.tags?.products;
      linkedProducts = _getProductDataModel(socialProductList ?? []);
      emit(
        LoadLinkedProductsState(
          productList: linkedProducts,
          totalProductsCount: linkedProducts.length,
        ),
      );
    }
    _isForEdit = true;
    _makePostRequest();
    emit(MediaSelectedState(mediaDataList: _mediaDataList, isPostButtonEnable: false));
  }

  String _extractFileName(String url) {
    final uri = Uri.parse(url);
    final fullName = uri.pathSegments.last;
    final nameWithoutExt = fullName.split('.').first;
    return nameWithoutExt;
  }

  void _makePostRequest() {
    descriptionText = _postData?.caption ?? '';
  }

  bool checkForChangesInLinkedProducts(List<ProductDataModel> linkedProducts) {
    final hasChanges = linkedProducts.length != _linkedSocialProducts.length ||
        linkedProducts.any((product) => !_linkedSocialProducts
            .any((existingProduct) => existingProduct.childProductId == product.childProductId));
    _tags.products = _getSocialProductList(linkedProducts);
    debugPrint('hasChanges: $hasChanges');
    return hasChanges;
  }

  Future<File?> _compressFile(
      File? file, MediaType mediaType, Emitter<CreatePostState> emit) async {
    final fileLength = await file?.length();
    final fileSizeBeforeCompression = fileLength ?? 0 / (1024 * 1024);
    _isCompressionRunning = true;
    debugPrint('_compressFile......File size before compression: $fileSizeBeforeCompression mb');

    final compressedFile = await MediaCompressor.compressMedia(
      file!,
      isVideo: mediaType == MediaType.video,
      onProgress: (progress) {
        debugPrint('Compression progress: $progress');
        if (_isCompressionRunning) {
          emit(CompressionProgressState(mediaKey: file.path, progress: progress));
        }
      },
    );
    if (compressedFile == null) {
      return file;
    }
    final fileSizeAfterCompression = (await compressedFile.length()) / (1024 * 1024);
    debugPrint('_compressFile......File size after compression: $fileSizeAfterCompression mb');
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

  FutureOr<void> _uploadMedia(MediaUploadEvent event, Emitter<CreatePostState> emit) async {
    if (_mediaDataList.isEmptyOrNull == false) {
      for (var index = 0; index < _mediaDataList.length; index++) {
        final mediaData = _mediaDataList[index];
        if (mediaData.localPath.isEmptyOrNull == false &&
            Utility.isLocalUrl(mediaData.localPath ?? '')) {
          mediaData.url = await _uploadMediaToGoogleCloud(
            File(mediaData.localPath ?? ''),
            mediaData.fileName ?? '',
            mediaData.mediaType?.mediaType,
            (progress) {
              emit(ShowProgressDialogState(
                progress: progress,
                title: mediaData.mediaType?.mediaType == MediaType.photo
                    ? TranslationFile.uploadingImage
                    : TranslationFile.uploadingVideo,
                subTitle: 'Uploading media...',
              ));
            },
            _mediaDataList[_selectedMediaIndex].mediaType?.mediaType == MediaType.photo
                ? AppConstants.cloudinaryImageFolder
                : AppConstants.cloudinaryVideoFolder,
            mediaData.fileExtension ?? '',
          );
        }
        _mediaDataList[index] = mediaData;
      }
    }
    final isMediaChanged = _isMediaChanged();
    if (isMediaChanged) {
      add(MediaProcessingEvent(postId: event.postId));
    } else {
      if (_isForEdit) {
        _updatePostData();
      } else {
        await _createPostData(event.postId);
      }
      emit(PostCreatedState(
        postDataModel: _isForEdit ? jsonEncode(_postData?.toMap()) : null,
        postSuccessMessage: _isForEdit
            ? TranslationFile.postUpdatedSuccessfully
            : isScheduledPost
                ? TranslationFile.postScheduledSuccessfully
                : TranslationFile.socialPostCreatedSuccessfully,
        postSuccessTitle: _isForEdit
            ? TranslationFile.successfullyEdited
            : isScheduledPost
                ? TranslationFile.successfullyScheduled
                : TranslationFile.successfullyPosted,
        mediaDataList: _createPostRequest.media,
      ));
    }
  }

  bool _isMediaChanged() => _mediaDataList.any((mediaData) =>
      mediaData.localPath.isEmptyOrNull == false && Utility.isLocalUrl(mediaData.localPath ?? ''));

  FutureOr<void> _processMedia(MediaProcessingEvent event, Emitter<CreatePostState> emit) async {
    final apiResult = await mediaProcessingUseCase.executeMediaProcessing(
      isLoading: true,
      postId: event.postId,
    );
    if (apiResult.isSuccess) {
      if (_isForEdit) {
        _updatePostData();
      } else {
        await _createPostData(event.postId);
      }
      emit(PostCreatedState(
        postDataModel: _isForEdit ? jsonEncode(_postData?.toMap()) : null,
        postSuccessMessage: _isForEdit
            ? TranslationFile.postUpdatedSuccessfully
            : isScheduledPost
                ? TranslationFile.postScheduledSuccessfully
                : TranslationFile.socialPostCreatedSuccessfully,
        postSuccessTitle: _isForEdit
            ? TranslationFile.successfullyEdited
            : isScheduledPost
                ? TranslationFile.successfullyScheduled
                : TranslationFile.successfullyPosted,
        mediaDataList: _createPostRequest.media,
      ));
      _resetData();
    } else {
      ErrorHandler.showAppError(appError: apiResult.error, isNeedToShowError: true);
    }
  }

  Future<void> _createMediaUrls() async {
    if (_mediaDataList.isEmptyOrNull == false) {
      final userId = await _localDataUseCase.getUserId();
      for (var index = 0; index < _mediaDataList.length; index++) {
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
          if (mediaData.mediaType?.mediaType == MediaType.photo) {
            mediaData.previewUrl = mediaData.url;
          } else {
            if (mediaData.previewUrl.isEmptyOrNull == false &&
                Utility.isLocalUrl(mediaData.previewUrl ?? '')) {
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

  Future<void> _createPostData(String postId) async {
    final myUserId = await _localDataUseCase.getUserId();
    final userName = await _localDataUseCase.getFirstName();
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

  FutureOr<void> _removeSelectedMedia(RemoveMediaEvent event, Emitter<CreatePostState> emit) {
    _mediaDataList.remove(event.mediaData);
    CoverImageSelected(
      coverImage:
          _mediaDataList.isEmptyOrNull ? '' : _mediaDataList[_selectedMediaIndex].previewUrl,
      isPostButtonEnable: _isPostButtonEnabled(_mediaDataList),
    );
    emit(MediaSelectedState(
        mediaDataList: _mediaDataList, isPostButtonEnable: _isPostButtonEnabled(_mediaDataList)));
  }

  FutureOr<void> _goToPostAttributeView(
      PostAttributeNavigationEvent event, Emitter<CreatePostState> emit) async {
    _setPostRequest();
    _postAttributeClass.mentionedUserList = mentionedUserData;
    _postAttributeClass.tagDataList = hashTagDataList;
    _postAttributeClass.mediaDataList = _mediaDataList;
    _postAttributeClass.createPostRequest = _createPostRequest;
    _postAttributeClass = await InjectionUtils.getRouteManagement()
            .goToPostAttributionView(postAttributeClass: _postAttributeClass) ??
        _postAttributeClass;
    debugPrint('post attribution...$_postAttributeClass');
  }

  void _setPostRequest() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await _createMediaUrls();

    if (_mediaDataList.isEmptyOrNull == true) {
      return;
    }
    _createPostRequest.media = _mediaDataList;

    _createPostRequest.type = _mediaDataList.length > 1
        ? SocialPostType.carousel
        : _mediaDataList[_selectedMediaIndex].mediaType?.mediaType == MediaType.video
            ? SocialPostType.video
            : SocialPostType.image;
    _createPostRequest.visibility = SocialPostVisibility.public;
    _createPostRequest.caption = descriptionText;

    if (_isForEdit == false && isScheduledPost && selectedDate != null) {
      // Check if selected date is today
      if (DateTimeUtil.isTodayDate(selectedDate!)) {
        // If it's today, ensure time is at least one hour later
        final oneHourLater = getBufferedDate();
        if (selectedDate!.isBefore(oneHourLater)) {
          selectedDate = oneHourLater;
        }
      }
      _createPostRequest.scheduleTime =
          DateTimeUtil.getIsoDate(selectedDate!.millisecondsSinceEpoch);
      _createPostRequest.visibility = SocialPostVisibility.scheduled;
    }

    // _createPostRequest.tags = _tags;
  }
}
