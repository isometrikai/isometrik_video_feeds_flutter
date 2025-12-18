import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class SocialUserProfileUseCase extends BaseUseCase {
  SocialUserProfileUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<SocialUserProfileResponse?>> executeSearchUser({
    required bool isLoading,
    required String userId,
  }) async =>
      await super.execute(
        () async {
          final response = await _repository.getUserProfile(
            isLoading: isLoading,
            userId: userId,
          );
          return ApiResult(
            data: response.responseCode == 200 || response.responseCode == 201
                ? response.data
                : null,
          );
        },
      );
}
