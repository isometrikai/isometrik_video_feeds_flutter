import 'dart:io';

import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

abstract class SocialRepository extends BaseRepository {
  Future<CustomResponse<CreatePostResponse?>> createPost({
    required bool isLoading,
    Map<String, dynamic>? createPostRequest,
  });

  Future<CustomResponse<CreatePostResponse?>> editPost({
    required bool isLoading,
    required String postId,
    Map<String, dynamic>? editPostRequest,
  });

  Future<CustomResponse<PostResponse?>> getFollowingPost({
    required bool isLoading,
    required int page,
    required int pageLimit,
  });

  Future<CustomResponse<TimelineResponse?>> getTrendingPost({
    required bool isLoading,
    required int page,
    required int pageLimit,
  });

  Future<CustomResponse<ResponseClass?>> followPost({
    required bool isLoading,
    required String followingId,
    required FollowAction followAction,
  });

  Future<CustomResponse<ResponseClass?>> savePost({
    required bool isLoading,
    required String postId,
    required SocialPostAction socialPostAction,
  });

  Future<CustomResponse<ResponseClass?>> likePost({
    required bool isLoading,
    required String postId,
    required String userId,
    required LikeAction likeAction,
  });

  Future<CustomResponse<ResponseClass?>> reportPost({
    required bool isLoading,
    required String postId,
    required String message,
    required String reason,
  });

  Future<CustomResponse<List<String>?>> getReportReasons({
    required bool isLoading,
    ReasonsFor? reasonFor,
  });

  Future<CustomResponse<CloudDetailsResponse?>> getCloudDetails({
    required bool isLoading,
    required String key,
    required String value,
  });

  Future<CustomResponse<CommentsResponse?>> getPostComments({
    required bool isLoading,
    required String postId,
  });

  Future<CustomResponse<PostDetailsResponse?>> getPostDetails({
    required bool isLoading,
    List<String>? productIds,
    int? page,
    int? limit,
  });

  Future<CustomResponse<ResponseClass?>> doCommentAction({
    required bool isLoading,
    required Map<String, dynamic> commentRequest,
  });

  Future<CustomResponse<ResponseClass?>> deletePost({
    required bool isLoading,
    required String postId,
  });

  Future<CustomResponse<PostData?>> getPost({
    required bool isLoading,
    required String postId,
  });

  Future<String?> uploadMediaToGoogleCloud({
    required File file,
    required String fileName,
    required String userId,
    required String fileExtension,
    Function(double)? onProgress,
    String? cloudFolderName,
  });

  Future<CustomResponse<TimelineResponse?>> getTimeLinePosts({
    required bool isLoading,
    required int page,
    required int pageLimit,
  });

  Future<CustomResponse<ResponseClass?>> processMedia({
    required bool isLoading,
    required String postId,
  });

  Future<CustomResponse<SearchUserResponse?>> searchUser({
    required bool isLoading,
    required int limit,
    required int page,
    required String searchText,
  });

  Future<CustomResponse<HashTagResponse?>> searchTag({
    required bool isLoading,
    required int limit,
    required int page,
    required String searchText,
  });

  Future<CustomResponse<TimelineResponse?>> getForYouPosts({
    required bool isLoading,
    required int page,
    required int pageLimit,
  });
}
