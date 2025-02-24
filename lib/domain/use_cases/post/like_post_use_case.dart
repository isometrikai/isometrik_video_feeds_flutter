import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class LikePostUseCase extends BaseUseCase {
  LikePostUseCase(this._repository);

  final PostRepository _repository;

  Future<ApiResult<ResponseClass?>> executeLikePost({
    required bool isLoading,
    required String postId,
    required String userId,
    required LikeAction likeAction,
  }) async =>
      await super.execute(() async {
        final response = await _repository.likePost(
          isLoading: isLoading,
          postId: postId,
          userId: userId,
          likeAction: likeAction,
        );
        return ApiResult(data: response.responseCode == 200 ? response.data : null);
      });
}
