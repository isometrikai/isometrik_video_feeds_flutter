import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class GetTrendingPostUseCase extends BaseUseCase {
  GetTrendingPostUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<TimelineDataResponse?>> executeGetTrendingPost({
    required bool isLoading,
    required String? cursor,
    required int limit,
  }) async =>
      await super.execute(() async {
        final response = await _repository.getTrendingPost(
          isLoading: isLoading,
          cursor: cursor,
          limit: limit,
        );
        return ApiResult(
            data: response.responseCode == 200 ? response.data : null);
      });
}
