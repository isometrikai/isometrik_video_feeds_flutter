import 'package:ism_video_reel_player_example/core/core.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

class SavePostUseCase extends BaseUseCase {
  SavePostUseCase(this._repository);

  final SocialRepository _repository;

  Future<ApiResult<ResponseClass?>> executeSavePost({
    required bool isLoading,
    required String postId,
    required SocialPostAction socialPostAction,
  }) async =>
      await super.execute(() async {
        final response = await _repository.savePost(
          isLoading: isLoading,
          postId: postId,
          socialPostAction: socialPostAction,
        );
        return ApiResult(
            data: response.responseCode == 200 ? response.data : null);
      });
}
