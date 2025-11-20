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
        return ApiResult(data: response.responseCode == 200 ? response.data : null);
      });
}
