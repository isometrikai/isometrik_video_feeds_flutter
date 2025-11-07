import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class GetFollowingPostUseCase extends BaseUseCase {
  GetFollowingPostUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<PostResponse?>> executeGetFollowingPost({
    required bool isLoading,
    required int page,
    required int pageLimit,
  }) async =>
      await super.execute(() async {
        final response = await _repository.getFollowingPost(
          isLoading: isLoading,
          page: page,
          pageLimit: pageLimit,
        );
        return ApiResult(data: response.responseCode == 200 ? response.data : null);
      });
}
