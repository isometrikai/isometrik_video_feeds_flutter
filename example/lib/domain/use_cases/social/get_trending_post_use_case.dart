import 'package:ism_video_reel_player_example/core/core.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';

class GetTrendingPostUseCase extends BaseUseCase {
  GetTrendingPostUseCase(this._repository);

  final PostRepository _repository;

  Future<ApiResult<PostResponse?>> executeGetTrendingPost({
    required bool isLoading,
    required int page,
    required int pageLimit,
    Map<String, dynamic>? createPostRequest,
  }) async =>
      await super.execute(() async {
        final response = await _repository.getTrendingPost(
          isLoading: isLoading,
          page: page,
          pageLimit: pageLimit,
        );
        return ApiResult(
            data: response.responseCode == 200 ? response.data : null);
      });
}
