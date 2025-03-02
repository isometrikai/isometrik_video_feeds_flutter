import 'dart:async';
import 'dart:io';

import 'package:cloudinary/cloudinary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player_example/core/core.dart';
import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

part 'create_post_event.dart';
part 'create_post_state.dart';

class CreatePostBloc extends Bloc<CreatePostEvent, CreatePostState> {
  CreatePostBloc(
    this._createPostUseCase,
    this._getCloudDetailsUseCase,
  ) : super(CreatePostInitialState()) {
    on<PostCreateEvent>(_createPost);
    on<MediaSourceEvent>(_openMediaSource);
  }

  final CreatePostUseCase _createPostUseCase;
  final GetCloudDetailsUseCase _getCloudDetailsUseCase;

  final _createPostRequest = CreatePostRequest();
  final descriptionController = TextEditingController();

  CloudDetailsData? cloudDetailsData;

  Future<void> _getCloudDetails() async {
    final apiResult = await _getCloudDetailsUseCase.executeGetCloudDetails(
      key: 'folder',
      value: '${AppConstants.cloudinaryFolder}/${DateTime.now().millisecondsSinceEpoch}',
      isLoading: false,
    );
    if (apiResult.isSuccess) {
      cloudDetailsData = apiResult.data?.data;
    }
  }

  Future<String> _uploadImageToCloud(
    String? filePath,
    String fileName,
    Emitter<CreatePostState> emit,
    bool isCoverImage,
  ) async {
    var finalUrl = '';
    final cloudinary = CloudinaryHandler.getCloudinary(
      apiKey: cloudDetailsData?.apiKey ?? '',
      apiSecret: cloudDetailsData?.apiSecretKey ?? '',
      cloudName: cloudDetailsData?.cloudName ?? '',
    );

    if (cloudinary != null) {
      final response = await CloudinaryHandler.uploadMedia(
          cloudinary: cloudinary,
          file: File(filePath!),
          fileName: fileName,
          cloudinaryCustomFolder: AppConstants.cloudinaryFolder,
          resourceType: CloudinaryResourceType.image,
          progressCallback: (count, total) {
            final progress = (count * 100) / total;
            emit(isCoverImage ? UploadingCoverImageState(progress) : UploadingMediaState(progress));
          },
          onError: (error) {
            Utility.showAppError(message: 'Error uploading image: $error', errorViewType: ErrorViewType.toast);
          });
      if (response != null) {
        finalUrl = response.secureUrl ?? '';
        return finalUrl;
      }
    }
    Utility.closeProgressDialog();
    return finalUrl;
  }

  String _getFileName(String? file, String fileType) {
    // Extract the file name
    // final fileName = path.basename(file!);
    final fileName = path.basenameWithoutExtension(file!);

    // Get the current timestamp (in milliseconds)
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    // Modify the file name (convert to lowercase and replace spaces with hyphens)
    final modifiedFileName = fileName.toLowerCase().replaceAll(' ', '-');

    // Combine the file type, timestamp, and modified file name
    final newFileName = '$fileType-$timestamp-$modifiedFileName';
    return newFileName;
  }

  FutureOr<void> _openMediaSource(MediaSourceEvent event, Emitter<CreatePostState> emit) async {
    MediaInfoClass? mediaInfoClass;
    if (event.mediaSource == MediaSource.camera) {
      mediaInfoClass =
          await InjectionUtils.getRouteManagement().goToCameraView(context: event.context, mediaType: event.mediaType);
    }
    if (event.mediaSource == MediaSource.gallery && event.context.mounted) {
      mediaInfoClass = await _pickFromGallery(event.context, event.mediaType, event.mediaSource);
    }
    if (mediaInfoClass != null) {
      final postAttributeClass = await _processMediaInfo(event.context, mediaInfoClass, emit);
      emit(
        event.isCoverImage
            ? CoverImageSelected(coverImage: postAttributeClass?.url)
            : MediaSelectedState(postAttributeClass: postAttributeClass),
      );
      if (cloudDetailsData == null) {
        await _getCloudDetails();
      }
      if (cloudDetailsData == null) return;

      if (event.isCoverImage) {
        final fileName = _getFileName(postAttributeClass?.coverImage, 'thumbnail');
        final cloudinaryImageUrl = await _uploadImageToCloud(postAttributeClass?.coverImage, fileName, emit, true);
        if (cloudinaryImageUrl.isEmptyOrNull == true) {
          Utility.showInSnackBar('Error uploading image', event.context);
          return;
        }
        _createPostRequest.thumbnailUrl = cloudinaryImageUrl;
      } else {
        _createPostRequest.mediaType = postAttributeClass?.postType?.mediaType;
        _createPostRequest.duration = postAttributeClass?.duration;
        _createPostRequest.description = descriptionController.text;
        _createPostRequest.cloudinaryPublicId = cloudDetailsData?.publicId;
        _createPostRequest.size = postAttributeClass?.size;

        final fileName =
            _getFileName(postAttributeClass?.url, postAttributeClass?.postType == MediaType.photo ? 'photo' : 'video');
        _createPostRequest.fileName = fileName;

        if (postAttributeClass?.postType == MediaType.photo) {
          final cloudinaryImageUrl = await _uploadImageToCloud(postAttributeClass?.url, fileName, emit, false);
          if (cloudinaryImageUrl.isEmptyOrNull == true) {
            Utility.showInSnackBar('Error uploading image', event.context);
            return;
          }
          _createPostRequest.imageUrl = cloudinaryImageUrl;
          _createPostRequest.thumbnailUrl = _createPostRequest.imageUrl;
          if (_createPostRequest.thumbnailUrl?.contains('media_') == true) {
            _createPostRequest.thumbnailUrl = _createPostRequest.thumbnailUrl!.replaceAll('photo_', 'thumbnail_');
          }
        } else {
          final cloudinaryVideoUrl = await _uploadImageToCloud(postAttributeClass?.url, fileName, emit, false);
          if (cloudinaryVideoUrl.isEmptyOrNull == true) {
            Utility.showInSnackBar('Error uploading video', event.context);
            return;
          }
          _createPostRequest.url = cloudinaryVideoUrl;
          final coverFileName = _getFileName(postAttributeClass?.thumbnailUrl, 'thumbnail');
          _createPostRequest.thumbnailUrl =
              await _uploadImageToCloud(postAttributeClass?.thumbnailUrl, coverFileName, emit, true);
        }
      }
    }
    debugPrint('createPostRequest: ${_createPostRequest.toJson()}');
  }

// Add this method in _CameraViewState
  Future<MediaInfoClass?> _pickFromGallery(BuildContext context, MediaType mediaType, MediaSource mediaSource) async {
    final picker = ImagePicker();
    try {
      XFile? file;
      if (mediaType == MediaType.video) {
        file = await picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(seconds: 30),
        );
      } else if (mediaType == MediaType.photo) {
        file = await picker.pickImage(
          source: ImageSource.gallery,
        );
      }

      if (file != null && file.path.isEmptyOrNull == false) {
        debugPrint('Selected media path: ${file.path}');
        final mediaInfoClass = MediaInfoClass(
          duration: 0,
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
      debugPrint('Error picking video: $e');
    }
    return null;
  }

  FutureOr<PostAttributeClass?> _processMediaInfo(
      BuildContext context, MediaInfoClass mediaInfoClass, Emitter<CreatePostState> emit) async {
    final postAttributeClass = PostAttributeClass();
    final mediaType = mediaInfoClass.mediaType;
    final mediaFile = mediaInfoClass.mediaFile;

    if (mediaFile?.path.isEmptyOrNull == false) {
      postAttributeClass.file = File(mediaFile?.path ?? '');
      postAttributeClass.size = postAttributeClass.file?.lengthSync();
      postAttributeClass.url = mediaFile?.path;
      postAttributeClass.coverImage = mediaFile?.path;

      if (postAttributeClass.file == null || postAttributeClass.file?.path.isEmptyOrNull == true) return null;

      postAttributeClass.duration = mediaInfoClass.duration;
      postAttributeClass.postType = mediaType;

      if (mediaType == MediaType.video) {
        final trimmedVideoThumbnailPath = await VideoThumbnail.thumbnailFile(
              video: postAttributeClass.file?.path ?? '',
              imageFormat: ImageFormat.PNG,
              quality: 50,
              thumbnailPath: (await getTemporaryDirectory()).path,
            ) ??
            '';
        if (trimmedVideoThumbnailPath.isEmpty) return null;
        final trimmedVideoThumbnailBytes = await File(trimmedVideoThumbnailPath).readAsBytes();
        postAttributeClass.thumbnailUrl = trimmedVideoThumbnailPath;
        postAttributeClass.coverImage = trimmedVideoThumbnailPath;
        postAttributeClass.thumbnailBytes = trimmedVideoThumbnailBytes;
        // if (context.mounted) {
        //   postAttributeClass = await InjectionUtils.getRouteManagement()
        //       .goToVideoTrimView(context: context, postAttributeClass: postAttributeClass);
        // }
      }
    }
    return postAttributeClass;
  }

  FutureOr<void> _createPost(PostCreateEvent event, Emitter<CreatePostState> emit) async {
    _createPostRequest.description = descriptionController.text;
    if (_createPostRequest.imageUrl == null && _createPostRequest.url == null) {
      Utility.showAppError(message: 'Select a media file', errorViewType: ErrorViewType.toast);
      return;
    }
    if (_createPostRequest.thumbnailUrl.isEmptyOrNull == true) {
      Utility.showAppError(message: 'Select a cover', errorViewType: ErrorViewType.toast);
      return;
    }
    final apiResult = await _createPostUseCase.executeCreatePost(
      isLoading: true,
      createPostRequest: _createPostRequest.toJson(),
    );
    if (apiResult.isSuccess) {
      final createPostData = apiResult.data?.newData;
      final postDataModel = createPostData == null ? null : PostDataModel.fromJson(createPostData.toJson());

      emit(PostCreatedState(postDataModel: postDataModel));
    } else {
      ErrorHandler.showAppError(appError: apiResult.error, isNeedToShowError: true);
    }
  }
}
