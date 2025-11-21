class SocialApiEndPoints {
  static const getFollowingPosts = '/social/v1/home';
  static const getTimeLinePosts = '/api/v1/posts/timeline';
  static const getTrendingPosts = '/api/v1/posts/trending';
  static const postCreatePost = '/api/v1/posts';
  static const postFollowUser = '/api/v1/follows';
  static const postSavePost = '/api/v1/posts/save';
  static const postLike = '/api/v1/likes/post';
  static const postUnLike = '/api/v1/likes/post';
  static const String reportPost = '/api/v1/reports';
  static const String getReportSocialPostReasons = '/api/v1/report-reasons';
  static const String getReportCommentReasons = '/api/v1/report-reasons';
  static const String getCloudDetails = '/v1/cloudinary';
  static const String getPostComments = '/api/v1/comments/post';
  static const String postComment = '/api/v1/comments';
  static const String postCommentLike = '/api/v1/likes/comment';
  static const String postReportComment = '/api/v1/reports';
  static const String getPostDetails = '/api/v1/posts/detail';
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
  static const String getSearchTags = '/api/v1/tags/hashtags/search';
  static const String getTaggedPosts = '/api/v1/tags/posts';
  static const String getForYouPosts = '/api/v1/posts/fyp';
  static const String getMentionedUsers = '/api/v1/posts';
  static const String deleteMention = '/api/v1/posts/mentions';
}
