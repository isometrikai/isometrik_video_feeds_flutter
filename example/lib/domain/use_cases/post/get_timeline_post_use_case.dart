import 'package:ism_video_reel_player_example/core/core.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';

class GetTimelinePostUseCase extends BaseUseCase {
  GetTimelinePostUseCase(this._repository);

  final PostRepository _repository;

  Future<ApiResult<TimelineResponse?>> executeTimeLinePost({
    required bool isLoading,
    required int page,
    required int pageLimit,
  }) async =>
      await super.execute(() async {
        final response = await _repository.getTimeLinePosts(
          isLoading: isLoading,
          page: page,
          pageLimit: pageLimit,
        );
        return ApiResult(data: response.responseCode == 200 ? response.data : null);
      });
}
