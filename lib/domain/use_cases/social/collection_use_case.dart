import 'package:ism_video_reel_player/ism_video_reel_player.dart';

class CollectionUseCase extends BaseUseCase {
  CollectionUseCase(this._repository);

  final SocialRepository _repository;

  /// Create collection
  Future<ApiResult<ResponseClass?>> executeCreateUserCollectionList({
    required bool isLoading,
    required Map<String, dynamic> requestMap,
  }) async =>
      await super.execute(() async {
        final response = await _repository.createCollection(
          isLoading: isLoading,
          requestMap: requestMap,
        );
        return ApiResult(
            data: response.responseCode == 200 || response.responseCode == 201
                ? response.data
                : null);
      });

  /// Get list of collections
  Future<ApiResult<CollectionResponseModel?>> executeGetCollectionList({
    required bool isLoading,
    required int page,
    required int pageSize,
    required bool isPublicOnly,
    String? postId,
  }) async =>
      await super.execute(() async {
        final response = await _repository.getCollectionList(
          isLoading: isLoading,
          page: page,
          pageSize: pageSize,
          isPublicOnly: isPublicOnly,
          postId: postId,
        );
        return ApiResult(
            data: response.responseCode == 200 ? response.data : null);
      });

  /// Move post to one or more collections
  Future<ApiResult<ResponseClass?>> executeMoveToCollection({
    required bool isLoading,
    required String postId,
    required List<String> collectionIds,
  }) async =>
      await super.execute(() async {
        final response = await _repository.movePostToCollection(
          isLoading: isLoading,
          postId: postId,
          collectionIds: collectionIds,
        );
        return ApiResult(
            data: response.responseCode == 200 || response.responseCode == 201
                ? response.data
                : null);
      });

  /// Create or update collection
  Future<ApiResult<ResponseClass?>> executeModifyUserCollectionList({
    required bool isLoading,
    required Map<String, dynamic> requestMap,
    required String collectionId,
  }) async =>
      await super.execute(() async {
        final response = await _repository.updateCollection(
          isLoading: isLoading,
          collectionId: collectionId,
          requestMap: requestMap,
        );
        return ApiResult(
            data: response.responseCode == 200 || response.responseCode == 201
                ? response.data
                : null);
      });

  /// Delete collection
  Future<ApiResult<ResponseClass?>> executeDeleteCollection({
    required bool isLoading,
    required String collectionId,
  }) async =>
      await super.execute(() async {
        final response = await _repository.deleteCollection(
          isLoading: isLoading,
          collectionId: collectionId,
        );
        return ApiResult(
            data: response.responseCode == 200 ? response.data : null);
      });
}
