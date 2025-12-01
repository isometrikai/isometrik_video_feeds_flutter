import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class GetUserPostDataUseCase extends BaseUseCase {
  GetUserPostDataUseCase(this._socialRepository);

  final SocialRepository _socialRepository;

  Future<ApiResult<TimelineResponse?>> executeGetUserProfilePostData({
    required bool isLoading,
    required int page,
    required int pageSize,
    required String memberId,
  }) async =>
      await super.execute(() async {
        final response = await _socialRepository.getProfileUserPostData(
          isLoading: isLoading,
          page: page,
          pageSize: pageSize,
          memberId: memberId,
        );
        return ApiResult(
            data: response.responseCode == 200 && response.responseCode != 204
                ? response.data
                : null);
      });
}
