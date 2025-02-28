import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

abstract class PostRepository extends BaseRepository {
  Future<CustomResponse<CreatePostResponse?>> createPost({
    required bool isLoading,
    Map<String, dynamic>? createPostRequest,
  });

  Future<CustomResponse<PostResponse?>> getFollowingPost({
    required bool isLoading,
    required int page,
    required int pageLimit,
  });

  Future<CustomResponse<PostResponse?>> getTrendingPost({
    required bool isLoading,
    required int page,
    required int pageLimit,
  });

  Future<CustomResponse<ResponseClass?>> followPost({
    required bool isLoading,
    required String followingId,
  });

  Future<CustomResponse<ResponseClass?>> savePost({
    required bool isLoading,
    required String postId,
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
  });

  Future<CustomResponse<CloudDetailsResponse?>> getCloudDetails({
    required bool isLoading,
    required String key,
    required String value,
  });
}
