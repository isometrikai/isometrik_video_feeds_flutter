import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/remote/remote.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

abstract class SocialApiService extends BaseService {
  Future<ResponseModel> createPost({
    required bool isLoading,
    required Header header,
    Map<String, dynamic>? createPostRequest,
  });

  Future<ResponseModel> editPost({
    required bool isLoading,
    required Header header,
    required String postId,
    Map<String, dynamic>? editPostRequest,
  });

  Future<ResponseModel> getFollowingPosts({
    required bool isLoading,
    required Header header,
    required int page,
    required int pageLimit,
  });

  Future<ResponseModel> getTimeLinePosts({
    required bool isLoading,
    required Header header,
    required int page,
    required int pageLimit,
  });

  Future<ResponseModel> getTrendingPosts({
    required bool isLoading,
    required Header header,
    required int page,
    required int pageLimit,
  });

  Future<ResponseModel> followUser({
    required bool isLoading,
    required String followingId,
    required Header header,
    required FollowAction followAction,
  });

  Future<ResponseModel> unFollowPost({
    required bool isLoading,
    required String followingId,
    required Header header,
  });

  Future<ResponseModel> savePost({
    required bool isLoading,
    required String postId,
    required Header header,
    required SocialPostAction socialPostAction,
  });

  Future<ResponseModel> likePost({
    required bool isLoading,
    required String postId,
    required String userId,
    required LikeAction likeAction,
    required Header header,
  });

  Future<ResponseModel> reportPost({
    required bool isLoading,
    required String postId,
    required String message,
    required String reason,
    required Header header,
  });

  Future<ResponseModel> getReportReasons({
    required bool isLoading,
    required Header header,
    ReasonsFor? reasonFor,
  });

  Future<ResponseModel> getCloudDetails({
    required bool isLoading,
    required String key,
    required String value,
    required Header header,
  });

  Future<ResponseModel> getPostComments({
    required bool isLoading,
    required String postId,
    required String? parentCommitId,
    required Header header,
    int? page,
    int? pageLimit,
  });

  Future<ResponseModel> getSocialProducts({
    required bool isLoading,
    required String postId,
    List<String>? productIds,
    int? page,
    int? limit,
    required Header header,
  });

  Future<ResponseModel> doCommentAction({
    required bool isLoading,
    required Map<String, dynamic> commentRequest,
    required Header header,
  });

  Future<ResponseModel> getPostDetails({
    required bool isLoading,
    required String postId,
    required Header header,
  });

  Future<ResponseModel> deletePost({
    required bool isLoading,
    required String postId,
    required Header header,
  });

  Future<ResponseModel> getPost({
    required bool isLoading,
    required String postId,
    required Header header,
  });

  Future<ResponseModel> processMedia({
    required bool isLoading,
    required String postId,
    required Header header,
  });

  Future<ResponseModel> searchUser({
    required bool isLoading,
    required int limit,
    required int page,
    required String searchText,
    required Header header,
  });

  Future<ResponseModel> searchTag({
    required bool isLoading,
    required int limit,
    required int page,
    required String searchText,
    required Header header,
  });

  Future<ResponseModel> getTaggedPosts({
    required bool isLoading,
    required Header header,
    required String tagValue,
    required TagType tagType,
    required int page,
    required int pageLimit,
  });

  Future<ResponseModel> getForYouPosts({
    required bool isLoading,
    required Header header,
    required int page,
    required int pageLimit,
  });
}
