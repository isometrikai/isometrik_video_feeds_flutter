import 'package:ism_video_reel_player/core/core.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class SavePostUseCase extends BaseUseCase {
  SavePostUseCase(this._repository);

  final PostRepository _repository;

  Future<ApiResult<ResponseClass?>> executeSavePost({
    required bool isLoading,
    required String postId,
  }) async =>
      await super.execute(() async {
        final response = await _repository.savePost(
          isLoading: isLoading,
          postId: postId,
        );
        return ApiResult(data: response.responseCode == 200 ? response.data : null);
      });
} 