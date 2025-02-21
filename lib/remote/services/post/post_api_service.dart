import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/remote/remote.dart';

abstract class PostApiService extends BaseService {
  Future<ResponseModel> createPost({
    required bool isLoading,
    required Header header,
    Map<String, dynamic>? createPostRequest,
  });
  Future<ResponseModel> getFollowingPosts({
    required bool isLoading,
    required Header header,
  });
}
