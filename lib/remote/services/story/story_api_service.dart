import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/remote/remote.dart';

abstract class StoryApiService extends BaseService {
  Future<ResponseModel> createStory({
    required bool isLoading,
    required Header header,
    required Map<String, dynamic> requestMap,
  });

  Future<ResponseModel> getStories({
    required bool isLoading,
    required Header header,
    required String userId,
  });

  Future<ResponseModel> startStoryProcessing({
    required bool isLoading,
    required Header header,
    required String storyId,
  });

  Future<ResponseModel> getStoryFeed({
    required bool isLoading,
    required Header header,
    int? limit,
    String? cursor,
  });

  Future<ResponseModel> createStoryHighlight({
    required bool isLoading,
    required Header header,
    required Map<String, dynamic> requestMap,
  });

  Future<ResponseModel> getStoryHighlights({
    required bool isLoading,
    required Header header,
    required String userId,
    int? page,
    int? pageSize,
  });

  Future<ResponseModel> getStoryHighlightById({
    required bool isLoading,
    required Header header,
    required String highlightId,
  });

  Future<ResponseModel> updateStoryHighlight({
    required bool isLoading,
    required Header header,
    required String highlightId,
    required Map<String, dynamic> requestMap,
  });

  Future<ResponseModel> deleteStoryHighlight({
    required bool isLoading,
    required Header header,
    required String highlightId,
  });

  Future<ResponseModel> addStoriesToHighlight({
    required bool isLoading,
    required Header header,
    required String highlightId,
    required Map<String, dynamic> requestMap,
  });

  Future<ResponseModel> removeStoryFromHighlight({
    required bool isLoading,
    required Header header,
    required String highlightId,
    required String storyId,
  });

  Future<ResponseModel> getStoryDetail({
    required bool isLoading,
    required Header header,
    required String storyId,
  });

  Future<ResponseModel> deleteStory({
    required bool isLoading,
    required Header header,
    required String storyId,
  });

  Future<ResponseModel> markStoryViewed({
    required bool isLoading,
    required Header header,
    required String storyId,
  });

  Future<ResponseModel> addStoryReaction({
    required bool isLoading,
    required Header header,
    required String storyId,
    required String reactionType,
  });

  Future<ResponseModel> removeStoryReaction({
    required bool isLoading,
    required Header header,
    required String storyId,
  });
}
