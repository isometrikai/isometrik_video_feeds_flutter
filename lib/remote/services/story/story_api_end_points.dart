class StoryApiEndPoints {
  static const String postStory = '/api/v1/stories';
  static const String getStories = '/api/v1/stories';
  static const String getStoryFeed = '/api/v1/stories/feed';
  static String postStoryStartProcessing(String storyId) =>
      '/api/v1/stories/$storyId/start-processing';
  static String getStoryDetail(String storyId) =>
      '/api/v1/stories/detail/$storyId';
  static String deleteStory(String storyId) => '/api/v1/stories/$storyId';
  static String postStoryView(String storyId) =>
      '/api/v1/stories/$storyId/view';
  static String postStoryReaction(String storyId) =>
      '/api/v1/stories/$storyId/react';

  static const String postStoryHighlights = '/api/v1/stories/highlights';
  static const String getStoryHighlights = '/api/v1/stories/highlights';
  static String getStoryHighlightById(String highlightId) =>
      '/api/v1/stories/highlights/$highlightId';
  static String patchStoryHighlightById(String highlightId) =>
      '/api/v1/stories/highlights/$highlightId';
  static String deleteStoryHighlightById(String highlightId) =>
      '/api/v1/stories/highlights/$highlightId';
  static String postAddStoriesToHighlight(String highlightId) =>
      '/api/v1/stories/highlights/$highlightId/stories';
  static String deleteStoryFromHighlight({
    required String highlightId,
    required String storyId,
  }) =>
      '/api/v1/stories/highlights/$highlightId/stories/$storyId';
}
