import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class GetSocialProductsUseCase extends BaseUseCase {
  GetSocialProductsUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<PostDetailsResponse?>> executeGetSocialProducts({
    required bool isLoading,
    required String postId,
    List<String>? productIds,
    int? page,
    int? limit,
  }) async =>
      await super.execute(() async {
        final response = await _repository.getSocialProducts(
          isLoading: isLoading,
          postId: postId,
          productIds: productIds,
          page: page,
          limit: limit,
        );
        return ApiResult(
            data: response.responseCode == 200 ? response.data : null);
      });
}
