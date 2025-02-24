import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/remote/remote.dart';
import 'package:ism_video_reel_player/utils/isr_enums.dart';

abstract class PostApiService extends BaseService {
  Future<ResponseModel> createPost({
    required bool isLoading,
    required Header header,
    Map<String, dynamic>? createPostRequest,
  });
  Future<ResponseModel> getFollowingPosts({
    required bool isLoading,
    required Header header,
    required int page,
    required int pageLimit,
  });
  Future<ResponseModel> getTrendingPosts({
    required bool isLoading,
    required Header header,
  });

  Future<ResponseModel> followPost({
    required bool isLoading,
    required String followingId,
    required Header header,
  });

  Future<ResponseModel> savePost({
    required bool isLoading,
    required String postId,
    required Header header,
  });

  Future<ResponseModel> likePost({
    required bool isLoading,
    required String postId,
    required String userId,
    required LikeAction likeAction,
    required Header header,
  });
}
