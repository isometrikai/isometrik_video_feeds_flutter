import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class FollowUnFollowUserUseCase extends BaseUseCase {
  FollowUnFollowUserUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<FollowUnfollowResponseModel?>> executeFollowUser({
    required bool isLoading,
    required String followingId,
    required FollowAction followAction,
  }) async =>
      await super.execute(() async {
        final response = await _repository.followUser(
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
