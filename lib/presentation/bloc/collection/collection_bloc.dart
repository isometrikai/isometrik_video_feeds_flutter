import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:path/path.dart' as path;

part 'collection_event.dart';
part 'collection_state.dart';

class CollectionBloc extends Bloc<CollectionEvent, CollectionState> {
  CollectionBloc(
    this._userCollectionsUseCase,
    this.getSavedPostDataUseCase,
    this.localDataUseCase,
    this.googleCloudStorageUploaderUseCase,
  ) : super(CollectionInitState()) {
    on<CollectionInitEvent>((event, emit) {
      emit(CollectionInitState());
    });
    on<GetUserCollectionEvent>(getUserCollection);
    on<CreateUserCollectionEvent>(createUserCollection);
    on<EditUserCollectionEvent>(editUserCollection);
    on<ModifyUserCollectionEvent>(modifyUserCollection);
    on<CollectionImageUploadEvent>(collectionImageUpload);
    on<SavePostActionEvent>(_savePostAction);
    on<GetSavedPostEvent>(getSavedPost);
    on<MoveToCollectionEvent>(moveToCollection);
    on<GetCollectionPostsEvent>(_getCollectionPosts);
    on<DeleteCollectionEvent>(_deleteCollection);
    on<RemovePostFromCollectionEvent>(_removePostFromCollection);
  }

  final CollectionUseCase _userCollectionsUseCase;
  final SavePostUseCase getSavedPostDataUseCase;
  final IsmLocalDataUseCase localDataUseCase;
  final GoogleCloudStorageUploaderUseCase googleCloudStorageUploaderUseCase;

  /// Image picker
  final ImagePicker picker = ImagePicker();

  /// Image file
  File? imageFile;

  /// Cropped Profile Image.
  File? croppedProfileImage;

  String? uploadedImageUrl;

  ///Get user collection list
  Future<void> getUserCollection(
      GetUserCollectionEvent event, Emitter<CollectionState> emit) async {
    emit(UserCollectionLoadingState());
    final apiResult = await _userCollectionsUseCase.executeGetCollectionList(
      isLoading: false,
      page: event.skip,
      pageSize: event.limit,
      isPublicOnly: false,
    );
    if (apiResult.isSuccess) {
      emit(
          UserCollectionFetchState(collectionList: apiResult.data?.data ?? []));
    } else {
      emit(UserCollectionErrorState(apiResult.error?.message ?? ''));
    }
  }

  ///Modify user collection
  modifyUserCollection(
      ModifyUserCollectionEvent event, Emitter<CollectionState> emit) async {
    emit(ModifyUserCollectionLoadingState());
    final apiResult =
        await _userCollectionsUseCase.executeModifyUserCollectionList(
      isLoading: false,
      collectionId: event.collectionId,
      requestMap: event.collectionRequestModel.toJson(),
    );
    if (apiResult.isSuccess) {
      emit(ModifyUserCollectionSuccessState(
        isPost: event.isPost,
        action: event.collectionRequestModel.action,
        collectionNames: event.collectionRequestModel.collectionName ?? [],
      ));
    } else {
      emit(ModifyUserCollectionErrorState(apiResult.error?.message ?? ''));
    }
  }

  ///Create user collection
  void createUserCollection(
      CreateUserCollectionEvent event, Emitter<CollectionState> emit) async {
    emit(CreateCollectionLoadingState());
    final apiResult =
        await _userCollectionsUseCase.executeCreateUserCollectionList(
      isLoading: false,
      requestMap: event.createCollectionRequestModel.toJson(),
    );
    if (apiResult.isSuccess) {
      final response = apiResult.data;
      if (response != null) {
        final collectionId = response.data.isNotEmpty
            ? jsonDecode(response.data)['collectionId'] == null
                ? ''
                : jsonDecode(response.data)['collectionId'] as String
            : '';

        emit(CreateCollectionSuccessState(
          message:
              '${event.createCollectionRequestModel.name} ${IsrTranslationFile.createdSuccessfully}',
          collectionId: collectionId,
        ));
      } else {
        emit(CreateCollectionErrorState(apiResult.error?.message ?? ''));
      }
    } else {
      emit(CreateCollectionErrorState(IsrTranslationFile.somethingWentWrong));
    }
  }

  ///Edit user collection
  editUserCollection(
      EditUserCollectionEvent event, Emitter<CollectionState> emit) async {
    emit(EditCollectionLoadingState());
    final apiResult =
        await _userCollectionsUseCase.executeModifyUserCollectionList(
      isLoading: false,
      collectionId: event.collectionId,
      requestMap: event.editedCollectionRequestModel.toJson(),
    );
    if (apiResult.isSuccess) {
      emit(EditCollectionSuccessState(
          editCollectionRequestModel: event.editedCollectionRequestModel,
          message:
              '${event.editedCollectionRequestModel.name} ${IsrTranslationFile.updatedSuccessfully}'));
    } else {
      emit(EditCollectionErrorState(apiResult.error?.message ?? ''));
    }
  }

  //Upload Image for create collection
  void collectionImageUpload(
      CollectionImageUploadEvent event, Emitter<CollectionState> emit) async {
    final pickedFile = await picker.pickImage(source: event.imageSource!);
    if (pickedFile == null || pickedFile.path.isEmpty) {
      return;
    }
    final imageFile = File(pickedFile.path);
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Choose Image',
            toolbarColor: IsrColors.white,
            toolbarWidgetColor: IsrColors.black,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: true,
            cropStyle: CropStyle.rectangle,
            aspectRatioPresets: [CropAspectRatioPreset.square]),
        IOSUiSettings(
          minimumAspectRatio: 1.0,
          title: 'Choose Image',
          cropStyle: CropStyle.rectangle,
        ),
      ],
    );

    if (croppedFile == null) {
      emit(CollectionImageUpdateErrorState('Image cropping canceled.'));
      return;
    }

    croppedProfileImage = await _compressFile(
      File(croppedFile.path),
    );
    emit(CollectionImageLoadingState());

    if (croppedProfileImage == null) {
      emit(CollectionImageUpdateErrorState('Image compression failed.'));
      return;
    }

    try {
      final uploadedImageUrl = await _uploadMediaToGoogleCloud(
        croppedProfileImage,
        'collection_image_${DateTime.now().millisecondsSinceEpoch}',
        MediaType.photo,
            (progress) {},
        AppConstants.cloudinaryImageFolder,
        path.extension(croppedProfileImage!.path),
      );

      if (uploadedImageUrl.isNotEmpty) {
        emit(CollectionImageUpdateSuccessState(
          imageString: uploadedImageUrl,
          localFile: croppedProfileImage!,
        ));
      } else {
        emit(CollectionImageUpdateErrorState('Image upload failed.'));
      }
    } catch (e) {
      debugPrint('Image upload error: $e');
      emit(CollectionImageUpdateErrorState('Image upload failed.'));
    }
  }

  Future<String> _uploadMediaToGoogleCloud(
      File? file,
      String fileName,
      MediaType? mediaType,
      Function(double) progressCallBackFunction,
      String folderName,
      String fileExtension,
      ) async {
    final customUpload =
        IsrVideoReelConfig.socialConfig.socialCallBackConfig?.uploadMediaToCloud;
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
      final myUserId = await localDataUseCase.getUserId();
      var mainProgress = 0;
      try {
        final response = await googleCloudStorageUploaderUseCase.executeGoogleCloudStorageUploader(
            file: file!,
            fileName: fileName,
            fileExtension: fileExtension,
            userId: myUserId,
            onProgress: (_) {
              final progress = (_ * 100).toInt();
              if (mainProgress != progress) {
                mainProgress = progress;
                debugPrint('_uploadMediaToGoogleCloud......progress: $progress');
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

  String _applyConvertToGumletUrl(String mediaUrl) {
    if (mediaUrl.isEmpty) return mediaUrl;
    final convert =
        IsrVideoReelConfig.socialConfig.socialCallBackConfig?.convertToGumletUrl;
    if (convert == null) return mediaUrl;
    try {
      final converted = convert(mediaUrl);
      if (converted.isNotEmpty) return converted;
    } catch (e) {
      debugPrint('convertToGumletUrl error: $e');
    }
    return mediaUrl;
  }

  FutureOr<void> _savePostAction(
      SavePostActionEvent event, Emitter<CollectionState> emit) async {
    emit(SavePostLoadingState(postId: event.postId));
    final isLoggedIn = await isUserLoggedIn();
    if (!isLoggedIn) {
      return;
    }
    final apiResult = await getSavedPostDataUseCase.executeSavePost(
      isLoading: false,
      postId: event.postId,
      socialPostAction:
          event.isSaved ? SocialPostAction.unSave : SocialPostAction.save,
    );
    if (apiResult.isSuccess) {
      emit(SavePostSuccessState(
          postId: event.postId,
          socialPostAction:
              event.isSaved ? SocialPostAction.unSave : SocialPostAction.save));
    } else {
      emit(SavePostErrorState(
        message:
            apiResult.error?.message ?? IsrTranslationFile.somethingWentWrong,
      ));
    }
  }

  FutureOr<void> getSavedPost(
      GetSavedPostEvent event, Emitter<CollectionState> emit) async {
    emit(SavedPostDataLoadingState());
    final profilePic = await localDataUseCase.getProfilePic();
    final apiResult =
        await getSavedPostDataUseCase.executeGetProfileSavedPostData(
      isLoading: false,
      page: event.skip,
      pageSize: event.limit,
    );
    if (apiResult.isSuccess) {
      emit(SavedPostDataSuccessState(
        totalPosts: apiResult.data?.total ?? 0,
        profilePic: profilePic,
      ));
    } else {
      if (apiResult.statusCode == 204) {
        emit(SavedPostDataSuccessState(
          totalPosts: 0,
          profilePic: profilePic,
        ));
      } else {
        emit(SavedPostDataErrorState());
      }
    }
  }

  Future<void> addOrRemoveSavedPostToLocal(
      String postId, SocialPostAction socialPostAction) async {
    // final savedPosts = await localDataUseCase.getListOfSavedPost();
    // if (socialPostAction == SocialPostAction.save) {
    //   if (!savedPosts.contains(postId)) {
    //     savedPosts.add(postId);
    //     localDataUseCase.saveListOfPost(savedPosts);
    //   }
    // } else if (socialPostAction == SocialPostAction.unSave) {
    //   if (savedPosts.contains(postId)) {
    //     savedPosts.remove(postId);
    //     localDataUseCase.saveListOfPost(savedPosts);
    //   }
    // }
  }

  Future<bool> isUserLoggedIn() async {
    var isLoggedIn = await localDataUseCase.isLoggedIn();
    // if (!isLoggedIn) {
    //   await InjectionUtils.getRouteManagement().goToAuthView();
    //   isLoggedIn = await localDataUseCase.isLoggedIn();
    // }
    return isLoggedIn;
  }

  Future<File?> _compressFile(File? file) async {
    if (file == null) return null;

    final fileLength = await file.length();
    final fileSizeBeforeCompression = fileLength / (1024 * 1024);

    debugPrint(
        '_uploadImageToCloud → File size before compression: ${fileSizeBeforeCompression.toStringAsFixed(2)} MB');

    final compressedFile = await MediaCompressor.compressMedia(
      file,
      isVideo: false,
      onProgress: (progress) {},
    );

    if (compressedFile == null) {
      debugPrint(
          '_uploadImageToCloud → Compression failed, returning original file.');
      return file;
    }

    final compressedLength = await compressedFile.length();
    final fileSizeAfterCompression = compressedLength / (1024 * 1024);

    debugPrint(
        '_uploadImageToCloud → File size after compression: ${fileSizeAfterCompression.toStringAsFixed(2)} MB');

    return compressedFile;
  }

  FutureOr<void> moveToCollection(
      MoveToCollectionEvent event, Emitter<CollectionState> emit) async {
    final apiResult = await _userCollectionsUseCase.executeMoveToCollection(
      isLoading: true,
      postId: event.postId,
      collectionId: event.collectionId,
    );
    if (apiResult.isSuccess) {
      event.onMoveToCollection?.call();
      add(GetUserCollectionEvent(skip: 1, limit: 10));
    }
  }

  /// Get posts in a collection by collectionId
  FutureOr<void> _getCollectionPosts(
      GetCollectionPostsEvent event, Emitter<CollectionState> emit) async {
    emit(GetCollectionPostsLoadingState());
    final apiResult =
        await getSavedPostDataUseCase.executeGetProfileSavedPostData(
      isLoading: false,
      page: event.page,
      pageSize: event.pageSize,
      collectionId: event.collectionId,
    );
    if (apiResult.isSuccess && apiResult.data != null) {
      emit(GetCollectionPostsSuccessState(
        posts: apiResult.data?.data ?? [],
        totalPosts: (apiResult.data?.total ?? 0).toInt(),
      ));
    } else {
      emit(GetCollectionPostsErrorState(
        error:
            apiResult.error?.message ?? IsrTranslationFile.somethingWentWrong,
      ));
    }
  }

  /// Delete a collection
  FutureOr<void> _deleteCollection(
      DeleteCollectionEvent event, Emitter<CollectionState> emit) async {
    emit(DeleteCollectionLoadingState());
    final apiResult = await _userCollectionsUseCase.executeDeleteCollection(
      isLoading: false,
      collectionId: event.collectionId,
    );
    if (apiResult.isSuccess) {
      emit(DeleteCollectionSuccessState(
        message: 'Collection deleted successfully',
      ));
    } else {
      emit(DeleteCollectionErrorState(
        error:
            apiResult.error?.message ?? IsrTranslationFile.somethingWentWrong,
      ));
    }
  }

  /// Remove a post from collection
  FutureOr<void> _removePostFromCollection(RemovePostFromCollectionEvent event,
      Emitter<CollectionState> emit) async {
    emit(RemovePostFromCollectionLoadingState());
    final apiResult =
        await _userCollectionsUseCase.executeModifyUserCollectionList(
      isLoading: false,
      collectionId: event.collectionId,
      requestMap: {
        'action': 'REMOVE',
        'postIds': [event.postId],
      },
    );
    if (apiResult.isSuccess) {
      emit(RemovePostFromCollectionSuccessState(postId: event.postId));
    } else {
      emit(RemovePostFromCollectionErrorState(
        error:
            apiResult.error?.message ?? IsrTranslationFile.somethingWentWrong,
      ));
    }
  }
}
