import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class FollowPostUseCase extends BaseUseCase {
  FollowPostUseCase(this._repository);

  final PostRepository _repository;

  Future<ApiResult<ResponseClass?>> executeFollowPost({
    required bool isLoading,
    required String followingId,
  }) async =>
      await super.execute(() async {
        final response = await _repository.followPost(
          isLoading: isLoading,
          followingId: followingId,
        );
        return ApiResult(data: response.responseCode == 200 ? response.data : null);
      });
} 