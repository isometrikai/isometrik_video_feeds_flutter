import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class GetFollowingPostUseCase extends BaseUseCase {
  GetFollowingPostUseCase(this._repository);

  final PostRepository _repository;

  Future<ApiResult<PostResponse?>> executeGetFollowingPost({
    required bool isLoading,
    Map<String, dynamic>? createPostRequest,
  }) async =>
      await super.execute(() async {
        final response = await _repository.getFollowingPost(
          isLoading: isLoading,
        );
        return ApiResult(data: response.responseCode == 200 ? response.data : null);
      });
}
