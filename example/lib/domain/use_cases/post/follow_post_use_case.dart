import 'package:ism_video_reel_player_example/core/core.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

class FollowPostUseCase extends BaseUseCase {
  FollowPostUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<ResponseClass?>> executeFollowPost({
    required bool isLoading,
    required String followingId,
    required FollowAction followAction,
  }) async =>
      await super.execute(() async {
        final response = await _repository.followPost(
          isLoading: isLoading,
          followingId: followingId,
          followAction: followAction,
        );
        return ApiResult(
            data: response.responseCode == 200 || response.responseCode == 201
                ? response.data
                : null);
      });
}
