import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class GetPostsBySoundUseCase extends BaseUseCase {
  GetPostsBySoundUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<PostsBySoundResponse?>> executeGetPostsBySound({
    required bool isLoading,
    required String soundId,
    required int page,
    required int pageSize,
  }) async =>
      super.execute(() async {
        final response = await _repository.getPostsBySound(
          isLoading: isLoading,
          soundId: soundId,
          page: page,
          pageSize: pageSize,
        );
        return ApiResult(
          data: response.responseCode == 200 ? response.data : null,
        );
      });
}
