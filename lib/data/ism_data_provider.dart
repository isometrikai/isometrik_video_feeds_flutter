import 'dart:convert';

import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class IsmDataProvider {
  /// Private constructor
  IsmDataProvider._();

  /// Single instance
  static final IsmDataProvider _instance = IsmDataProvider._();

  /// Access the singleton instance
  static IsmDataProvider get instance => _instance;

  /// Get UseCases from DI
  CollectionUseCase get _collectionUseCase =>
      IsmInjectionUtils.getUseCase<CollectionUseCase>();

  SavePostUseCase get _savedPostUseCase =>
      IsmInjectionUtils.getUseCase<SavePostUseCase>();

  GetTaggedPostsUseCase get _getTaggedPostUseCase =>
      IsmInjectionUtils.getUseCase<GetTaggedPostsUseCase>();

  GetUserPostDataUseCase get _userPostDataUseCase =>
      IsmInjectionUtils.getUseCase<GetUserPostDataUseCase>();

  CreatePostUseCase get _createPostUseCase =>
      IsmInjectionUtils.getUseCase<CreatePostUseCase>();

  DeletePostUseCase get _deletePostUseCase =>
      IsmInjectionUtils.getUseCase<DeletePostUseCase>();

  /// Private generic handler to reduce code duplication
  Future<void> _executeApiCall<T>({
    required Future<ApiResult<T>> Function() apiCall,
    required Map<String, dynamic> Function(T?) toJson,
    int successStatusCode = 200,
    Function(String, int)? onSuccess,
    Function(String, int)? onError,
  }) async {
    final result = await apiCall();
    if (result.isSuccess) {
      onSuccess?.call(
        jsonEncode(toJson(result.data)),
        result.statusCode ?? successStatusCode,
      );
    } else {
      onError?.call(result.error?.message ?? '', result.statusCode ?? 500);
    }
  }

  /// Fetches collection list
  Future<void> fetchCollectionList({
    required int page,
    required int pageSize,
    bool isLoading = false,
    bool isPublicOnly = false,
    Function(String, int)? onSuccess,
    Function(String, int)? onError,
  }) async {
    await _executeApiCall(
      apiCall: () => _collectionUseCase.executeGetCollectionList(
        isLoading: isLoading,
        page: page,
        pageSize: pageSize,
        isPublicOnly: isPublicOnly,
      ),
      toJson: (data) => data?.toMap() ?? {},
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Fetches collection post list
  Future<void> fetchCollectionPostList({
    required int page,
    required int pageSize,
    bool isLoading = false,
    String collectionId = '',
    Function(String, int)? onSuccess,
    Function(String, int)? onError,
  }) async {
    await _executeApiCall(
      apiCall: () => _savedPostUseCase.executeGetProfileSavedPostData(
        isLoading: isLoading,
        page: page,
        pageSize: pageSize,
        collectionId: collectionId,
      ),
      toJson: (data) => data?.toMap() ?? {},
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Create collection
  /// `requestMap` is a `Map` containing the following properties:
  /// - `description`: A description of the collection
  /// - `is_private`: A boolean indicating whether the collection is private or not
  /// - `name`: The name of the collection
  Future<void> createCollection({
    bool isLoading = false,
    required Map<String, dynamic> requestMap,
    Function(String, int)? onSuccess,
    Function(String, int)? onError,
  }) async {
    await _executeApiCall(
      apiCall: () => _collectionUseCase.executeCreateUserCollectionList(
        isLoading: isLoading,
        requestMap: requestMap,
      ),
      toJson: (data) => data?.toMap() ?? {},
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Move post to collection
  Future<void> movePostToCollection({
    required String postId,
    required String collectionId,
    bool isLoading = false,
    Function(String, int)? onSuccess,
    Function(String, int)? onError,
  }) async {
    await _executeApiCall(
      apiCall: () => _collectionUseCase.executeMoveToCollection(
        isLoading: isLoading,
        postId: postId,
        collectionId: collectionId,
      ),
      toJson: (data) => data?.toMap() ?? {},
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Update collection
  Future<void> updateCollection({
    required String collectionId,
    required Map<String, dynamic> requestMap,
    bool isLoading = false,
    Function(String, int)? onSuccess,
    Function(String, int)? onError,
  }) async {
    await _executeApiCall(
      apiCall: () => _collectionUseCase.executeModifyUserCollectionList(
        isLoading: isLoading,
        collectionId: collectionId,
        requestMap: requestMap,
      ),
      toJson: (data) => data?.toMap() ?? {},
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Delete collection
  Future<void> deleteCollection({
    required String collectionId,
    bool isLoading = false,
    Function(String, int)? onSuccess,
    Function(String, int)? onError,
  }) async {
    await _executeApiCall(
      apiCall: () => _collectionUseCase.executeDeleteCollection(
        isLoading: isLoading,
        collectionId: collectionId,
      ),
      toJson: (data) => data?.toMap() ?? {},
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Create post
  Future<void> createPost({
    bool isLoading = false,
    Map<String, dynamic>? createPostRequest,
    Function(String, int)? onSuccess,
    Function(String, int)? onError,
  }) async {
    await _executeApiCall(
      apiCall: () => _createPostUseCase.executeCreatePost(
        isLoading: isLoading,
        createPostRequest: createPostRequest,
      ),
      toJson: (data) => data?.toJson() ?? {},
      successStatusCode: 201,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Edit post
  Future<void> editPost({
    required String postId,
    bool isLoading = false,
    Map<String, dynamic>? editPostRequest,
    Function(String, int)? onSuccess,
    Function(String, int)? onError,
  }) async {
    await _executeApiCall(
      apiCall: () => _createPostUseCase.executeEditPost(
        isLoading: isLoading,
        postId: postId,
        editPostRequest: editPostRequest,
      ),
      toJson: (data) => data?.toJson() ?? {},
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Delete post
  Future<void> deletePost({
    required String postId,
    bool isLoading = false,
    Function(String, int)? onSuccess,
    Function(String, int)? onError,
  }) async {
    await _executeApiCall(
      apiCall: () => _deletePostUseCase.executeDeletePost(
        isLoading: isLoading,
        postId: postId,
      ),
      toJson: (data) => data?.toMap() ?? {},
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Get user posts
  Future<void> getUserPosts({
    required String userId,
    required int page,
    required int pageSize,
    bool isLoading = false,
    Function(String, int)? onSuccess,
    Function(String, int)? onError,
  }) async {
    await _executeApiCall(
      apiCall: () => _userPostDataUseCase.executeGetUserProfilePostData(
        isLoading: isLoading,
        page: page,
        pageSize: pageSize,
        memberId: userId,
      ),
      toJson: (data) => data?.toMap() ?? {},
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Get saved post
  Future<void> getSavedPosts({
    required int page,
    required int pageSize,
    bool isLoading = false,
    Function(String, int)? onSuccess,
    Function(String, int)? onError,
  }) async {
    await _executeApiCall(
      apiCall: () => _savedPostUseCase.executeGetProfileSavedPostData(
        isLoading: isLoading,
        page: page,
        pageSize: pageSize,
      ),
      toJson: (data) => data?.toMap() ?? {},
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Get tagged posts
  Future<void> getTaggedPosts({
    required TagType tagType,
    required String tagValue,
    required int page,
    required int pageSize,
    bool isLoading = false,
    Function(String, int)? onSuccess,
    Function(String, int)? onError,
  }) async {
    await _executeApiCall(
      apiCall: () => _getTaggedPostUseCase.executeGetTaggedPosts(
        isLoading: isLoading,
        page: page,
        pageLimit: pageSize,
        tagType: tagType,
        tagValue: tagValue,
      ),
      toJson: (data) => data?.toMap() ?? {},
      onSuccess: onSuccess,
      onError: onError,
    );
  }
}
