class SocialApiEndPoints {
  static const getFollowingPosts = '/social/v1/home';
  static const getTimeLinePosts = '/api/v1/posts/timeline';
  static const getTrendingPosts = '/api/v1/posts/trending';
  static const postCreatePost = '/api/v1/posts';
  static const postFollowUser = '/api/v1/follows';
  static const getFollowRequestsIncoming = '/api/v1/follows/requests/incoming';
  /// GET: list outgoing. DELETE with query `target_id`: cancel a pending request you sent.
  static const getFollowRequestsOutgoing = '/api/v1/follows/requests/outgoing';
  static String postFollowRequestAccept(String requestId) =>
      '/api/v1/follows/requests/$requestId/accept';
  static String postFollowRequestDecline(String requestId) =>
      '/api/v1/follows/requests/$requestId/decline';
  static const postSavePost = '/api/v1/posts/save';
  static const postLike = '/api/v1/likes/post';
  static const postUnLike = '/api/v1/likes/post';
  static const String reportPost = '/api/v1/reports';
  static const String getReportReasons = '/api/v1/report-reasons';
  static const String getCloudDetails = '/v1/cloudinary';
  static const String getPostComments = '/api/v1/comments/post';
  static const String postComment = '/api/v1/comments';
  static const String postCommentLike = '/api/v1/likes/comment';
  static const String postReportComment = '/api/v1/reports';
  static const String getPostDetails = '/api/v1/posts/detail';
  static String getPostInsights(String postId) => '/api/v1/posts/$postId/insights';
  static String get getSocialProducts => '/fast/api/v1/social-pdp/bulk';
  // static String get getSocialProducts => switch (appFlavour) {
  //   AppFlavor.production => '/v1/product/socialpost/details',
  //   AppFlavor.development => '/fast/api/v1/social-pdp/bulk',
  // };

  // static const String getPostDetails = '/fast/api/v1/social-posts';
  static const String putEditPost = '/api/v1/posts';
  static const String deletePost = '/api/v1/posts';
  static const String getPost = '/social/v1/post';
  static const getSavedPostsOfUserSocial = '/api/v1/posts/saved';
  static const getProfileUserPostSocial = '/api/v1/posts/user';
  static String postMediaProcess(String postId) =>
      '/api/v1/posts/$postId/start-processing';
  static const String getSearchUsers = '/api/v1/users/search';
  static const String getPopularUsers = '/api/v1/users/popular';
  static const String getSearchTags = '/api/v1/tags/hashtags/search';
  static String getUserProfile(String userId) =>
      '/api/v1/users/$userId/profile';
  static const String getTaggedPosts = '/api/v1/tags/posts';
  static const String getForYouPosts = '/api/v1/posts/fyp';
  static const String getMentionedUsers = '/api/v1/posts';
  static String postScheduledPost(String postId) =>
      '/api/v1/posts/scheduled/$postId/publish';
  static const String deleteMention = '/api/v1/posts/mentions';
  static const String createCollection = '/api/v1/posts/collections';
  static const String getCollectionList = '/api/v1/posts/collections';
  static const String postMoveToCollection = '/api/v1/posts/move_to_collection';
  static const String putCollection = '/api/v1/posts/collections';
  static const String deleteCollection = '/api/v1/posts/collections';
  static const String postImpressions = '/api/v1/views';
  static const String onShareSuccess = '/api/v1/shares';

}
