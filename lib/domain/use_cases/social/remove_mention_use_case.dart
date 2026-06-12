import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class RemoveMentionUseCase extends BaseUseCase {
  RemoveMentionUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<ResponseClass?>> executeRemoveMention({
    required bool isLoading,
    required String postId,
  }) async =>
      await super.execute(() async {
        final response = await _repository.removeMentionFromPost(
          isLoading: isLoading,
          postId: postId,
        );
        final statusCode = response.responseCode ?? 0;
        return ApiResult(
          data: statusCode >= 200 && statusCode < 300 ? response.data : null,
          statusCode: statusCode,
        );
      });
}
