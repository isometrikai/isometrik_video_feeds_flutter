import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class GetPostInsightTimeSeriesUseCase extends BaseUseCase {
  GetPostInsightTimeSeriesUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<InsightsTimeSeriesResponse?>> executeGetPostInsightTimeSeries({
    required bool isLoading,
    required String postId,
    required String start,
    required String end,
  }) async =>
      await super.execute(() async {
        final response = await _repository.getPostInsightTimeSeries(
          isLoading: isLoading,
          postId: postId,
          start: start,
          end: end,
        );
        return ApiResult(
            data: response.responseCode == 200 ? response.data : null);
      });
}
