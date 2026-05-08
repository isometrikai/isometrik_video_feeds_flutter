import 'package:ism_video_reel_player/ism_video_reel_player.dart';

class StoryUseCase extends BaseUseCase {
  StoryUseCase(this._repository);

  final StoryRepository _repository;

  Future<ApiResult<StoryFeedResponse?>> executeGetStoryFeed({
    required bool isLoading,
    int? limit,
    String? cursor,
  }) async =>
      execute(() async {
        final response = await _repository.getStoryFeed(
          isLoading: isLoading,
          limit: limit,
          cursor: cursor,
        );
        return ApiResult(
          data: response.responseCode == 200 ? response.data : null,
        );
      });

  Future<ApiResult<List<StoryData>?>> executeGetStories({
    required bool isLoading,
    required String userId,
  }) async =>
      execute(() async {
        final response = await _repository.getStories(
          isLoading: isLoading,
          userId: userId,
        );
        return ApiResult(
          data: response.responseCode == 200 ? response.data : null,
        );
      });

  Future<ApiResult<ResponseClass?>> executeCreateStory({
    required bool isLoading,
    required CreateStoryRequest request,
  }) async =>
      execute(() async {
        final response = await _repository.createStory(
          isLoading: isLoading,
          request: request,
        );
        return ApiResult(
          data: response.responseCode == 200 || response.responseCode == 201
              ? response.data
              : null,
        );
      });

  Future<ApiResult<ResponseClass?>> executeStartStoryProcessing({
    required bool isLoading,
    required String storyId,
  }) async =>
      execute(() async {
        final response = await _repository.startStoryProcessing(
          isLoading: isLoading,
          storyId: storyId,
        );
        return ApiResult(
          data: response.responseCode == 200 || response.responseCode == 201
              ? response.data
              : null,
        );
      });

  Future<ApiResult<ResponseClass?>> executeMarkStoryViewed({
    required bool isLoading,
    required String storyId,
  }) async =>
      execute(() async {
        final response = await _repository.markStoryViewed(
          isLoading: isLoading,
          storyId: storyId,
        );
        return ApiResult(
            data: response.responseCode == 200 ? response.data : null);
      });

  Future<ApiResult<ResponseClass?>> executeAddStoryReaction({
    required bool isLoading,
    required String storyId,
    required String reactionType,
  }) async =>
      execute(() async {
        final response = await _repository.addStoryReaction(
          isLoading: isLoading,
          storyId: storyId,
          reactionType: reactionType,
        );
        return ApiResult(
          data: response.responseCode == 200 || response.responseCode == 201
              ? response.data
              : null,
        );
      });

  Future<ApiResult<ResponseClass?>> executeRemoveStoryReaction({
    required bool isLoading,
    required String storyId,
  }) async =>
      execute(() async {
        final response = await _repository.removeStoryReaction(
          isLoading: isLoading,
          storyId: storyId,
        );
        return ApiResult(
            data: response.responseCode == 200 ? response.data : null);
      });

  Future<ApiResult<List<StoryHighlightData>?>> executeGetStoryHighlights({
    required bool isLoading,
    required String userId,
    int? page,
    int? pageSize,
  }) async =>
      execute(() async {
        final response = await _repository.getStoryHighlights(
          isLoading: isLoading,
          userId: userId,
          page: page,
          pageSize: pageSize,
        );
        return ApiResult(
          data: response.responseCode == 200 ? response.data : null,
        );
      });

  Future<ApiResult<ResponseClass?>> executeCreateStoryHighlight({
    required bool isLoading,
    required CreateStoryHighlightRequest request,
  }) async =>
      execute(() async {
        final response = await _repository.createStoryHighlight(
          isLoading: isLoading,
          request: request,
        );
        return ApiResult(
          data: response.responseCode == 200 || response.responseCode == 201
              ? response.data
              : null,
        );
      });

  Future<ApiResult<ResponseClass?>> executeUpdateStoryHighlight({
    required bool isLoading,
    required String highlightId,
    required UpdateStoryHighlightRequest request,
  }) async =>
      execute(() async {
        final response = await _repository.updateStoryHighlight(
          isLoading: isLoading,
          highlightId: highlightId,
          request: request,
        );
        return ApiResult(
            data: response.responseCode == 200 ? response.data : null);
      });

  Future<ApiResult<ResponseClass?>> executeDeleteStoryHighlight({
    required bool isLoading,
    required String highlightId,
  }) async =>
      execute(() async {
        final response = await _repository.deleteStoryHighlight(
          isLoading: isLoading,
          highlightId: highlightId,
        );
        return ApiResult(
            data: response.responseCode == 200 ? response.data : null);
      });

  Future<ApiResult<ResponseClass?>> executeAddStoriesToHighlight({
    required bool isLoading,
    required String highlightId,
    required AddStoriesToHighlightRequest request,
  }) async =>
      execute(() async {
        final response = await _repository.addStoriesToHighlight(
          isLoading: isLoading,
          highlightId: highlightId,
          request: request,
        );
        return ApiResult(
          data: response.responseCode == 200 || response.responseCode == 201
              ? response.data
              : null,
        );
      });

  Future<ApiResult<ResponseClass?>> executeRemoveStoryFromHighlight({
    required bool isLoading,
    required String highlightId,
    required String storyId,
  }) async =>
      execute(() async {
        final response = await _repository.removeStoryFromHighlight(
          isLoading: isLoading,
          highlightId: highlightId,
          storyId: storyId,
        );
        return ApiResult(
            data: response.responseCode == 200 ? response.data : null);
      });

  Future<ApiResult<StoryHighlightData?>> executeGetStoryHighlightById({
    required bool isLoading,
    required String highlightId,
  }) async =>
      execute(() async {
        final response = await _repository.getStoryHighlightById(
          isLoading: isLoading,
          highlightId: highlightId,
        );
        return ApiResult(
          data: response.responseCode == 200 ? response.data : null,
        );
      });

  Future<ApiResult<StoryData?>> executeGetStoryDetail({
    required bool isLoading,
    required String storyId,
  }) async =>
      execute(() async {
        final response = await _repository.getStoryDetail(
          isLoading: isLoading,
          storyId: storyId,
        );
        return ApiResult(
          data: response.responseCode == 200 ? response.data : null,
        );
      });

  Future<ApiResult<ResponseClass?>> executeDeleteStory({
    required bool isLoading,
    required String storyId,
  }) async =>
      execute(() async {
        final response = await _repository.deleteStory(
          isLoading: isLoading,
          storyId: storyId,
        );
        return ApiResult(
            data: response.responseCode == 200 ? response.data : null);
      });
}
