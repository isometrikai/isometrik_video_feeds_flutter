import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ism_video_reel_player_example/core/core.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

// import 'package:video_compress/video_compress.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';

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
    on<MediaSourceEvent>(_openMediaSource);
    on<GetSocialPostDetailsEvent>(_getPostDetails);
    on<EditPostEvent>(_editPost);
    on<MediaUploadEvent>(_uploadMedia);
    on<MediaProcessingEvent>(_processMedia);
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

  // PostAttributeClass? _postAttributeClass;
  final List<MediaData> _mediaDataList = [];
  var _selectedMediaIndex = 0;
  var _tags = Tags();
  var _isForEdit = false;

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

  void _resetData() {
    // Dismiss keyboard
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
    MediaInfoClass? mediaInfoClass;
    if (event.mediaSource == MediaSource.camera) {
      /*mediaInfoClass = await InjectionUtils.getRouteManagement().goToCameraView(
        context: event.context,
        mediaType: event.mediaType,
      );*/
      mediaInfoClass = await _pickFromFromCamera(event.context, event.mediaType, event.mediaSource);
    }
    if (event.mediaSource == MediaSource.gallery && event.context.mounted) {
      mediaInfoClass = await _pickFromGallery(event.context, event.mediaType, event.mediaSource);
    }
    if (mediaInfoClass != null) {
      // _postAttributeClass ??= PostAttributeClass();
      // _postAttributeClass?.isCoverImage = event.isCoverImage;
      var mediaData =
          _mediaDataList.isEmptyOrNull == false ? _mediaDataList[_selectedMediaIndex] : null;
      mediaData = await _processMediaInfo(
          event.context, mediaInfoClass, emit, event.isCoverImage, mediaData);
      if (_mediaDataList.isEmptyOrNull == false && _mediaDataList.length >= _selectedMediaIndex) {
        _mediaDataList[_selectedMediaIndex] = mediaData!;
      } else {
        _mediaDataList.add(mediaData!);
      }
      emit(
        event.isCoverImage
            ? CoverImageSelected(
                coverImage: _mediaDataList[_selectedMediaIndex].previewUrl,
                isPostButtonEnable: mediaData.localPath.isEmptyOrNull == false &&
                    mediaData.previewUrl.isEmptyOrNull == false,
              )
            : MediaSelectedState(
                mediaDataList: _mediaDataList,
                isPostButtonEnable: mediaData.localPath.isEmptyOrNull == false &&
                    mediaData.previewUrl.isEmptyOrNull == false,
              ),
      );

      if (AppConstants.isCompressionEnable &&
          _mediaDataList[_selectedMediaIndex].localPath.isEmptyOrNull == false) {
        final compressedFile =
            await _compressFile(File(mediaData.localPath ?? ''), event.mediaType, emit);
        _mediaDataList[_selectedMediaIndex].localPath = compressedFile?.path;
      }
      emit(
        event.isCoverImage
            ? CoverImageSelected(
                coverImage: _mediaDataList[_selectedMediaIndex].previewUrl,
                isPostButtonEnable: mediaData.localPath.isEmptyOrNull == false &&
                    mediaData.previewUrl.isEmptyOrNull == false,
              )
            : MediaSelectedState(
                mediaDataList: _mediaDataList,
                isPostButtonEnable: mediaData.localPath.isEmptyOrNull == false &&
                    mediaData.previewUrl.isEmptyOrNull == false,
              ),
      );
      debugPrint('postAttribute: ${jsonEncode(mediaData.toMap())}');
      debugPrint('postAttribute local path: ${mediaData.localPath}');
    }
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
    } catch (e) {
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
    MediaData? mediaData,
  ) async {
    final newMediaData = mediaData ?? MediaData();
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
    newMediaData.position = mediaData == null
        ? _selectedMediaIndex == 0
            ? 1
            : _selectedMediaIndex
        : mediaData.position;
    return newMediaData;
  }

  FutureOr<void> _createPost(PostCreateEvent event, Emitter<CreatePostState> emit) async {
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
    _createPostRequest.visibility = 'public';
    _createPostRequest.caption = descriptionText;

    if (event.isForEdit == false && isScheduledPost && selectedDate != null) {
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
      _createPostRequest.visibility = 'scheduled';
    }

    _createPostRequest.tags = _tags;

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
      final postDataModelResponse =
          _postData != null ? jsonEncode(_postData?.toMap()) : jsonEncode(createPostData?.toJson());
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

  /// search product
  void searchProduct(String query) {
    resetApiCall();
    _deBouncer.run(() {
      _searchQuery = query;
      add(GetProductsEvent());
    });
  }

  List<String>? _getProductIds(List<ProductDataModel> linkedProducts) {
    final productIds = <String>[];
    for (final product in linkedProducts) {
      productIds.add(product.childProductId ?? '');
    }
    return productIds;
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
        if (_isCompressionRunning) {
          emit(CompressionProgressState(progress: progress));
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
      }
      emit(PostCreatedState(
        postDataModel: jsonEncode(_postData?.toMap()),
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
      }
      emit(PostCreatedState(
        postDataModel: _isForEdit ? jsonEncode(_postData?.toMap()) : '',
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
          final finalFileName = '${mediaData.fileName}_${DateTime.now().millisecondsSinceEpoch}';
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
                  '${mediaData.coverFileName}_${DateTime.now().millisecondsSinceEpoch}';
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
}
