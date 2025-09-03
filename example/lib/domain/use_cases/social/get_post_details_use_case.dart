import 'package:ism_video_reel_player_example/core/core.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';

class GetPostDetailsUseCase extends BaseUseCase {
  GetPostDetailsUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<PostDetailsResponse?>> executeGetPostDetails({
    required bool isLoading,
    List<String>? productIds,
    String? postId,
    int? page,
    int? limit,
  }) async =>
      await super.execute(() async {
        final response = await _repository.getPostDetails(
          isLoading: isLoading,
          productIds: productIds,
          page: page,
          limit: limit,
        );
        return ApiResult(data: response.responseCode == 200 ? response.data : null);
      });
}
