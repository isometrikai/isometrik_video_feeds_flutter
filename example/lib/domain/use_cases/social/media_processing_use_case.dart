import 'package:ism_video_reel_player_example/core/core.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';

class MediaProcessingUseCase extends BaseUseCase {
  MediaProcessingUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<ResponseClass?>> executeMediaProcessing({
    required bool isLoading,
    required String postId,
  }) async =>
      await super.execute(() async {
        final response = await _repository.processMedia(
          isLoading: isLoading,
          postId: postId,
        );
        return ApiResult(data: response.responseCode == 200 ? response.data : null);
      });
}
