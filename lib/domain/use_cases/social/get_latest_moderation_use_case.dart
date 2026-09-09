import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class GetLatestModerationUseCase extends BaseUseCase {
  GetLatestModerationUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<PostModerationData?>> executeGetLatestModeration({
    required bool isLoading,
    required String contentId,
    String contentType = 'post',
  }) async =>
      await super.execute(() async {
        final response = await _repository.getLatestModeration(
          isLoading: isLoading,
          contentId: contentId,
          contentType: contentType,
        );
        return ApiResult(
            data: response.responseCode == 200 ? response.data : null);
      });
}
