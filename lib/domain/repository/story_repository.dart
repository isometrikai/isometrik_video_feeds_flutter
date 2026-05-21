import 'package:ism_video_reel_player/domain/models/models.dart';
import 'package:ism_video_reel_player/domain/repository/base_repository.dart';

abstract class StoryRepository extends BaseRepository {
  Future<CustomResponse<ResponseClass?>> createStory({
    required bool isLoading,
    required CreateStoryRequest request,
  });

  Future<CustomResponse<List<StoryData>?>> getStories({
    required bool isLoading,
    required String userId,
  });

  Future<CustomResponse<List<StoryData>?>> getMyStories({
    required bool isLoading,
  });

  Future<CustomResponse<ResponseClass?>> startStoryProcessing({
    required bool isLoading,
    required String storyId,
  });

  Future<CustomResponse<StoryFeedResponse?>> getStoryFeed({
    required bool isLoading,
    int? limit,
    String? cursor,
  });

  Future<CustomResponse<ResponseClass?>> createStoryHighlight({
    required bool isLoading,
    required CreateStoryHighlightRequest request,
  });

  Future<CustomResponse<List<StoryHighlightData>?>> getStoryHighlights({
    required bool isLoading,
    required String userId,
    int? page,
    int? pageSize,
  });

  Future<CustomResponse<StoryHighlightData?>> getStoryHighlightById({
    required bool isLoading,
    required String highlightId,
  });

  Future<CustomResponse<ResponseClass?>> updateStoryHighlight({
    required bool isLoading,
    required String highlightId,
    required UpdateStoryHighlightRequest request,
  });

  Future<CustomResponse<ResponseClass?>> deleteStoryHighlight({
    required bool isLoading,
    required String highlightId,
  });

  Future<CustomResponse<ResponseClass?>> addStoriesToHighlight({
    required bool isLoading,
    required String highlightId,
    required AddStoriesToHighlightRequest request,
  });

  Future<CustomResponse<ResponseClass?>> removeStoryFromHighlight({
    required bool isLoading,
    required String highlightId,
    required String storyId,
  });

  Future<CustomResponse<StoryData?>> getStoryDetail({
    required bool isLoading,
    required String storyId,
  });

  Future<CustomResponse<ResponseClass?>> deleteStory({
    required bool isLoading,
    required String storyId,
  });

  Future<CustomResponse<ResponseClass?>> markStoryViewed({
    required bool isLoading,
    required String storyId,
  });

  Future<CustomResponse<ResponseClass?>> addStoryReaction({
    required bool isLoading,
    required String storyId,
    required String reactionType,
  });

  Future<CustomResponse<ResponseClass?>> removeStoryReaction({
    required bool isLoading,
    required String storyId,
  });
}
