import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class GetForYouPostUseCase extends BaseUseCase {
  GetForYouPostUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<TimelineResponse?>> executeGetForYouPost({
    required bool isLoading,
    required int page,
    required int pageLimit,
  }) async =>
      await super.execute(() async {
        final response = await _repository.getForYouPosts(
          isLoading: isLoading,
          page: page,
          pageLimit: pageLimit,
        );
        return ApiResult(
            data: response.responseCode == 200 ? response.data : null);
      });
}
