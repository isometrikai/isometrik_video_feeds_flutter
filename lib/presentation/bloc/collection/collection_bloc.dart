import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

part 'collection_event.dart';
part 'collection_state.dart';

class CollectionBloc extends Bloc<CollectionEvent, CollectionState> {
  CollectionBloc(
    this._userCollectionsUseCase,
    this.getSavedPostDataUseCase,
    this.localDataUseCase,
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
      emit(UserCollectionFetchState(collectionList: apiResult.data?.data ?? []));
    } else {
      emit(UserCollectionErrorState(apiResult.error?.message ?? ''));
    }
  }

  ///Modify user collection
  modifyUserCollection(ModifyUserCollectionEvent event, Emitter<CollectionState> emit) async {
    emit(ModifyUserCollectionLoadingState());
    final apiResult = await _userCollectionsUseCase.executeModifyUserCollectionList(
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
  void createUserCollection(CreateUserCollectionEvent event, Emitter<CollectionState> emit) async {
    emit(CreateCollectionLoadingState());
    final apiResult = await _userCollectionsUseCase.executeCreateUserCollectionList(
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
  editUserCollection(EditUserCollectionEvent event, Emitter<CollectionState> emit) async {
    emit(EditCollectionLoadingState());
    final apiResult = await _userCollectionsUseCase.executeModifyUserCollectionList(
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

    // final apiResult = await _userCollectionsUseCase.executeCollectionAddImage(
    //     isLoading: false, file: croppedProfileImage!, uploadTo: 1);
    // if (apiResult.isSuccess) {
    //   final response = jsonDecode(apiResult.data?.data ?? '');
    //   emit(CollectionImageUpdateSuccessState(
    //     imageString: response['data']['imageUrl'] as String,
    //     localFile: croppedProfileImage!,
    //   ));
    // } else {
    //   emit(CollectionImageUpdateErrorState(apiResult.error?.message ?? ''));
    //   ErrorHandler.showAppError(isNeedToShowError: true, appError: apiResult.error);
    // }
  }

  FutureOr<void> _savePostAction(SavePostActionEvent event, Emitter<CollectionState> emit) async {
    emit(SavePostLoadingState(postId: event.postId));
    final isLoggedIn = await isUserLoggedIn();
    if (!isLoggedIn) {
      return;
    }
    final apiResult = await getSavedPostDataUseCase.executeSavePost(
      isLoading: false,
      postId: event.postId,
      socialPostAction: event.isSaved ? SocialPostAction.unSave : SocialPostAction.save,
    );
    if (apiResult.isSuccess) {
      emit(SavePostSuccessState(
          postId: event.postId,
          socialPostAction: event.isSaved ? SocialPostAction.unSave : SocialPostAction.save));
    } else {
      emit(SavePostErrorState(
        message: apiResult.error?.message ?? IsrTranslationFile.somethingWentWrong,
      ));
    }
  }

  FutureOr<void> getSavedPost(GetSavedPostEvent event, Emitter<CollectionState> emit) async {
    emit(SavedPostDataLoadingState());
    final profilePic = await localDataUseCase.getProfilePic();
    final apiResult = await getSavedPostDataUseCase.executeGetProfileSavedPostData(
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

  Future<void> addOrRemoveSavedPostToLocal(String postId, SocialPostAction socialPostAction) async {
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
      debugPrint('_uploadImageToCloud → Compression failed, returning original file.');
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
      isLoading: false,
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
    final apiResult = await getSavedPostDataUseCase.executeGetProfileSavedPostData(
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
        error: apiResult.error?.message ?? IsrTranslationFile.somethingWentWrong,
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
        error: apiResult.error?.message ?? IsrTranslationFile.somethingWentWrong,
      ));
    }
  }

  /// Remove a post from collection
  FutureOr<void> _removePostFromCollection(
      RemovePostFromCollectionEvent event, Emitter<CollectionState> emit) async {
    emit(RemovePostFromCollectionLoadingState());
    final apiResult = await _userCollectionsUseCase.executeModifyUserCollectionList(
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
        error: apiResult.error?.message ?? IsrTranslationFile.somethingWentWrong,
      ));
    }
  }
}
