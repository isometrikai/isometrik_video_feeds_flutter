import 'package:ism_video_reel_player/domain/domain.dart';

abstract class PostRepository extends BaseRepository {
  Future<CustomResponse<ResponseClass?>> createPost({
    required bool isLoading,
    Map<String, dynamic>? createPostRequest,
  });
  Future<CustomResponse<PostResponse?>> getFollowingPost({
    required bool isLoading,
  });
}
