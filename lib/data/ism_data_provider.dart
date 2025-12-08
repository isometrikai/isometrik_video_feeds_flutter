import 'dart:convert';

import 'package:ism_video_reel_player/di/di.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class IsmDataProvider {
  /// Private constructor
  IsmDataProvider._();

  /// Single instance
  static final IsmDataProvider _instance = IsmDataProvider._();

  /// Access the singleton instance
  static IsmDataProvider get instance => _instance;

  /// Get CollectionUseCase from DI
  CollectionUseCase get _collectionUseCase => IsmInjectionUtils.getUseCase<CollectionUseCase>();

  /// Fetches collection list
  Future<void> fetchCollectionList({
    required int page,
    required int pageSize,
    bool isLoading = false,
    bool isPublicOnly = false,
    Function(String, int)? onSuccess,
    Function(String, int)? onError,
  }) async {
    final result = await _collectionUseCase.executeGetCollectionList(
      isLoading: isLoading,
      page: page,
      pageSize: pageSize,
      isPublicOnly: isPublicOnly,
    );
    if (result.isSuccess) {
      onSuccess?.call(jsonEncode(result.data?.toMap() ?? {}), result.statusCode ?? 200);
    } else {
      onError?.call(result.error?.message ?? '', result.statusCode ?? 500);
    }
  }

  /// Create collection
  Future<void> createCollection({
    bool isLoading = false,
    Function(String, int)? onSuccess,
    Function(String, int)? onError,
  }) async {
    final result = await _collectionUseCase.executeCreateCollection(
      isLoading: isLoading,
    );
    if (result.isSuccess) {
      onSuccess?.call(jsonEncode(result.data?.toMap() ?? {}), result.statusCode ?? 200);
    } else {
      onError?.call(result.error?.message ?? '', result.statusCode ?? 500);
    }
  }

  /// Move post to collection
  Future<void> movePostToCollection({
    required String postId,
    required String collectionId,
    bool isLoading = false,
    Function(String, int)? onSuccess,
    Function(String, int)? onError,
  }) async {
    final result = await _collectionUseCase.executeMoveToCollection(
      isLoading: isLoading,
      postId: postId,
      collectionId: collectionId,
    );
    if (result.isSuccess) {
      onSuccess?.call(jsonEncode(result.data?.toMap() ?? {}), result.statusCode ?? 200);
    } else {
      onError?.call(result.error?.message ?? '', result.statusCode ?? 500);
    }
  }

  /// Update collection
  Future<void> updateCollection({
    required String collectionId,
    bool isLoading = false,
    Function(String, int)? onSuccess,
    Function(String, int)? onError,
  }) async {
    final result = await _collectionUseCase.executeUpdateCollection(
      isLoading: isLoading,
      collectionId: collectionId,
    );
    if (result.isSuccess) {
      onSuccess?.call(jsonEncode(result.data?.toMap() ?? {}), result.statusCode ?? 200);
    } else {
      onError?.call(result.error?.message ?? '', result.statusCode ?? 500);
    }
  }

  /// Delete collection
  Future<void> deleteCollection({
    required String collectionId,
    bool isLoading = false,
    Function(String, int)? onSuccess,
    Function(String, int)? onError,
  }) async {
    final result = await _collectionUseCase.executeDeleteCollection(
      isLoading: isLoading,
      collectionId: collectionId,
    );
    if (result.isSuccess) {
      onSuccess?.call(jsonEncode(result.data?.toMap() ?? {}), result.statusCode ?? 200);
    } else {
      onError?.call(result.error?.message ?? '', result.statusCode ?? 500);
    }
  }
}
